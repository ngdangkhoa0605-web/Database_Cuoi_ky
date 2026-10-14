/* =====================================================================
   MODULE D - GIẢNG VIÊN VÀ GIẢNG DẠY
   Database : QL_TTNgoaiNgu (SQL Server 2016 SP1 trở lên)
   Bảng phụ trách : GIANGVIEN, BUOIHOC, DIEMDANH
   Gồm 12 đối tượng: 2 Trigger, 2 View, 2 Index, 2 Procedure,
                     2 Function, 2 Transaction

   Quy ước chung của nhóm:
   - Tiền tố TRG_ / V_ / IX_ / SP_ / FN_
   - Mọi trigger và procedure bắt đầu bằng SET NOCOUNT ON
   - Trigger chỉ THROW (không ROLLBACK); thủ tục giao dịch dùng mẫu
     @@TRANCOUNT + SAVE TRANSACTION giống module B
   - Mã lỗi: A 510xx, B 520xx, C 530xx (dự kiến), D 540xx (54001 - 54099)

   Script chạy lại được nhiều lần (CREATE OR ALTER / kiểm tra tồn tại).
   Thứ tự tạo: Function -> View -> Index -> Trigger -> Procedure,
   vì view dùng function, procedure dùng cả view lẫn function.

   Quy ước thứ trong tuần: Chủ Nhật = 1 ... Thứ 7 = 7 (khớp LICHHOC.Thu).

   THỨ TỰ CHẠY TOÀN NHÓM: schema -> dữ liệu mẫu -> Module A, B, C, D
       -> Security_Roles.sql -> Grant_Module_*.sql (có Grant_Module_D.sql) -> Test_Module_*.sql
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO

/* =====================================================================
   PHẦN 1. FUNCTION
   ===================================================================== */

-- ---------------------------------------------------------------------
-- FN_TyLeChuyenCan (scalar)
-- Tỷ lệ chuyên cần (%) của MỘT đăng ký = số lượt "Có mặt" / tổng số lượt
-- đã được điểm danh của đăng ký đó. Trả về NULL nếu chưa có lượt nào.
-- Mẫu số là số lượt ĐÃ điểm danh (không phải số buổi của lớp) để học viên
-- vào lớp muộn không bị tính thiếu những buổi diễn ra trước ngày đăng ký.
-- Vắng có phép vẫn tính là không có mặt.
-- ---------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.FN_TyLeChuyenCan (@MaDK VARCHAR(8))
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @TongLuot INT, @SoCoMat INT;

    SELECT @TongLuot = COUNT(*),
           @SoCoMat  = COUNT(CASE WHEN TrangThaiDiemDanh = N'Có mặt' THEN 1 END)
    FROM dbo.DIEMDANH
    WHERE MaDK = @MaDK;

    RETURN CASE WHEN @TongLuot = 0 THEN NULL
                ELSE CAST(@SoCoMat * 100.0 / @TongLuot AS DECIMAL(5,2))
           END;
END;
GO

-- ---------------------------------------------------------------------
-- FN_DSGiangVien_TheoNN (inline table-valued)
-- Giảng viên ĐANG CÔNG TÁC của một ngôn ngữ, kèm số lớp đang phụ trách
-- (lớp đang tuyển sinh hoặc đang học). Dùng để chọn người nhận bàn giao.
-- ---------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.FN_DSGiangVien_TheoNN (@MaNN CHAR(3))
RETURNS TABLE
AS
RETURN
(
    SELECT gv.MaGV, gv.HoTen, gv.SDT, gv.Email,
           SoLopDangPhuTrach = (SELECT COUNT(*)
                                FROM dbo.LOP l
                                WHERE l.MaGV_Chinh = gv.MaGV
                                  AND l.TrangThai IN (N'Đang tuyển sinh', N'Đang học'))
    FROM dbo.GIANGVIEN gv
    WHERE gv.MaNN = @MaNN
      AND gv.TrangThai = N'Đang công tác'
);
GO

/* =====================================================================
   PHẦN 2. VIEW
   ===================================================================== */

