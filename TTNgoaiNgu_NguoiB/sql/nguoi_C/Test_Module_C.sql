/* =========================================================
   TEST MODULE C - LOP HOC VA LICH HOC
   Database: QL_TTNgoaiNgu

   Chay sau Module_C_Lop_LichHoc.sql.
   Phan 1-4 la kiem tra doc du lieu, khong sua du lieu.
   Phan 5 la tinh huong loi co chu dich; TRY/CATCH se hien thi loi mong doi.
   ========================================================= */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* 1. Kiem tra du 12 doi tuong cua Module C da ton tai. */
SELECT N'TRIGGER' AS Loai, name AS TenDoiTuong
FROM sys.triggers
WHERE parent_id IN (OBJECT_ID(N'dbo.LOP'), OBJECT_ID(N'dbo.LICHHOC'))
  AND name IN (N'TRG_LOP_KiemTraGV', N'TRG_LICHHOC_ChongLanGio')
UNION ALL
SELECT N'VIEW', name
FROM sys.views
WHERE name IN (N'V_LICH_HOC_TUAN', N'V_LOP_TinhTrang')
UNION ALL
SELECT N'INDEX', name
FROM sys.indexes
WHERE object_id IN (OBJECT_ID(N'dbo.LOP'), OBJECT_ID(N'dbo.LICHHOC'))
  AND name IN (N'IX_LOP_MaKH_TrangThai', N'IX_LOP_MaGV_Chinh')
UNION ALL
SELECT N'PROCEDURE', name
FROM sys.procedures
WHERE name IN (N'SP_TimKiemLop', N'SP_LichHoc_TheoPhong',
               N'SP_TaoLop_VaLichHoc', N'SP_KetThucLop')
UNION ALL
SELECT N'FUNCTION', name
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
  AND name IN (N'FN_SiSoHienTai', N'FN_DSLichHoc_Lop')
ORDER BY Loai, TenDoiTuong;
GO

/* 2. Test view: danh sach lop va tinh trang si so. */
SELECT TOP (50) *
FROM dbo.V_LOP_TinhTrang
ORDER BY NgayKhaiGiang, MaLop;
GO

/* 3. Test view lich hoc tuan. */
SELECT TOP (100) *
FROM dbo.V_LICH_HOC_TUAN
ORDER BY Thu, GioBatDau, PhongHoc;
GO

/* 4. Test function va procedure tra cuu. */
DECLARE @MaLopMau VARCHAR(6);
SELECT TOP (1) @MaLopMau = MaLop FROM dbo.LOP ORDER BY MaLop;

IF @MaLopMau IS NOT NULL
BEGIN
    SELECT @MaLopMau AS MaLopKiemThu,
           dbo.FN_SiSoHienTai(@MaLopMau) AS SiSoHienTai;

    SELECT *
    FROM dbo.FN_DSLichHoc_Lop(@MaLopMau);
END
ELSE
    PRINT N'Chua co du lieu LOP de kiem thu function.';
GO

EXEC dbo.SP_TimKiemLop;
GO

DECLARE @PhongMau VARCHAR(10);
SELECT TOP (1) @PhongMau = PhongHoc FROM dbo.LICHHOC ORDER BY PhongHoc;
IF @PhongMau IS NOT NULL
    EXEC dbo.SP_LichHoc_TheoPhong @PhongHoc = @PhongMau, @Thu = NULL;
ELSE
    PRINT N'Chua co du lieu LICHHOC de kiem thu SP_LichHoc_TheoPhong.';
GO

/* 5. Test loi: ket thuc mot lop khong ton tai.
   Mong doi: SP_KetThucLop phat sinh loi ma 53012.
   Khong thay doi du lieu. */
BEGIN TRY
    EXEC dbo.SP_KetThucLop @MaLop = 'ZZTEST';
    PRINT N'CAN KIEM TRA: thu tuc khong phat sinh loi voi ma lop khong ton tai.';
END TRY
BEGIN CATCH
    SELECT N'TEST LOI MONG DOI' AS KetQua,
           ERROR_NUMBER() AS MaLoi,
           ERROR_MESSAGE() AS NoiDungLoi;
END CATCH;
GO

/* 6. Test transaction rollback khi ngay ket thuc khong sau ngay khai giang.
   Dung ma lop thu nghiem; procedure phai bao loi va khong tao lop nay.
   Can co it nhat mot khoa hoc va mot giang vien hop le trong CSDL.
   Trigger kiem tra giao vien cung ngon ngu va dang cong tac, nen chon du lieu phu hop. */
DECLARE @MaKH VARCHAR(6), @MaGV CHAR(4);
SELECT TOP (1) @MaKH = kh.MaKH, @MaGV = gv.MaGV
FROM dbo.KHOAHOC AS kh
JOIN dbo.GIANGVIEN AS gv ON gv.MaNN = kh.MaNN
WHERE gv.TrangThai = N'Đang công tác'
ORDER BY kh.MaKH, gv.MaGV;

IF @MaKH IS NULL OR @MaGV IS NULL
BEGIN
    PRINT N'BO QUA TEST TRANSACTION: can co KHOAHOC va GIANGVIEN dang cong tac cung ngon ngu.';
END
ELSE
BEGIN
    BEGIN TRY
        EXEC dbo.SP_TaoLop_VaLichHoc
            @MaLop = 'ZCTEST',
            @MaKH = @MaKH,
            @MaGV_Chinh = @MaGV,
            @NgayKhaiGiang = '2026-12-20',
            @NgayKetThuc = '2026-12-01',
            @SiSoToiDa = 10,
            @TrangThai = N'Đang tuyển sinh',
            @DanhSachLich = N'<LichHoc><Lich MaLich="ZCLH0001" Thu="2" GioBatDau="08:00" GioKetThuc="10:00" PhongHoc="ZCPHONG1" /></LichHoc>';

        PRINT N'CAN KIEM TRA: procedure khong tu choi ngay ket thuc khong hop le.';
    END TRY
    BEGIN CATCH
        SELECT N'TEST ROLLBACK MONG DOI' AS KetQua,
               ERROR_NUMBER() AS MaLoi,
               ERROR_MESSAGE() AS NoiDungLoi;
    END CATCH;

    IF EXISTS (SELECT 1 FROM dbo.LOP WHERE MaLop = 'ZCTEST')
        PRINT N'LOI: lop ZCTEST van ton tai sau khi test that bai.';
    ELSE
        PRINT N'DAT: lop ZCTEST khong duoc tao; transaction da huy thay doi.';
END;
GO

/* 7. Test trigger chong lan gio (chi doc du lieu hien co).
   Liet ke cac cap lich trong cung phong/cung thu co khoang gio giao nhau.
   Ket qua binh thuong phai rong. */
SELECT a.MaLich AS MaLichA, b.MaLich AS MaLichB,
       a.PhongHoc, a.Thu,
       a.GioBatDau AS BatDauA, a.GioKetThuc AS KetThucA,
       b.GioBatDau AS BatDauB, b.GioKetThuc AS KetThucB
FROM dbo.LICHHOC AS a
JOIN dbo.LICHHOC AS b
  ON a.PhongHoc = b.PhongHoc
 AND a.Thu = b.Thu
 AND a.MaLich < b.MaLich
 AND a.GioBatDau < b.GioKetThuc
 AND b.GioBatDau < a.GioKetThuc;
GO
