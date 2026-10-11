/* =====================================================================
   PHÂN QUYỀN CHO MODULE D (Giảng viên và giảng dạy)
   CSDL: QL_TTNgoaiNgu. Chạy bằng tài khoản sysadmin, SAU Module_D và SAU Security_Roles.sql
   (file của Kiên tạo 4 role). Chạy lại nhiều lần không lỗi.

   Nguyên tắc (theo chính sách chung trong Security_Roles.sql):
     - Quyền tối thiểu, không role nào có DDL.
     - Thủ tục/view/hàm thuộc dbo cùng chủ sở hữu với bảng nên nhờ ownership chaining
       chỉ cần EXECUTE / SELECT trên đối tượng, không cần quyền trên bảng bên trong.
     - Nghiệp vụ nhạy cảm (cho giảng viên nghỉ + bàn giao lớp) chỉ quản trị viên; role khác bị DENY.

     Đối tượng                     QuanTri      GiaoVu       KeToan   GiangVien
     GIANGVIEN                     S/I/U/D      S            -        S
     BUOIHOC                       S/I/U/D      S/I/U        -        S
     DIEMDANH                      S/I/U/D      S/I/U        DENY IUD S/I/U (DENY D)
     V_CHUYEN_CAN                  SELECT       SELECT       -        SELECT
     V_GIANGVIEN_TaiTrong          SELECT       SELECT       -        -
     FN_TyLeChuyenCan              EXECUTE      EXECUTE      -        EXECUTE
     FN_DSGiangVien_TheoNN         SELECT       SELECT       -        -
     SP_ThongKeChuyenCan_Lop       EXECUTE      EXECUTE      -        EXECUTE
     SP_LichDay_GiangVien          EXECUTE      EXECUTE      -        EXECUTE
     SP_DiemDanh_CaLop             EXECUTE      EXECUTE      DENY     EXECUTE
     SP_BanGiaoLop_KhiGVNghi       EXECUTE      DENY         DENY     DENY
     (S = SELECT, I = INSERT, U = UPDATE, D = DELETE)

   Ngoài ra màn hình của D đọc LOP, KHOAHOC (chọn lớp) nên cấp SELECT cho GiaoVu và GiangVien
   (khóa học Kiên đã cấp SELECT cho mọi role; lớp học người C có thể cấp lại, không xung đột).

   GIỚI HẠN ĐÃ BIẾT: quyền theo bảng/thủ tục, chưa phân quyền theo hàng. Một tài khoản
   role_GiangVien xem được lịch dạy và điểm danh của mọi giảng viên (hướng phát triển: Row-Level Security).
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

IF DATABASE_PRINCIPAL_ID(N'role_QuanTri') IS NULL OR DATABASE_PRINCIPAL_ID(N'role_GiaoVu') IS NULL
   OR DATABASE_PRINCIPAL_ID(N'role_KeToan') IS NULL OR DATABASE_PRINCIPAL_ID(N'role_GiangVien') IS NULL
BEGIN
    RAISERROR(N'Chưa có đủ 4 role. Hãy chạy Security_Roles.sql (của Kiên) trước file này.', 16, 1);
    RETURN;
END;
GO

/* =====================================================================
   1. REVOKE: đặt lại quyền trên đối tượng của D (REVOKE xóa cả GRANT lẫn DENY cũ)
   ===================================================================== */
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.GIANGVIEN FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.BUOIHOC   FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT, INSERT, UPDATE, DELETE ON dbo.DIEMDANH  FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.V_CHUYEN_CAN          FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.V_GIANGVIEN_TaiTrong  FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.FN_TyLeChuyenCan      FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE SELECT  ON dbo.FN_DSGiangVien_TheoNN FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_ThongKeChuyenCan_Lop FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_LichDay_GiangVien    FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_DiemDanh_CaLop       FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
REVOKE EXECUTE ON dbo.SP_BanGiaoLop_KhiGVNghi FROM role_QuanTri, role_GiaoVu, role_KeToan, role_GiangVien;
GO

/* =====================================================================
   2. GRANT / DENY
   ===================================================================== */
-- 2.1 Bảng
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.GIANGVIEN TO role_QuanTri;
GRANT SELECT ON dbo.GIANGVIEN TO role_GiaoVu, role_GiangVien;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.BUOIHOC TO role_QuanTri;
GRANT SELECT, INSERT, UPDATE         ON dbo.BUOIHOC TO role_GiaoVu;       -- giáo vụ lên lịch/đổi buổi học
GRANT SELECT                         ON dbo.BUOIHOC TO role_GiangVien;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.DIEMDANH TO role_QuanTri;
GRANT SELECT, INSERT, UPDATE         ON dbo.DIEMDANH TO role_GiaoVu, role_GiangVien;
DENY  DELETE ON dbo.DIEMDANH TO role_GiangVien;                           -- giảng viên không xóa lịch sử điểm danh
DENY  INSERT, UPDATE, DELETE ON dbo.DIEMDANH TO role_KeToan;              -- kế toán không được sửa điểm danh

-- 2.2 Màn hình của D đọc LOP, KHOAHOC để chọn lớp
GRANT SELECT ON dbo.LOP     TO role_GiaoVu, role_GiangVien;
GRANT SELECT ON dbo.KHOAHOC TO role_GiaoVu, role_GiangVien;