-- ---------------------------------------------------------------------
-- V_CHUYEN_CAN
-- Mỗi dòng là một đăng ký (học viên x lớp): số lượt có mặt / vắng có phép /
-- vắng không phép, tỷ lệ chuyên cần của học viên (gọi FN_TyLeChuyenCan) và
-- tỷ lệ chuyên cần chung của cả lớp (hàm cửa sổ theo MaLop).
-- Đăng ký chưa được điểm danh lượt nào vẫn xuất hiện, tỷ lệ là NULL.
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_CHUYEN_CAN
AS
WITH TongHop AS
(
    SELECT dk.MaDK, dk.MaHV, dk.MaLop,
           SoLuotDiemDanh  = COUNT(dd.MaBuoi),
           SoCoMat         = COUNT(CASE WHEN dd.TrangThaiDiemDanh = N'Có mặt'          THEN 1 END),
           SoVangCoPhep    = COUNT(CASE WHEN dd.TrangThaiDiemDanh = N'Vắng có phép'    THEN 1 END),
           SoVangKhongPhep = COUNT(CASE WHEN dd.TrangThaiDiemDanh = N'Vắng không phép' THEN 1 END)
    FROM dbo.DANGKY dk
    LEFT JOIN dbo.DIEMDANH dd ON dd.MaDK = dk.MaDK
    GROUP BY dk.MaDK, dk.MaHV, dk.MaLop
)
SELECT t.MaDK, t.MaHV, hv.HoTen AS HoTenHV,
       t.MaLop, kh.TenKhoa,
       t.SoLuotDiemDanh, t.SoCoMat, t.SoVangCoPhep, t.SoVangKhongPhep,
       TyLeCoMat    = dbo.FN_TyLeChuyenCan(t.MaDK),
       TyLeCoMatLop = CAST(SUM(t.SoCoMat) OVER (PARTITION BY t.MaLop) * 100.0
                           / NULLIF(SUM(t.SoLuotDiemDanh) OVER (PARTITION BY t.MaLop), 0)
                           AS DECIMAL(5,2))
FROM TongHop t
JOIN dbo.HOCVIEN hv ON hv.MaHV = t.MaHV
JOIN dbo.LOP     l  ON l.MaLop = t.MaLop
JOIN dbo.KHOAHOC kh ON kh.MaKH = l.MaKH;
GO

-- ---------------------------------------------------------------------
-- V_GIANGVIEN_TaiTrong
-- Tải giảng dạy của từng giảng viên: số lớp chính (tất cả / đang phụ trách),
-- số buổi đã dạy thực tế và số buổi dạy thay (lớp có GV chính là người khác).
-- Dùng subquery tương quan để các phép đếm không nhân dòng lẫn nhau.
-- ---------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.V_GIANGVIEN_TaiTrong
AS
SELECT gv.MaGV, gv.HoTen, gv.MaNN, nn.TenNN, gv.TrangThai,
       SoLopChinh = (SELECT COUNT(*) FROM dbo.LOP l
                     WHERE l.MaGV_Chinh = gv.MaGV),
       SoLopDangPhuTrach = (SELECT COUNT(*) FROM dbo.LOP l
                            WHERE l.MaGV_Chinh = gv.MaGV
                              AND l.TrangThai IN (N'Đang tuyển sinh', N'Đang học')),
       SoBuoiDaDay = (SELECT COUNT(*) FROM dbo.BUOIHOC b
                      WHERE b.MaGV_Day = gv.MaGV
                        AND b.TrangThaiBuoiHoc = N'Đã diễn ra'),
       SoBuoiDayThay = (SELECT COUNT(*) FROM dbo.BUOIHOC b
                        JOIN dbo.LOP l ON l.MaLop = b.MaLop
                        WHERE b.MaGV_Day = gv.MaGV
                          AND b.TrangThaiBuoiHoc = N'Đã diễn ra'
                          AND l.MaGV_Chinh <> gv.MaGV)
FROM dbo.GIANGVIEN gv
JOIN dbo.NGONNGU nn ON nn.MaNN = gv.MaNN;
GO

