/* =====================================================================
   DEMO KHÔI PHỤC SAU SỰ CỐ (BACKUP / RESTORE) - Kiên (24110262)
   Tình huống: nhân viên lỡ chạy DELETE thiếu WHERE, xóa sạch bảng DIEMDANH.
   Mục tiêu: khôi phục CSDL về ĐÚNG THỜI ĐIỂM ngay trước sự cố (point-in-time restore):
     - Dữ liệu bị xóa nhầm được lấy lại.
     - Công việc hợp lệ làm SAU bản sao lưu đầy đủ (thêm một khóa học) KHÔNG bị mất.
   (Nếu chỉ restore bản sao lưu đầy đủ thì sẽ mất công việc hợp lệ đó.)

   CHIẾN LƯỢC SAO LƯU:
     - Recovery model FULL: mọi thay đổi được ghi đủ vào transaction log.
     - Full backup (.bak)    : ảnh chụp toàn bộ CSDL.
     - Tail-log backup (.trn): phần log từ sau full backup tới lúc sự cố (chứa cả lệnh DELETE).
     - RESTORE full WITH NORECOVERY -> RESTORE LOG WITH STOPAT = <thời điểm an toàn>, RECOVERY.

   CHẠY TOÀN BỘ FILE BẰNG TÀI KHOẢN SYSADMIN (Windows Authentication của máy).
   ⚠ BƯỚC 4 ngắt MỌI kết nối khác tới QL_TTNgoaiNgu (ứng dụng Java, các tab SSMS khác)
     -> đóng ứng dụng trước khi chạy. Chỉ chạy trên máy thử / máy demo.
   ⚠ Phải chạy TỪ ĐẦU TỚI CUỐI trong CÙNG MỘT cửa sổ query (bảng #MocThoiGian sống theo phiên).
     Có thể chạy từng BƯỚC theo thứ tự để chụp ảnh, nhưng không đóng cửa sổ giữa chừng.
   File sao lưu lưu ở thư mục backup mặc định của SQL Server (in ra ở BƯỚC 0).
   Nếu bị dừng giữa BƯỚC 4 và BƯỚC 5 khiến CSDL kẹt ở trạng thái "Restoring", chạy:
       RESTORE DATABASE QL_TTNgoaiNgu WITH RECOVERY;  ALTER DATABASE QL_TTNgoaiNgu SET MULTI_USER;
   ===================================================================== */
USE master;
GO
SET NOCOUNT ON;
GO

/* ---------- BƯỚC 0: chuẩn bị ---------- */
IF OBJECT_ID('tempdb..#MocThoiGian') IS NOT NULL DROP TABLE #MocThoiGian;
CREATE TABLE #MocThoiGian
(
    MaKHDemo        VARCHAR(6) NULL,   -- khóa học thêm hợp lệ sau full backup
    SoDiemDanhGoc   INT        NULL,   -- số dòng DIEMDANH trước sự cố
    ThoiDiemAnToan  DATETIME   NULL    -- mốc khôi phục (STOPAT)
);

SELECT name                                         AS CSDL,
       recovery_model_desc                          AS RecoveryModel_HienTai,
       CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(400)) AS ThuMucSaoLuu
FROM sys.databases
WHERE name = N'QL_TTNgoaiNgu';
GO

/* ---------- BƯỚC 1: bật FULL recovery + sao lưu đầy đủ + kiểm tra bản sao lưu ---------- */
ALTER DATABASE QL_TTNgoaiNgu SET RECOVERY FULL;
GO
DECLARE @Full NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(300))
                            + N'\QL_TTNgoaiNgu_DEMO_Full.bak';
BACKUP DATABASE QL_TTNgoaiNgu
    TO DISK = @Full
    WITH INIT, CHECKSUM, NAME = N'QL_TTNgoaiNgu - Full backup (demo)';
RESTORE VERIFYONLY FROM DISK = @Full WITH CHECKSUM;
PRINT N'BƯỚC 1: đã sao lưu đầy đủ vào ' + @Full;
GO

/* ---------- BƯỚC 2: công việc HỢP LỆ sau full backup ----------
   Thêm một khóa học bằng SP_ThemKhoaHoc_VaNgonNgu. Khóa này phải CÒN sau khi khôi phục. */
DECLARE @MaKH VARCHAR(6), @DaThemNN BIT;
EXEC QL_TTNgoaiNgu.dbo.SP_ThemKhoaHoc_VaNgonNgu
     @MaNN = 'ANH', @TenKhoa = N'Khóa demo khôi phục', @TrinhDo = N'So cap',
     @SoBuoi = 10, @HocPhi = 1000000, @MaKH = @MaKH OUTPUT, @DaThemNgonNgu = @DaThemNN OUTPUT;

INSERT INTO #MocThoiGian (MaKHDemo, SoDiemDanhGoc)
SELECT @MaKH, COUNT(*) FROM QL_TTNgoaiNgu.dbo.DIEMDANH;

-- Ghi mốc an toàn, cách các thao tác trước/sau 2 giây cho rõ ràng
WAITFOR DELAY '00:00:02';
UPDATE #MocThoiGian SET ThoiDiemAnToan = GETDATE();
WAITFOR DELAY '00:00:02';

SELECT MaKHDemo AS KhoaHocVuaThem, SoDiemDanhGoc, ThoiDiemAnToan FROM #MocThoiGian;
GO