-- 2.3 View và hàm
GRANT SELECT  ON dbo.V_CHUYEN_CAN          TO role_QuanTri, role_GiaoVu, role_GiangVien;
GRANT SELECT  ON dbo.V_GIANGVIEN_TaiTrong  TO role_QuanTri, role_GiaoVu;
GRANT EXECUTE ON dbo.FN_TyLeChuyenCan      TO role_QuanTri, role_GiaoVu, role_GiangVien;   -- hàm vô hướng: EXECUTE
GRANT SELECT  ON dbo.FN_DSGiangVien_TheoNN TO role_QuanTri, role_GiaoVu;                   -- hàm bảng: SELECT

-- 2.4 Thủ tục
GRANT EXECUTE ON dbo.SP_ThongKeChuyenCan_Lop TO role_QuanTri, role_GiaoVu, role_GiangVien;
GRANT EXECUTE ON dbo.SP_LichDay_GiangVien    TO role_QuanTri, role_GiaoVu, role_GiangVien;
GRANT EXECUTE ON dbo.SP_DiemDanh_CaLop       TO role_QuanTri, role_GiaoVu, role_GiangVien;
DENY  EXECUTE ON dbo.SP_DiemDanh_CaLop       TO role_KeToan;

-- 2.5 Cho giảng viên nghỉ + bàn giao lớp: chỉ quản trị viên
GRANT EXECUTE ON dbo.SP_BanGiaoLop_KhiGVNghi TO role_QuanTri;
DENY  EXECUTE ON dbo.SP_BanGiaoLop_KhiGVNghi TO role_GiaoVu, role_KeToan, role_GiangVien;
GO

/* =====================================================================
   3. KIỂM TRA: quyền đã cấp trên đối tượng của D (dùng làm bảng minh chứng trong báo cáo)
   ===================================================================== */
SELECT dp.name                AS TenRole,
       o.name                 AS DoiTuong,
       p.permission_name      AS Quyen,
       p.state_desc           AS TrangThai
FROM sys.database_permissions AS p
JOIN sys.objects              AS o  ON o.object_id = p.major_id
JOIN sys.database_principals  AS dp ON dp.principal_id = p.grantee_principal_id
WHERE p.class = 1
  AND dp.name IN (N'role_QuanTri', N'role_GiaoVu', N'role_KeToan', N'role_GiangVien')
  AND o.name IN (N'GIANGVIEN', N'BUOIHOC', N'DIEMDANH', N'V_CHUYEN_CAN', N'V_GIANGVIEN_TaiTrong',
                 N'FN_TyLeChuyenCan', N'FN_DSGiangVien_TheoNN', N'SP_ThongKeChuyenCan_Lop',
                 N'SP_LichDay_GiangVien', N'SP_DiemDanh_CaLop', N'SP_BanGiaoLop_KhiGVNghi')
ORDER BY o.name, dp.name, p.permission_name;
GO

/* =====================================================================
   4. MINH CHỨNG PHÂN QUYỀN (chạy từng khối, chụp ảnh Messages). Mỗi khối giả danh một
      người dùng bằng EXECUTE AS rồi REVERT; mọi thao tác được ROLLBACK nên không đổi dữ liệu.
      Mong đợi ghi ở cuối mỗi dòng. Cần đã chạy Security_Roles.sql (có user ttnn_*).
   ===================================================================== */
/*
-- 4.1 Giảng viên điểm danh được, xem lịch dạy được, nhưng KHÔNG cho giảng viên khác nghỉ việc
EXECUTE AS USER = 'ttnn_giangvien';
    EXEC dbo.SP_LichDay_GiangVien 'GV02', '2026-02-01', '2026-02-28';          -- chạy được
    SELECT TOP (3) * FROM dbo.V_CHUYEN_CAN;                                      -- chạy được
    BEGIN TRY EXEC dbo.SP_BanGiaoLop_KhiGVNghi 'GV05'; END TRY
    BEGIN CATCH PRINT N'Bị chặn đúng: ' + ERROR_MESSAGE(); END CATCH;           -- lỗi 229: không có quyền EXECUTE
    BEGIN TRY SELECT * FROM dbo.V_GIANGVIEN_TaiTrong; END TRY
    BEGIN CATCH PRINT N'Bị chặn đúng: ' + ERROR_MESSAGE(); END CATCH;           -- lỗi 229: không có quyền SELECT
REVERT;

-- 4.2 Giáo vụ: điểm danh được, KHÔNG xóa được điểm danh, KHÔNG cho giảng viên nghỉ
EXECUTE AS USER = 'ttnn_giaovu';
    BEGIN TRY DELETE FROM dbo.DIEMDANH WHERE 1 = 0; END TRY      -- giáo vụ chỉ có S/I/U nên bị lỗi 229
    BEGIN CATCH PRINT N'Bị chặn đúng: ' + ERROR_MESSAGE(); END CATCH;
    BEGIN TRY EXEC dbo.SP_BanGiaoLop_KhiGVNghi 'GV05'; END TRY
    BEGIN CATCH PRINT N'Bị chặn đúng: ' + ERROR_MESSAGE(); END CATCH;
REVERT;

-- 4.3 Kế toán: không đụng vào điểm danh và không điểm danh qua thủ tục
EXECUTE AS USER = 'ttnn_ketoan';
    BEGIN TRY EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'[{"MaDK":"DK008","TrangThai":"Có mặt"}]'; END TRY
    BEGIN CATCH PRINT N'Bị chặn đúng: ' + ERROR_MESSAGE(); END CATCH;
REVERT;

-- 4.4 Quản trị viên: bàn giao lớp được (ROLLBACK để giữ dữ liệu)
EXECUTE AS USER = 'ttnn_quantri';
    BEGIN TRAN;
    EXEC dbo.SP_BanGiaoLop_KhiGVNghi 'GV01', 'GV02';                             -- thành công, SoLopBanGiao = 1
    ROLLBACK;
REVERT;
*/
GO
