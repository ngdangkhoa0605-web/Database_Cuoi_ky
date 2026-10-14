/* =====================================================================
   KIỂM THỬ MODULE D (Giảng viên và giảng dạy)
   Chạy SAU Module_D_GiangVien_GiangDay.sql, trên dữ liệu mẫu của Người A.
   - Mỗi ca chạy trong giao dịch riêng và ROLLBACK -> KHÔNG làm đổi dữ liệu mẫu
     (ca D14 kiểm tra lại điều đó ở cuối).
   - Kết quả: bảng PASS/FAIL ở cuối. Mong đợi: tất cả PASS, SoCaFAIL = 0.
   - Số liệu mong đợi tính tay từ DataQLTTNgoaiNgu.sql (xem chú thích từng ca).
   - Chạy bằng tài khoản sysadmin (không phụ thuộc phân quyền).
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

-- Bảng hứng kết quả của các thủ tục (INSERT ... EXEC)
CREATE TABLE #CC (MaDK VARCHAR(8), MaHV CHAR(5), HoTenHV NVARCHAR(40), SoLuot INT, SoCoMat INT,
                  SoVCP INT, SoVKP INT, TyLe DECIMAL(5,2), TyLeLop DECIMAL(5,2), CanhBao BIT);
CREATE TABLE #LD (MaBuoi VARCHAR(8), Ngay DATE, Thu INT, MaLop VARCHAR(6), TenKhoa NVARCHAR(50),
                  VaiTro NVARCHAR(30), TrangThai NVARCHAR(20), GioBD TIME, GioKT TIME, Phong VARCHAR(10));
CREATE TABLE #DD (MaBuoi VARCHAR(8), SoThem INT, SoCapNhat INT);
CREATE TABLE #BG (MaGV_Nghi CHAR(4), MaGV_Moi CHAR(4), SoLop INT, TrangThaiMoi NVARCHAR(20));

DECLARE @n INT, @m INT, @a DECIMAL(5,2), @b DECIMAL(5,2), @c DECIMAL(5,2), @d DECIMAL(5,2),
        @s1 NVARCHAR(40), @s2 NVARCHAR(40), @err INT, @msg NVARCHAR(400), @ok BIT;

/* ---------- D01: hai index tồn tại ---------- */
SELECT @n = COUNT(*) FROM sys.indexes
WHERE (name = N'IX_BUOIHOC_MaLop_Ngay' AND object_id = OBJECT_ID(N'dbo.BUOIHOC'))
   OR (name = N'IX_DIEMDANH_MaDK'      AND object_id = OBJECT_ID(N'dbo.DIEMDANH'));
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D01', N'Có đủ 2 index IX_BUOIHOC_MaLop_Ngay, IX_DIEMDANH_MaDK',
        CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số index tìm thấy = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- D02: FN_TyLeChuyenCan ----------
   DK001 = 3/3 = 100 | DK002 = 2/3 = 66.67 | DK007 = 0/1 = 0 | DK010 = 1/2 = 50 | DK999 (không có) = NULL */
SELECT @a = dbo.FN_TyLeChuyenCan('DK001'), @b = dbo.FN_TyLeChuyenCan('DK002'),
       @c = dbo.FN_TyLeChuyenCan('DK007'), @d = dbo.FN_TyLeChuyenCan('DK010');
SET @ok = CASE WHEN @a = 100 AND @b = 66.67 AND @c = 0 AND @d = 50
                AND dbo.FN_TyLeChuyenCan('DK999') IS NULL THEN 1 ELSE 0 END;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D02', N'FN_TyLeChuyenCan: DK001=100, DK002=66.67, DK007=0, DK010=50, DK999=NULL',
        CASE WHEN @ok = 1 THEN 'PASS' ELSE 'FAIL' END,
        N'DK001=' + ISNULL(CAST(@a AS NVARCHAR(10)), N'NULL') + N'; DK002=' + ISNULL(CAST(@b AS NVARCHAR(10)), N'NULL')
        + N'; DK007=' + ISNULL(CAST(@c AS NVARCHAR(10)), N'NULL') + N'; DK010=' + ISNULL(CAST(@d AS NVARCHAR(10)), N'NULL'));

