/* =====================================================================
   MODULE A - DANH MỤC KHÓA HỌC
   Sinh viên thực hiện: Đoàn Trung Kiên - MSSV 24110262
   Đề tài : Hệ thống quản lý trung tâm ngoại ngữ (DBMS330284)
   CSDL   : QL_TTNgoaiNgu  (schema đã khóa cứng - KHÔNG thêm/sửa bảng)
   Bảng phụ trách: NGONNGU, KHOAHOC

   12 đối tượng:
     Trigger     : TRG_KHOAHOC_NgungTuyenSinh, TRG_KHOAHOC_KhoaNgonNgu
     View        : V_KHOAHOC_ThongKe, V_THONGKE_NgonNgu
     Index       : IX_KHOAHOC_MaNN_TrangThai, IX_KHOAHOC_HocPhi
     Procedure   : SP_TimKiemKhoaHoc, SP_ThongKeDangKy_TheoKhoa
     Function    : FN_SoHocVien_KhoaHoc (scalar), FN_DSKhoaHoc_TheoNN (table-valued)
     Transaction : SP_CapNhatHocPhiKhoa, SP_ThemKhoaHoc_VaNgonNgu

   THAY ĐỔI SO VỚI KẾ HOẠCH (đã thống nhất):
     - TRG_KHOAHOC_GhiLogHocPhi  -> TRG_KHOAHOC_KhoaNgonNgu  (không thêm bảng LOG_HOCPHI)
     - IX_KHOAHOC_TenKhoa        -> IX_KHOAHOC_HocPhi
       (tìm tên dạng LIKE N'%...%' không seek được index trên TenKhoa)

   QUY ƯỚC CHUNG CỦA NHÓM:
     - Tiền tố TRG_/V_/IX_/SP_/FN_ ; mọi trigger/procedure bắt đầu SET NOCOUNT ON.
     - Mọi procedure có TRY...CATCH, lỗi thì ROLLBACK rồi THROW cho ứng dụng.
     - Mã lỗi THROW của Kiên dùng dải 51000 - 51999 (B dùng 52000 - 52999).
     - Procedure có giao dịch dùng mẫu "lồng an toàn" giống Module B
       (@@TRANCOUNT = 0 -> BEGIN/COMMIT; > 0 -> SAVE TRANSACTION) để gọi được cả từ
       JpaUtil.inTx(...) (đã có giao dịch JPA) lẫn chạy thẳng trong SSMS.

   Đối tượng của A CHỈ ĐỌC bảng của người khác (LOP, DANGKY, GIANGVIEN), trừ
   SP_CapNhatHocPhiKhoa cập nhật HOADON.SoTienCanThu (đã thống nhất với B).

   FILE CHẠY LẠI NHIỀU LẦN KHÔNG LỖI. Yêu cầu SQL Server 2016 SP1 trở lên.
   THỨ TỰ: Index -> Function -> View -> Trigger -> Procedure -> Transaction.
   ===================================================================== */

USE QL_TTNgoaiNgu;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1. INDEX
   ===================================================================== */

-- IX_KHOAHOC_MaNN_TrangThai
-- Mục đích : khóa ngoại KHOAHOC.MaNN chưa có index (SQL Server không tự tạo index cho FK).
--            Phục vụ: lọc khóa học theo ngôn ngữ + trạng thái (FN_DSKhoaHoc_TheoNN,
--            SP_TimKiemKhoaHoc khi chọn ngôn ngữ), phép nối NGONNGU - KHOAHOC trong
--            V_THONGKE_NgonNgu. INCLUDE các cột FN_DSKhoaHoc_TheoNN trả về nên hàm này
--            đọc trọn trên index, không phải quay lại bảng (Key Lookup).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_KHOAHOC_MaNN_TrangThai' AND object_id = OBJECT_ID(N'dbo.KHOAHOC'))
    CREATE NONCLUSTERED INDEX IX_KHOAHOC_MaNN_TrangThai
        ON dbo.KHOAHOC (MaNN, TrangThai)
        INCLUDE (TenKhoa, TrinhDo, SoBuoi, HocPhi);
GO

