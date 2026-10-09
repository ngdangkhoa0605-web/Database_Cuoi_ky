/* =====================================================================
   KIỂM THỬ MODULE A - Kiên (24110262)
   Chạy SAU Module_A_KhoaHoc.sql, trên dữ liệu mẫu DataQLTTNgoaiNgu.sql.
   - Mỗi ca chạy trong giao dịch riêng và ROLLBACK -> KHÔNG làm đổi dữ liệu mẫu
     (ngoại lệ có chủ đích: A12 đổi học phí KH0005 rồi đổi lại, kết quả cuối không đổi).
   - Kết quả: bảng PASS/FAIL ở cuối. Mong đợi: SoCaFAIL = 0.
   - Số liệu mong đợi tính tay từ DataQLTTNgoaiNgu.sql (xem chú thích từng ca).
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
    MoTa    NVARCHAR(150) NOT NULL,
    KetQua  VARCHAR(4)    NOT NULL,
    ChiTiet NVARCHAR(400) NULL
);

DECLARE @n INT, @n2 INT, @tien MONEY, @tien2 MONEY,
        @ma VARCHAR(6), @bit BIT, @tt NVARCHAR(30), @ok BIT;

/* ---------- A01: hai index tồn tại ---------- */
SELECT @n = COUNT(*) FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.KHOAHOC')
  AND name IN (N'IX_KHOAHOC_MaNN_TrangThai', N'IX_KHOAHOC_HocPhi');
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A01', N'Có đủ 2 index IX_KHOAHOC_MaNN_TrangThai, IX_KHOAHOC_HocPhi',
        CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số index = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- A02: FN_SoHocVien_KhoaHoc ----------
   KH0001: LOP001 (HV001-003) + LOP005 (HV009, HV010) = 5 | KH0002 = 2 | KH0005 (không lớp) = 0 | KH9999 = NULL */
SET @ok = CASE WHEN dbo.FN_SoHocVien_KhoaHoc('KH0001') = 5
                AND dbo.FN_SoHocVien_KhoaHoc('KH0002') = 2
                AND dbo.FN_SoHocVien_KhoaHoc('KH0005') = 0
                AND dbo.FN_SoHocVien_KhoaHoc('KH9999') IS NULL THEN 1 ELSE 0 END;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A02', N'FN_SoHocVien_KhoaHoc: KH0001=5, KH0002=2, KH0005=0, KH9999=NULL',
        CASE WHEN @ok = 1 THEN 'PASS' ELSE 'FAIL' END,
        N'KH0001=' + ISNULL(CAST(dbo.FN_SoHocVien_KhoaHoc('KH0001') AS NVARCHAR(10)), N'NULL'));

/* ---------- A03: FN_DSKhoaHoc_TheoNN ----------
   ANH: KH0001, KH0002 (đang giảng dạy) = 2 | TRU: KH0005 ngừng tuyển sinh -> 0 */
SELECT @n  = COUNT(*) FROM dbo.FN_DSKhoaHoc_TheoNN('ANH');
SELECT @n2 = COUNT(*) FROM dbo.FN_DSKhoaHoc_TheoNN('TRU');
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A03', N'FN_DSKhoaHoc_TheoNN: ANH = 2 dòng, TRU = 0 dòng',
        CASE WHEN @n = 2 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END,
        N'ANH=' + CAST(@n AS NVARCHAR(10)) + N'; TRU=' + CAST(@n2 AS NVARCHAR(10)));

/* ---------- A04: V_KHOAHOC_ThongKe ----------
   5 khóa; KH0001: 2 lớp (LOP001 đang học, LOP005 đã kết thúc) -> SoLopDangMo = 1, 5 học viên; KH0005: 0 lớp */
SELECT @n = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe;
SELECT @n2 = COUNT(*) FROM dbo.V_KHOAHOC_ThongKe
WHERE (MaKH = 'KH0001' AND SoLop = 2 AND SoLopDangMo = 1 AND SoHocVien = 5)
   OR (MaKH = 'KH0005' AND SoLop = 0 AND SoLopDangMo = 0 AND SoHocVien = 0);
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A04', N'V_KHOAHOC_ThongKe: 5 dòng; KH0001 2 lớp/1 đang mở/5 HV; KH0005 0 lớp',
        CASE WHEN @n = 5 AND @n2 = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- A05: V_THONGKE_NgonNgu ----------
   4 ngôn ngữ; ANH: 2 khóa, 3 lớp (LOP001, LOP002, LOP005), 3 GV, 2 GV đang công tác (GV06 tạm nghỉ)
   TRU: 1 khóa, 0 khóa đang giảng dạy */
