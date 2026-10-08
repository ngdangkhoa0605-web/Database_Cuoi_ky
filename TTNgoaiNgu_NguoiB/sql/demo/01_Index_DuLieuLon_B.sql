/* =====================================================================
   DEMO INDEX CUA NGUYỄN ĐĂNG KHOA (24110255)  (IX_DANGKY_MaLop, IX_HOCVIEN_HoTen)
   Muc tieu: chung minh bang so lieu (STATISTICS IO / TIME + execution plan) index lam
   truy van nhanh hon tren DU LIEU LON.

   An toan: script KHONG dung vao bang that. No tao 2 bang tam DEMO_B_HOCVIEN (200.000 dong),
   DEMO_B_DANGKY (500.000 dong) co cau truc tuong duong, do truy van TRUOC khi co index,
   tao index, do lai SAU khi co index, roi xoa bang tam o buoc cuoi. Chay lai nhieu lan duoc.

   CACH CHAY DE CHUP ANH CHO BAO CAO:
     1) Bat Include Actual Execution Plan (Ctrl+M) truoc khi chay.
     2) Chay tung BUOC (boi den doan lenh -> F5): xem tab Messages (logical reads, CPU/elapsed time)
        va tab Execution Plan (Scan truoc, Seek sau).
     3) Co the chay ca file mot lan: tab Messages van giu so lieu du bang tam da bi xoa o BUOC 7.
   Du lieu tinh theo so doc logic (logical reads) la on dinh; thoi gian (ms) tuy may.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* ---------- BUOC 0: don dep (neu lan chay truoc bo do) ---------- */
IF OBJECT_ID(N'dbo.DEMO_B_DANGKY', N'U')  IS NOT NULL DROP TABLE dbo.DEMO_B_DANGKY;
IF OBJECT_ID(N'dbo.DEMO_B_HOCVIEN', N'U') IS NOT NULL DROP TABLE dbo.DEMO_B_HOCVIEN;
GO

/* ---------- BUOC 1: tao bang tam, MOI BANG CHI CO KHOA CHINH (giong luc chua tao index) ---------- */
CREATE TABLE dbo.DEMO_B_HOCVIEN
(
    MaHV     INT           NOT NULL CONSTRAINT PK_DEMO_B_HOCVIEN PRIMARY KEY,
    HoTen    NVARCHAR(40)  NOT NULL,
    NgaySinh DATE          NOT NULL,
    SDT      VARCHAR(15)   NOT NULL,
    Email    VARCHAR(50)   NOT NULL,
    DiaChi   NVARCHAR(100) NOT NULL
);
CREATE TABLE dbo.DEMO_B_DANGKY
(
    MaDK       INT          NOT NULL CONSTRAINT PK_DEMO_B_DANGKY PRIMARY KEY,
    MaHV       INT          NOT NULL,
    MaLop      INT          NOT NULL,
    NgayDangKy DATE         NOT NULL,
    DiemCuoiKy NUMERIC(4,2) NULL
);
-- Bang DANGKY that co UNIQUE (MaHV, MaLop): chi tim nhanh theo MaHV, KHONG ho tro tim theo MaLop.
-- Tao index tuong duong de mo phong dung tinh huong do.
CREATE NONCLUSTERED INDEX IX_DEMO_B_DANGKY_MaHV_MaLop ON dbo.DEMO_B_DANGKY (MaHV, MaLop);
GO

/* ---------- BUOC 2: sinh du lieu lon ---------- */
;WITH N AS
(
    SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b CROSS JOIN sys.all_objects AS c
)
INSERT INTO dbo.DEMO_B_HOCVIEN (MaHV, HoTen, NgaySinh, SDT, Email, DiaChi)
SELECT n,
       CHOOSE(n % 8 + 1, N'Nguyễn', N'Trần', N'Lê', N'Phạm', N'Hoàng', N'Võ', N'Đặng', N'Bùi')
         + N' ' + CHOOSE(n / 8 % 2 + 1, N'Văn', N'Thị')
         + N' ' + CHOOSE(n / 16 % 10 + 1, N'An', N'Bình', N'Chi', N'Dũng', N'Hà', N'Lan', N'Minh', N'Nam', N'Phúc', N'Quân')
         + N' ' + CAST(n AS NVARCHAR(10)),
       DATEADD(DAY, n % 9000, CAST('1985-01-01' AS DATE)),
       '09' + RIGHT('00000000' + CAST(n AS VARCHAR(10)), 8),
       'hv' + CAST(n AS VARCHAR(10)) + '@demo.com',
       N'Địa chỉ số ' + CAST(n AS NVARCHAR(10))
FROM N;

