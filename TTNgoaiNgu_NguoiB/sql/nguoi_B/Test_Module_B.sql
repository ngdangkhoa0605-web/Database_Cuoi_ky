/* =====================================================================
   KIỂM THỬ MODULE B  (chạy SAU Module_B_HocVien_TaiChinh.sql, trên dữ liệu mẫu của Người A)
   - Mỗi ca kiểm thử chạy trong giao dịch riêng và ROLLBACK -> KHÔNG làm đổi dữ liệu mẫu
     (ngoại lệ có chủ đích: ca T12 tạo rồi hủy một đăng ký, kết quả cuối cùng bằng 0).
   - Kết quả: bảng PASS/FAIL ở cuối. Mong đợi: tất cả PASS.
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

-- Biến dùng chung cho các ca kiểm thử (khai báo một lần)
DECLARE @n INT, @tien MONEY, @tien2 MONEY,
        @a VARCHAR(8), @b VARCHAR(8),
        @s1 NVARCHAR(30), @s2 NVARCHAR(30), @s3 NVARCHAR(30),
        @d1 DATE, @d3 DATE,
        @conno MONEY, @tt NVARCHAR(30),
        @ok BIT;

/* ---------- T01: hai index tồn tại ---------- */
SELECT @n = COUNT(*) FROM sys.indexes
WHERE name IN (N'IX_DANGKY_MaLop', N'IX_HOCVIEN_HoTen');
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T01', N'Có đủ 2 index IX_DANGKY_MaLop, IX_HOCVIEN_HoTen',
        CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số index tìm thấy = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- T02: FN_TinhCongNo ----------
   DK002: 3.000.000 - 1.500.000 = 1.500.000 | DK003 = 3.000.000 | DK001 = 0 | DK999 (không có) = NULL */
SELECT @tien = dbo.FN_TinhCongNo('DK002'), @tien2 = dbo.FN_TinhCongNo('DK003');
SET @ok = CASE WHEN @tien = 1500000 AND @tien2 = 3000000
                AND dbo.FN_TinhCongNo('DK001') = 0
                AND dbo.FN_TinhCongNo('DK999') IS NULL THEN 1 ELSE 0 END;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T02', N'FN_TinhCongNo: DK002=1.5tr, DK003=3tr, DK001=0, DK999=NULL',
        CASE WHEN @ok = 1 THEN 'PASS' ELSE 'FAIL' END,
        N'DK002=' + CAST(@tien AS NVARCHAR(20)) + N'; DK003=' + CAST(@tien2 AS NVARCHAR(20)));

/* ---------- T03: FN_DSDangKy_HocVien ----------
   HV001 chỉ có 1 đăng ký: DK001 - LOP001, công nợ 0 */
SELECT @n = COUNT(*) FROM dbo.FN_DSDangKy_HocVien('HV001') WHERE MaDK = 'DK001' AND MaLop = 'LOP001' AND CongNo = 0;
SELECT @tien = COUNT(*) FROM dbo.FN_DSDangKy_HocVien('HV001');
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T03', N'FN_DSDangKy_HocVien(HV001) trả đúng 1 dòng DK001/LOP001/nợ 0',
        CASE WHEN @n = 1 AND @tien = 1 THEN 'PASS' ELSE 'FAIL' END, N'Tổng dòng = ' + CAST(@tien AS NVARCHAR(20)));

/* ---------- T04: V_CONGNO_HocPhi ----------
   5 hóa đơn còn nợ: HD002 1.5tr, HD003 3tr, HD005 2.5tr, HD007 3.5tr, HD008 2.2tr -> tổng 12.7tr */
SELECT @n = COUNT(*), @tien = SUM(SoTienNo) FROM dbo.V_CONGNO_HocPhi;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T04', N'V_CONGNO_HocPhi: 5 dòng nợ, tổng nợ 12.700.000',
        CASE WHEN @n = 5 AND @tien = 12700000 THEN 'PASS' ELSE 'FAIL' END,
        N'Số dòng = ' + CAST(@n AS NVARCHAR(10)) + N'; tổng nợ = ' + CAST(@tien AS NVARCHAR(20)));

/* ---------- T05: V_HOCVIEN_LichSuHoc ----------
   10 đăng ký -> 10 dòng; DK009 có điểm 8.5 */
SELECT @n = COUNT(*) FROM dbo.V_HOCVIEN_LichSuHoc;
SELECT @tien = COUNT(*) FROM dbo.V_HOCVIEN_LichSuHoc WHERE MaDK = 'DK009' AND DiemCuoiKy = 8.5;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T05', N'V_HOCVIEN_LichSuHoc: 10 dòng, DK009 có điểm 8.5',
        CASE WHEN @n = 10 AND @tien = 1 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- T06: SP_TimKiemHocVien ---------- */