/* ---------- D03: FN_DSGiangVien_TheoNN ----------
   ANH: GV01, GV02 (mỗi người 1 lớp đang phụ trách); GV06 "Tạm nghỉ" không xuất hiện | NHA: chỉ GV03 */
SELECT @n = COUNT(*) FROM dbo.FN_DSGiangVien_TheoNN('ANH');
SELECT @m = COUNT(*) FROM dbo.FN_DSGiangVien_TheoNN('ANH')
WHERE MaGV IN ('GV01', 'GV02') AND SoLopDangPhuTrach = 1;
SET @ok = CASE WHEN @n = 2 AND @m = 2
                AND (SELECT COUNT(*) FROM dbo.FN_DSGiangVien_TheoNN('NHA') WHERE MaGV = 'GV03') = 1
                AND (SELECT COUNT(*) FROM dbo.FN_DSGiangVien_TheoNN('NHA')) = 1 THEN 1 ELSE 0 END;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D03', N'FN_DSGiangVien_TheoNN: ANH = GV01, GV02 (GV06 tạm nghỉ bị loại); NHA = GV03',
        CASE WHEN @ok = 1 THEN 'PASS' ELSE 'FAIL' END, N'Số GV tiếng Anh = ' + CAST(@n AS NVARCHAR(10)));

/* ---------- D04: V_CHUYEN_CAN ----------
   10 đăng ký -> 10 dòng | LOP001 cả lớp 7/9 = 77.78 | LOP003 = 1/2 = 50 | LOP005 = 3/4 = 75
   DK004, DK005 (LOP002) = 100 | DK007 = 0 */
SELECT @n = COUNT(*) FROM dbo.V_CHUYEN_CAN;
SELECT @a = TyLeCoMatLop FROM dbo.V_CHUYEN_CAN WHERE MaDK = 'DK001';
SELECT @b = TyLeCoMatLop FROM dbo.V_CHUYEN_CAN WHERE MaDK = 'DK006';
SELECT @c = TyLeCoMatLop FROM dbo.V_CHUYEN_CAN WHERE MaDK = 'DK009';
SELECT @d = TyLeCoMat    FROM dbo.V_CHUYEN_CAN WHERE MaDK = 'DK007';
SET @ok = CASE WHEN @n = 10 AND @a = 77.78 AND @b = 50 AND @c = 75 AND @d = 0
                AND (SELECT COUNT(*) FROM dbo.V_CHUYEN_CAN WHERE MaLop = 'LOP002' AND TyLeCoMat = 100) = 2 THEN 1 ELSE 0 END;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D04', N'V_CHUYEN_CAN: 10 dòng; tỷ lệ lớp LOP001=77.78, LOP003=50, LOP005=75; DK007=0',
        CASE WHEN @ok = 1 THEN 'PASS' ELSE 'FAIL' END,
        N'Số dòng = ' + CAST(@n AS NVARCHAR(10)) + N'; LOP001=' + ISNULL(CAST(@a AS NVARCHAR(10)), N'NULL')
        + N'; LOP003=' + ISNULL(CAST(@b AS NVARCHAR(10)), N'NULL') + N'; LOP005=' + ISNULL(CAST(@c AS NVARCHAR(10)), N'NULL'));

/* ---------- D05: V_GIANGVIEN_TaiTrong ----------
   (SoLopChinh, SoLopDangPhuTrach, SoBuoiDaDay, SoBuoiDayThay):
   GV01 = 2,1,4,0 | GV02 = 1,1,2,1 (BH0003 dạy thay; BH0005 hoãn không tính) | GV05 = 0,0,0,0 */