SELECT @n = COUNT(*) FROM dbo.V_THONGKE_NgonNgu;
SELECT @n2 = COUNT(*) FROM dbo.V_THONGKE_NgonNgu
WHERE (MaNN = 'ANH' AND SoKhoaHoc = 2 AND SoKhoaDangGiangDay = 2 AND SoLop = 3 AND SoGiangVien = 3 AND SoGVDangCongTac = 2)
   OR (MaNN = 'TRU' AND SoKhoaHoc = 1 AND SoKhoaDangGiangDay = 0);
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A05', N'V_THONGKE_NgonNgu: 4 dòng; ANH 2 khóa/3 lớp/3 GV/2 đang công tác',
        CASE WHEN @n = 4 AND @n2 = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- A06: SP_TimKiemKhoaHoc ---------- */
CREATE TABLE #KH (MaKH VARCHAR(6), TenKhoa NVARCHAR(50), MaNN CHAR(3), TenNN NVARCHAR(30),
                  TrinhDo NVARCHAR(10), SoBuoi TINYINT, HocPhi MONEY, TrangThai NVARCHAR(20));

-- tên khớp một phần, không phân biệt hoa thường: 'toeic' -> KH0002
INSERT INTO #KH EXEC dbo.SP_TimKiemKhoaHoc @TenKhoa = N'toeic';
SELECT @n = COUNT(*) FROM #KH WHERE MaKH = 'KH0002';
SELECT @n2 = COUNT(*) FROM #KH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A06a', N'SP_TimKiemKhoaHoc: tên ''toeic'' -> đúng 1 dòng KH0002',
        CASE WHEN @n = 1 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n2 AS NVARCHAR(10)));
DELETE FROM #KH;

-- khoảng học phí 3.000.000 - 3.200.000 -> KH0001, KH0004, KH0005
INSERT INTO #KH EXEC dbo.SP_TimKiemKhoaHoc @HocPhiMin = 3000000, @HocPhiMax = 3200000;
SELECT @n = COUNT(*) FROM #KH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A06b', N'SP_TimKiemKhoaHoc: học phí 3tr-3.2tr -> 3 dòng',
        CASE WHEN @n = 3 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n AS NVARCHAR(10)));
DELETE FROM #KH;

-- ngôn ngữ ANH + trạng thái đang giảng dạy -> 2 ; ký tự '%' được escape -> 0 ; không tiêu chí -> 5
INSERT INTO #KH EXEC dbo.SP_TimKiemKhoaHoc @MaNN = 'ANH', @TrangThai = N'Đang giảng dạy';
SELECT @n = COUNT(*) FROM #KH;
DELETE FROM #KH;
INSERT INTO #KH EXEC dbo.SP_TimKiemKhoaHoc @TenKhoa = N'%';
SELECT @n2 = COUNT(*) FROM #KH;
DELETE FROM #KH;
INSERT INTO #KH EXEC dbo.SP_TimKiemKhoaHoc;
SELECT @tien = COUNT(*) FROM #KH;
DELETE FROM #KH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A06c', N'SP_TimKiemKhoaHoc: ANH+đang giảng dạy = 2; ''%'' = 0; không tiêu chí = 5',
        CASE WHEN @n = 2 AND @n2 = 0 AND @tien = 5 THEN 'PASS' ELSE 'FAIL' END,
        CAST(@n AS NVARCHAR(10)) + N' / ' + CAST(@n2 AS NVARCHAR(10)) + N' / ' + CAST(@tien AS NVARCHAR(10)));

-- học phí từ > học phí đến -> lỗi 51011
BEGIN TRY
    EXEC dbo.SP_TimKiemKhoaHoc @HocPhiMin = 5000000, @HocPhiMax = 1000000;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A06d', N'Học phí từ > đến phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A06d', N'Học phí từ > đến phải báo lỗi 51011', CASE WHEN ERROR_NUMBER() = 51011 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;
DROP TABLE #KH;

