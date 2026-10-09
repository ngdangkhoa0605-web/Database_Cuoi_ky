/* =====================================================================
   BẢO MẬT VÀ PHÂN QUYỀN - Đoàn Trung Kiên (24110262)
   CSDL: QL_TTNgoaiNgu

   Nội dung:
     1. Tạo 4 Role trong CSDL : role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien
     2. Tạo 4 Login (SQL Server Authentication) + User, mỗi user thuộc đúng 1 role:
          ttnn_quantri   -> role_QuanTri
          ttnn_giaovu    -> role_GiaoVu
          ttnn_ketoan    -> role_KeToan
          ttnn_giangvien -> role_GiangVien
        Ứng dụng đăng nhập bằng chính các Login này (JpaUtil.connect), sau đó dùng
        IS_ROLEMEMBER để biết người dùng thuộc role nào và hiện màn hình tương ứng.
     3. REVOKE: đặt lại quyền trên đối tượng của Kiên (để chạy lại script cho đúng).
     4. GRANT / DENY trên đối tượng của Kiên (NGONNGU, KHOAHOC và 10 đối tượng Module A).

   CHÍNH SÁCH CHUNG (theo kế hoạch nhóm):
     role_QuanTri   : quản trị viên - quản lý danh mục, xem mọi báo cáo.
     role_GiaoVu    : giáo vụ - lớp, lịch học, điểm danh (C, D cấp quyền chi tiết).
     role_KeToan    : kế toán - học viên, đăng ký, hóa đơn (B đã cấp trong Grant_Module_B.sql).
     role_GiangVien : giảng viên - xem lịch, ghi điểm danh (D cấp quyền chi tiết).
     Nguyên tắc:
       - Quyền tối thiểu: mỗi role chỉ có quyền cần cho công việc của mình; KHÔNG role
         nào có quyền DDL (CREATE/ALTER/DROP) - cấu trúc CSDL chỉ do sysadmin thay đổi.
       - Thao tác có nhiều bước liên quan (đổi học phí + hóa đơn, thêm khóa + ngôn ngữ)
         chỉ được làm qua thủ tục. Thủ tục thuộc dbo giống bảng nên nhờ ownership chaining
         người dùng chỉ cần EXECUTE trên thủ tục, không cần quyền trên bảng bên trong.
       - DENY dùng cho các thao tác nhạy cảm để chặn tuyệt đối (DENY thắng GRANT).

   QUYỀN TRÊN ĐỐI TƯỢNG CỦA A:
     Đối tượng                              QuanTri          GiaoVu  KeToan  GiangVien
     NGONNGU                                S/I/U/D          S       S       S
     KHOAHOC                                S/I/U/D          S       S       S
       cột KHOAHOC.HocPhi                   DENY UPDATE      -       -       -
     V_KHOAHOC_ThongKe, V_THONGKE_NgonNgu   SELECT           SELECT  SELECT  -
     FN_SoHocVien_KhoaHoc                   EXECUTE          EXECUTE EXECUTE -
     FN_DSKhoaHoc_TheoNN                    SELECT           SELECT  SELECT  SELECT
     SP_TimKiemKhoaHoc                      EXECUTE          EXECUTE EXECUTE EXECUTE
     SP_ThongKeDangKy_TheoKhoa              EXECUTE          EXECUTE EXECUTE -
     SP_CapNhatHocPhiKhoa                   EXECUTE          DENY    DENY    DENY
     SP_ThemKhoaHoc_VaNgonNgu               EXECUTE          DENY    DENY    DENY
     (S = SELECT, I = INSERT, U = UPDATE, D = DELETE)

     DENY UPDATE trên cột HocPhi: kể cả quản trị viên cũng không sửa học phí trực tiếp
     trên bảng, vì như vậy các hóa đơn chưa thanh toán sẽ không được cập nhật theo. Đổi
     học phí bắt buộc qua SP_CapNhatHocPhiKhoa (ownership chaining bỏ qua DENY này bên
     trong thủ tục). Ứng dụng: entity KhoaHoc khai báo cột HocPhi updatable = false.

   THỨ TỰ CHẠY: schema -> dữ liệu mẫu -> Module A, B, C, D -> FILE NÀY
                -> Grant_Module_B.sql (và Grant_Module_C/D nếu có).
   Chạy bằng tài khoản sysadmin (Windows Authentication của máy là đủ).
   SQL Server phải bật "SQL Server and Windows Authentication mode" thì Login mới đăng nhập được.
   FILE CHẠY LẠI NHIỀU LẦN KHÔNG LỖI. ĐỔI MẬT KHẨU trước khi dùng thật.
   ===================================================================== */