/* ---------- BƯỚC 3: SỰ CỐ - xóa nhầm toàn bộ điểm danh (DELETE thiếu WHERE) ---------- */
DELETE FROM QL_TTNgoaiNgu.dbo.DIEMDANH;
SELECT COUNT(*) AS SoDiemDanh_SauSuCo FROM QL_TTNgoaiNgu.dbo.DIEMDANH;   -- = 0
PRINT N'BƯỚC 3: SỰ CỐ - bảng DIEMDANH đã bị xóa sạch.';
GO

/* ---------- BƯỚC 4: sao lưu phần đuôi log (tail-log) ----------
   Cần quyền truy cập độc quyền -> chuyển SINGLE_USER (ngắt các kết nối khác).
   WITH NORECOVERY: CSDL chuyển sang trạng thái Restoring, không ai ghi thêm được nữa. */
ALTER DATABASE QL_TTNgoaiNgu SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DECLARE @Tail NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(300))
                            + N'\QL_TTNgoaiNgu_DEMO_Tail.trn';
BACKUP LOG QL_TTNgoaiNgu
    TO DISK = @Tail
    WITH INIT, CHECKSUM, NORECOVERY, NAME = N'QL_TTNgoaiNgu - Tail-log backup (demo)';
PRINT N'BƯỚC 4: đã sao lưu tail-log vào ' + @Tail;
GO

/* ---------- BƯỚC 5: khôi phục về thời điểm an toàn ---------- */
DECLARE @Full NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(300))
                            + N'\QL_TTNgoaiNgu_DEMO_Full.bak';
DECLARE @Tail NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(300))
                            + N'\QL_TTNgoaiNgu_DEMO_Tail.trn';
DECLARE @StopAt DATETIME = (SELECT ThoiDiemAnToan FROM #MocThoiGian);

RESTORE DATABASE QL_TTNgoaiNgu FROM DISK = @Full WITH NORECOVERY, CHECKSUM;
RESTORE LOG      QL_TTNgoaiNgu FROM DISK = @Tail WITH STOPAT = @StopAt, RECOVERY, CHECKSUM;
ALTER DATABASE QL_TTNgoaiNgu SET MULTI_USER;
PRINT N'BƯỚC 5: đã khôi phục về ' + CONVERT(NVARCHAR(30), @StopAt, 121);
GO

/* ---------- BƯỚC 6: kiểm tra kết quả ---------- */
DECLARE @MaKH VARCHAR(6), @Goc INT, @SauKhoiPhuc INT, @CoKhoa INT;
SELECT @MaKH = MaKHDemo, @Goc = SoDiemDanhGoc FROM #MocThoiGian;
SELECT @SauKhoiPhuc = COUNT(*) FROM QL_TTNgoaiNgu.dbo.DIEMDANH;
SELECT @CoKhoa = COUNT(*) FROM QL_TTNgoaiNgu.dbo.KHOAHOC WHERE MaKH = @MaKH;

SELECT N'Dữ liệu DIEMDANH bị xóa nhầm được lấy lại' AS KiemTra,
       CAST(@Goc AS NVARCHAR(10)) AS MongDoi, CAST(@SauKhoiPhuc AS NVARCHAR(10)) AS ThucTe,
       CASE WHEN @SauKhoiPhuc = @Goc AND @Goc > 0 THEN 'PASS' ELSE 'FAIL' END AS KetQua
UNION ALL
SELECT N'Khóa học thêm hợp lệ sau full backup (' + @MaKH + N') không bị mất',
       N'1', CAST(@CoKhoa AS NVARCHAR(10)),
       CASE WHEN @CoKhoa = 1 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT N'CSDL trở lại ONLINE, nhiều người dùng',
       N'ONLINE / MULTI_USER', state_desc + N' / ' + user_access_desc,
       CASE WHEN state_desc = N'ONLINE' AND user_access_desc = N'MULTI_USER' THEN 'PASS' ELSE 'FAIL' END
FROM sys.databases WHERE name = N'QL_TTNgoaiNgu';

-- Lịch sử sao lưu / khôi phục do SQL Server tự ghi (minh chứng cho báo cáo)
SELECT TOP (3) bs.backup_start_date AS ThoiGian,
       CASE bs.type WHEN 'D' THEN N'Full' WHEN 'L' THEN N'Log' ELSE bs.type END AS Loai,
       bmf.physical_device_name AS TepSaoLuu
FROM msdb.dbo.backupset AS bs
JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = N'QL_TTNgoaiNgu'
ORDER BY bs.backup_start_date DESC;

SELECT TOP (1) restore_date AS ThoiGianKhoiPhuc, stop_at AS KhoiPhucToi
FROM msdb.dbo.restorehistory
WHERE destination_database_name = N'QL_TTNgoaiNgu'
ORDER BY restore_date DESC;
GO

/* ---------- BƯỚC 7: dọn dẹp - xóa khóa học demo để dữ liệu mẫu trở lại như cũ ----------
   (Test_Module_A.sql và Test_Module_B.sql tính số liệu trên dữ liệu mẫu gốc.)
   Các file .bak/.trn vẫn nằm trong thư mục sao lưu; xóa tay nếu không cần.
   Recovery model giữ FULL (đúng cho hệ thống thật). Trên máy thử muốn log không phình to
   thì có thể chạy: ALTER DATABASE QL_TTNgoaiNgu SET RECOVERY SIMPLE; */
DECLARE @MaKH VARCHAR(6) = (SELECT MaKHDemo FROM #MocThoiGian);
DELETE FROM QL_TTNgoaiNgu.dbo.KHOAHOC WHERE MaKH = @MaKH;
DROP TABLE #MocThoiGian;
PRINT N'BƯỚC 7: đã xóa khóa học demo ' + @MaKH + N'. Dữ liệu mẫu trở lại như ban đầu.';
GO