SELECT @n = COUNT(*) FROM dbo.V_GIANGVIEN_TaiTrong;
SELECT @m = COUNT(*) FROM dbo.V_GIANGVIEN_TaiTrong
WHERE (MaGV = 'GV01' AND SoLopChinh = 2 AND SoLopDangPhuTrach = 1 AND SoBuoiDaDay = 4 AND SoBuoiDayThay = 0)
   OR (MaGV = 'GV02' AND SoLopChinh = 1 AND SoLopDangPhuTrach = 1 AND SoBuoiDaDay = 2 AND SoBuoiDayThay = 1)
   OR (MaGV = 'GV05' AND SoLopChinh = 0 AND SoLopDangPhuTrach = 0 AND SoBuoiDaDay = 0 AND SoBuoiDayThay = 0);
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D05', N'V_GIANGVIEN_TaiTrong: 6 giảng viên; GV01=2,1,4,0; GV02=1,1,2,1; GV05=0,0,0,0',
        CASE WHEN @n = 6 AND @m = 3 THEN 'PASS' ELSE 'FAIL' END,
        N'Số dòng = ' + CAST(@n AS NVARCHAR(10)) + N'; số dòng khớp = ' + CAST(@m AS NVARCHAR(10)));

/* ---------- D06: SP_ThongKeChuyenCan_Lop ---------- */
-- D06a: LOP001 ngưỡng 80 -> 3 dòng, DK002 và DK003 cảnh báo (66.67), DK001 không (100); đứng đầu là người thấp nhất
INSERT INTO #CC EXEC dbo.SP_ThongKeChuyenCan_Lop @MaLop = 'LOP001', @NguongCanhBao = 80;
SELECT @n = COUNT(*) FROM #CC;
SELECT @m = COUNT(*) FROM #CC WHERE CanhBao = 1 AND MaDK IN ('DK002', 'DK003');
SELECT @s1 = MaDK FROM #CC WHERE CanhBao = 0;
SELECT TOP (1) @s2 = MaDK FROM #CC ORDER BY TyLe ASC, MaHV;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D06a', N'SP_ThongKeChuyenCan_Lop(LOP001, 80): 3 dòng, DK002/DK003 cảnh báo, DK001 không',
        CASE WHEN @n = 3 AND @m = 2 AND @s1 = 'DK001' THEN 'PASS' ELSE 'FAIL' END,
        N'Số dòng = ' + CAST(@n AS NVARCHAR(10)) + N'; không cảnh báo = ' + ISNULL(@s1, N'(không có)'));
-- D06b: ngưỡng 60 -> không ai bị cảnh báo
DELETE FROM #CC;
INSERT INTO #CC EXEC dbo.SP_ThongKeChuyenCan_Lop @MaLop = 'LOP001', @NguongCanhBao = 60;
SELECT @n = COUNT(*) FROM #CC WHERE CanhBao = 1;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D06b', N'SP_ThongKeChuyenCan_Lop(LOP001, 60): không có cảnh báo',
        CASE WHEN @n = 0 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng cảnh báo = ' + CAST(@n AS NVARCHAR(10)));
-- D06c: lớp không tồn tại -> 54010
SET @err = NULL; SET @msg = NULL;
BEGIN TRY EXEC dbo.SP_ThongKeChuyenCan_Lop @MaLop = 'LOP999'; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D06c', N'Lớp không tồn tại phải báo lỗi 54010', CASE WHEN @err = 54010 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D06d: ngưỡng ngoài 0..100 -> 54011
SET @err = NULL; SET @msg = NULL;
BEGIN TRY EXEC dbo.SP_ThongKeChuyenCan_Lop @MaLop = 'LOP001', @NguongCanhBao = 150; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D06d', N'Ngưỡng 150 phải báo lỗi 54011', CASE WHEN @err = 54011 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));