/* =====================================================================
   1. ROLE
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

IF DATABASE_PRINCIPAL_ID(N'role_QuanTri')   IS NULL CREATE ROLE role_QuanTri;
IF DATABASE_PRINCIPAL_ID(N'role_GiaoVu')    IS NULL CREATE ROLE role_GiaoVu;
IF DATABASE_PRINCIPAL_ID(N'role_KeToan')    IS NULL CREATE ROLE role_KeToan;
IF DATABASE_PRINCIPAL_ID(N'role_GiangVien') IS NULL CREATE ROLE role_GiangVien;
GO

/* =====================================================================
   2. LOGIN (cấp máy chủ) + USER (cấp CSDL) + gán vào ROLE
   ===================================================================== */
USE master;
GO
IF SUSER_ID(N'ttnn_quantri') IS NULL
    CREATE LOGIN ttnn_quantri   WITH PASSWORD = N'Ttnn@QuanTri_2026!',   CHECK_POLICY = OFF, DEFAULT_DATABASE = QL_TTNgoaiNgu;
IF SUSER_ID(N'ttnn_giaovu') IS NULL
    CREATE LOGIN ttnn_giaovu    WITH PASSWORD = N'Ttnn@GiaoVu_2026!',    CHECK_POLICY = OFF, DEFAULT_DATABASE = QL_TTNgoaiNgu;
IF SUSER_ID(N'ttnn_ketoan') IS NULL
    CREATE LOGIN ttnn_ketoan    WITH PASSWORD = N'Ttnn@KeToan_2026!',    CHECK_POLICY = OFF, DEFAULT_DATABASE = QL_TTNgoaiNgu;
IF SUSER_ID(N'ttnn_giangvien') IS NULL
    CREATE LOGIN ttnn_giangvien WITH PASSWORD = N'Ttnn@GiangVien_2026!', CHECK_POLICY = OFF, DEFAULT_DATABASE = QL_TTNgoaiNgu;
GO

USE QL_TTNgoaiNgu;
GO
-- User trong CSDL (CSDL bị xóa/tạo lại thì user mất nhưng login vẫn còn -> tạo lại user)
IF DATABASE_PRINCIPAL_ID(N'ttnn_quantri')   IS NULL CREATE USER ttnn_quantri   FOR LOGIN ttnn_quantri;
IF DATABASE_PRINCIPAL_ID(N'ttnn_giaovu')    IS NULL CREATE USER ttnn_giaovu    FOR LOGIN ttnn_giaovu;
IF DATABASE_PRINCIPAL_ID(N'ttnn_ketoan')    IS NULL CREATE USER ttnn_ketoan    FOR LOGIN ttnn_ketoan;
IF DATABASE_PRINCIPAL_ID(N'ttnn_giangvien') IS NULL CREATE USER ttnn_giangvien FOR LOGIN ttnn_giangvien;
GO

IF IS_ROLEMEMBER(N'role_QuanTri',   N'ttnn_quantri')   = 0 ALTER ROLE role_QuanTri   ADD MEMBER ttnn_quantri;
IF IS_ROLEMEMBER(N'role_GiaoVu',    N'ttnn_giaovu')    = 0 ALTER ROLE role_GiaoVu    ADD MEMBER ttnn_giaovu;
IF IS_ROLEMEMBER(N'role_KeToan',    N'ttnn_ketoan')    = 0 ALTER ROLE role_KeToan    ADD MEMBER ttnn_ketoan;
IF IS_ROLEMEMBER(N'role_GiangVien', N'ttnn_giangvien') = 0 ALTER ROLE role_GiangVien ADD MEMBER ttnn_giangvien;
GO

/* =====================================================================
   3. REVOKE - đặt lại quyền trên đối tượng của Kiên
      REVOKE xóa cả GRANT lẫn DENY đã cấp trước đó (khác DENY: DENY là cấm hẳn).
      Nhờ bước này, sửa chính sách ở mục 4 rồi chạy lại file là ra đúng chính sách mới.
      Lưu ý: bước này cũng xóa GRANT SELECT trên KHOAHOC mà Grant_Module_B.sql cấp cho
      role_KeToan/role_QuanTri; mục 4 cấp lại SELECT đó nên kết quả không đổi.
   ===================================================================== */
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.NGONNGU FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.KHOAHOC FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE UPDATE (HocPhi) ON dbo.KHOAHOC                FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.V_KHOAHOC_ThongKe              FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.V_THONGKE_NgonNgu              FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.FN_SoHocVien_KhoaHoc           FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.FN_DSKhoaHoc_TheoNN            FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_TimKiemKhoaHoc              FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_ThongKeDangKy_TheoKhoa      FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_CapNhatHocPhiKhoa           FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_ThemKhoaHoc_VaNgonNgu       FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
GO

