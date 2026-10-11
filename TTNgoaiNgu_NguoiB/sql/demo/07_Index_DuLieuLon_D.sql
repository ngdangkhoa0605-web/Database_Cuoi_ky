/* =====================================================================
   DEMO INDEX CỦA THÀNH VIÊN D (IX_BUOIHOC_MaLop_Ngay, IX_DIEMDANH_MaDK)
   Mục tiêu: chứng minh bằng số liệu (STATISTICS IO / TIME + execution plan) rằng index làm
   truy vấn nhanh hơn trên DỮ LIỆU LỚN.

   An toàn: script KHÔNG đụng vào bảng thật. Nó tạo 2 bảng tạm DEMO_D_BUOIHOC (100.000 dòng),
   DEMO_D_DIEMDANH (1.000.000 dòng) có cấu trúc tương đương (chỉ có khóa chính), đo truy vấn
   TRƯỚC khi có index, tạo index, đo lại SAU khi có index, rồi xóa bảng tạm ở bước cuối.
   Chạy lại nhiều lần được. Mất khoảng 1 đến 2 phút ở bước nạp dữ liệu.

   CÁCH CHẠY ĐỂ CHỤP ẢNH CHO BÁO CÁO:
     1) Bật Include Actual Execution Plan (Ctrl+M) trước khi chạy.
     2) Chạy từng BƯỚC (bôi đen đoạn lệnh -> F5): xem tab Messages (logical reads, CPU/elapsed time)
        và tab Execution Plan (Scan trước, Seek sau).
     3) Có thể chạy cả file một lần: tab Messages vẫn giữ số liệu dù bảng tạm bị xóa ở BƯỚC 7.
   Số logical reads ổn định giữa các lần chạy; thời gian (ms) tùy máy.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* ---------- BƯỚC 0: dọn dẹp (nếu lần chạy trước bỏ dở) ---------- */
IF OBJECT_ID(N'dbo.DEMO_D_DIEMDANH', N'U') IS NOT NULL DROP TABLE dbo.DEMO_D_DIEMDANH;
IF OBJECT_ID(N'dbo.DEMO_D_BUOIHOC',  N'U') IS NOT NULL DROP TABLE dbo.DEMO_D_BUOIHOC;
GO

/* ---------- BƯỚC 1: tạo bảng tạm, MỖI BẢNG CHỈ CÓ KHÓA CHÍNH (giống lúc chưa tạo index) ---------- */
CREATE TABLE dbo.DEMO_D_BUOIHOC
(
    MaBuoi            VARCHAR(8)   NOT NULL CONSTRAINT PK_DEMO_D_BUOIHOC PRIMARY KEY,
    MaLop             VARCHAR(6)   NOT NULL,
    MaGV_Day          CHAR(4)      NOT NULL,
    NgayHocThucTe     DATE         NOT NULL,
    TrangThaiBuoiHoc  NVARCHAR(20) NOT NULL
);
CREATE TABLE dbo.DEMO_D_DIEMDANH
(
    MaBuoi             VARCHAR(8)   NOT NULL,
    MaDK               VARCHAR(8)   NOT NULL,
    TrangThaiDiemDanh  NVARCHAR(20) NOT NULL,
    GhiChu             NVARCHAR(100) NULL,
    CONSTRAINT PK_DEMO_D_DIEMDANH PRIMARY KEY (MaBuoi, MaDK)   -- giống PK_DIEMDANH: không hỗ trợ tìm theo MaDK
);
GO

/* ---------- BƯỚC 2: nạp dữ liệu ----------
   100.000 buổi học của 50 lớp (mỗi lớp 2.000 buổi, rải trên 1.825 ngày từ 2021-01-01).
   1.000.000 dòng điểm danh: mỗi buổi 10 đăng ký trong 5.000 đăng ký (mỗi đăng ký khoảng 200 lượt). */
;WITH N AS (SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO dbo.DEMO_D_BUOIHOC (MaBuoi, MaLop, MaGV_Day, NgayHocThucTe, TrangThaiBuoiHoc)
SELECT 'B' + RIGHT('0000000' + CAST(n AS VARCHAR(7)), 7),
       'LOP' + RIGHT('000' + CAST(n % 50 + 1 AS VARCHAR(3)), 3),
       'GV' + RIGHT('00' + CAST(n % 6 + 1 AS VARCHAR(2)), 2),
       DATEADD(DAY, (n / 50) % 1825, CAST('2021-01-01' AS DATE)),
       N'Đã diễn ra'
FROM N;

;WITH J AS (SELECT j FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS v(j))
INSERT INTO dbo.DEMO_D_DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh, GhiChu)
SELECT b.MaBuoi,
       'DK' + RIGHT('000000' + CAST(((x.n * 7 + J.j * 131) % 5000) + 1 AS VARCHAR(6)), 6),
       CASE (x.n + J.j) % 10 WHEN 8 THEN N'Vắng có phép' WHEN 9 THEN N'Vắng không phép' ELSE N'Có mặt' END,
       NULL