/* ---------- D07: SP_LichDay_GiangVien ---------- */
-- D07a: GV02 tháng 2/2026 -> BH0004 (Thứ 3, 19:30, P102, Giảng viên chính), BH0005 (Thứ 6, Hoãn)
INSERT INTO #LD EXEC dbo.SP_LichDay_GiangVien @MaGV = 'GV02', @TuNgay = '2026-02-01', @DenNgay = '2026-02-28';
SELECT @n = COUNT(*) FROM #LD;
SELECT @m = COUNT(*) FROM #LD
WHERE (MaBuoi = 'BH0004' AND Thu = 3 AND Phong = 'P102' AND VaiTro = N'Giảng viên chính' AND GioBD = '19:30')
   OR (MaBuoi = 'BH0005' AND Thu = 6 AND TrangThai = N'Hoãn');
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D07a', N'Lịch GV02 tháng 2/2026: BH0004 (Thứ 3, P102, GV chính), BH0005 (Thứ 6, Hoãn)',
        CASE WHEN @n = 2 AND @m = 2 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@n AS NVARCHAR(10)));
-- D07b: GV02 tháng 1/2026 -> chỉ BH0003 (Thứ 2, P101, Dạy thay)
DELETE FROM #LD;
INSERT INTO #LD EXEC dbo.SP_LichDay_GiangVien @MaGV = 'GV02', @TuNgay = '2026-01-01', @DenNgay = '2026-01-31';
SELECT @n = COUNT(*) FROM #LD WHERE MaBuoi = 'BH0003' AND Thu = 2 AND Phong = 'P101' AND VaiTro = N'Dạy thay';
SELECT @m = COUNT(*) FROM #LD;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D07b', N'Lịch GV02 tháng 1/2026: BH0003 (Thứ 2, P101, Dạy thay)',
        CASE WHEN @n = 1 AND @m = 1 THEN 'PASS' ELSE 'FAIL' END, N'Số dòng = ' + CAST(@m AS NVARCHAR(10)));
-- D07c: gọi không truyền ngày (mặc định tháng hiện tại) không được lỗi
SET @err = NULL; SET @msg = NULL;
BEGIN TRY DELETE FROM #LD; INSERT INTO #LD EXEC dbo.SP_LichDay_GiangVien @MaGV = 'GV01'; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D07c', N'SP_LichDay_GiangVien không truyền ngày vẫn chạy được', CASE WHEN @err IS NULL THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'OK'));
-- D07d: giảng viên không tồn tại -> 54020 ; D07e: khoảng ngày ngược -> 54021
SET @err = NULL; SET @msg = NULL;
BEGIN TRY EXEC dbo.SP_LichDay_GiangVien @MaGV = 'GV99'; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D07d', N'Giảng viên không tồn tại phải báo lỗi 54020', CASE WHEN @err = 54020 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY EXEC dbo.SP_LichDay_GiangVien @MaGV = 'GV02', @TuNgay = '2026-03-01', @DenNgay = '2026-02-01'; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D07e', N'Khoảng ngày ngược phải báo lỗi 54021', CASE WHEN @err = 54021 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));

/* ---------- D08: TRG_DIEMDANH_DungLop (các trường hợp bị từ chối) ---------- */
-- D08a: DK001 thuộc LOP001 nhưng BH0004 là buổi của LOP002 -> 54001
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh) VALUES ('BH0004', 'DK001', N'Có mặt');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D08a', N'Điểm danh học viên sai lớp (INSERT) phải báo lỗi 54001', CASE WHEN @err = 54001 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D08b: BH0005 đang "Hoãn" (DK004 đúng lớp LOP002) -> 54002
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh) VALUES ('BH0005', 'DK004', N'Có mặt');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D08b', N'Điểm danh buổi đang Hoãn phải báo lỗi 54002', CASE WHEN @err = 54002 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D08c: UPDATE đổi đăng ký của một dòng sang học viên lớp khác -> 54001
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.DIEMDANH SET MaDK = 'DK004' WHERE MaBuoi = 'BH0001' AND MaDK = 'DK001';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D08c', N'Đổi đăng ký sang học viên lớp khác (UPDATE) phải báo lỗi 54001', CASE WHEN @err = 54001 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));