;WITH N AS
(
    SELECT TOP (500000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b CROSS JOIN sys.all_objects AS c
)
INSERT INTO dbo.DEMO_B_DANGKY (MaDK, MaHV, MaLop, NgayDangKy, DiemCuoiKy)
SELECT n,
       n % 200000 + 1,
       n % 2000 + 1,
       DATEADD(DAY, n % 365, CAST('2025-01-01' AS DATE)),
       CASE WHEN n % 5 = 0 THEN CAST((n % 101) / 10.0 AS NUMERIC(4,2)) END
FROM N;

SELECT (SELECT COUNT(*) FROM dbo.DEMO_B_HOCVIEN) AS SoHocVien,
       (SELECT COUNT(*) FROM dbo.DEMO_B_DANGKY)  AS SoDangKy;
GO

/* ---------- BUOC 3: chon gia tri tim kiem (chay chung voi cac BUOC 4 va 6) ---------- */
-- Ten day du cua hoc vien so 123456 va mot tien to cua ten do (khop vai chuc dong)
DECLARE @Ten NVARCHAR(40) = (SELECT HoTen FROM dbo.DEMO_B_HOCVIEN WHERE MaHV = 123456);
SELECT @Ten AS TenCanTim, SUBSTRING(@Ten, 1, LEN(@Ten) - 2) + N'%' AS MauTienTo;
GO

/* =====================================================================
   BUOC 4: DO TRUOC KHI CO INDEX
   Truy van 1: dem / liet ke hoc vien cua mot lop (giong TRG_DANGKY_SiSo, V_CONGNO_HocPhi)
   Truy van 2: tim hoc vien theo ho ten day du (giong SP_TimKiemHocVien khop chinh xac)
   Truy van 3: tim hoc vien theo phan dau cua ten
   ===================================================================== */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
-- CHECKPOINT; DBCC DROPCLEANBUFFERS;   -- (tuy chon, can quyen sysadmin, chi nen dung tren may thu nghiem) de do doc dia that

PRINT N'===== TRUOC INDEX - Truy van 1: so hoc vien cua lop 1234 =====';
SELECT COUNT(*) AS SiSo FROM dbo.DEMO_B_DANGKY WHERE MaLop = 1234;

PRINT N'===== TRUOC INDEX - Truy van 1b: danh sach hoc vien cua lop 1234 =====';
SELECT MaDK, MaHV FROM dbo.DEMO_B_DANGKY WHERE MaLop = 1234;

DECLARE @Ten NVARCHAR(40) = (SELECT HoTen FROM dbo.DEMO_B_HOCVIEN WHERE MaHV = 123456);
PRINT N'===== TRUOC INDEX - Truy van 2: tim theo ho ten day du =====';
SELECT MaHV, HoTen, SDT, Email FROM dbo.DEMO_B_HOCVIEN WHERE HoTen = @Ten OPTION (RECOMPILE);

DECLARE @Mau NVARCHAR(50) = (SELECT SUBSTRING(HoTen, 1, LEN(HoTen) - 2) + N'%' FROM dbo.DEMO_B_HOCVIEN WHERE MaHV = 123456);
PRINT N'===== TRUOC INDEX - Truy van 3: tim theo tien to cua ten =====';
SELECT MaHV, HoTen FROM dbo.DEMO_B_HOCVIEN WHERE HoTen LIKE @Mau OPTION (RECOMPILE);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* =====================================================================
   BUOC 5: TAO INDEX (cung dinh nghia voi IX_DANGKY_MaLop, IX_HOCVIEN_HoTen cua module B)
   ===================================================================== */
CREATE NONCLUSTERED INDEX IX_DEMO_B_DANGKY_MaLop ON dbo.DEMO_B_DANGKY (MaLop) INCLUDE (MaHV);
CREATE NONCLUSTERED INDEX IX_DEMO_B_HOCVIEN_HoTen ON dbo.DEMO_B_HOCVIEN (HoTen);
GO

/* =====================================================================
   BUOC 6: DO SAU KHI CO INDEX (cung cac truy van nhu BUOC 4)
   Mong doi: Truy van 1/1b tu "Index Scan" (doc het hang tram trang) thanh "Index Seek" (vai trang);
             Truy van 2/3 tu "Clustered Index Scan" thanh "Index Seek" (+ Key Lookup so dong rat it).
   ===================================================================== */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT N'===== SAU INDEX - Truy van 1: so hoc vien cua lop 1234 =====';
SELECT COUNT(*) AS SiSo FROM dbo.DEMO_B_DANGKY WHERE MaLop = 1234;

PRINT N'===== SAU INDEX - Truy van 1b: danh sach hoc vien cua lop 1234 =====';
SELECT MaDK, MaHV FROM dbo.DEMO_B_DANGKY WHERE MaLop = 1234;

DECLARE @Ten NVARCHAR(40) = (SELECT HoTen FROM dbo.DEMO_B_HOCVIEN WHERE MaHV = 123456);
PRINT N'===== SAU INDEX - Truy van 2: tim theo ho ten day du =====';
SELECT MaHV, HoTen, SDT, Email FROM dbo.DEMO_B_HOCVIEN WHERE HoTen = @Ten OPTION (RECOMPILE);

DECLARE @Mau NVARCHAR(50) = (SELECT SUBSTRING(HoTen, 1, LEN(HoTen) - 2) + N'%' FROM dbo.DEMO_B_HOCVIEN WHERE MaHV = 123456);
PRINT N'===== SAU INDEX - Truy van 3: tim theo tien to cua ten =====';
SELECT MaHV, HoTen FROM dbo.DEMO_B_HOCVIEN WHERE HoTen LIKE @Mau OPTION (RECOMPILE);

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------- Kich thuoc index (de dua vao phan "danh doi: index ton dung luong") ---------- */
SELECT OBJECT_NAME(i.object_id) AS Bang, i.name AS TenIndex, i.type_desc AS Loai,
       CAST(SUM(ps.used_page_count) * 8 / 1024.0 AS DECIMAL(10,2)) AS DungLuong_MB
FROM sys.indexes AS i
JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.object_id IN (OBJECT_ID(N'dbo.DEMO_B_HOCVIEN'), OBJECT_ID(N'dbo.DEMO_B_DANGKY'))
GROUP BY i.object_id, i.name, i.type_desc
ORDER BY Bang, TenIndex;
GO

/* ---------- BUOC 7: don dep bang tam ---------- */
IF OBJECT_ID(N'dbo.DEMO_B_DANGKY', N'U')  IS NOT NULL DROP TABLE dbo.DEMO_B_DANGKY;
IF OBJECT_ID(N'dbo.DEMO_B_HOCVIEN', N'U') IS NOT NULL DROP TABLE dbo.DEMO_B_HOCVIEN;
PRINT N'Da xoa bang tam DEMO_B_*. Bang that khong bi anh huong.';
GO