-- IX_KHOAHOC_HocPhi
-- Mục đích : tìm khóa học theo khoảng học phí (HocPhi BETWEEN min AND max) trong
--            SP_TimKiemKhoaHoc. Điều kiện khoảng trên cột đầu của index -> Index Seek.
--            INCLUDE các cột còn lại mà SP_TimKiemKhoaHoc trả về để tránh Key Lookup.
--            Đánh đổi: tốn thêm dung lượng và INSERT/UPDATE học phí chậm hơn một chút;
--            chấp nhận được vì KHOAHOC là bảng danh mục, đọc nhiều - ghi ít.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_KHOAHOC_HocPhi' AND object_id = OBJECT_ID(N'dbo.KHOAHOC'))
    CREATE NONCLUSTERED INDEX IX_KHOAHOC_HocPhi
        ON dbo.KHOAHOC (HocPhi)
        INCLUDE (TenKhoa, MaNN, TrinhDo, SoBuoi, TrangThai);
GO

/* =====================================================================
   2. FUNCTION
   ===================================================================== */

-- FN_SoHocVien_KhoaHoc (scalar) : số học viên KHÁC NHAU đã đăng ký các lớp của một khóa
-- (một học viên học 2 lớp cùng khóa chỉ tính 1). Trả NULL nếu khóa học không tồn tại,
-- trả 0 nếu khóa có nhưng chưa có đăng ký. Dùng trong V_KHOAHOC_ThongKe.
CREATE OR ALTER FUNCTION dbo.FN_SoHocVien_KhoaHoc (@MaKH VARCHAR(6))
RETURNS INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.KHOAHOC WHERE MaKH = @MaKH)
        RETURN NULL;

    RETURN (SELECT COUNT(DISTINCT dk.MaHV)
            FROM dbo.DANGKY AS dk
            JOIN dbo.LOP    AS l ON l.MaLop = dk.MaLop
            WHERE l.MaKH = @MaKH);
END;
GO

-- FN_DSKhoaHoc_TheoNN (inline table-valued) : danh sách khóa học 'Đang giảng dạy' của
-- một ngôn ngữ. Ứng dụng dùng cho ô chọn khóa học sau khi chọn ngôn ngữ.
-- Truy vấn khớp đúng IX_KHOAHOC_MaNN_TrangThai (seek theo MaNN + TrangThai, đủ cột).
CREATE OR ALTER FUNCTION dbo.FN_DSKhoaHoc_TheoNN (@MaNN CHAR(3))
RETURNS TABLE
AS
RETURN
(
    SELECT kh.MaKH, kh.TenKhoa, kh.TrinhDo, kh.SoBuoi, kh.HocPhi
    FROM dbo.KHOAHOC AS kh
    WHERE kh.MaNN = @MaNN
      AND kh.TrangThai = N'Đang giảng dạy'
);
GO

/* =====================================================================
   3. VIEW
   ===================================================================== */

-- V_KHOAHOC_ThongKe : mỗi khóa học kèm ngôn ngữ, tổng số lớp, số lớp đang mở
-- (đang tuyển sinh hoặc đang học) và số học viên (FN_SoHocVien_KhoaHoc).
-- Khóa chưa có lớp vẫn hiện với số lớp = 0 (OUTER APPLY).
CREATE OR ALTER VIEW dbo.V_KHOAHOC_ThongKe
AS
SELECT kh.MaKH,
       kh.TenKhoa,
       kh.MaNN,
       nn.TenNN,
       kh.TrinhDo,
       kh.SoBuoi,
       kh.HocPhi,
       kh.TrangThai,
       ISNULL(lp.SoLop, 0)      AS SoLop,
       ISNULL(lp.SoLopDangMo, 0) AS SoLopDangMo,
       dbo.FN_SoHocVien_KhoaHoc(kh.MaKH) AS SoHocVien
FROM dbo.KHOAHOC AS kh
JOIN dbo.NGONNGU AS nn ON nn.MaNN = kh.MaNN
OUTER APPLY (SELECT COUNT(*) AS SoLop,
                    SUM(CASE WHEN l.TrangThai IN (N'Đang tuyển sinh', N'Đang học') THEN 1 ELSE 0 END) AS SoLopDangMo
             FROM dbo.LOP AS l
             WHERE l.MaKH = kh.MaKH) AS lp;
GO