/* =====================================================================
   PHẦN 3. INDEX
   Không thay đổi schema: chỉ thêm chỉ mục không cụm (nonclustered).
   ===================================================================== */

-- Tra cứu buổi học theo lớp và khoảng ngày. PK của BUOIHOC là MaBuoi nên
-- truy vấn theo MaLop phải quét toàn bảng. INCLUDE để truy vấn "danh sách
-- buổi học của lớp" được phủ hoàn toàn bởi index (không cần Key Lookup).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_BUOIHOC_MaLop_Ngay' AND object_id = OBJECT_ID('dbo.BUOIHOC'))
    CREATE NONCLUSTERED INDEX IX_BUOIHOC_MaLop_Ngay
        ON dbo.BUOIHOC (MaLop, NgayHocThucTe)
        INCLUDE (MaGV_Day, TrangThaiBuoiHoc);
GO

-- Tra cứu điểm danh theo đăng ký. PK của DIEMDANH bắt đầu bằng MaBuoi nên
-- không hỗ trợ tìm theo MaDK; index này còn phục vụ V_CHUYEN_CAN,
-- FN_TyLeChuyenCan và kiểm tra khóa ngoại FK_DIEMDANH_DANGKY.
-- MaBuoi (khóa cụm) tự động nằm trong mọi index không cụm.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_DIEMDANH_MaDK' AND object_id = OBJECT_ID('dbo.DIEMDANH'))
    CREATE NONCLUSTERED INDEX IX_DIEMDANH_MaDK
        ON dbo.DIEMDANH (MaDK)
        INCLUDE (TrangThaiDiemDanh);
GO

/* =====================================================================
   PHẦN 4. TRIGGER
   ===================================================================== */

-- ---------------------------------------------------------------------
-- TRG_DIEMDANH_DungLop
-- Quy tắc nghiệp vụ mà FK/CHECK không biểu diễn được:
--   (1) Đăng ký (MaDK) được điểm danh phải thuộc CÙNG LỚP với buổi học (MaBuoi).
--   (2) Chỉ điểm danh cho buổi học "Đã diễn ra" (không điểm danh buổi Hoãn/Hủy).
-- ---------------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_DIEMDANH_DungLop
ON dbo.DIEMDANH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Msg NVARCHAR(400), @MaBuoi VARCHAR(8), @MaDK VARCHAR(8);

    -- (1) Sai lớp
    SELECT TOP (1) @MaBuoi = i.MaBuoi, @MaDK = i.MaDK
    FROM inserted i
    JOIN dbo.DANGKY  dk ON dk.MaDK   = i.MaDK
    JOIN dbo.BUOIHOC bh ON bh.MaBuoi = i.MaBuoi
    WHERE dk.MaLop <> bh.MaLop;

    IF @MaBuoi IS NOT NULL
    BEGIN
        SET @Msg = CONCAT(N'Đăng ký ', @MaDK, N' không thuộc lớp của buổi học ', @MaBuoi,
                          N'. Không thể điểm danh.');
        THROW 54001, @Msg, 1;
    END;

    -- (2) Buổi học không diễn ra
    SELECT TOP (1) @MaBuoi = i.MaBuoi
    FROM inserted i
    JOIN dbo.BUOIHOC bh ON bh.MaBuoi = i.MaBuoi
    WHERE bh.TrangThaiBuoiHoc <> N'Đã diễn ra';

    IF @MaBuoi IS NOT NULL
    BEGIN
        SET @Msg = CONCAT(N'Buổi học ', @MaBuoi,
                          N' không ở trạng thái "Đã diễn ra" nên không thể điểm danh.');
        THROW 54002, @Msg, 1;
    END;
END;
GO

