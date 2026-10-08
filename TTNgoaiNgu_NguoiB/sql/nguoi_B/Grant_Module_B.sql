/* =====================================================================
   PHAN QUYEN CHO MODULE B (goi y de Kien ghep vao bang chinh sach phan quyen)
   Chay SAU Module_B_HocVien_TaiChinh.sql. Script chay lai nhieu lan khong loi.

   Mac dinh trong ke hoach: role_KeToan lam viec voi dang ky + hoa don (+ hoc vien).
   Role chua ton tai (Kien chua tao) thi script chi in canh bao, KHONG tao role -> khong xung dot.
   Thu tuc/view nam o schema dbo cung chu so huu voi bang nen chi can EXECUTE / SELECT
   (ownership chaining), khong can cap quyen truc tiep len bang ma thu tuc dung ben trong.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* ---------- 1. role_KeToan ---------- */
IF DATABASE_PRINCIPAL_ID(N'role_KeToan') IS NULL
    PRINT N'[Canh bao] Chua co role_KeToan (Kien tao). Bo qua phan GRANT cho role_KeToan.';
ELSE
BEGIN
    -- Thu tuc cua Nguyễn Đăng Khoa (24110255)
    GRANT EXECUTE ON dbo.SP_TimKiemHocVien      TO role_KeToan;
    GRANT EXECUTE ON dbo.SP_ThongKeDoanhThu     TO role_KeToan;
    GRANT EXECUTE ON dbo.SP_DangKy_VaTaoHoaDon  TO role_KeToan;
    GRANT EXECUTE ON dbo.SP_ThanhToanHocPhi     TO role_KeToan;
    GRANT EXECUTE ON dbo.SP_HuyDangKy           TO role_KeToan;
    -- Ham
    GRANT SELECT  ON dbo.FN_DSDangKy_HocVien    TO role_KeToan;   -- ham bang: can SELECT
    GRANT EXECUTE ON dbo.FN_TinhCongNo          TO role_KeToan;   -- ham vo huong: can EXECUTE
    -- View
    GRANT SELECT  ON dbo.V_CONGNO_HocPhi        TO role_KeToan;
    GRANT SELECT  ON dbo.V_HOCVIEN_LichSuHoc    TO role_KeToan;
    -- Bang: quan ly hoc vien (CRUD), xem dang ky/hoa don, nhap diem
    GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.HOCVIEN TO role_KeToan;
    GRANT SELECT, UPDATE ON dbo.DANGKY          TO role_KeToan;
    GRANT SELECT ON dbo.HOADON                  TO role_KeToan;
    -- Doc danh muc de chon lop khi dang ky (ung dung doc LOP, KHOAHOC bang truy van)
    GRANT SELECT ON dbo.LOP                     TO role_KeToan;
    GRANT SELECT ON dbo.KHOAHOC                 TO role_KeToan;
    -- Ke toan KHONG duoc sua hoa don truc tiep: moi thay doi tien phai qua thu tuc
    DENY INSERT, UPDATE, DELETE ON dbo.HOADON   TO role_KeToan;
    PRINT N'Da cap quyen Module B cho role_KeToan.';
END;
GO

/* ---------- 2. role_QuanTri : toan quyen tren cac doi tuong cua B ---------- */
IF DATABASE_PRINCIPAL_ID(N'role_QuanTri') IS NULL
    PRINT N'[Canh bao] Chua co role_QuanTri (Kien tao). Bo qua phan GRANT cho role_QuanTri.';
ELSE
BEGIN
    GRANT EXECUTE ON dbo.SP_TimKiemHocVien      TO role_QuanTri;
    GRANT EXECUTE ON dbo.SP_ThongKeDoanhThu     TO role_QuanTri;
    GRANT EXECUTE ON dbo.SP_DangKy_VaTaoHoaDon  TO role_QuanTri;
    GRANT EXECUTE ON dbo.SP_ThanhToanHocPhi     TO role_QuanTri;
    GRANT EXECUTE ON dbo.SP_HuyDangKy           TO role_QuanTri;
    GRANT SELECT  ON dbo.FN_DSDangKy_HocVien    TO role_QuanTri;
    GRANT EXECUTE ON dbo.FN_TinhCongNo          TO role_QuanTri;
    GRANT SELECT  ON dbo.V_CONGNO_HocPhi        TO role_QuanTri;
    GRANT SELECT  ON dbo.V_HOCVIEN_LichSuHoc    TO role_QuanTri;
    GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.HOCVIEN TO role_QuanTri;
    GRANT SELECT, UPDATE ON dbo.DANGKY          TO role_QuanTri;
    GRANT SELECT ON dbo.HOADON                  TO role_QuanTri;
    GRANT SELECT ON dbo.LOP                     TO role_QuanTri;
    GRANT SELECT ON dbo.KHOAHOC                 TO role_QuanTri;
    PRINT N'Da cap quyen Module B cho role_QuanTri.';