FROM (SELECT MaBuoi, CAST(SUBSTRING(MaBuoi, 2, 7) AS INT) AS n FROM dbo.DEMO_D_BUOIHOC) AS x
JOIN dbo.DEMO_D_BUOIHOC AS b ON b.MaBuoi = x.MaBuoi
CROSS JOIN J;

SELECT 'DEMO_D_BUOIHOC' AS Bang, COUNT(*) AS SoDong FROM dbo.DEMO_D_BUOIHOC
UNION ALL SELECT 'DEMO_D_DIEMDANH', COUNT(*) FROM dbo.DEMO_D_DIEMDANH;
GO

/* ---------- BƯỚC 3: đo TRƯỚC khi có index (chụp ảnh Messages + Execution Plan) ---------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Q1: buổi học của một lớp trong một tháng.
--     Kỳ vọng TRƯỚC: Clustered Index Scan trên PK (đọc cả 100.000 dòng)
SELECT MaBuoi, NgayHocThucTe, MaGV_Day, TrangThaiBuoiHoc
FROM dbo.DEMO_D_BUOIHOC
WHERE MaLop = 'LOP007' AND NgayHocThucTe BETWEEN '2023-03-01' AND '2023-03-31';

-- Q2: lịch sử điểm danh của một đăng ký.
--     Kỳ vọng TRƯỚC: Clustered Index Scan trên PK (đọc cả 1.000.000 dòng)
SELECT MaBuoi, TrangThaiDiemDanh
FROM dbo.DEMO_D_DIEMDANH
WHERE MaDK = 'DK000123';

-- Q3: đúng truy vấn nằm trong FN_TyLeChuyenCan (đếm lượt có mặt / tổng lượt của một đăng ký).
SELECT COUNT(*) AS TongLuot, COUNT(CASE WHEN TrangThaiDiemDanh = N'Có mặt' THEN 1 END) AS SoCoMat
FROM dbo.DEMO_D_DIEMDANH
WHERE MaDK = 'DK000123';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------- BƯỚC 4: tạo đúng 2 index của module D (cùng định nghĩa với index thật) ---------- */
CREATE NONCLUSTERED INDEX IX_DEMO_D_BUOIHOC_MaLop_Ngay
    ON dbo.DEMO_D_BUOIHOC (MaLop, NgayHocThucTe) INCLUDE (MaGV_Day, TrangThaiBuoiHoc);
CREATE NONCLUSTERED INDEX IX_DEMO_D_DIEMDANH_MaDK
    ON dbo.DEMO_D_DIEMDANH (MaDK) INCLUDE (TrangThaiDiemDanh);
UPDATE STATISTICS dbo.DEMO_D_BUOIHOC;
UPDATE STATISTICS dbo.DEMO_D_DIEMDANH;
GO

/* ---------- BƯỚC 5: đo SAU khi có index (chụp ảnh Messages + Execution Plan) ---------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Q1 - Kỳ vọng SAU: Index Seek trên IX_DEMO_D_BUOIHOC_MaLop_Ngay, không Key Lookup (INCLUDE đủ cột)
SELECT MaBuoi, NgayHocThucTe, MaGV_Day, TrangThaiBuoiHoc
FROM dbo.DEMO_D_BUOIHOC
WHERE MaLop = 'LOP007' AND NgayHocThucTe BETWEEN '2023-03-01' AND '2023-03-31';

-- Q2 - Kỳ vọng SAU: Index Seek trên IX_DEMO_D_DIEMDANH_MaDK
SELECT MaBuoi, TrangThaiDiemDanh
FROM dbo.DEMO_D_DIEMDANH
WHERE MaDK = 'DK000123';

-- Q3 - Kỳ vọng SAU: Index Seek, logical reads giảm từ hàng nghìn xuống vài trang
SELECT COUNT(*) AS TongLuot, COUNT(CASE WHEN TrangThaiDiemDanh = N'Có mặt' THEN 1 END) AS SoCoMat
FROM dbo.DEMO_D_DIEMDANH
WHERE MaDK = 'DK000123';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------- BƯỚC 6: chi phí của index (ghi vào phần nhận xét của báo cáo) ---------- */
SELECT OBJECT_NAME(i.object_id) AS Bang, i.name AS TenIndex,
       CAST(SUM(s.used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS DungLuongMB
FROM sys.indexes AS i
JOIN sys.dm_db_partition_stats AS s ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE i.object_id IN (OBJECT_ID(N'dbo.DEMO_D_BUOIHOC'), OBJECT_ID(N'dbo.DEMO_D_DIEMDANH'))
GROUP BY i.object_id, i.name
ORDER BY Bang, TenIndex;
GO

/* ---------- BƯỚC 7: xóa bảng tạm (chạy cuối cùng, sau khi đã chụp ảnh) ---------- */
IF OBJECT_ID(N'dbo.DEMO_D_DIEMDANH', N'U') IS NOT NULL DROP TABLE dbo.DEMO_D_DIEMDANH;
IF OBJECT_ID(N'dbo.DEMO_D_BUOIHOC',  N'U') IS NOT NULL DROP TABLE dbo.DEMO_D_BUOIHOC;
GO