CREATE TABLE #HV (MaHV CHAR(5), HoTen NVARCHAR(40), NgaySinh DATE, SDT VARCHAR(15), Email VARCHAR(50), DiaChi NVARCHAR(100), SoLopDangKy INT);

INSERT INTO #HV EXEC dbo.SP_TimKiemHocVien @HoTen = N'Nguyễn';
SELECT @n = COUNT(*) FROM #HV WHERE MaHV = 'HV001';
SELECT @tien = COUNT(*) FROM #HV;
DELETE FROM #HV;
INSERT INTO #HV EXEC dbo.SP_TimKiemHocVien @SDT = '0901000005';
SELECT @tien2 = COUNT(*) FROM #HV WHERE MaHV = 'HV005';
DELETE FROM #HV;
INSERT INTO #HV EXEC dbo.SP_TimKiemHocVien @Email = 'minh.tran';
SELECT @conno = COUNT(*) FROM #HV WHERE MaHV = 'HV002';
DELETE FROM #HV;
INSERT INTO #HV EXEC dbo.SP_TimKiemHocVien @HoTen = N'%';       -- ký tự % được escape: không học viên nào có chữ %
SELECT @s1 = CAST(COUNT(*) AS NVARCHAR(10)) FROM #HV;
DELETE FROM #HV;
INSERT INTO #HV EXEC dbo.SP_TimKiemHocVien;                      -- không tiêu chí: trả tất cả
SELECT @s2 = CAST(COUNT(*) AS NVARCHAR(10)) FROM #HV;
DROP TABLE #HV;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T06', N'SP_TimKiemHocVien: theo tên, SĐT, email; escape ký tự %; không tiêu chí = 10 dòng',
        CASE WHEN @n = 1 AND @tien = 1 AND @tien2 = 1 AND @conno = 1 AND @s1 = N'0' AND @s2 = N'10' THEN 'PASS' ELSE 'FAIL' END,
        N'tên=' + CAST(@tien AS NVARCHAR(10)) + N'; ký tự %=' + @s1 + N'; tất cả=' + @s2);

/* ---------- T07: SP_ThongKeDoanhThu ----------
   Tổng đã thu có ngày thanh toán = 21.500.000. Tháng 01/2026: HD004 (4.5tr) + HD005 (2tr) = 6.5tr, 2 hóa đơn.
   Khóa KH0001: HD001 3tr + HD002 1.5tr + HD009 3tr + HD010 3tr = 10.5tr */
CREATE TABLE #DT (Nam INT, Thang INT, MaKH VARCHAR(6), TenKhoa NVARCHAR(50), SoHoaDon INT, TongPhaiThu MONEY, DoanhThu MONEY, ConPhaiThu MONEY);

INSERT INTO #DT EXEC dbo.SP_ThongKeDoanhThu;
SELECT @tien = SUM(DoanhThu) FROM #DT;
DELETE FROM #DT;
INSERT INTO #DT EXEC dbo.SP_ThongKeDoanhThu @Nam = 2026, @Thang = 1;
SELECT @tien2 = SUM(DoanhThu), @n = SUM(SoHoaDon) FROM #DT;
DELETE FROM #DT;
INSERT INTO #DT EXEC dbo.SP_ThongKeDoanhThu @MaKH = 'KH0001', @NhomTheo = 'KHOA';
SELECT @conno = SUM(DoanhThu) FROM #DT;
DROP TABLE #DT;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('T07', N'SP_ThongKeDoanhThu: tổng 21.5tr; 01/2026 = 6.5tr (2 HĐ); KH0001 = 10.5tr',
        CASE WHEN @tien = 21500000 AND @tien2 = 6500000 AND @n = 2 AND @conno = 10500000 THEN 'PASS' ELSE 'FAIL' END,
        N'tổng=' + CAST(@tien AS NVARCHAR(20)) + N'; 01/2026=' + CAST(@tien2 AS NVARCHAR(20)) + N'; KH0001=' + CAST(@conno AS NVARCHAR(20)));

