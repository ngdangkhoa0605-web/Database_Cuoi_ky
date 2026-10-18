/*
    GRANT MODULE C - QUAN LY LOP HOC VA LICH HOC
    Database: QL_TTNgoaiNgu
    Chay sau Module_C_Lop_LichHoc.sql.
    Khong tao role/login/user; su dung role chung do nhom truong quan ly.
    Neu role chua ton tai, script in canh bao va bo qua role do.
*/
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* 1. role_QuanTri: quyen quan ly cac doi tuong thuoc Module C */
IF DATABASE_PRINCIPAL_ID(N'role_QuanTri') IS NULL
    PRINT N'[Canh bao] Chua co role_QuanTri. Bo qua GRANT Module C cho role_QuanTri.';
ELSE
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LOP TO role_QuanTri;
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LICHHOC TO role_QuanTri;
    GRANT SELECT ON OBJECT::dbo.V_LICH_HOC_TUAN TO role_QuanTri;
    GRANT SELECT ON OBJECT::dbo.V_LOP_TinhTrang TO role_QuanTri;
    GRANT SELECT ON OBJECT::dbo.FN_DSLichHoc_Lop TO role_QuanTri;
    GRANT EXECUTE ON OBJECT::dbo.FN_SiSoHienTai TO role_QuanTri;
    GRANT EXECUTE ON OBJECT::dbo.SP_TimKiemLop TO role_QuanTri;
    GRANT EXECUTE ON OBJECT::dbo.SP_LichHoc_TheoPhong TO role_QuanTri;
    GRANT EXECUTE ON OBJECT::dbo.SP_TaoLop_VaLichHoc TO role_QuanTri;
    GRANT EXECUTE ON OBJECT::dbo.SP_KetThucLop TO role_QuanTri;
    PRINT N'Da cap quyen Module C cho role_QuanTri.';
END;
GO

/* 2. role_GiaoVu: quan ly lop va lich hoc theo nghiep vu */
IF DATABASE_PRINCIPAL_ID(N'role_GiaoVu') IS NULL
    PRINT N'[Canh bao] Chua co role_GiaoVu. Bo qua GRANT Module C cho role_GiaoVu.';
ELSE
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LOP TO role_GiaoVu;
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.LICHHOC TO role_GiaoVu;
    GRANT SELECT ON OBJECT::dbo.V_LICH_HOC_TUAN TO role_GiaoVu;
    GRANT SELECT ON OBJECT::dbo.V_LOP_TinhTrang TO role_GiaoVu;
    GRANT SELECT ON OBJECT::dbo.FN_DSLichHoc_Lop TO role_GiaoVu;
    GRANT EXECUTE ON OBJECT::dbo.FN_SiSoHienTai TO role_GiaoVu;
    GRANT EXECUTE ON OBJECT::dbo.SP_TimKiemLop TO role_GiaoVu;
    GRANT EXECUTE ON OBJECT::dbo.SP_LichHoc_TheoPhong TO role_GiaoVu;
    GRANT EXECUTE ON OBJECT::dbo.SP_TaoLop_VaLichHoc TO role_GiaoVu;
    GRANT EXECUTE ON OBJECT::dbo.SP_KetThucLop TO role_GiaoVu;
    PRINT N'Da cap quyen Module C cho role_GiaoVu.';
END;
GO

/* 3. role_GiangVien: xem thong tin lop va lich hoc, khong sua bang */
IF DATABASE_PRINCIPAL_ID(N'role_GiangVien') IS NULL
    PRINT N'[Canh bao] Chua co role_GiangVien. Bo qua GRANT Module C cho role_GiangVien.';
ELSE
BEGIN
    GRANT SELECT ON OBJECT::dbo.V_LICH_HOC_TUAN TO role_GiangVien;
    GRANT SELECT ON OBJECT::dbo.V_LOP_TinhTrang TO role_GiangVien;
    GRANT SELECT ON OBJECT::dbo.FN_DSLichHoc_Lop TO role_GiangVien;
    GRANT EXECUTE ON OBJECT::dbo.FN_SiSoHienTai TO role_GiangVien;
    GRANT EXECUTE ON OBJECT::dbo.SP_TimKiemLop TO role_GiangVien;
    GRANT EXECUTE ON OBJECT::dbo.SP_LichHoc_TheoPhong TO role_GiangVien;
    DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.LOP TO role_GiangVien;
    DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.LICHHOC TO role_GiangVien;
    PRINT N'Da cap quyen xem va tu choi sua lop/lich cho role_GiangVien.';
END;
GO

/* 4. role_KeToan: chi doc danh sach lop de ho tro dang ky hoc */
IF DATABASE_PRINCIPAL_ID(N'role_KeToan') IS NULL
    PRINT N'[Canh bao] Chua co role_KeToan. Bo qua GRANT Module C cho role_KeToan.';
ELSE
BEGIN
    GRANT SELECT ON OBJECT::dbo.LOP TO role_KeToan;
    PRINT N'Da cap quyen doc bang LOP cho role_KeToan.';
END;
GO

/* 5. Kiem tra quyen da cap trong pham vi Module C */
SELECT r.name AS TenRole,
       p.state_desc AS TrangThaiQuyen,
       p.permission_name AS TenQuyen,
       OBJECT_SCHEMA_NAME(p.major_id) AS TenSchema,
       OBJECT_NAME(p.major_id) AS TenDoiTuong
FROM sys.database_permissions AS p
INNER JOIN sys.database_principals AS r
    ON r.principal_id = p.grantee_principal_id
WHERE r.name IN (N'role_QuanTri', N'role_GiaoVu', N'role_GiangVien', N'role_KeToan')
  AND p.major_id IN (
      OBJECT_ID(N'dbo.LOP'), OBJECT_ID(N'dbo.LICHHOC'),
      OBJECT_ID(N'dbo.V_LICH_HOC_TUAN'), OBJECT_ID(N'dbo.V_LOP_TinhTrang'),
      OBJECT_ID(N'dbo.FN_DSLichHoc_Lop'), OBJECT_ID(N'dbo.FN_SiSoHienTai'),
      OBJECT_ID(N'dbo.SP_TimKiemLop'), OBJECT_ID(N'dbo.SP_LichHoc_TheoPhong'),
      OBJECT_ID(N'dbo.SP_TaoLop_VaLichHoc'), OBJECT_ID(N'dbo.SP_KetThucLop')
  )
ORDER BY r.name, OBJECT_NAME(p.major_id), p.permission_name;
GO