/* ---------- A07: SP_ThongKeDangKy_TheoKhoa ----------
   Tháng 12/2025: DK001, DK002, DK003 (LOP001 - KH0001), DK006 (LOP003 - KH0003) -> tổng 4
   Trả về đủ 5 khóa (khóa không có đăng ký = 0); KH0001 = 3 đăng ký, 75.00% */
CREATE TABLE #TK (MaKH VARCHAR(6), TenKhoa NVARCHAR(50), TenNN NVARCHAR(30), SoLopCoDangKy INT,
                  SoDangKy INT, SoHocVien INT, TyLePhanTram DECIMAL(5,2));
INSERT INTO #TK EXEC dbo.SP_ThongKeDangKy_TheoKhoa @TuNgay = '2025-12-01', @DenNgay = '2025-12-31';
SELECT @n = COUNT(*), @n2 = SUM(SoDangKy) FROM #TK;
SELECT @tien = COUNT(*) FROM #TK WHERE MaKH = 'KH0001' AND SoDangKy = 3 AND TyLePhanTram = 75.00;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('A07a', N'SP_ThongKeDangKy_TheoKhoa 12/2025: 5 dòng, tổng 4 ĐK, KH0001 = 3 (75%)',
        CASE WHEN @n = 5 AND @n2 = 4 AND @tien = 1 THEN 'PASS' ELSE 'FAIL' END,
        N'Số dòng = ' + CAST(@n AS NVARCHAR(10)) + N'; tổng ĐK = ' + CAST(@n2 AS NVARCHAR(10)));
DROP TABLE #TK;

BEGIN TRY
    EXEC dbo.SP_ThongKeDangKy_TheoKhoa @TuNgay = '2026-02-01', @DenNgay = '2026-01-01';
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A07b', N'Từ ngày > đến ngày phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A07b', N'Từ ngày > đến ngày phải báo lỗi 51020', CASE WHEN ERROR_NUMBER() = 51020 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- A08: TRG_KHOAHOC_NgungTuyenSinh ---------- */
-- A08a: KH0004 còn LOP004 'Đang tuyển sinh' -> chặn, lỗi 51001
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.KHOAHOC SET TrangThai = N'Ngừng tuyển sinh' WHERE MaKH = 'KH0004';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A08a', N'Ngừng tuyển sinh KH0004 (còn lớp tuyển sinh) phải bị chặn', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A08a', N'Ngừng tuyển sinh KH0004 phải bị chặn (51001)', CASE WHEN ERROR_NUMBER() = 51001 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- A08b: KH0001 chỉ có lớp đang học / đã kết thúc -> được phép
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.KHOAHOC SET TrangThai = N'Ngừng tuyển sinh' WHERE MaKH = 'KH0001';
    SELECT @tt = TrangThai FROM dbo.KHOAHOC WHERE MaKH = 'KH0001';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A08b', N'Ngừng tuyển sinh KH0001 (không còn lớp tuyển sinh) được phép',
            CASE WHEN @tt = N'Ngừng tuyển sinh' THEN 'PASS' ELSE 'FAIL' END, @tt);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A08b', N'Ngừng tuyển sinh KH0001 được phép', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- A09: TRG_KHOAHOC_KhoaNgonNgu ---------- */