/* ---------- D09: TRG_DIEMDANH_DungLop (trường hợp hợp lệ không bị chặn) ----------
   Tạo buổi BH0010 của LOP004 (đã diễn ra), điểm danh DK008 (đúng lớp LOP004) */
SET @err = NULL; SET @msg = NULL; SET @n = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.BUOIHOC (MaBuoi, MaLop, MaGV_Day, NgayHocThucTe, TrangThaiBuoiHoc)
    VALUES ('BH0010', 'LOP004', 'GV04', '2026-03-06', N'Đã diễn ra');
    INSERT INTO dbo.DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh) VALUES ('BH0010', 'DK008', N'Có mặt');
    SELECT @n = COUNT(*) FROM dbo.DIEMDANH WHERE MaBuoi = 'BH0010';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D09', N'Điểm danh đúng lớp, buổi đã diễn ra thì được chấp nhận', CASE WHEN @err IS NULL AND @n = 1 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'OK'));

/* ---------- D10: TRG_GIANGVIEN_NghiViec ---------- */
-- D10a: GV02 là GV chính LOP002 (Đang học) -> 54003
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.GIANGVIEN SET TrangThai = N'Tạm nghỉ' WHERE MaGV = 'GV02';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D10a', N'GV02 còn lớp đang học, chuyển Tạm nghỉ phải báo lỗi 54003', CASE WHEN @err = 54003 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D10b: GV04 là GV chính LOP004 (Đang tuyển sinh) -> 54003 khi chuyển Đã nghỉ việc
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.GIANGVIEN SET TrangThai = N'Đã nghỉ việc' WHERE MaGV = 'GV04';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D10b', N'GV04 còn lớp đang tuyển sinh, chuyển Đã nghỉ việc phải báo lỗi 54003', CASE WHEN @err = 54003 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D10c: GV05 không phụ trách lớp nào -> được phép nghỉ; sửa họ tên GV02 (không đổi trạng thái) -> được phép;
--       GV06 (Tạm nghỉ) quay lại Đang công tác -> được phép
SET @err = NULL; SET @msg = NULL; SET @s1 = NULL; SET @s2 = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.GIANGVIEN SET TrangThai = N'Đã nghỉ việc' WHERE MaGV = 'GV05';
    UPDATE dbo.GIANGVIEN SET HoTen = HoTen WHERE MaGV = 'GV02';
    UPDATE dbo.GIANGVIEN SET TrangThai = N'Đang công tác' WHERE MaGV = 'GV06';
    SELECT @s1 = TrangThai FROM dbo.GIANGVIEN WHERE MaGV = 'GV05';
    SELECT @s2 = TrangThai FROM dbo.GIANGVIEN WHERE MaGV = 'GV06';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D10c', N'GV05 (không có lớp) nghỉ được; sửa GV02 không đổi trạng thái được; GV06 quay lại được',
        CASE WHEN @err IS NULL AND @s1 = N'Đã nghỉ việc' AND @s2 = N'Đang công tác' THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'OK'));

/* ---------- D11: SP_DiemDanh_CaLop (thành công) ---------- */
-- D11a: buổi mới BH0010 (LOP004): lần 1 thêm 1; lần 2 cập nhật 1 (đổi trạng thái + ghi chú)
SET @err = NULL; SET @msg = NULL; SET @n = NULL; SET @s1 = NULL; SET @s2 = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.BUOIHOC (MaBuoi, MaLop, MaGV_Day, NgayHocThucTe, TrangThaiBuoiHoc)
    VALUES ('BH0010', 'LOP004', 'GV04', '2026-03-06', N'Đã diễn ra');
    INSERT INTO #DD EXEC dbo.SP_DiemDanh_CaLop 'BH0010', N'[{"MaDK":"DK008","TrangThai":"Có mặt","GhiChu":null}]';
    INSERT INTO #DD EXEC dbo.SP_DiemDanh_CaLop 'BH0010', N'[{"MaDK":"DK008","TrangThai":"Vắng có phép","GhiChu":"Xin nghỉ"}]';
    SELECT @s1 = TrangThaiDiemDanh, @s2 = GhiChu FROM dbo.DIEMDANH WHERE MaBuoi = 'BH0010' AND MaDK = 'DK008';
    SELECT @n = COUNT(*) FROM dbo.DIEMDANH WHERE MaBuoi = 'BH0010';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