-- V_THONGKE_NgonNgu : mỗi ngôn ngữ kèm số khóa học (tổng / đang giảng dạy), số lớp,
-- số giảng viên (tổng / đang công tác). Mỗi số đếm bằng truy vấn con riêng nên các
-- phép nối không nhân dòng lẫn nhau. Chỉ đọc LOP (người C) và GIANGVIEN (người D).
CREATE OR ALTER VIEW dbo.V_THONGKE_NgonNgu
AS
SELECT nn.MaNN,
       nn.TenNN,
       (SELECT COUNT(*) FROM dbo.KHOAHOC AS kh
         WHERE kh.MaNN = nn.MaNN)                                  AS SoKhoaHoc,
       (SELECT COUNT(*) FROM dbo.KHOAHOC AS kh
         WHERE kh.MaNN = nn.MaNN AND kh.TrangThai = N'Đang giảng dạy') AS SoKhoaDangGiangDay,
       (SELECT COUNT(*) FROM dbo.LOP AS l
         JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH
         WHERE kh.MaNN = nn.MaNN)                                  AS SoLop,
       (SELECT COUNT(*) FROM dbo.GIANGVIEN AS gv
         WHERE gv.MaNN = nn.MaNN)                                  AS SoGiangVien,
       (SELECT COUNT(*) FROM dbo.GIANGVIEN AS gv
         WHERE gv.MaNN = nn.MaNN AND gv.TrangThai = N'Đang công tác') AS SoGVDangCongTac
FROM dbo.NGONNGU AS nn;
GO

/* =====================================================================
   4. TRIGGER
   ===================================================================== */

-- TRG_KHOAHOC_NgungTuyenSinh
-- Không cho chuyển khóa học sang 'Ngừng tuyển sinh' khi khóa còn lớp 'Đang tuyển sinh':
-- phải đóng tuyển sinh các lớp đó trước, tránh trạng thái mâu thuẫn "khóa ngừng tuyển
-- nhưng lớp vẫn đang tuyển" (SP_DangKy_VaTaoHoaDon của B cũng từ chối khóa ngừng tuyển).
-- Lớp 'Đang học' KHÔNG bị chặn: ngừng tuyển sinh không ảnh hưởng học viên đang học.
CREATE OR ALTER TRIGGER dbo.TRG_KHOAHOC_NgungTuyenSinh
ON dbo.KHOAHOC
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(TrangThai)
        RETURN;

    DECLARE @MaKH VARCHAR(6), @MaLop VARCHAR(6), @Msg NVARCHAR(300);

    SELECT TOP (1) @MaKH = i.MaKH, @MaLop = l.MaLop
    FROM inserted AS i
    JOIN deleted  AS d ON d.MaKH = i.MaKH
    JOIN dbo.LOP  AS l ON l.MaKH = i.MaKH
    WHERE i.TrangThai = N'Ngừng tuyển sinh'
      AND d.TrangThai <> N'Ngừng tuyển sinh'
      AND l.TrangThai = N'Đang tuyển sinh'
    ORDER BY i.MaKH, l.MaLop;

    IF @MaKH IS NOT NULL
    BEGIN
        SET @Msg = N'Không thể ngừng tuyển sinh khóa ' + @MaKH + N': lớp ' + @MaLop
                 + N' vẫn đang tuyển sinh. Hãy đổi trạng thái các lớp đang tuyển sinh trước.';
        THROW 51001, @Msg, 1;
    END;
END;
GO

-- TRG_KHOAHOC_KhoaNgonNgu
-- Không cho đổi ngôn ngữ (MaNN) của khóa học đã có lớp (kể cả lớp đã kết thúc).
-- Lý do: giảng viên chính của lớp phải cùng ngôn ngữ với khóa học (TRG_LOP_KiemTraGV
-- của người C chỉ kiểm khi ghi vào LOP). Nếu đổi MaNN của khóa, mọi lớp cũ lập tức có
-- giảng viên sai ngôn ngữ mà không trigger nào phát hiện. FK/CHECK không biểu diễn được
-- quy tắc này. Khóa chưa có lớp vẫn được sửa MaNN (sửa nhập sai).
CREATE OR ALTER TRIGGER dbo.TRG_KHOAHOC_KhoaNgonNgu
ON dbo.KHOAHOC
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(MaNN)
        RETURN;

    DECLARE @MaKH VARCHAR(6), @Msg NVARCHAR(300);

    SELECT TOP (1) @MaKH = i.MaKH
    FROM inserted AS i
    JOIN deleted  AS d ON d.MaKH = i.MaKH
    WHERE i.MaNN <> d.MaNN
      AND EXISTS (SELECT 1 FROM dbo.LOP AS l WHERE l.MaKH = i.MaKH)
    ORDER BY i.MaKH;

    IF @MaKH IS NOT NULL
    BEGIN
        SET @Msg = N'Không thể đổi ngôn ngữ của khóa ' + @MaKH
                 + N' vì khóa đã có lớp học (giảng viên các lớp sẽ sai ngôn ngữ). Hãy tạo khóa học mới.';
        THROW 51002, @Msg, 1;
    END;