-- A09a: KH0001 đã có lớp -> đổi MaNN bị chặn, lỗi 51002
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.KHOAHOC SET MaNN = 'NHA' WHERE MaKH = 'KH0001';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A09a', N'Đổi ngôn ngữ KH0001 (đã có lớp) phải bị chặn', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A09a', N'Đổi ngôn ngữ KH0001 phải bị chặn (51002)', CASE WHEN ERROR_NUMBER() = 51002 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- A09b: KH0005 chưa có lớp -> đổi MaNN được phép
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.KHOAHOC SET MaNN = 'HAN' WHERE MaKH = 'KH0005';
    SELECT @tt = MaNN FROM dbo.KHOAHOC WHERE MaKH = 'KH0005';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A09b', N'Đổi ngôn ngữ KH0005 (chưa có lớp) được phép', CASE WHEN @tt = N'HAN' THEN 'PASS' ELSE 'FAIL' END, @tt);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A09b', N'Đổi ngôn ngữ KH0005 được phép', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- A10: SP_CapNhatHocPhiKhoa (trong giao dịch ngoài -> nhánh SAVE TRANSACTION) ----------
   KH0001 -> 3.200.000. Hóa đơn chưa thanh toán của khóa: chỉ HD003 (LOP001). HD002 (một phần),
   HD001/HD009/HD010 (đã đủ) giữ nguyên 3.000.000. HD003 vẫn 'Chưa thanh toán'. */
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0001', @HocPhiMoi = 3200000, @SoHoaDonCapNhat = @n OUTPUT;
    SELECT @tien = HocPhi FROM dbo.KHOAHOC WHERE MaKH = 'KH0001';
    SELECT @tien2 = SoTienCanThu, @tt = TrangThaiThanhToan FROM dbo.HOADON WHERE MaHD = 'HD003';
    SELECT @n2 = COUNT(*) FROM dbo.HOADON WHERE MaHD IN ('HD001', 'HD002', 'HD009', 'HD010') AND SoTienCanThu = 3000000;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A10a', N'Đổi học phí KH0001: 1 hóa đơn (HD003) đổi, 4 hóa đơn đã thu giữ nguyên',
            CASE WHEN @n = 1 AND @tien = 3200000 AND @tien2 = 3200000 AND @tt = N'Chưa thanh toán' AND @n2 = 4
                 THEN 'PASS' ELSE 'FAIL' END,
            N'Số HĐ = ' + CAST(@n AS NVARCHAR(10)) + N'; HD003 = ' + CAST(@tien2 AS NVARCHAR(20)));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A10a', N'Đổi học phí KH0001', 'FAIL', ERROR_MESSAGE());
END CATCH;

-- A10b-d: lỗi tham số
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH9999', @HocPhiMoi = 1000000, @SoHoaDonCapNhat = @n OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A10b', N'Khóa không tồn tại phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A10b', N'Khóa không tồn tại phải báo lỗi 51032', CASE WHEN ERROR_NUMBER() = 51032 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0001', @HocPhiMoi = -1, @SoHoaDonCapNhat = @n OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A10c', N'Học phí âm phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A10c', N'Học phí âm phải báo lỗi 51031', CASE WHEN ERROR_NUMBER() = 51031 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0001', @HocPhiMoi = 3000000, @SoHoaDonCapNhat = @n OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A10d', N'Học phí trùng phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A10d', N'Học phí trùng phải báo lỗi 51033', CASE WHEN ERROR_NUMBER() = 51033 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- A11: SP_ThemKhoaHoc_VaNgonNgu ---------- */
-- A11a: ngôn ngữ mới PHA + khóa đầu tiên -> KH0006, DaThemNgonNgu = 1
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThemKhoaHoc_VaNgonNgu @MaNN = 'PHA', @TenNN = N'Tiếng Pháp', @TenKhoa = N'Tiếng Pháp A1',
         @TrinhDo = N'So cap', @SoBuoi = 24, @HocPhi = 3800000, @MaKH = @ma OUTPUT, @DaThemNgonNgu = @bit OUTPUT;
    SELECT @n = COUNT(*) FROM dbo.NGONNGU WHERE MaNN = 'PHA';
    SELECT @n2 = COUNT(*) FROM dbo.KHOAHOC WHERE MaKH = @ma AND MaNN = 'PHA' AND TrangThai = N'Đang giảng dạy';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A11a', N'Thêm ngôn ngữ PHA + khóa KH0006 trong một giao dịch',
            CASE WHEN @ma = 'KH0006' AND @bit = 1 AND @n = 1 AND @n2 = 1 THEN 'PASS' ELSE 'FAIL' END,
            N'MaKH = ' + ISNULL(@ma, N'NULL'));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A11a', N'Thêm ngôn ngữ + khóa', 'FAIL', ERROR_MESSAGE());
END CATCH;

-- A11b: ngôn ngữ có sẵn ANH, không nhập tên -> chỉ thêm khóa, DaThemNgonNgu = 0
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThemKhoaHoc_VaNgonNgu @MaNN = 'ANH', @TenKhoa = N'IELTS 6.5', @TrinhDo = N'Cao cap',
         @SoBuoi = 40, @HocPhi = 7000000, @MaKH = @ma OUTPUT, @DaThemNgonNgu = @bit OUTPUT;
    SELECT @n = COUNT(*) FROM dbo.NGONNGU;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A11b', N'Thêm khóa cho ngôn ngữ có sẵn: không thêm ngôn ngữ',
            CASE WHEN @ma = 'KH0006' AND @bit = 0 AND @n = 4 THEN 'PASS' ELSE 'FAIL' END,
            N'MaKH = ' + ISNULL(@ma, N'NULL'));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A11b', N'Thêm khóa cho ngôn ngữ có sẵn', 'FAIL', ERROR_MESSAGE());