-- T07b: tham số sai phải báo lỗi 52011 (tháng 13)
BEGIN TRY
    EXEC dbo.SP_ThongKeDoanhThu @Nam = 2026, @Thang = 13;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T07b', N'SP_ThongKeDoanhThu: tháng 13 phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T07b', N'SP_ThongKeDoanhThu: tháng 13 phải báo lỗi 52011',
            CASE WHEN ERROR_NUMBER() = 52011 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- T08: TRG_HOADON_TuDongTrangThai ----------
   HD003 (cần thu 3tr, đã thu 0): thu 1tr -> 'Thanh toán một phần' (có ngày); thu đủ 3tr -> 'Đã thanh toán đủ';
   về 0 -> 'Chưa thanh toán' và NgayThanhToan = NULL */
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.HOADON SET SoTienDaThu = 1000000 WHERE MaHD = 'HD003';
    SELECT @s1 = TrangThaiThanhToan, @d1 = NgayThanhToan FROM dbo.HOADON WHERE MaHD = 'HD003';
    UPDATE dbo.HOADON SET SoTienDaThu = 3000000 WHERE MaHD = 'HD003';
    SELECT @s2 = TrangThaiThanhToan FROM dbo.HOADON WHERE MaHD = 'HD003';
    UPDATE dbo.HOADON SET SoTienDaThu = 0 WHERE MaHD = 'HD003';
    SELECT @s3 = TrangThaiThanhToan, @d3 = NgayThanhToan FROM dbo.HOADON WHERE MaHD = 'HD003';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T08', N'TRG_HOADON_TuDongTrangThai: một phần -> đủ -> chưa thanh toán',
            CASE WHEN @s1 = N'Thanh toán một phần' AND @d1 IS NOT NULL
                      AND @s2 = N'Đã thanh toán đủ'
                      AND @s3 = N'Chưa thanh toán' AND @d3 IS NULL THEN 'PASS' ELSE 'FAIL' END,
            ISNULL(@s1, N'?') + N' | ' + ISNULL(@s2, N'?') + N' | ' + ISNULL(@s3, N'?'));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T08', N'TRG_HOADON_TuDongTrangThai', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- T09: TRG_DANGKY_SiSo ---------- */
-- T09a: đăng ký vào lớp 'Đã kết thúc' (LOP005) phải bị chặn, mã lỗi 52001
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy) VALUES ('DKT01', 'HV001', 'LOP005', '2026-01-01');
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T09a', N'TRG_DANGKY_SiSo: lớp đã kết thúc phải bị chặn', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T09a', N'TRG_DANGKY_SiSo: lớp đã kết thúc phải bị chặn (52001)',
            CASE WHEN ERROR_NUMBER() = 52001 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T09b: lớp sĩ số tối đa 1 đã có 1 học viên -> thêm học viên thứ 2 bị chặn, mã lỗi 52002
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.LOP (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai)
    VALUES ('LTEST1', 'KH0001', 'GV01', '2026-06-01', '2026-09-01', 1, N'Đang tuyển sinh');
    INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy) VALUES ('DKT01', 'HV001', 'LTEST1', '2026-01-01');
    INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy) VALUES ('DKT02', 'HV002', 'LTEST1', '2026-01-01');
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T09b', N'TRG_DANGKY_SiSo: vượt sĩ số phải bị chặn', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T09b', N'TRG_DANGKY_SiSo: vượt sĩ số phải bị chặn (52002)',
            CASE WHEN ERROR_NUMBER() = 52002 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T09c: cập nhật điểm của đăng ký thuộc lớp đã kết thúc (MaLop không đổi) KHÔNG bị chặn
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.DANGKY SET MaLop = MaLop, DiemCuoiKy = 9.0 WHERE MaDK = 'DK010';
    SELECT @tien = DiemCuoiKy FROM dbo.DANGKY WHERE MaDK = 'DK010';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T09c', N'TRG_DANGKY_SiSo: sửa điểm (MaLop không đổi) ở lớp đã kết thúc vẫn được',
            CASE WHEN @tien = 9.0 THEN 'PASS' ELSE 'FAIL' END, N'Điểm sau khi sửa = ' + CAST(@tien AS NVARCHAR(20)));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T09c', N'TRG_DANGKY_SiSo: sửa điểm ở lớp đã kết thúc', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- T10: SP_DangKy_VaTaoHoaDon - trường hợp thành công (có giao dịch bên ngoài -> đường savepoint) ----------
   HV010 -> LOP004 (KH0004, học phí 3.200.000): mã mới DK011 / HD011, chưa thu.
   HV010 -> LOP003 (KH0003, học phí 3.500.000) thu ngay 1.000.000 -> 'Thanh toán một phần' */
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV010', @MaLop = 'LOP004', @NgayDangKy = NULL,
         @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    SELECT @tien = hd.SoTienCanThu, @s1 = hd.TrangThaiThanhToan
    FROM dbo.HOADON AS hd WHERE hd.MaHD = @b AND hd.MaDK = @a;

    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV010', @MaLop = 'LOP003', @NgayDangKy = NULL,
         @SoTienThuNgay = 1000000, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    SELECT @tien2 = hd.SoTienDaThu, @s2 = hd.TrangThaiThanhToan
    FROM dbo.HOADON AS hd WHERE hd.MaHD = @b AND hd.MaDK = @a;
    SELECT @n = COUNT(*) FROM dbo.DANGKY WHERE MaHV = 'HV010';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T10', N'SP_DangKy_VaTaoHoaDon: tạo đăng ký + hóa đơn đúng học phí, thu ngay một phần',
            CASE WHEN @a = 'DK012' AND @b = 'HD012' AND @tien = 3200000 AND @s1 = N'Chưa thanh toán'
                      AND @tien2 = 1000000 AND @s2 = N'Thanh toán một phần' AND @n = 3 THEN 'PASS' ELSE 'FAIL' END,
            N'mã cuối = ' + ISNULL(@a, '?') + N'/' + ISNULL(@b, '?') + N'; học phí = ' + ISNULL(CAST(@tien AS NVARCHAR(20)), '?'));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T10', N'SP_DangKy_VaTaoHoaDon thành công', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- T11: SP_DangKy_VaTaoHoaDon - các trường hợp phải báo lỗi (mỗi ca một giao dịch) ---------- */