SELECT @m = COUNT(*) FROM #DD WHERE (SoThem = 1 AND SoCapNhat = 0) OR (SoThem = 0 AND SoCapNhat = 1);
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D11a', N'SP_DiemDanh_CaLop: lần 1 thêm 1, lần 2 cập nhật 1 (Vắng có phép, "Xin nghỉ")',
        CASE WHEN @err IS NULL AND @m = 2 AND @n = 1 AND @s1 = N'Vắng có phép' AND @s2 = N'Xin nghỉ' THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(@msg, N'Số dòng thêm/cập nhật khớp = ' + CAST(@m AS NVARCHAR(10))));
-- D11b: sửa điểm danh buổi cũ BH0001 (3 học viên LOP001) -> cập nhật 3, thêm 0
DELETE FROM #DD;
SET @err = NULL; SET @msg = NULL; SET @s1 = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO #DD EXEC dbo.SP_DiemDanh_CaLop 'BH0001',
        N'[{"MaDK":"DK001","TrangThai":"Vắng không phép"},{"MaDK":"DK002","TrangThai":"Có mặt"},{"MaDK":"DK003","TrangThai":"Có mặt"}]';
    SELECT @s1 = TrangThaiDiemDanh FROM dbo.DIEMDANH WHERE MaBuoi = 'BH0001' AND MaDK = 'DK001';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D11b', N'SP_DiemDanh_CaLop: sửa buổi BH0001 -> cập nhật 3, thêm 0, DK001 thành Vắng không phép',
        CASE WHEN @err IS NULL AND EXISTS (SELECT 1 FROM #DD WHERE SoThem = 0 AND SoCapNhat = 3) AND @s1 = N'Vắng không phép' THEN 'PASS' ELSE 'FAIL' END,
        ISNULL(@msg, N'OK'));

/* ---------- D12: SP_DiemDanh_CaLop (các lỗi, mỗi ca bắt đúng mã lỗi) ---------- */
-- D12a: một dòng sai lớp (DK001 thuộc LOP001, buổi BH0007 thuộc LOP004) -> 54036, buổi BH0007 không đổi
SET @err = NULL; SET @msg = NULL; SET @s1 = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'[{"MaDK":"DK008","TrangThai":"Vắng có phép"},{"MaDK":"DK001","TrangThai":"Có mặt"}]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    SELECT @s1 = TrangThaiDiemDanh FROM dbo.DIEMDANH WHERE MaBuoi = 'BH0007' AND MaDK = 'DK008';  -- trước khi rollback
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12a', N'Điểm danh có một dòng sai lớp: lỗi 54036 và buổi BH0007 không bị đổi (DK008 vẫn Có mặt)',
        CASE WHEN @err = 54036 AND @s1 = N'Có mặt' THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12b: buổi Hoãn -> 54031
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0005', N'[{"MaDK":"DK004","TrangThai":"Có mặt"}]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12b', N'Buổi Hoãn phải báo lỗi 54031', CASE WHEN @err = 54031 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12c: trạng thái sai -> 54035
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'[{"MaDK":"DK008","TrangThai":"Đi trễ"}]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12c', N'Trạng thái "Đi trễ" phải báo lỗi 54035', CASE WHEN @err = 54035 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12d: buổi không tồn tại -> 54030
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH9999', N'[{"MaDK":"DK008","TrangThai":"Có mặt"}]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12d', N'Buổi không tồn tại phải báo lỗi 54030', CASE WHEN @err = 54030 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12e: không phải JSON -> 54032
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'đây không phải json';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12e', N'Chuỗi không phải JSON phải báo lỗi 54032', CASE WHEN @err = 54032 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12f: danh sách rỗng -> 54033
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'[]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12f', N'Danh sách rỗng phải báo lỗi 54033', CASE WHEN @err = 54033 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12g: trùng mã đăng ký -> 54034
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', N'[{"MaDK":"DK008","TrangThai":"Có mặt"},{"MaDK":"DK008","TrangThai":"Vắng có phép"}]';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12g', N'Trùng mã đăng ký trong danh sách phải báo lỗi 54034', CASE WHEN @err = 54034 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D12h: ghi chú dài 101 ký tự -> 54037
SET @err = NULL; SET @msg = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @json NVARCHAR(MAX) = N'[{"MaDK":"DK008","TrangThai":"Có mặt","GhiChu":"' + REPLICATE(N'x', 101) + N'"}]';
    EXEC dbo.SP_DiemDanh_CaLop 'BH0007', @json;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D12h', N'Ghi chú quá 100 ký tự phải báo lỗi 54037', CASE WHEN @err = 54037 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));