-- ---------------------------------------------------------------------
-- TRG_GIANGVIEN_NghiViec
-- Chặn chuyển giảng viên sang "Tạm nghỉ" / "Đã nghỉ việc" khi người đó vẫn
-- là giảng viên chính của lớp đang tuyển sinh hoặc đang học. Phải bàn giao
-- lớp trước (xem SP_BanGiaoLop_KhiGVNghi). Lớp "Đã kết thúc" không bị chặn.
-- ---------------------------------------------------------------------
CREATE OR ALTER TRIGGER dbo.TRG_GIANGVIEN_NghiViec
ON dbo.GIANGVIEN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(TrangThai) RETURN;

    DECLARE @MaGV CHAR(4), @MaLop VARCHAR(6), @Msg NVARCHAR(400);

    SELECT TOP (1) @MaGV = i.MaGV, @MaLop = l.MaLop
    FROM inserted i
    JOIN deleted  d ON d.MaGV = i.MaGV
    JOIN dbo.LOP  l ON l.MaGV_Chinh = i.MaGV
    WHERE i.TrangThai IN (N'Tạm nghỉ', N'Đã nghỉ việc')
      AND d.TrangThai <> i.TrangThai
      AND l.TrangThai IN (N'Đang tuyển sinh', N'Đang học')
    ORDER BY l.MaLop;

    IF @MaGV IS NOT NULL
    BEGIN
        SET @Msg = CONCAT(N'Giảng viên ', @MaGV, N' vẫn là giảng viên chính của lớp ', @MaLop,
                          N' (đang tuyển sinh/đang học). Hãy bàn giao lớp trước khi cho nghỉ.');
        THROW 54003, @Msg, 1;
    END;
END;
GO

/* =====================================================================
   PHẦN 5. STORED PROCEDURE (truy vấn)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- SP_ThongKeChuyenCan_Lop
-- Thống kê chuyên cần của một lớp, mỗi học viên một dòng, sắp xếp từ thấp
-- đến cao. Cột CanhBao = 1 khi tỷ lệ thấp hơn ngưỡng (mặc định 80%).
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.SP_ThongKeChuyenCan_Lop
    @MaLop         VARCHAR(6),
    @NguongCanhBao DECIMAL(5,2) = 80
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @MaLop IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.LOP WHERE MaLop = @MaLop)
            THROW 54010, N'Lớp học không tồn tại.', 1;
        IF @NguongCanhBao IS NULL OR @NguongCanhBao < 0 OR @NguongCanhBao > 100
            THROW 54011, N'Ngưỡng cảnh báo phải nằm trong khoảng 0 đến 100.', 1;

        SELECT v.MaDK, v.MaHV, v.HoTenHV,
               v.SoLuotDiemDanh, v.SoCoMat, v.SoVangCoPhep, v.SoVangKhongPhep,
               v.TyLeCoMat, v.TyLeCoMatLop,
               CanhBao = CAST(CASE WHEN v.TyLeCoMat IS NOT NULL
                                    AND v.TyLeCoMat < @NguongCanhBao THEN 1 ELSE 0 END AS BIT)
        FROM dbo.V_CHUYEN_CAN v
        WHERE v.MaLop = @MaLop
        ORDER BY v.TyLeCoMat ASC, v.MaHV;
    END TRY
    BEGIN CATCH
        THROW;   -- thủ tục chỉ đọc: không đụng tới giao dịch của nơi gọi
    END CATCH
END;
GO

-- ---------------------------------------------------------------------
-- SP_LichDay_GiangVien
-- Lịch dạy THỰC TẾ của một giảng viên trong khoảng ngày (mặc định: tháng
-- hiện tại). Gồm cả buổi dạy thay. Giờ và phòng lấy từ LICHHOC của lớp theo
-- đúng thứ trong tuần của ngày học; buổi học bù ngoài lịch thì để NULL.
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.SP_LichDay_GiangVien
    @MaGV    CHAR(4),
    @TuNgay  DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @MaGV IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.GIANGVIEN WHERE MaGV = @MaGV)
            THROW 54020, N'Giảng viên không tồn tại.', 1;

        SET @TuNgay  = ISNULL(@TuNgay, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
        SET @DenNgay = ISNULL(@DenNgay, EOMONTH(@TuNgay));

        IF @TuNgay > @DenNgay
            THROW 54021, N'Từ ngày phải nhỏ hơn hoặc bằng đến ngày.', 1;

        SELECT b.MaBuoi, b.NgayHocThucTe,
               -- Chủ Nhật = 1 ... Thứ 7 = 7, không phụ thuộc SET DATEFIRST
               Thu = (DATEPART(WEEKDAY, b.NgayHocThucTe) + @@DATEFIRST + 6) % 7 + 1,
               b.MaLop, kh.TenKhoa,
               VaiTro = CASE WHEN l.MaGV_Chinh = @MaGV THEN N'Giảng viên chính' ELSE N'Dạy thay' END,
               b.TrangThaiBuoiHoc,
               lh.GioBatDau, lh.GioKetThuc, lh.PhongHoc
        FROM dbo.BUOIHOC b
        JOIN dbo.LOP     l  ON l.MaLop = b.MaLop
        JOIN dbo.KHOAHOC kh ON kh.MaKH = l.MaKH
        OUTER APPLY (SELECT TOP (1) x.GioBatDau, x.GioKetThuc, x.PhongHoc
                     FROM dbo.LICHHOC x
                     WHERE x.MaLop = b.MaLop
                       AND x.Thu = (DATEPART(WEEKDAY, b.NgayHocThucTe) + @@DATEFIRST + 6) % 7 + 1
                     ORDER BY x.GioBatDau) lh
        WHERE b.MaGV_Day = @MaGV
          AND b.NgayHocThucTe BETWEEN @TuNgay AND @DenNgay
        ORDER BY b.NgayHocThucTe, lh.GioBatDau, b.MaBuoi;
    END TRY
    BEGIN CATCH
        THROW;   -- thủ tục chỉ đọc: không đụng tới giao dịch của nơi gọi
    END CATCH
END;
GO

/* =====================================================================
   PHẦN 6. STORED PROCEDURE NGHIỆP VỤ GIAO DỊCH (TRANSACTION)
   Mẫu giao dịch thống nhất của nhóm (giống SP_DangKy_VaTaoHoaDon của B):
     - Ứng dụng gọi trong JpaUtil.inTx (đã có giao dịch JDBC) -> thủ tục chỉ
       SAVE TRANSACTION, lỗi thì rollback về điểm lưu, giao dịch ngoài do
       JpaUtil.inTx rollback nốt.
     - Gọi từ SSMS không có giao dịch -> thủ tục tự BEGIN/COMMIT.
   ===================================================================== */

