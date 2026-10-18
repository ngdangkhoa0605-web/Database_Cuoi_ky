/*
    MODULE C - LOP HOC VA LICH HOC
    Yeu cau: 2 Trigger, 2 View, 2 Index, 2 Procedure,
             2 Function, 2 Transaction Procedure.
*/
USE QL_TTNgoaiNgu;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

   --1. INDEX

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_LOP_MaKH_TrangThai'
      AND object_id = OBJECT_ID(N'dbo.LOP')
)
    CREATE NONCLUSTERED INDEX IX_LOP_MaKH_TrangThai
        ON dbo.LOP (MaKH, TrangThai)
        INCLUDE (MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_LOP_MaGV_Chinh'
      AND object_id = OBJECT_ID(N'dbo.LOP')
)
    CREATE NONCLUSTERED INDEX IX_LOP_MaGV_Chinh
        ON dbo.LOP (MaGV_Chinh)
        INCLUDE (MaKH, TrangThai, NgayKhaiGiang, NgayKetThuc);
GO

   --2. FUNCTION

-- Si so hien tai: dem hoc vien dang ky lop.
CREATE OR ALTER FUNCTION dbo.FN_SiSoHienTai
(
    @MaLop VARCHAR(6)
)
RETURNS INT
AS
BEGIN
    DECLARE @SiSo INT;

    SELECT @SiSo = COUNT(*)
    FROM dbo.DANGKY
    WHERE MaLop = @MaLop;

    RETURN ISNULL(@SiSo, 0);
END;
GO

-- Danh sach lich hoc cua mot lop.
CREATE OR ALTER FUNCTION dbo.FN_DSLichHoc_Lop
(
    @MaLop VARCHAR(6)
)
RETURNS TABLE
AS
RETURN
(
    SELECT lh.MaLich, lh.MaLop, lh.Thu,
           lh.GioBatDau, lh.GioKetThuc, lh.PhongHoc
    FROM dbo.LICHHOC AS lh
    WHERE lh.MaLop = @MaLop
);
GO


   --3. VIEW
-- Lich hoc tuan kem thong tin lop, khoa hoc, giang vien.
CREATE OR ALTER VIEW dbo.V_LICH_HOC_TUAN
AS
SELECT
    lh.MaLich,
    lh.MaLop,
    kh.MaKH,
    kh.TenKhoa,
    gv.MaGV,
    gv.HoTen AS TenGiangVien,
    lh.Thu,
    CASE lh.Thu
        WHEN 1 THEN N'Chủ Nhật'
        WHEN 2 THEN N'Thứ 2'
        WHEN 3 THEN N'Thứ 3'
        WHEN 4 THEN N'Thứ 4'
        WHEN 5 THEN N'Thứ 5'
        WHEN 6 THEN N'Thứ 6'
        WHEN 7 THEN N'Thứ 7'
    END AS TenThu,
    lh.GioBatDau,
    lh.GioKetThuc,
    lh.PhongHoc,
    l.TrangThai AS TrangThaiLop
FROM dbo.LICHHOC AS lh
INNER JOIN dbo.LOP AS l ON l.MaLop = lh.MaLop
INNER JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH
INNER JOIN dbo.GIANGVIEN AS gv ON gv.MaGV = l.MaGV_Chinh;
GO

-- Thong tin lop, si so hien tai, si so toi da va ty le lap day.
CREATE OR ALTER VIEW dbo.V_LOP_TinhTrang
AS
SELECT
    l.MaLop,
    l.MaKH,
    kh.TenKhoa,
    l.MaGV_Chinh,
    gv.HoTen AS TenGiangVien,
    l.NgayKhaiGiang,
    l.NgayKetThuc,
    l.SiSoToiDa,
    dbo.FN_SiSoHienTai(l.MaLop) AS SiSoHienTai,
    CAST(
        dbo.FN_SiSoHienTai(l.MaLop) * 100.0
        / NULLIF(l.SiSoToiDa, 0)
        AS DECIMAL(5,2)
    ) AS TyLeLapDay,
    l.TrangThai
FROM dbo.LOP AS l
INNER JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH
INNER JOIN dbo.GIANGVIEN AS gv ON gv.MaGV = l.MaGV_Chinh;
GO


   --4. TRIGGER

-- Giao vien chinh phai dang cong tac va cung ngon ngu voi khoa hoc.
CREATE OR ALTER TRIGGER dbo.TRG_LOP_KiemTraGV
ON dbo.LOP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.GIANGVIEN AS gv ON gv.MaGV = i.MaGV_Chinh
        INNER JOIN dbo.KHOAHOC AS kh ON kh.MaKH = i.MaKH
        WHERE gv.TrangThai <> N'Đang công tác'
           OR gv.MaNN <> kh.MaNN
    )
    BEGIN
        THROW 53001, N'Giảng viên chính phải đang công tác và cùng ngôn ngữ với khóa học của lớp.', 1;
    END;