/* ---------- D13: SP_BanGiaoLop_KhiGVNghi ---------- */
-- D13a: GV01 -> GV02 (cùng tiếng Anh): bàn giao 1 lớp (LOP001), LOP005 (đã kết thúc) vẫn GV01, GV01 thành Đã nghỉ việc
SET @err = NULL; SET @msg = NULL; SET @s1 = NULL; SET @s2 = NULL; SET @n = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO #BG EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV02';
    SELECT @s1 = MaGV_Chinh FROM dbo.LOP WHERE MaLop = 'LOP001';
    SELECT @s2 = MaGV_Chinh FROM dbo.LOP WHERE MaLop = 'LOP005';
    SELECT @msg = TrangThai FROM dbo.GIANGVIEN WHERE MaGV = 'GV01';
    SELECT @n = SoLop FROM #BG;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13a', N'Bàn giao GV01 -> GV02: 1 lớp; LOP001 sang GV02; LOP005 vẫn GV01; GV01 Đã nghỉ việc',
        CASE WHEN @err IS NULL AND @n = 1 AND @s1 = 'GV02' AND @s2 = 'GV01' AND @msg = N'Đã nghỉ việc' THEN 'PASS' ELSE 'FAIL' END,
        N'SoLop=' + ISNULL(CAST(@n AS NVARCHAR(10)), N'NULL') + N'; LOP001=' + ISNULL(@s1, N'NULL') + N'; LOP005=' + ISNULL(@s2, N'NULL') + N'; ' + ISNULL(@msg, N''));
-- D13b: GV05 không có lớp, không cần người nhận, trạng thái Tạm nghỉ
SET @err = NULL; SET @msg = NULL; SET @n = NULL; DELETE FROM #BG;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO #BG EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV05', @TrangThaiMoi = N'Tạm nghỉ';
    SELECT @n = SoLop FROM #BG;
    SELECT @msg = TrangThai FROM dbo.GIANGVIEN WHERE MaGV = 'GV05';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13b', N'GV05 không có lớp: nghỉ không cần người nhận (SoLop=0, Tạm nghỉ)',
        CASE WHEN @err IS NULL AND @n = 0 AND @msg = N'Tạm nghỉ' THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N''));