-- T11a: trùng đăng ký
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV001', @MaLop = 'LOP001', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11a', N'Đăng ký trùng phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11a', N'Đăng ký trùng phải báo lỗi 52028', CASE WHEN ERROR_NUMBER() = 52028 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T11b: lớp đã kết thúc
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV001', @MaLop = 'LOP005', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11b', N'Lớp đã kết thúc phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11b', N'Lớp đã kết thúc phải báo lỗi 52025', CASE WHEN ERROR_NUMBER() = 52025 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T11c: học viên không tồn tại
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV999', @MaLop = 'LOP001', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11c', N'Học viên không tồn tại phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11c', N'Học viên không tồn tại phải báo lỗi 52023', CASE WHEN ERROR_NUMBER() = 52023 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T11d: lớp không tồn tại
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV001', @MaLop = 'LOP999', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11d', N'Lớp không tồn tại phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11d', N'Lớp không tồn tại phải báo lỗi 52024', CASE WHEN ERROR_NUMBER() = 52024 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T11e: lớp đã đầy (sĩ số tối đa 1, đã có HV001; HV002 đăng ký thêm)
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.LOP (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai)
    VALUES ('LTEST1', 'KH0001', 'GV01', '2026-06-01', '2026-09-01', 1, N'Đang tuyển sinh');
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV001', @MaLop = 'LTEST1', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV002', @MaLop = 'LTEST1', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11e', N'Lớp đã đầy phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11e', N'Lớp đã đầy phải báo lỗi 52029', CASE WHEN ERROR_NUMBER() = 52029 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T11f: khóa học đã ngừng tuyển sinh (KH0005) - tạo lớp thử thuộc KH0005 do GV05 (tiếng Trung) phụ trách
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.LOP (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai)
    VALUES ('LTEST2', 'KH0005', 'GV05', '2026-06-01', '2026-09-01', 10, N'Đang tuyển sinh');
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV001', @MaLop = 'LTEST2', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T11f', N'Khóa học ngừng tuyển sinh phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T11f', N'Khóa học ngừng tuyển sinh phải báo lỗi 52026', CASE WHEN ERROR_NUMBER() = 52026 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- T12: SP_DangKy_VaTaoHoaDon + SP_HuyDangKy KHÔNG có giao dịch bên ngoài (thủ tục tự COMMIT) ----------
   Đăng ký HV010 -> LOP004 (commit thật) -> kiểm tra tồn tại -> hủy bằng SP_HuyDangKy -> kiểm tra đã mất. */
BEGIN TRY
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV010', @MaLop = 'LOP004', @NgayDangKy = NULL, @SoTienThuNgay = NULL, @MaDK = @a OUTPUT, @MaHD = @b OUTPUT;
    SELECT @n = COUNT(*) FROM dbo.DANGKY WHERE MaDK = @a;
    SELECT @tien = COUNT(*) FROM dbo.HOADON WHERE MaHD = @b;
    SET @s1 = @a;
    EXEC dbo.SP_HuyDangKy @MaDK = @a;
    SELECT @tien2 = COUNT(*) FROM dbo.DANGKY WHERE MaDK = @s1;
    SELECT @conno = COUNT(*) FROM dbo.HOADON WHERE MaHD = @b;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T12', N'Không có giao dịch ngoài: SP tự COMMIT; SP_HuyDangKy xóa sạch đăng ký + hóa đơn',
            CASE WHEN @n = 1 AND @tien = 1 AND @tien2 = 0 AND @conno = 0 AND @@TRANCOUNT = 0 THEN 'PASS' ELSE 'FAIL' END,
            N'mã = ' + ISNULL(@s1, N'?') + N'; @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10)));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T12', N'SP tự COMMIT + SP_HuyDangKy', 'FAIL', ERROR_MESSAGE());
