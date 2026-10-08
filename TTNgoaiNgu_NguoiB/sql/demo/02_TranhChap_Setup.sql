/* =====================================================================
   DEMO TRANH CHAP (CONCURRENCY) - BUOC CHUAN BI   [Nguyễn Đăng Khoa - 24110255]
   Kich ban : lop LCC001 co SiSoToiDa = 2 va da co 1 hoc vien -> con DUNG 1 CHO.
              Hai nhan vien o hai cua so SSMS cung dang ky 2 hoc vien khac nhau vao lop do cung luc.
   Ket qua mong doi:
     - KHONG KHOA (thu tuc mau SP_DEMO_DangKy_KhongKhoa): CA HAI thanh cong -> 3 dang ky / 2 cho (SAI).
     - CO KHOA (SP_DangKy_VaTaoHoaDon that): chi MOT nguoi thanh cong, nguoi con lai nhan loi 52029.

   LUU Y: TRG_DANGKY_SiSo la lop bao ve CUOI (khong cho tong dang ky vuot sinh so). De thay duoc
   loi tranh chap cua cach viet KHONG KHOA, script nay TAM TAT trigger do va BAT LAI o buoc don dep
   (03_TranhChap_KiemTra_DonDep.sql). Chi lam tren CSDL thu nghiem.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* 1) Don dep neu lan truoc con sot */
DELETE FROM dbo.HOADON WHERE MaDK IN (SELECT MaDK FROM dbo.DANGKY WHERE MaLop = 'LCC001');
DELETE FROM dbo.DANGKY WHERE MaLop = 'LCC001';
DELETE FROM dbo.LOP    WHERE MaLop = 'LCC001';
GO

/* 2) Tao lop thu nghiem: khoa KH0001 (tieng Anh), GV01 (tieng Anh), toi da 2 hoc vien */
INSERT INTO dbo.LOP (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai)
VALUES ('LCC001', 'KH0001', 'GV01', '2026-11-01', '2027-02-01', 2, N'Đang tuyển sinh');

/* 3) Da co 1 hoc vien (HV001) -> con 1 cho */
INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy, DiemCuoiKy)
VALUES ('DKC00', 'HV001', 'LCC001', CAST(GETDATE() AS DATE), NULL);
GO

/* 4) Tam tat trigger cho viec chung minh (xem LUU Y o dau file) */
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'TRG_DANGKY_SiSo' AND is_disabled = 0)
    DISABLE TRIGGER dbo.TRG_DANGKY_SiSo ON dbo.DANGKY;
GO

/* 5) Thu tuc MAU viet SAI co chu y: kiem tra cho -> cho -> ghi, KHONG khoa (tinh trang "check-then-act") */
CREATE OR ALTER PROCEDURE dbo.SP_DEMO_DangKy_KhongKhoa
    @MaDK      VARCHAR(8),
    @MaHV      CHAR(5),
    @MaLop     VARCHAR(6),
    @DelayGiay INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SiSo INT, @Max INT, @Delay CHAR(8);

    BEGIN TRANSACTION;
        SELECT @Max  = SiSoToiDa FROM dbo.LOP WHERE MaLop = @MaLop;
        SELECT @SiSo = COUNT(*)  FROM dbo.DANGKY WHERE MaLop = @MaLop;   -- doc KHONG khoa nguoi khac
        PRINT N'[' + @MaHV + N'] thay si so hien tai = ' + CAST(@SiSo AS NVARCHAR(10))
              + N' / ' + CAST(@Max AS NVARCHAR(10)) + N' -> ' +
              CASE WHEN @SiSo < @Max THEN N'con cho, tiep tuc dang ky' ELSE N'het cho' END;

        IF @SiSo >= @Max
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52900, N'Lớp đã đủ sĩ số.', 1;
        END;

        -- Mo phong do tre xu ly (nhap thong tin, goi thanh toan...) de hai phien chong cheo nhau
        SET @Delay = CONVERT(CHAR(8), DATEADD(SECOND, @DelayGiay, CAST('00:00:00' AS TIME)), 108);
        WAITFOR DELAY @Delay;

        INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy, DiemCuoiKy)
        VALUES (@MaDK, @MaHV, @MaLop, CAST(GETDATE() AS DATE), NULL);
    COMMIT TRANSACTION;
    PRINT N'[' + @MaHV + N'] dang ky THANH CONG.';
END;
GO

SELECT l.MaLop, l.SiSoToiDa, COUNT(dk.MaDK) AS DaDangKy, l.SiSoToiDa - COUNT(dk.MaDK) AS ConCho
FROM dbo.LOP AS l
LEFT JOIN dbo.DANGKY AS dk ON dk.MaLop = l.MaLop
WHERE l.MaLop = 'LCC001'
GROUP BY l.MaLop, l.SiSoToiDa;
GO