-- ---------------------------------------------------------------------
-- SP_DiemDanh_CaLop
-- Điểm danh hàng loạt cho MỘT buổi học. Danh sách truyền dạng JSON:
--   [{"MaDK":"DK001","TrangThai":"Có mặt","GhiChu":null},
--    {"MaDK":"DK002","TrangThai":"Vắng có phép","GhiChu":"Xin nghỉ ốm"}]
-- Tất cả hoặc không gì cả: bất kỳ dòng nào sai (sai lớp, sai trạng thái,
-- trùng mã...) thì không ghi gì và báo rõ dòng sai. Buổi đã có điểm danh thì
-- cập nhật dòng cũ, chưa có thì thêm mới. Cần compatibility level >= 130.
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.SP_DiemDanh_CaLop
    @MaBuoi   VARCHAR(8),
    @DanhSach NVARCHAR(MAX)
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
            SAVE TRANSACTION SV_DiemDanhCaLop;
        END;

        DECLARE @Ds TABLE (MaDK VARCHAR(20) NULL, TrangThai NVARCHAR(50) NULL, GhiChu NVARCHAR(4000) NULL);
        DECLARE @MaLop VARCHAR(6), @TrangThaiBuoi NVARCHAR(20), @Loi VARCHAR(20), @Msg NVARCHAR(400);
        DECLARE @SoCapNhat INT = 0, @SoThem INT = 0;

        -- 1. Kiểm tra buổi học
        SELECT @MaLop = MaLop, @TrangThaiBuoi = TrangThaiBuoiHoc
        FROM dbo.BUOIHOC WHERE MaBuoi = @MaBuoi;

        IF @MaLop IS NULL
            THROW 54030, N'Buổi học không tồn tại.', 1;
        IF @TrangThaiBuoi <> N'Đã diễn ra'
            THROW 54031, N'Chỉ được điểm danh buổi học ở trạng thái "Đã diễn ra".', 1;

        -- 2. Kiểm tra và đọc danh sách JSON
        IF @DanhSach IS NULL OR ISJSON(@DanhSach) <> 1
            THROW 54032, N'Danh sách điểm danh không phải JSON hợp lệ.', 1;

        INSERT INTO @Ds (MaDK, TrangThai, GhiChu)
        SELECT MaDK, TrangThai, GhiChu
        FROM OPENJSON(@DanhSach)
             WITH (MaDK      VARCHAR(20)    '$.MaDK',
                   TrangThai NVARCHAR(50)   '$.TrangThai',
                   GhiChu    NVARCHAR(4000) '$.GhiChu');

        IF NOT EXISTS (SELECT 1 FROM @Ds)
            THROW 54033, N'Danh sách điểm danh rỗng.', 1;

        -- 3. Kiểm tra từng dòng (chưa ghi gì vào CSDL)
        SELECT TOP (1) @Loi = MaDK FROM @Ds GROUP BY MaDK HAVING COUNT(*) > 1;
        IF @Loi IS NOT NULL
        BEGIN
            SET @Msg = CONCAT(N'Đăng ký ', @Loi, N' xuất hiện nhiều lần trong danh sách.');
            THROW 54034, @Msg, 1;
        END;

        SELECT TOP (1) @Loi = ISNULL(MaDK, '(trống)') FROM @Ds
        WHERE TrangThai IS NULL
           OR TrangThai NOT IN (N'Có mặt', N'Vắng có phép', N'Vắng không phép');
        IF @Loi IS NOT NULL
        BEGIN
            SET @Msg = CONCAT(N'Trạng thái điểm danh của đăng ký ', @Loi, N' không hợp lệ.');
            THROW 54035, @Msg, 1;
        END;

        SELECT TOP (1) @Loi = ISNULL(d.MaDK, '(trống)')
        FROM @Ds d
        LEFT JOIN dbo.DANGKY dk ON dk.MaDK = d.MaDK AND dk.MaLop = @MaLop
        WHERE dk.MaDK IS NULL;
        IF @Loi IS NOT NULL
        BEGIN
            SET @Msg = CONCAT(N'Đăng ký ', @Loi, N' không tồn tại hoặc không thuộc lớp ', @MaLop,
                              N' của buổi học ', @MaBuoi, N'.');
            THROW 54036, @Msg, 1;
        END;

        SELECT TOP (1) @Loi = MaDK FROM @Ds WHERE LEN(GhiChu) > 100;
        IF @Loi IS NOT NULL
        BEGIN
            SET @Msg = CONCAT(N'Ghi chú của đăng ký ', @Loi, N' dài quá 100 ký tự.');
            THROW 54037, @Msg, 1;
        END;

        -- 4. Ghi: cập nhật dòng đã có, thêm dòng chưa có
        UPDATE dd
        SET dd.TrangThaiDiemDanh = s.TrangThai,
            dd.GhiChu            = s.GhiChu
        FROM dbo.DIEMDANH dd
        JOIN @Ds s ON s.MaDK = dd.MaDK
        WHERE dd.MaBuoi = @MaBuoi;
        SET @SoCapNhat = @@ROWCOUNT;

        INSERT INTO dbo.DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh, GhiChu)
        SELECT @MaBuoi, s.MaDK, s.TrangThai, s.GhiChu
        FROM @Ds s
        WHERE NOT EXISTS (SELECT 1 FROM dbo.DIEMDANH dd
                          WHERE dd.MaBuoi = @MaBuoi AND dd.MaDK = s.MaDK);
        SET @SoThem = @@ROWCOUNT;

        -- COMMIT là lệnh cuối của khối TRY
        IF @TranCount = 0
            COMMIT TRANSACTION;

        SELECT @MaBuoi AS MaBuoi, @SoThem AS SoDongThem, @SoCapNhat AS SoDongCapNhat;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_DiemDanhCaLop;
        END;
        THROW;
    END CATCH
