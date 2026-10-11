/* =====================================================================
   DEMO INDEX - Kiên (24110262): IX_KHOAHOC_MaNN_TrangThai, IX_KHOAHOC_HocPhi
   Mục tiêu: chứng minh bằng số liệu (STATISTICS IO / TIME + execution plan) rằng hai
   index của Module A làm truy vấn nhanh hơn trên DỮ LIỆU LỚN, và giải thích vì sao
   KHÔNG chọn index trên TenKhoa.

   AN TOÀN: KHÔNG đụng vào bảng thật. Script tạo bảng tạm DEMO_A_KHOAHOC (300.000 dòng)
   có cấu trúc giống KHOAHOC, đo TRƯỚC khi có index, tạo index, đo lại SAU, rồi xóa bảng
   tạm ở bước cuối. Chạy lại nhiều lần được. (Cùng cách làm với 01_Index_DuLieuLon_B.sql.)
   Bảng KHOAHOC thật chỉ có 5 dòng nên không thể hiện được khác biệt.

   CÁCH CHẠY ĐỂ CHỤP ẢNH CHO BÁO CÁO:
     1) Bật Include Actual Execution Plan (Ctrl+M) trước khi chạy.
     2) Chạy từng BƯỚC (bôi đen đoạn lệnh -> F5). Xem tab Messages (logical reads,
        CPU/elapsed time) và tab Execution Plan (Scan trước, Seek sau).
     3) Có thể chạy cả file một lần; tab Messages vẫn giữ số liệu dù bảng tạm bị xóa.
   Số đọc logic (logical reads) ổn định giữa các máy; thời gian (ms) tùy máy.

   KẾT QUẢ MONG ĐỢI:
     Truy vấn 1 (lọc MaNN + TrangThai) : Clustered Index Scan -> Index Seek trên IX_DEMO_A_MaNN_TrangThai
     Truy vấn 2 (khoảng HocPhi)        : Clustered Index Scan -> Index Seek trên IX_DEMO_A_HocPhi
     Truy vấn 3 (giống SP_TimKiemKhoaHoc, OR ... IS NULL + RECOMPILE): cũng chuyển sang Seek
     BƯỚC 6: index trên TenKhoa CHỈ seek được với tìm theo phần đầu ('abc%'),
             tìm chứa ('%abc%' - cách SP_TimKiemKhoaHoc tìm tên) vẫn phải Scan.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* ---------- BƯỚC 0: dọn dẹp (nếu lần chạy trước bỏ dở) ---------- */
IF OBJECT_ID(N'dbo.DEMO_A_KHOAHOC', N'U') IS NOT NULL DROP TABLE dbo.DEMO_A_KHOAHOC;
GO

/* ---------- BƯỚC 1: tạo bảng tạm, CHỈ CÓ KHÓA CHÍNH (giống lúc chưa tạo index) ---------- */
CREATE TABLE dbo.DEMO_A_KHOAHOC
(
    MaKH      INT           NOT NULL CONSTRAINT PK_DEMO_A_KHOAHOC PRIMARY KEY,
    TenKhoa   NVARCHAR(50)  NOT NULL,
    MaNN      CHAR(3)       NOT NULL,
    TrinhDo   NVARCHAR(10)  NOT NULL,
    SoBuoi    TINYINT       NOT NULL,
    HocPhi    MONEY         NOT NULL,
    TrangThai NVARCHAR(20)  NOT NULL
);
GO

/* ---------- BƯỚC 2: sinh 300.000 khóa học ----------
   - 100 ngôn ngữ (L00 .. L99)  -> mỗi ngôn ngữ ~3.000 khóa (1%)
   - 80% 'Đang giảng dạy', 20% 'Ngừng tuyển sinh'
   - Học phí 1.000.000 .. 10.000.000, bước 10.000 (901 mức) */