END CATCH;

/* ---------- T13: SP_ThanhToanHocPhi ---------- */
-- T13a: thu đúng phần còn nợ của HD002 (1.500.000) -> đã thanh toán đủ, còn nợ 0
-- T13b: thu một phần HD003 (1.000.000) -> 'Thanh toán một phần', còn nợ 2.000.000
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThanhToanHocPhi @MaHD = 'HD002', @SoTienThu = 1500000, @NgayThu = NULL, @SoTienConNo = @tien OUTPUT, @TrangThai = @s1 OUTPUT;
    EXEC dbo.SP_ThanhToanHocPhi @MaHD = 'HD003', @SoTienThu = 1000000, @NgayThu = NULL, @SoTienConNo = @tien2 OUTPUT, @TrangThai = @s2 OUTPUT;
    SELECT @s3 = TrangThaiThanhToan FROM dbo.HOADON WHERE MaHD = 'HD002';
    SELECT @d3 = NgayThanhToan FROM dbo.HOADON WHERE MaHD = 'HD003';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T13', N'SP_ThanhToanHocPhi: thu đủ HD002, thu một phần HD003',
            CASE WHEN @tien = 0 AND @s1 = N'Đã thanh toán đủ' AND @s3 = N'Đã thanh toán đủ'
                      AND @tien2 = 2000000 AND @s2 = N'Thanh toán một phần' AND @d3 IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
            N'HD002: ' + ISNULL(@s1, N'?') + N'; HD003 còn nợ ' + ISNULL(CAST(@tien2 AS NVARCHAR(20)), N'?'));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T13', N'SP_ThanhToanHocPhi thành công', 'FAIL', ERROR_MESSAGE());
END CATCH;

-- T13c: thu vượt (HD003 còn nợ 3.000.000, thu 4.000.000) phải báo lỗi 52045
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThanhToanHocPhi @MaHD = 'HD003', @SoTienThu = 4000000, @NgayThu = NULL, @SoTienConNo = @tien OUTPUT, @TrangThai = @s1 OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T13c', N'Thu vượt số cần thu phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T13c', N'Thu vượt số cần thu phải báo lỗi 52045', CASE WHEN ERROR_NUMBER() = 52045 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

-- T13d: số tiền 0 (52041), T13e: hóa đơn không tồn tại (52043)
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThanhToanHocPhi @MaHD = 'HD003', @SoTienThu = 0, @NgayThu = NULL, @SoTienConNo = @tien OUTPUT, @TrangThai = @s1 OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T13d', N'Thu 0 đồng phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T13d', N'Thu 0 đồng phải báo lỗi 52041', CASE WHEN ERROR_NUMBER() = 52041 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_ThanhToanHocPhi @MaHD = 'HD999', @SoTienThu = 1000, @NgayThu = NULL, @SoTienConNo = @tien OUTPUT, @TrangThai = @s1 OUTPUT;
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T13e', N'Hóa đơn không tồn tại phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T13e', N'Hóa đơn không tồn tại phải báo lỗi 52043', CASE WHEN ERROR_NUMBER() = 52043 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- T14: SP_HuyDangKy - không cho hủy đăng ký đã có điểm (DK009 có điểm 8.5) ---------- */
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_HuyDangKy @MaDK = 'DK009';
    ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet) VALUES ('T14', N'Hủy đăng ký đã có điểm phải báo lỗi', 'FAIL', N'Không có lỗi');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
    VALUES ('T14', N'Hủy đăng ký đã có điểm phải báo lỗi 52052', CASE WHEN ERROR_NUMBER() = 52052 THEN 'PASS' ELSE 'FAIL' END, ERROR_MESSAGE());
END CATCH;

/* ---------- KẾT QUẢ ---------- */
SELECT STT, Ma, MoTa, KetQua, ChiTiet FROM #KQ ORDER BY STT;
SELECT SUM(CASE WHEN KetQua = 'PASS' THEN 1 ELSE 0 END) AS SoCaPASS,
       SUM(CASE WHEN KetQua = 'FAIL' THEN 1 ELSE 0 END) AS SoCaFAIL,
       COUNT(*) AS TongSoCa
FROM #KQ;
DROP TABLE #KQ;
GO
