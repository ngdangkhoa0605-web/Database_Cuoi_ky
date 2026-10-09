/* =====================================================================
   MINH HỌA PHÂN QUYỀN (GRANT / REVOKE / DENY) - Kiên (24110262)
   Chạy SAU Security_Roles.sql, bằng tài khoản sysadmin.
   Mỗi ca dùng EXECUTE AS USER để chạy thử dưới danh nghĩa một user, sau đó REVERT.
   Ca nào có thay đổi dữ liệu hoặc quyền đều chạy trong giao dịch và ROLLBACK
   (GRANT/REVOKE/DENY trong SQL Server cũng rollback được) -> không đổi CSDL.
   Kết quả: bảng PASS/FAIL ở cuối, mong đợi SoCaFAIL = 0. Chụp bảng này cho Chương 4.
   Mã lỗi hệ thống: 229 = bị từ chối quyền trên đối tượng; 230 = bị từ chối quyền trên cột.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#KQ') IS NOT NULL DROP TABLE #KQ;
CREATE TABLE #KQ
(
    STT     INT IDENTITY(1,1) PRIMARY KEY,
    Ma      VARCHAR(10)   NOT NULL,
    MoTa    NVARCHAR(200) NOT NULL,
    KetQua  VARCHAR(4)    NOT NULL,
    ChiTiet NVARCHAR(400) NULL
);

DECLARE @n INT, @err INT, @msg NVARCHAR(400), @tien MONEY;

/* ---------- P01: mỗi login thuộc đúng role của mình (ứng dụng dùng IS_ROLEMEMBER như thế này) ---------- */
SET @n = 0;
EXECUTE AS USER = N'ttnn_quantri';   SET @n += IS_ROLEMEMBER(N'role_QuanTri');   REVERT;
EXECUTE AS USER = N'ttnn_giaovu';    SET @n += IS_ROLEMEMBER(N'role_GiaoVu');    REVERT;
EXECUTE AS USER = N'ttnn_ketoan';    SET @n += IS_ROLEMEMBER(N'role_KeToan');    REVERT;
EXECUTE AS USER = N'ttnn_giangvien'; SET @n += IS_ROLEMEMBER(N'role_GiangVien'); REVERT;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('P01', N'4 login thuộc đúng 4 role', CASE WHEN @n = 4 THEN 'PASS' ELSE 'FAIL' END,
        N'Số login đúng role = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- P02: GRANT - giảng viên được đọc danh mục khóa học ---------- */
BEGIN TRY
    EXECUTE AS USER = N'ttnn_giangvien';
    SELECT @n = COUNT(*) FROM dbo.KHOAHOC;
    REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P02', N'GRANT: ttnn_giangvien SELECT KHOAHOC được phép', CASE WHEN @n = 5 THEN 'PASS' ELSE 'FAIL' END,
            N'Số khóa đọc được = ' + CAST(@n AS NVARCHAR(10)));
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P02', N'GRANT: ttnn_giangvien SELECT KHOAHOC được phép', 'FAIL', @msg);
END CATCH;

/* ---------- P03: không được cấp - giảng viên không xem thống kê ---------- */
BEGIN TRY
    EXECUTE AS USER = N'ttnn_giangvien';
    SELECT @n = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe;
    REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P03', N'ttnn_giangvien SELECT V_KHOAHOC_ThongKe phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P03', N'Không cấp quyền: ttnn_giangvien SELECT V_KHOAHOC_ThongKe bị từ chối (229)',
            CASE WHEN @err = 229 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- P04: chỉ đọc - kế toán không sửa được KHOAHOC ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_ketoan';
    UPDATE dbo.KHOAHOC SET TenKhoa = TenKhoa WHERE MaKH = 'KH0001';
    REVERT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P04', N'ttnn_ketoan UPDATE KHOAHOC phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P04', N'Chỉ có SELECT: ttnn_ketoan UPDATE KHOAHOC bị từ chối (229)',
            CASE WHEN @err = 229 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- P05: DENY - kế toán không được đổi học phí qua thủ tục ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_ketoan';
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0005', @HocPhiMoi = 3100000, @SoHoaDonCapNhat = @n OUTPUT;
    REVERT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P05', N'ttnn_ketoan EXEC SP_CapNhatHocPhiKhoa phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P05', N'DENY: ttnn_ketoan EXEC SP_CapNhatHocPhiKhoa bị từ chối (229)',
            CASE WHEN @err = 229 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- P06: DENY mức cột - quản trị viên KHÔNG sửa trực tiếp HocPhi ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_quantri';
    UPDATE dbo.KHOAHOC SET HocPhi = 3100000 WHERE MaKH = 'KH0005';
    REVERT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P06', N'ttnn_quantri UPDATE KHOAHOC.HocPhi phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P06', N'DENY cột: ttnn_quantri UPDATE trực tiếp HocPhi bị từ chối (230)',
            CASE WHEN @err = 230 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- P07: quản trị viên sửa cột khác của KHOAHOC vẫn được ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_quantri';
    UPDATE dbo.KHOAHOC SET TenKhoa = N'Tiếng Trung HSK1 (sửa thử)' WHERE MaKH = 'KH0005';
    REVERT;
    SELECT @msg = TenKhoa FROM dbo.KHOAHOC WHERE MaKH = 'KH0005';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P07', N'GRANT bảng: ttnn_quantri sửa TenKhoa được phép',
            CASE WHEN @msg = N'Tiếng Trung HSK1 (sửa thử)' THEN 'PASS' ELSE 'FAIL' END, @msg);
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P07', N'GRANT bảng: ttnn_quantri sửa TenKhoa được phép', 'FAIL', @msg);
END CATCH;