END;
GO

-- Chan lich hoc trung khoang thoi gian trong cung phong.
-- Hai lich giao nhau neu bat dau lich A < ket thuc B va bat dau B < ket thuc A.
CREATE OR ALTER TRIGGER dbo.TRG_LICHHOC_ChongLanGio
ON dbo.LICHHOC
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.LICHHOC AS lh
            ON lh.Thu = i.Thu
           AND lh.PhongHoc = i.PhongHoc
           AND lh.MaLich <> i.MaLich
           AND i.GioBatDau < lh.GioKetThuc
           AND lh.GioBatDau < i.GioKetThuc
    )
    BEGIN
        THROW 53002, N'Lịch học bị trùng khoảng thời gian trong cùng phòng vào cùng thứ.', 1;
    END;

    -- Mot lop khong the co hai lich giao nhau trong cung thu.
    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.LICHHOC AS lh
            ON lh.Thu = i.Thu
           AND lh.MaLop = i.MaLop
           AND lh.MaLich <> i.MaLich
           AND i.GioBatDau < lh.GioKetThuc
           AND lh.GioBatDau < i.GioKetThuc
    )
    BEGIN
        THROW 53003, N'Lớp đã có lịch khác bị trùng khoảng thời gian trong cùng thứ.', 1;
    END;
END;
GO

   --5. STORED PROCEDURE

-- Tim lop theo cac tieu chi tuy chon.
CREATE OR ALTER PROCEDURE dbo.SP_TimKiemLop
    @MaKH VARCHAR(6) = NULL,
    @MaGV_Chinh CHAR(4) = NULL,
    @TrangThai NVARCHAR(20) = NULL,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @TuNgay IS NOT NULL AND @DenNgay IS NOT NULL AND @DenNgay < @TuNgay
            THROW 53004, N'Ngày kết thúc tìm kiếm phải lớn hơn hoặc bằng ngày bắt đầu.', 1;

        SELECT
            v.MaLop, v.MaKH, v.TenKhoa, v.MaGV_Chinh, v.TenGiangVien,
            v.NgayKhaiGiang, v.NgayKetThuc, v.SiSoHienTai,
            v.SiSoToiDa, v.TyLeLapDay, v.TrangThai
        FROM dbo.V_LOP_TinhTrang AS v
        WHERE (@MaKH IS NULL OR v.MaKH = @MaKH)
          AND (@MaGV_Chinh IS NULL OR v.MaGV_Chinh = @MaGV_Chinh)
          AND (@TrangThai IS NULL OR v.TrangThai = @TrangThai)
          AND (@TuNgay IS NULL OR v.NgayKhaiGiang >= @TuNgay)
          AND (@DenNgay IS NULL OR v.NgayKhaiGiang <= @DenNgay)
        ORDER BY v.NgayKhaiGiang, v.MaLop;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

-- Xem lich su dung mot phong theo thu.
CREATE OR ALTER PROCEDURE dbo.SP_LichHoc_TheoPhong
    @PhongHoc VARCHAR(10),
    @Thu TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NULLIF(LTRIM(RTRIM(@PhongHoc)), '') IS NULL
            THROW 53005, N'Phòng học không được để trống.', 1;

        IF @Thu IS NOT NULL AND @Thu NOT BETWEEN 1 AND 7
            THROW 53006, N'Thứ phải nằm trong khoảng 1 đến 7 (Chủ Nhật = 1).', 1;

        SELECT
            lh.PhongHoc, lh.Thu,
            CASE lh.Thu
                WHEN 1 THEN N'Chủ Nhật'
                WHEN 2 THEN N'Thứ 2'
                WHEN 3 THEN N'Thứ 3'
                WHEN 4 THEN N'Thứ 4'
                WHEN 5 THEN N'Thứ 5'
                WHEN 6 THEN N'Thứ 6'
                WHEN 7 THEN N'Thứ 7'
            END AS TenThu,
            lh.GioBatDau, lh.GioKetThuc,
            lh.MaLich, lh.MaLop, kh.TenKhoa,
            l.TrangThai AS TrangThaiLop
        FROM dbo.LICHHOC AS lh
        INNER JOIN dbo.LOP AS l ON l.MaLop = lh.MaLop
        INNER JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH
        WHERE lh.PhongHoc = @PhongHoc
          AND (@Thu IS NULL OR lh.Thu = @Thu)
        ORDER BY lh.Thu, lh.GioBatDau;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

   --6. TRANSACTION PROCEDURE
 