END CATCH;

-- A11c: ROLLBACK cả hai - ngôn ngữ mới hợp lệ nhưng số buổi sai -> lỗi 51041, không có PHA trong NGONNGU
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThemKhoaHoc_VaNgonNgu @MaNN = 'PHA', @TenNN = N'Tiếng Pháp', @TenKhoa = N'Tiếng Pháp A1',
         @TrinhDo = N'So cap', @SoBuoi = 0, @HocPhi = 3800000, @MaKH = @ma OUTPUT, @DaThemNgonNgu = @bit OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A11c', N'Số buổi 0 phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    SET @n = ERROR_NUMBER();
    SET @tt = LEFT(ERROR_MESSAGE(), 30);
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT @n2 = COUNT(*) FROM dbo.NGONNGU WHERE MaNN = 'PHA';
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A11c', N'Số buổi 0 -> lỗi 51041, ngôn ngữ PHA không được thêm',
            CASE WHEN @n = 51041 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END, @tt);
END CATCH;

-- A11d: mã ANH đã có nhưng nhập tên khác -> lỗi 51045
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThemKhoaHoc_VaNgonNgu @MaNN = 'ANH', @TenNN = N'Tiếng Pháp', @TenKhoa = N'Khóa thử',
         @TrinhDo = N'So cap', @SoBuoi = 10, @HocPhi = 1000000, @MaKH = @ma OUTPUT, @DaThemNgonNgu = @bit OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A11d', N'Mã ngôn ngữ có sẵn với tên khác phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A11d', N'Mã ngôn ngữ có sẵn với tên khác phải báo lỗi 51045', CASE WHEN ERROR_NUMBER() = 51045 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- A12: gọi KHÔNG có giao dịch ngoài -> thủ tục tự BEGIN/COMMIT ----------
   KH0005 không có lớp/hóa đơn: đổi 3.000.000 -> 3.100.000 rồi đổi lại -> dữ liệu cuối không đổi */
BEGIN TRY
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0005', @HocPhiMoi = 3100000, @SoHoaDonCapNhat = @n OUTPUT;
    SELECT @tien = HocPhi FROM dbo.KHOAHOC WHERE MaKH = 'KH0005';
    SET @n2 = @@TRANCOUNT;
    EXEC dbo.SP_CapNhatHocPhiKhoa @MaKH = 'KH0005', @HocPhiMoi = 3000000, @SoHoaDonCapNhat = @n OUTPUT;
    SELECT @tien2 = HocPhi FROM dbo.KHOAHOC WHERE MaKH = 'KH0005';
    -- Đọc @@TRANCOUNT bằng lệnh SET riêng: bên trong câu INSERT (autocommit) @@TRANCOUNT luôn = 1
    SET @ok = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('A12', N'Không giao dịch ngoài: tự COMMIT, @@TRANCOUNT = 0, trả lại học phí cũ',
            CASE WHEN @tien = 3100000 AND @n2 = 0 AND @tien2 = 3000000 AND @ok = 1 THEN 'PASS' ELSE 'FAIL' END,
            N'Sau lần 1 = ' + CAST(@tien AS NVARCHAR(20)) + N'; cuối = ' + CAST(@tien2 AS NVARCHAR(20)));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('A12', N'Gọi không có giao dịch ngoài', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- KẾT QUẢ ---------- */
SELECT STT, Ma, MoTa, KetQua, ChiTiet FROM #KQ ORDER BY STT;
SELECT SUM(CASE WHEN KetQua = 'PASS' THEN 1 ELSE 0 END) AS SoCaPASS,
       SUM(CASE WHEN KetQua = 'FAIL' THEN 1 ELSE 0 END) AS SoCaFAIL,
       COUNT(*) AS TongSoCa
FROM #KQ;
DROP TABLE #KQ;
GO