;WITH N AS
(
    SELECT TOP (300000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b CROSS JOIN sys.all_objects AS c
)
INSERT INTO dbo.DEMO_A_KHOAHOC (MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai)
SELECT n,
       CHOOSE(n % 8 + 1, N'Anh giao tiếp', N'Luyện thi TOEIC', N'Luyện thi IELTS', N'Tiếng Nhật N5',
                         N'Tiếng Hàn sơ cấp', N'Tiếng Trung HSK', N'Tiếng Pháp A1', N'Tiếng Đức A1')
         + N' ' + CAST(n AS NVARCHAR(10)),
       'L' + RIGHT('0' + CAST(n % 100 AS VARCHAR(3)), 2),
       CHOOSE(n % 3 + 1, N'So cap', N'Trung cap', N'Cao cap'),
       CAST(12 + n % 37 AS TINYINT),
       1000000 + (n % 901) * 10000,
       CASE WHEN n % 5 = 0 THEN N'Ngừng tuyển sinh' ELSE N'Đang giảng dạy' END
FROM N;

SELECT COUNT(*) AS SoKhoaHoc FROM dbo.DEMO_A_KHOAHOC;
GO

/* =====================================================================
   BƯỚC 3: ĐO TRƯỚC KHI CÓ INDEX
   ===================================================================== */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
-- CHECKPOINT; DBCC DROPCLEANBUFFERS;   -- (tùy chọn, cần sysadmin, chỉ dùng trên máy thử) để đo đọc đĩa thật

PRINT N'===== TRƯỚC INDEX - Truy vấn 1: khóa đang giảng dạy của ngôn ngữ L42 (giống FN_DSKhoaHoc_TheoNN) =====';
SELECT MaKH, TenKhoa, TrinhDo, SoBuoi, HocPhi
FROM dbo.DEMO_A_KHOAHOC
WHERE MaNN = 'L42' AND TrangThai = N'Đang giảng dạy';

PRINT N'===== TRƯỚC INDEX - Truy vấn 2: khóa có học phí 3.000.000 - 3.050.000 =====';
SELECT MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai
FROM dbo.DEMO_A_KHOAHOC
WHERE HocPhi BETWEEN 3000000 AND 3050000
ORDER BY HocPhi, MaKH;

PRINT N'===== TRƯỚC INDEX - Truy vấn 3: cùng điều kiện, viết như SP_TimKiemKhoaHoc =====';
DECLARE @MaNN CHAR(3) = NULL, @TrangThai NVARCHAR(20) = NULL,
        @HocPhiMin MONEY = 3000000, @HocPhiMax MONEY = 3050000;
SELECT MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai
FROM dbo.DEMO_A_KHOAHOC
WHERE (@MaNN      IS NULL OR MaNN = @MaNN)
  AND (@TrangThai IS NULL OR TrangThai = @TrangThai)
  AND (@HocPhiMin IS NULL OR HocPhi >= @HocPhiMin)
  AND (@HocPhiMax IS NULL OR HocPhi <= @HocPhiMax)
ORDER BY HocPhi, MaKH
OPTION (RECOMPILE);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* =====================================================================
   BƯỚC 4: TẠO INDEX (cùng định nghĩa với IX_KHOAHOC_MaNN_TrangThai, IX_KHOAHOC_HocPhi)
   ===================================================================== */
CREATE NONCLUSTERED INDEX IX_DEMO_A_MaNN_TrangThai
    ON dbo.DEMO_A_KHOAHOC (MaNN, TrangThai)
    INCLUDE (TenKhoa, TrinhDo, SoBuoi, HocPhi);

CREATE NONCLUSTERED INDEX IX_DEMO_A_HocPhi
    ON dbo.DEMO_A_KHOAHOC (HocPhi)
    INCLUDE (TenKhoa, MaNN, TrinhDo, SoBuoi, TrangThai);
GO

/* =====================================================================
   BƯỚC 5: ĐO SAU KHI CÓ INDEX (cùng các truy vấn như BƯỚC 3)
   Mong đợi: Clustered Index Scan (đọc hết bảng) -> Index Seek (chỉ đọc vài chục trang),
   không có Key Lookup vì INCLUDE đã đủ cột.
   ===================================================================== */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT N'===== SAU INDEX - Truy vấn 1: khóa đang giảng dạy của ngôn ngữ L42 =====';
SELECT MaKH, TenKhoa, TrinhDo, SoBuoi, HocPhi
FROM dbo.DEMO_A_KHOAHOC
WHERE MaNN = 'L42' AND TrangThai = N'Đang giảng dạy';

PRINT N'===== SAU INDEX - Truy vấn 2: khóa có học phí 3.000.000 - 3.050.000 =====';
SELECT MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai
FROM dbo.DEMO_A_KHOAHOC
WHERE HocPhi BETWEEN 3000000 AND 3050000
ORDER BY HocPhi, MaKH;

PRINT N'===== SAU INDEX - Truy vấn 3: cùng điều kiện, viết như SP_TimKiemKhoaHoc =====';
DECLARE @MaNN CHAR(3) = NULL, @TrangThai NVARCHAR(20) = NULL,
        @HocPhiMin MONEY = 3000000, @HocPhiMax MONEY = 3050000;
SELECT MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai
FROM dbo.DEMO_A_KHOAHOC
WHERE (@MaNN      IS NULL OR MaNN = @MaNN)
  AND (@TrangThai IS NULL OR TrangThai = @TrangThai)
  AND (@HocPhiMin IS NULL OR HocPhi >= @HocPhiMin)
  AND (@HocPhiMax IS NULL OR HocPhi <= @HocPhiMax)
ORDER BY HocPhi, MaKH
OPTION (RECOMPILE);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* =====================================================================
   BƯỚC 6: VÌ SAO KHÔNG CHỌN INDEX TRÊN TenKhoa
   Tạo thử index trên TenKhoa rồi so sánh hai kiểu tìm:
     6a. Tìm theo phần đầu  LIKE N'Luyện thi TOEIC 12%' -> Index Seek (index có tác dụng)
     6b. Tìm chứa           LIKE N'%TOEIC 12%'          -> Index Scan (vẫn đọc toàn bộ index)
   SP_TimKiemKhoaHoc tìm tên theo kiểu 6b (người dùng gõ một từ bất kỳ trong tên), nên index
   trên TenKhoa gần như không giúp được -> thay bằng IX_KHOAHOC_HocPhi.
   ===================================================================== */
CREATE NONCLUSTERED INDEX IX_DEMO_A_TenKhoa ON dbo.DEMO_A_KHOAHOC (TenKhoa);
GO
SET STATISTICS IO ON;

PRINT N'===== 6a - Tìm theo PHẦN ĐẦU của tên (có thể Seek) =====';
SELECT MaKH, TenKhoa FROM dbo.DEMO_A_KHOAHOC WHERE TenKhoa LIKE N'Luyện thi TOEIC 12%';

PRINT N'===== 6b - Tìm CHỨA một từ trong tên (không Seek được) =====';
SELECT MaKH, TenKhoa FROM dbo.DEMO_A_KHOAHOC WHERE TenKhoa LIKE N'%TOEIC 12%';

SET STATISTICS IO OFF;
GO

/* ---------- Kích thước index (cho phần "đánh đổi: index tốn dung lượng") ---------- */
SELECT i.name AS TenIndex, i.type_desc AS Loai,
       CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(10, 2)) AS DungLuong_MB
FROM sys.indexes AS i
JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.object_id = OBJECT_ID(N'dbo.DEMO_A_KHOAHOC')
GROUP BY i.name, i.type_desc
ORDER BY TenIndex;
GO

/* ---------- BƯỚC 7: dọn bảng tạm ---------- */
IF OBJECT_ID(N'dbo.DEMO_A_KHOAHOC', N'U') IS NOT NULL DROP TABLE dbo.DEMO_A_KHOAHOC;
PRINT N'Đã xóa bảng tạm DEMO_A_KHOAHOC. Bảng thật không bị ảnh hưởng.';
GO