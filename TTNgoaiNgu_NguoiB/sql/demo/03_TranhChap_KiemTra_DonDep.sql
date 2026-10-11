/* =====================================================================
   DEMO TRANH CHAP - KIEM TRA KET QUA VA DON DEP   [Nguyễn Đăng Khoa - 24110255]
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO
SET NOCOUNT ON;
GO

/* ---------- A. KIEM TRA ket qua sau moi phan ----------
   PHAN 1 (khong khoa): DaDangKy = 3 > SiSoToiDa = 2  => SAI (vuot cho)
   PHAN 2 (co khoa)   : DaDangKy = 2 = SiSoToiDa      => DUNG                              */
SELECT l.MaLop, l.SiSoToiDa, COUNT(dk.MaDK) AS DaDangKy,
       CASE WHEN COUNT(dk.MaDK) > l.SiSoToiDa THEN N'VUOT SI SO (sai)' ELSE N'Dung' END AS DanhGia
FROM dbo.LOP AS l
LEFT JOIN dbo.DANGKY AS dk ON dk.MaLop = l.MaLop
WHERE l.MaLop = 'LCC001'
GROUP BY l.MaLop, l.SiSoToiDa;

SELECT dk.MaDK, dk.MaHV, dk.MaLop, hd.MaHD FROM dbo.DANGKY AS dk
LEFT JOIN dbo.HOADON AS hd ON hd.MaDK = dk.MaDK
WHERE dk.MaLop = 'LCC001' ORDER BY dk.MaDK;
GO

/* ---------- A2. (Tuy chon) Quan sat khoa DANG CHAN nhau: chay o cua so THU BA khi PHAN 2 dang treo ---------- */
SELECT r.session_id, r.blocking_session_id, r.wait_type, r.wait_time AS cho_ms,
       DB_NAME(r.database_id) AS CSDL, SUBSTRING(t.text, 1, 120) AS Lenh
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE r.blocking_session_id <> 0;
GO

/* ---------- B. DAT LAI ve 1 hoc vien (HV001) de lam lai PHAN 2 sau PHAN 1 ---------- */
DELETE FROM dbo.HOADON WHERE MaDK IN (SELECT MaDK FROM dbo.DANGKY WHERE MaLop = 'LCC001' AND MaDK <> 'DKC00');
DELETE FROM dbo.DANGKY WHERE MaLop = 'LCC001' AND MaDK <> 'DKC00';
SELECT COUNT(*) AS SoDangKyConLai FROM dbo.DANGKY WHERE MaLop = 'LCC001';   -- mong doi 1
GO

/* ---------- C. DON DEP HOAN TOAN sau khi demo xong ---------- */
-- (Bo dau chu thich ca khoi nay khi muon xoa lop thu nghiem va bat lai trigger)
/*
DELETE FROM dbo.HOADON WHERE MaDK IN (SELECT MaDK FROM dbo.DANGKY WHERE MaLop = 'LCC001');
DELETE FROM dbo.DANGKY WHERE MaLop = 'LCC001';
DELETE FROM dbo.LOP    WHERE MaLop = 'LCC001';
DROP PROCEDURE IF EXISTS dbo.SP_DEMO_DangKy_KhongKhoa;
ENABLE TRIGGER dbo.TRG_DANGKY_SiSo ON dbo.DANGKY;
SELECT name, is_disabled FROM sys.triggers WHERE name = N'TRG_DANGKY_SiSo';   -- is_disabled phai = 0
*/
GO