END;
GO

/* =====================================================================
   5. STORED PROCEDURE (truy vấn / thống kê)
   ===================================================================== */

-- SP_TimKiemKhoaHoc : tìm khóa học theo tên (khớp một phần), ngôn ngữ, trạng thái,
-- khoảng học phí. Tiêu chí NULL hoặc rỗng thì bỏ qua; nhiều tiêu chí là AND.
-- Ký tự đặc biệt của LIKE (% _ [ \) được escape giống SP_TimKiemHocVien của B.
-- OPTION (RECOMPILE): kế hoạch thực thi lập theo tiêu chí thật sự được nhập, nên khi
-- có khoảng học phí thì dùng được Index Seek trên IX_KHOAHOC_HocPhi, khi có ngôn ngữ
-- thì dùng IX_KHOAHOC_MaNN_TrangThai.
CREATE OR ALTER PROCEDURE dbo.SP_TimKiemKhoaHoc
    @TenKhoa   NVARCHAR(100) = NULL,
    @MaNN      CHAR(3)       = NULL,
    @TrangThai NVARCHAR(20)  = NULL,
    @HocPhiMin MONEY         = NULL,
    @HocPhiMax MONEY         = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @pTen NVARCHAR(220) = NULL;

        SET @TenKhoa   = NULLIF(LTRIM(RTRIM(@TenKhoa)), N'');
        SET @MaNN      = NULLIF(LTRIM(RTRIM(@MaNN)), '');
        SET @TrangThai = NULLIF(LTRIM(RTRIM(@TrangThai)), N'');

        IF @HocPhiMin < 0 OR @HocPhiMax < 0
            THROW 51010, N'Học phí tìm kiếm không được âm.', 1;
        IF @HocPhiMin > @HocPhiMax
            THROW 51011, N'Học phí từ phải nhỏ hơn hoặc bằng học phí đến.', 1;
        IF @TrangThai IS NOT NULL AND @TrangThai NOT IN (N'Đang giảng dạy', N'Ngừng tuyển sinh')
            THROW 51012, N'Trạng thái khóa học không hợp lệ (Đang giảng dạy / Ngừng tuyển sinh).', 1;

        IF @TenKhoa IS NOT NULL
            SET @pTen = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@TenKhoa, N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';

        SELECT kh.MaKH, kh.TenKhoa, kh.MaNN, nn.TenNN, kh.TrinhDo, kh.SoBuoi, kh.HocPhi, kh.TrangThai
        FROM dbo.KHOAHOC AS kh
        JOIN dbo.NGONNGU AS nn ON nn.MaNN = kh.MaNN
        WHERE (@pTen      IS NULL OR kh.TenKhoa LIKE @pTen ESCAPE N'\')
          AND (@MaNN      IS NULL OR kh.MaNN = @MaNN)
          AND (@TrangThai IS NULL OR kh.TrangThai = @TrangThai)
          AND (@HocPhiMin IS NULL OR kh.HocPhi >= @HocPhiMin)
          AND (@HocPhiMax IS NULL OR kh.HocPhi <= @HocPhiMax)
        ORDER BY kh.HocPhi, kh.MaKH
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

-- SP_ThongKeDangKy_TheoKhoa : số đăng ký theo khóa học trong khoảng ngày đăng ký.
--   @TuNgay / @DenNgay NULL = không giới hạn phía đó (cả hai NULL = toàn bộ).
--   Trả về MỌI khóa học (khóa không có đăng ký trong kỳ hiện số 0) gồm: số lớp có đăng
--   ký, số đăng ký, số học viên khác nhau, tỷ lệ % trên tổng số đăng ký của kỳ.
--   Khác SP_ThongKeDoanhThu của B: B thống kê TIỀN, thủ tục này thống kê SỐ ĐĂNG KÝ.
CREATE OR ALTER PROCEDURE dbo.SP_ThongKeDangKy_TheoKhoa
    @TuNgay  DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @TuNgay > @DenNgay
            THROW 51020, N'Từ ngày phải nhỏ hơn hoặc bằng đến ngày.', 1;

        SELECT kh.MaKH,
               kh.TenKhoa,
               nn.TenNN,
               COUNT(DISTINCT dk.MaLop) AS SoLopCoDangKy,
               COUNT(dk.MaDK)           AS SoDangKy,
               COUNT(DISTINCT dk.MaHV)  AS SoHocVien,
               CAST(ISNULL(COUNT(dk.MaDK) * 100.0 / NULLIF(SUM(COUNT(dk.MaDK)) OVER (), 0), 0)
                    AS DECIMAL(5, 2))   AS TyLePhanTram
        FROM dbo.KHOAHOC AS kh
        JOIN dbo.NGONNGU AS nn ON nn.MaNN = kh.MaNN
        LEFT JOIN (dbo.LOP AS l
                   JOIN dbo.DANGKY AS dk
                     ON dk.MaLop = l.MaLop
                    AND (@TuNgay  IS NULL OR dk.NgayDangKy >= @TuNgay)
                    AND (@DenNgay IS NULL OR dk.NgayDangKy <= @DenNgay))
               ON l.MaKH = kh.MaKH
        GROUP BY kh.MaKH, kh.TenKhoa, nn.TenNN
        ORDER BY SoDangKy DESC, kh.MaKH
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* =====================================================================
   6. TRANSACTION (procedure có giao dịch - mẫu "lồng an toàn" giống Module B)
     - @TranCount = @@TRANCOUNT ở đầu.
     - @TranCount = 0 -> tự BEGIN TRANSACTION, COMMIT ở lệnh cuối khối TRY.
     - @TranCount > 0 (JPA đã mở giao dịch) -> SAVE TRANSACTION; lỗi chỉ rollback về
       savepoint, không commit/rollback hộ giao dịch bên ngoài.
     - XACT_STATE() = -1 (giao dịch hỏng) -> ROLLBACK toàn bộ.
     - Cuối CATCH luôn THROW để ứng dụng nhận lỗi.
   ===================================================================== */

-- SP_CapNhatHocPhiKhoa : đổi học phí của khóa học VÀ cập nhật số tiền cần thu của mọi
-- hóa đơn CHƯA THANH TOÁN (chưa thu đồng nào) thuộc các lớp của khóa đó - kể cả lớp đã
-- kết thúc - trong MỘT giao dịch. Hóa đơn đã thu một phần / đã thu đủ giữ nguyên.
--   Đồng thời: khóa dòng KHOAHOC bằng UPDLOCK, HOLDLOCK. SP_DangKy_VaTaoHoaDon của B đọc
--   học phí bằng HOLDLOCK nên hai thủ tục xếp hàng: đăng ký mới hoặc lấy học phí cũ
--   (rồi hóa đơn mới được thủ tục này cập nhật), hoặc lấy học phí mới - không lẫn lộn.
--   Trạng thái hóa đơn do TRG_HOADON_TuDongTrangThai (B) tự tính lại.
--   OUTPUT @SoHoaDonCapNhat : số hóa đơn đã đổi số tiền cần thu.
CREATE OR ALTER PROCEDURE dbo.SP_CapNhatHocPhiKhoa
    @MaKH            VARCHAR(6),
    @HocPhiMoi       MONEY,
    @SoHoaDonCapNhat INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SV_CapNhatHocPhi;
        END;

        DECLARE @HocPhiCu MONEY;
        DECLARE @DSHoaDon TABLE (MaHD VARCHAR(8) NOT NULL PRIMARY KEY);

        SET @SoHoaDonCapNhat = 0;
        SET @MaKH = LTRIM(RTRIM(@MaKH));

        -- 1) Kiểm tra tham số
        IF ISNULL(@MaKH, '') = ''
            THROW 51030, N'Thiếu mã khóa học.', 1;
        IF @HocPhiMoi IS NULL OR @HocPhiMoi < 0
            THROW 51031, N'Học phí mới phải được nhập và không được âm.', 1;

        -- 2) Khóa dòng khóa học tới hết giao dịch
        SELECT @HocPhiCu = kh.HocPhi
        FROM dbo.KHOAHOC AS kh WITH (UPDLOCK, HOLDLOCK)
        WHERE kh.MaKH = @MaKH;

        IF @HocPhiCu IS NULL
            THROW 51032, N'Khóa học không tồn tại.', 1;
        IF @HocPhiCu = @HocPhiMoi
            THROW 51033, N'Học phí mới trùng với học phí hiện tại, không có gì để cập nhật.', 1;

        -- 3) Đổi học phí khóa học
        UPDATE dbo.KHOAHOC
        SET HocPhi = @HocPhiMoi
        WHERE MaKH = @MaKH;

        -- 4) Cập nhật các hóa đơn chưa thanh toán của mọi lớp thuộc khóa
        UPDATE hd
        SET hd.SoTienCanThu = @HocPhiMoi
        OUTPUT inserted.MaHD INTO @DSHoaDon (MaHD)
        FROM dbo.HOADON AS hd
        JOIN dbo.DANGKY AS dk ON dk.MaDK = hd.MaDK
        JOIN dbo.LOP    AS l  ON l.MaLop = dk.MaLop
        WHERE l.MaKH = @MaKH
          AND hd.TrangThaiThanhToan = N'Chưa thanh toán'
          AND hd.SoTienDaThu = 0;

        SELECT @SoHoaDonCapNhat = COUNT(*) FROM @DSHoaDon;

        -- COMMIT là lệnh cuối của khối TRY
        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @SoHoaDonCapNhat = 0;
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_CapNhatHocPhi;
        END;
        THROW;
    END CATCH;