-- Tao lop va nhieu lich hoc trong mot giao dich.
-- @DanhSachLich XML co dang:
-- <LichHoc>
--   <Lich MaLich="LH000001" Thu="2" GioBatDau="08:00" GioKetThuc="10:00" PhongHoc="P101" />
--   <Lich MaLich="LH000002" Thu="4" GioBatDau="08:00" GioKetThuc="10:00" PhongHoc="P102" />
-- </LichHoc>
CREATE OR ALTER PROCEDURE dbo.SP_TaoLop_VaLichHoc
    @MaLop VARCHAR(6),
    @MaKH VARCHAR(6),
    @MaGV_Chinh CHAR(4),
    @NgayKhaiGiang DATE,
    @NgayKetThuc DATE,
    @SiSoToiDa TINYINT,
    @TrangThai NVARCHAR(20) = N'Đang tuyển sinh',
    @DanhSachLich XML
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TranNgoai BIT = 0;

    BEGIN TRY
        IF @DanhSachLich IS NULL
            THROW 53007, N'Danh sách lịch học không được để trống.', 1;

        IF @NgayKetThuc <= @NgayKhaiGiang
            THROW 53008, N'Ngày kết thúc phải sau ngày khai giảng.', 1;

        IF @SiSoToiDa = 0
            THROW 53009, N'Sĩ số tối đa phải lớn hơn 0.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM @DanhSachLich.nodes('/LichHoc/Lich') AS X(N)
            WHERE X.N.value('@MaLich', 'VARCHAR(8)') = ''
               OR X.N.value('@PhongHoc', 'VARCHAR(10)') = ''
               OR X.N.value('@Thu', 'INT') NOT BETWEEN 1 AND 7
               OR X.N.value('@GioKetThuc', 'TIME') <= X.N.value('@GioBatDau', 'TIME')
        )
            THROW 53010, N'Danh sách có lịch thiếu thông tin hoặc thời gian không hợp lệ.', 1;

        IF @DanhSachLich.exist('/LichHoc/Lich[1]') = 0
            THROW 53011, N'Phải cung cấp ít nhất một lịch học.', 1;

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION TranTaoLopLich;
            SET @TranNgoai = 1;
        END;

        INSERT INTO dbo.LOP
            (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai)
        VALUES
            (@MaLop, @MaKH, @MaGV_Chinh, @NgayKhaiGiang, @NgayKetThuc, @SiSoToiDa, @TrangThai);

        INSERT INTO dbo.LICHHOC
            (MaLich, MaLop, Thu, GioBatDau, GioKetThuc, PhongHoc)
        SELECT
            X.N.value('@MaLich', 'VARCHAR(8)'),
            @MaLop,
            X.N.value('@Thu', 'TINYINT'),
            X.N.value('@GioBatDau', 'TIME'),
            X.N.value('@GioKetThuc', 'TIME'),
            X.N.value('@PhongHoc', 'VARCHAR(10)')
        FROM @DanhSachLich.nodes('/LichHoc/Lich') AS X(N);

        IF @TranNgoai = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = 1
        BEGIN
            IF @TranNgoai = 1
                ROLLBACK TRANSACTION TranTaoLopLich;
            ELSE
                ROLLBACK TRANSACTION;
        END
        ELSE IF XACT_STATE() = -1 AND @TranNgoai = 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Ket thuc lop khi tat ca buoi hoc da dien ra hoac bi huy.
CREATE OR ALTER PROCEDURE dbo.SP_KetThucLop
    @MaLop VARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TranNgoai BIT = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.LOP WHERE MaLop = @MaLop)
            THROW 53012, N'Lớp học không tồn tại.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.BUOIHOC AS bh
            WHERE bh.MaLop = @MaLop
              AND bh.TrangThaiBuoiHoc NOT IN (N'Đã diễn ra', N'Hủy')
        )
            THROW 53013, N'Không thể kết thúc lớp vì vẫn còn buổi học chưa diễn ra hoặc chưa hủy.', 1;

        IF @@TRANCOUNT = 0
            BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION TranKetThucLop;
            SET @TranNgoai = 1;
        END;

        UPDATE dbo.LOP
        SET TrangThai = N'Đã kết thúc'
        WHERE MaLop = @MaLop;

        IF @TranNgoai = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = 1
        BEGIN
            IF @TranNgoai = 1
                ROLLBACK TRANSACTION TranKetThucLop;
            ELSE
                ROLLBACK TRANSACTION;
        END
        ELSE IF XACT_STATE() = -1 AND @TranNgoai = 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