/* ---------- P08: ownership chaining - quản trị viên đổi học phí QUA THỦ TỤC được phép
                   (dù bị DENY UPDATE cột HocPhi trên bảng) ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_quantri';
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0005', @HocPhiMoi = 3100000, @SoHoaDonCapNhat = @n OUTPUT;
    REVERT;
    SELECT @tien = HocPhi FROM dbo.KHOAHOC WHERE MaKH = 'KH0005';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P08', N'Ownership chaining: ttnn_quantri đổi HocPhi qua SP_CapNhatHocPhiKhoa được phép',
            CASE WHEN @tien = 3100000 THEN 'PASS' ELSE 'FAIL' END, N'HocPhi sau khi gọi = ' + CAST(@tien AS NVARCHAR(20)));
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P08', N'Ownership chaining qua thủ tục', 'FAIL', @msg);
END CATCH;

/* ---------- P09: REVOKE - thu hồi quyền xem thống kê của giáo vụ ----------
   Trước REVOKE: đọc được. Sau REVOKE: bị từ chối. ROLLBACK -> quyền được trả lại. */
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER = N'ttnn_giaovu';
    SELECT @n = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe;     -- trước REVOKE: được
    REVERT;
    REVOKE SELECT ON dbo.V_KHOAHOC_ThongKe FROM role_GiaoVu;
    EXECUTE AS USER = N'ttnn_giaovu';
    SELECT @n = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe;     -- sau REVOKE: phải lỗi
    REVERT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P09', N'Sau REVOKE, ttnn_giaovu phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P09', N'REVOKE: trước thu hồi đọc được, sau thu hồi ttnn_giaovu bị từ chối (229)',
            CASE WHEN @err = 229 AND @n = 5 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

-- P09b: sau ROLLBACK quyền được trả lại
BEGIN TRY
    EXECUTE AS USER = N'ttnn_giaovu';
    SELECT @n = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe;
    REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P09b', N'Sau ROLLBACK, ttnn_giaovu đọc lại V_KHOAHOC_ThongKe được', CASE WHEN @n = 5 THEN 'PASS' ELSE 'FAIL' END, NULL);
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P09b', N'Sau ROLLBACK, ttnn_giaovu đọc lại được', 'FAIL', @msg);
END CATCH;

/* ---------- P10: DENY thắng GRANT ----------
   Cấp thêm EXECUTE trực tiếp cho user ttnn_ketoan, nhưng role_KeToan đang bị DENY
   -> vẫn bị từ chối. ROLLBACK để bỏ GRANT thử nghiệm. */
BEGIN TRY
    BEGIN TRANSACTION;
    GRANT EXECUTE ON dbo.SP_CapNhatHocPhiKhoa TO ttnn_ketoan;
    EXECUTE AS USER = N'ttnn_ketoan';
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0005', @HocPhiMoi = 3100000, @SoHoaDonCapNhat = @n OUTPUT;
    REVERT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P10', N'DENY phải thắng GRANT', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P10', N'DENY thắng GRANT: GRANT riêng cho ttnn_ketoan vẫn bị DENY của role chặn (229)',
            CASE WHEN @err = 229 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- P11: không role nào có quyền DDL ---------- */
BEGIN TRY
    EXECUTE AS USER = N'ttnn_quantri';
    EXEC (N'CREATE TABLE dbo.BANG_THU (Id INT);');
    REVERT;
    IF OBJECT_ID(N'dbo.BANG_THU') IS NOT NULL DROP TABLE dbo.BANG_THU;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('P11', N'ttnn_quantri CREATE TABLE phải bị từ chối', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SELECT @err = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
    IF USER_NAME() <> N'dbo' REVERT;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('P11', N'Không có quyền DDL: ttnn_quantri CREATE TABLE bị từ chối (262)',
            CASE WHEN @err = 262 THEN 'PASS' ELSE 'FAIL' END, @msg);
END CATCH;

/* ---------- KẾT QUẢ ---------- */
SELECT STT, Ma, MoTa, KetQua, ChiTiet FROM #KQ ORDER BY STT;
SELECT SUM(CASE WHEN KetQua = 'PASS' THEN 1 ELSE 0 END) AS SoCaPASS,
       SUM(CASE WHEN KetQua = 'FAIL' THEN 1 ELSE 0 END) AS SoCaFAIL,
       COUNT(*) AS TongSoCa
FROM #KQ;
DROP TABLE #KQ;
GO