END;
GO

/* ---------- 3. role_GiaoVu, role_GiangVien : KHONG duoc dung hoc vien/tai chinh ----------
   Chi DENY khi role ton tai. DENY tren thu tuc/view cua B de minh chung phan quyen trong bao cao. */
IF DATABASE_PRINCIPAL_ID(N'role_GiangVien') IS NOT NULL
BEGIN
    DENY EXECUTE ON dbo.SP_ThanhToanHocPhi TO role_GiangVien;
    DENY EXECUTE ON dbo.SP_ThongKeDoanhThu TO role_GiangVien;
    DENY SELECT  ON dbo.V_CONGNO_HocPhi    TO role_GiangVien;
    DENY SELECT  ON dbo.HOADON             TO role_GiangVien;
    PRINT N'Da DENY doi tuong tai chinh cho role_GiangVien.';
END;
GO

/* ---------- 4. TAI KHOAN DEMO CHO UNG DUNG CUA NGUYỄN ĐĂNG KHOA (24110255) (tuy chon, chi dung de chay thu) ----------
   Tao login ttnn_demo_b (khong trung ten login cua Kien). Neu da co role_KeToan thi them vao role,
   neu chua co thi cap quyen truc tiep nhu role_KeToan o tren.
   DOI MAT KHAU truoc khi chay tren may that. Xoa bang:
     DROP USER ttnn_demo_b; DROP LOGIN ttnn_demo_b;                                               */
USE master;
GO
IF SUSER_ID(N'ttnn_demo_b') IS NULL
    CREATE LOGIN ttnn_demo_b WITH PASSWORD = N'Ttnn@Demo_B_2026!', CHECK_POLICY = OFF,
                                  DEFAULT_DATABASE = QL_TTNgoaiNgu;
GO
USE QL_TTNgoaiNgu;
GO
IF DATABASE_PRINCIPAL_ID(N'ttnn_demo_b') IS NULL
    CREATE USER ttnn_demo_b FOR LOGIN ttnn_demo_b;
GO
IF DATABASE_PRINCIPAL_ID(N'role_KeToan') IS NOT NULL
BEGIN
    IF IS_ROLEMEMBER(N'role_KeToan', N'ttnn_demo_b') = 0
        ALTER ROLE role_KeToan ADD MEMBER ttnn_demo_b;
    PRINT N'ttnn_demo_b da la thanh vien role_KeToan.';
END
ELSE
BEGIN
    GRANT EXECUTE ON dbo.SP_TimKiemHocVien      TO ttnn_demo_b;
    GRANT EXECUTE ON dbo.SP_ThongKeDoanhThu     TO ttnn_demo_b;
    GRANT EXECUTE ON dbo.SP_DangKy_VaTaoHoaDon  TO ttnn_demo_b;
    GRANT EXECUTE ON dbo.SP_ThanhToanHocPhi     TO ttnn_demo_b;
    GRANT EXECUTE ON dbo.SP_HuyDangKy           TO ttnn_demo_b;
    GRANT SELECT  ON dbo.FN_DSDangKy_HocVien    TO ttnn_demo_b;
    GRANT EXECUTE ON dbo.FN_TinhCongNo          TO ttnn_demo_b;
    GRANT SELECT  ON dbo.V_CONGNO_HocPhi        TO ttnn_demo_b;
    GRANT SELECT  ON dbo.V_HOCVIEN_LichSuHoc    TO ttnn_demo_b;
    GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.HOCVIEN TO ttnn_demo_b;
    GRANT SELECT, UPDATE ON dbo.DANGKY          TO ttnn_demo_b;
    GRANT SELECT ON dbo.HOADON                  TO ttnn_demo_b;
    GRANT SELECT ON dbo.LOP                     TO ttnn_demo_b;
    GRANT SELECT ON dbo.KHOAHOC                 TO ttnn_demo_b;
    PRINT N'Da cap quyen truc tiep cho ttnn_demo_b (chua co role_KeToan).';
END;
GO