END;
GO

-- ---------------------------------------------------------------------
-- SP_BanGiaoLop_KhiGVNghi
-- Giảng viên nghỉ: chuyển mọi lớp đang tuyển sinh/đang học của người đó
-- sang giảng viên nhận bàn giao, RỒI MỚI đổi trạng thái giảng viên nghỉ
-- (đổi ngược thứ tự sẽ bị TRG_GIANGVIEN_NghiViec chặn). Lỗi ở bước nào
-- cũng hoàn tác cả hai bước. Lớp "Đã kết thúc" giữ nguyên để lưu lịch sử.
-- @MaGV_Moi được phép NULL khi giảng viên nghỉ không còn lớp nào cần bàn giao.
-- Người nhận phải đang công tác và cùng ngôn ngữ (FN_DSGiangVien_TheoNN),
-- khớp với quy tắc của TRG_LOP_KiemTraGV (người C).
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.SP_BanGiaoLop_KhiGVNghi
    @MaGV_Nghi    CHAR(4),
    @MaGV_Moi     CHAR(4)      = NULL,
    @TrangThaiMoi NVARCHAR(20) = N'Đã nghỉ việc'
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
            SAVE TRANSACTION SV_BanGiaoLop;
        END;

        DECLARE @MaNN CHAR(3), @SoLop INT = 0;

        SELECT @MaNN = MaNN FROM dbo.GIANGVIEN WHERE MaGV = @MaGV_Nghi;
        IF @MaNN IS NULL
            THROW 54040, N'Giảng viên nghỉ không tồn tại.', 1;
        IF @TrangThaiMoi IS NULL OR @TrangThaiMoi NOT IN (N'Tạm nghỉ', N'Đã nghỉ việc')
            THROW 54041, N'Trạng thái mới phải là "Tạm nghỉ" hoặc "Đã nghỉ việc".', 1;
        IF @MaGV_Moi = @MaGV_Nghi
            THROW 54042, N'Giảng viên nhận bàn giao phải khác giảng viên nghỉ.', 1;

        -- Khóa các lớp cần bàn giao rồi đếm: lớp mới không chen vào giữa lúc kiểm tra và lúc chuyển
        SELECT @SoLop = COUNT(*)
        FROM dbo.LOP WITH (UPDLOCK, HOLDLOCK)
        WHERE MaGV_Chinh = @MaGV_Nghi AND TrangThai IN (N'Đang tuyển sinh', N'Đang học');

        IF @SoLop > 0 AND @MaGV_Moi IS NULL
            THROW 54043, N'Giảng viên còn lớp đang phụ trách, cần chỉ định người nhận bàn giao.', 1;

        IF @MaGV_Moi IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.FN_DSGiangVien_TheoNN(@MaNN) WHERE MaGV = @MaGV_Moi)
            THROW 54044, N'Người nhận bàn giao phải đang công tác và cùng ngôn ngữ với giảng viên nghỉ.', 1;

        IF @SoLop > 0
            UPDATE dbo.LOP
            SET MaGV_Chinh = @MaGV_Moi
            WHERE MaGV_Chinh = @MaGV_Nghi AND TrangThai IN (N'Đang tuyển sinh', N'Đang học');

        UPDATE dbo.GIANGVIEN SET TrangThai = @TrangThaiMoi WHERE MaGV = @MaGV_Nghi;

        -- COMMIT là lệnh cuối của khối TRY
        IF @TranCount = 0
            COMMIT TRANSACTION;

        SELECT @MaGV_Nghi AS MaGV_Nghi, @MaGV_Moi AS MaGV_Moi,
               @SoLop AS SoLopBanGiao, @TrangThaiMoi AS TrangThaiMoi;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_BanGiaoLop;
        END;
        THROW;
    END CATCH
END;
GO

PRINT N'Đã tạo xong module D: 2 trigger, 2 view, 2 index, 2 procedure, 2 function, 2 transaction.';
GO