/* =====================================================================
   4. GRANT / DENY trên đối tượng của Kiên
   ===================================================================== */

-- 4.1 Bảng danh mục: quản trị viên quản lý; các role khác chỉ đọc (để chọn khóa học
--     khi tạo lớp, đăng ký, xem lịch...).
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NGONNGU TO role_QuanTri;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.KHOAHOC TO role_QuanTri;
GRANT SELECT ON dbo.NGONNGU TO role_GiaoVu, role_KeToan, role_GiangVien;
GRANT SELECT ON dbo.KHOAHOC TO role_GiaoVu, role_KeToan, role_GiangVien;

-- 4.2 Cấm sửa trực tiếp cột HocPhi (kể cả quản trị viên): phải qua SP_CapNhatHocPhiKhoa.
--     DENY ở mức cột phải chạy SAU GRANT ở mức bảng (GRANT mức bảng chạy sau sẽ xóa
--     DENY mức cột).
DENY UPDATE (HocPhi) ON dbo.KHOAHOC TO role_QuanTri;

-- 4.3 Báo cáo / thống kê khóa học: quản trị, giáo vụ, kế toán. Giảng viên không cần.
GRANT SELECT  ON dbo.V_KHOAHOC_ThongKe         TO role_QuanTri, role_GiaoVu, role_KeToan;
GRANT SELECT  ON dbo.V_THONGKE_NgonNgu         TO role_QuanTri, role_GiaoVu, role_KeToan;
GRANT EXECUTE ON dbo.FN_SoHocVien_KhoaHoc      TO role_QuanTri, role_GiaoVu, role_KeToan;   -- hàm vô hướng: EXECUTE
GRANT EXECUTE ON dbo.SP_ThongKeDangKy_TheoKhoa TO role_QuanTri, role_GiaoVu, role_KeToan;

-- 4.4 Tra cứu danh mục: mọi role.
GRANT SELECT  ON dbo.FN_DSKhoaHoc_TheoNN TO role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;  -- hàm bảng: SELECT
GRANT EXECUTE ON dbo.SP_TimKiemKhoaHoc   TO role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;

-- 4.5 Nghiệp vụ thay đổi danh mục và tiền: chỉ quản trị viên; các role khác bị DENY.
GRANT EXECUTE ON dbo.SP_CapNhatHocPhiKhoa     TO role_QuanTri;
GRANT EXECUTE ON dbo.SP_ThemKhoaHoc_VaNgonNgu TO role_QuanTri;
DENY  EXECUTE ON dbo.SP_CapNhatHocPhiKhoa     TO role_GiaoVu, role_KeToan, role_GiangVien;
DENY  EXECUTE ON dbo.SP_ThemKhoaHoc_VaNgonNgu TO role_GiaoVu, role_KeToan, role_GiangVien;
GO

/* =====================================================================
   5. KIỂM TRA
   ===================================================================== */
-- 5.1 Thành viên của 4 role (mong đợi: mỗi role có login tương ứng; role_KeToan có thêm
--     ttnn_demo_b nếu đã chạy Grant_Module_B.sql)
SELECT r.name AS TenRole, m.name AS ThanhVien
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
WHERE r.name IN (N'role_QuanTri', N'role_GiaoVu', N'role_KeToan', N'role_GiangVien')
ORDER BY r.name, m.name;

-- 5.2 Quyền đã cấp trên đối tượng của Kiên (dùng làm bảng minh chứng trong Chương 4)
SELECT dp.name                AS TenRole,
       o.name                 AS DoiTuong,
       c.name                 AS Cot,
       p.permission_name      AS Quyen,
       p.state_desc           AS TrangThai
FROM sys.database_permissions AS p
JOIN sys.objects              AS o  ON o.object_id = p.major_id
JOIN sys.database_principals  AS dp ON dp.principal_id = p.grantee_principal_id
LEFT JOIN sys.columns         AS c  ON c.object_id = p.major_id AND c.column_id = p.minor_id
WHERE p.class = 1
  AND dp.name IN (N'role_QuanTri', N'role_GiaoVu', N'role_KeToan', N'role_GiangVien')
  AND o.name IN (N'NGONNGU', N'KHOAHOC', N'V_KHOAHOC_ThongKe', N'V_THONGKE_NgonNgu',
                 N'FN_SoHocVien_KhoaHoc', N'FN_DSKhoaHoc_TheoNN', N'SP_TimKiemKhoaHoc',
                 N'SP_ThongKeDangKy_TheoKhoa', N'SP_CapNhatHocPhiKhoa', N'SP_ThemKhoaHoc_VaNgonNgu')
ORDER BY dp.name, o.name, p.permission_name;
GO