END;
GO

-- SP_ThemKhoaHoc_VaNgonNgu : thêm khóa học; nếu ngôn ngữ chưa có thì thêm ngôn ngữ
-- trước, cả hai trong MỘT giao dịch (thêm khóa lỗi thì ngôn ngữ vừa thêm cũng bị hủy).
--   @MaNN đã tồn tại : @TenNN có thể bỏ trống; nếu nhập thì phải trùng tên hiện có.
--   @MaNN chưa có    : bắt buộc @TenNN, và tên không được trùng ngôn ngữ khác.
--   Khóa mới luôn ở trạng thái 'Đang giảng dạy'.
--   Mã khóa học sinh trong thủ tục (KH0001 ... KH9999), tuần tự hóa bằng sp_getapplock
--   giống cách B sinh mã DK/HD.
--   OUTPUT @MaKH (mã khóa vừa tạo), @DaThemNgonNgu (1 = có thêm ngôn ngữ mới).
CREATE OR ALTER PROCEDURE dbo.SP_ThemKhoaHoc_VaNgonNgu
    @MaNN          CHAR(3),
    @TenNN         NVARCHAR(30) = NULL,
    @TenKhoa       NVARCHAR(50),
    @TrinhDo       NVARCHAR(10),
    @SoBuoi        INT,
    @HocPhi        MONEY,
    @MaKH          VARCHAR(6) OUTPUT,
    @DaThemNgonNgu BIT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SV_ThemKhoaHoc;
        END;

        DECLARE @TenNNHienCo NVARCHAR(30),
                @Rc          INT,
                @So          INT;

        SET @MaKH = NULL;
        SET @DaThemNgonNgu = 0;
        SET @MaNN    = NULLIF(LTRIM(RTRIM(@MaNN)), '');
        SET @TenNN   = NULLIF(LTRIM(RTRIM(@TenNN)), N'');
        SET @TenKhoa = NULLIF(LTRIM(RTRIM(@TenKhoa)), N'');
        SET @TrinhDo = NULLIF(LTRIM(RTRIM(@TrinhDo)), N'');

        -- 1) Kiểm tra tham số (báo lỗi rõ ràng trước khi CHECK của bảng chặn)
        IF @MaNN IS NULL OR @TenKhoa IS NULL OR @TrinhDo IS NULL
            THROW 51040, N'Thiếu mã ngôn ngữ, tên khóa học hoặc trình độ.', 1;
        IF @SoBuoi IS NULL OR @SoBuoi < 1 OR @SoBuoi > 255
            THROW 51041, N'Số buổi phải từ 1 đến 255.', 1;
        IF @HocPhi IS NULL OR @HocPhi < 0
            THROW 51042, N'Học phí phải được nhập và không được âm.', 1;

        -- 2) Ngôn ngữ: khóa dòng (hoặc khoảng khóa nếu chưa có) để phiên khác không
        --    thêm cùng mã ngôn ngữ giữa chừng
        SELECT @TenNNHienCo = nn.TenNN
        FROM dbo.NGONNGU AS nn WITH (UPDLOCK, HOLDLOCK)
        WHERE nn.MaNN = @MaNN;

        IF @TenNNHienCo IS NULL
        BEGIN
            IF @TenNN IS NULL
                THROW 51043, N'Ngôn ngữ chưa có trong hệ thống, hãy nhập tên ngôn ngữ để thêm mới.', 1;
            IF EXISTS (SELECT 1 FROM dbo.NGONNGU WITH (UPDLOCK, HOLDLOCK) WHERE TenNN = @TenNN)
                THROW 51044, N'Tên ngôn ngữ đã được dùng cho một mã ngôn ngữ khác.', 1;

            INSERT INTO dbo.NGONNGU (MaNN, TenNN)
            VALUES (@MaNN, @TenNN);

            SET @DaThemNgonNgu = 1;
        END
        ELSE IF @TenNN IS NOT NULL AND @TenNN <> @TenNNHienCo
            THROW 51045, N'Mã ngôn ngữ đã tồn tại với tên khác.', 1;

        -- 3) Sinh mã khóa học (khóa ứng dụng, tự nhả khi hết giao dịch)
        EXEC @Rc = sys.sp_getapplock @Resource    = N'TTNN_SinhMa_KhoaHoc',
                                     @LockMode    = N'Exclusive',
                                     @LockOwner   = N'Transaction',
                                     @LockTimeout = 10000;
        IF @Rc < 0
            THROW 51046, N'Hệ thống đang bận sinh mã khóa học, vui lòng thử lại.', 1;

        SELECT @So = ISNULL(MAX(TRY_CAST(SUBSTRING(MaKH, 3, 4) AS INT)), 0) + 1
        FROM dbo.KHOAHOC
        WHERE MaKH LIKE 'KH[0-9][0-9][0-9][0-9]';

        IF @So > 9999
            THROW 51047, N'Đã hết dải mã khóa học (KH9999).', 1;

        SET @MaKH = 'KH' + RIGHT('0000' + CAST(@So AS VARCHAR(5)), 4);

        -- 4) Thêm khóa học
        INSERT INTO dbo.KHOAHOC (MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai)
        VALUES (@MaKH, @TenKhoa, @MaNN, @TrinhDo, @SoBuoi, @HocPhi, N'Đang giảng dạy');

        -- COMMIT là lệnh cuối của khối TRY
        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @MaKH = NULL;
        SET @DaThemNgonNgu = 0;
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_ThemKhoaHoc;
        END;
        THROW;
    END CATCH;
END;
GO

/* =====================================================================
   7. KIỂM TRA: liệt kê 12 đối tượng của A đã được tạo (mong đợi 12 dòng)
   ===================================================================== */
SELECT o.type_desc AS LoaiDoiTuong, o.name AS TenDoiTuong
FROM sys.objects AS o
WHERE o.name IN (N'TRG_KHOAHOC_NgungTuyenSinh', N'TRG_KHOAHOC_KhoaNgonNgu',
                 N'V_KHOAHOC_ThongKe', N'V_THONGKE_NgonNgu',
                 N'SP_TimKiemKhoaHoc', N'SP_ThongKeDangKy_TheoKhoa',
                 N'FN_SoHocVien_KhoaHoc', N'FN_DSKhoaHoc_TheoNN',
                 N'SP_CapNhatHocPhiKhoa', N'SP_ThemKhoaHoc_VaNgonNgu')
UNION ALL
SELECT N'INDEX', i.name
FROM sys.indexes AS i
WHERE i.name IN (N'IX_KHOAHOC_MaNN_TrangThai', N'IX_KHOAHOC_HocPhi')
ORDER BY 1, 2;
GO