-- D13c..h: các lỗi
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV99', @MaGV_Moi = 'GV02'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13c', N'Giảng viên nghỉ không tồn tại phải báo lỗi 54040', CASE WHEN @err = 54040 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV02', @TrangThaiMoi = N'Nghỉ'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13d', N'Trạng thái mới không hợp lệ phải báo lỗi 54041', CASE WHEN @err = 54041 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV01'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13e', N'Người nhận trùng người nghỉ phải báo lỗi 54042', CASE WHEN @err = 54042 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13f', N'GV01 còn lớp mà không chỉ định người nhận phải báo lỗi 54043', CASE WHEN @err = 54043 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV03'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13g', N'Người nhận khác ngôn ngữ (GV03 dạy tiếng Nhật) phải báo lỗi 54044', CASE WHEN @err = 54044 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
SET @err = NULL; SET @msg = NULL;
BEGIN TRY BEGIN TRANSACTION; EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV06'; ROLLBACK TRANSACTION; END TRY
BEGIN CATCH SET @err = ERROR_NUMBER(); SET @msg = ERROR_MESSAGE(); IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13h', N'Người nhận đang Tạm nghỉ (GV06) phải báo lỗi 54044', CASE WHEN @err = 54044 THEN 'PASS' ELSE 'FAIL' END, ISNULL(@msg, N'Không có lỗi'));
-- D13i: lỗi giữa chừng được hoàn tác: giao dịch ngoài vẫn dùng được sau lỗi (rollback về điểm lưu), LOP001 không đổi
SET @err = NULL; SET @s1 = NULL; SET @m = NULL;
BEGIN TRY
    BEGIN TRANSACTION;
    BEGIN TRY
        EXEC dbo.SP_BanGiaoLop_KhiGVNghi @MaGV_Nghi = 'GV01', @MaGV_Moi = 'GV03';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_NUMBER();
    END CATCH;
    SELECT @s1 = MaGV_Chinh FROM dbo.LOP WHERE MaLop = 'LOP001';
    SET @m = XACT_STATE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D13i', N'Gọi trong giao dịch ngoài: lỗi 54044 và LOP001 vẫn thuộc GV01',
        CASE WHEN @err = 54044 AND @s1 = 'GV01' THEN 'PASS' ELSE 'FAIL' END,
        N'Lỗi = ' + ISNULL(CAST(@err AS NVARCHAR(10)), N'NULL') + N'; LOP001 = ' + ISNULL(@s1, N'NULL') + N'; XACT_STATE = ' + ISNULL(CAST(@m AS NVARCHAR(5)), N'NULL'));

/* ---------- D14: dữ liệu mẫu không bị đổi sau toàn bộ các ca ---------- */
SELECT @n = COUNT(*) FROM dbo.DIEMDANH;
SELECT @m = COUNT(*) FROM dbo.BUOIHOC;
SELECT @s1 = MaGV_Chinh FROM dbo.LOP WHERE MaLop = 'LOP001';
SELECT @s2 = TrangThai FROM dbo.GIANGVIEN WHERE MaGV = 'GV01';
INSERT INTO #KQ (Ma, MoTa, KetQua, ChiTiet)
VALUES ('D14', N'Dữ liệu mẫu không đổi: 18 dòng điểm danh, 9 buổi học, LOP001 vẫn GV01, GV01 vẫn Đang công tác',
        CASE WHEN @n = 18 AND @m = 9 AND @s1 = 'GV01' AND @s2 = N'Đang công tác' THEN 'PASS' ELSE 'FAIL' END,
        N'DIEMDANH=' + CAST(@n AS NVARCHAR(10)) + N'; BUOIHOC=' + CAST(@m AS NVARCHAR(10)));

/* ---------- KẾT QUẢ ---------- */
SELECT STT, Ma, MoTa, KetQua, ChiTiet FROM #KQ ORDER BY STT;
SELECT SUM(CASE WHEN KetQua = 'PASS' THEN 1 ELSE 0 END) AS SoCaPASS,
       SUM(CASE WHEN KetQua = 'FAIL' THEN 1 ELSE 0 END) AS SoCaFAIL,
       COUNT(*) AS TongSoCa
FROM #KQ;
DROP TABLE #KQ; DROP TABLE #CC; DROP TABLE #LD; DROP TABLE #DD; DROP TABLE #BG;
GO
