/* =========================================================
   DỮ LIỆU MẪU - CSDL QUẢN LÝ TRUNG TÂM NGOẠI NGỮ
   Database: QL_TTNgoaiNgu
   ========================================================= */

USE QL_TTNgoaiNgu;
GO

-- =========================================================
-- 1. NGONNGU
-- =========================================================
INSERT INTO NGONNGU (MaNN, TenNN) VALUES
('ANH', N'Tiếng Anh'),
('NHA', N'Tiếng Nhật'),
('HAN', N'Tiếng Hàn'),
('TRU', N'Tiếng Trung');
GO

-- =========================================================
-- 2. HOCVIEN
-- =========================================================
INSERT INTO HOCVIEN (MaHV, HoTen, NgaySinh, SDT, Email, DiaChi) VALUES
('HV001', N'Nguyễn Thị Lan',    '2001-03-12', '0901000001', 'lan.nguyen01@email.com',  N'12 Lê Lợi, Q1, TP.HCM'),
('HV002', N'Trần Văn Minh',     '2000-07-25', '0901000002', 'minh.tran02@email.com',   N'45 Nguyễn Trãi, Q5, TP.HCM'),
('HV003', N'Lê Thị Hoa',        '2002-01-09', '0901000003', 'hoa.le03@email.com',      N'78 Cách Mạng Tháng 8, Q3, TP.HCM'),
('HV004', N'Phạm Văn Đức',      '1999-11-30', '0901000004', 'duc.pham04@email.com',    N'23 Trần Hưng Đạo, Q1, TP.HCM'),
('HV005', N'Hoàng Thị Mai',     '2003-05-18', '0901000005', 'mai.hoang05@email.com',   N'56 Võ Văn Tần, Q3, TP.HCM'),
('HV006', N'Vũ Văn Nam',        '2001-09-02', '0901000006', 'nam.vu06@email.com',      N'89 Nguyễn Đình Chiểu, Q3, TP.HCM'),
('HV007', N'Đặng Thị Thu',      '2002-12-14', '0901000007', 'thu.dang07@email.com',    N'34 Điện Biên Phủ, Bình Thạnh, TP.HCM'),
('HV008', N'Bùi Văn Tùng',      '2000-04-22', '0901000008', 'tung.bui08@email.com',    N'67 Phan Xích Long, Phú Nhuận, TP.HCM'),
('HV009', N'Ngô Thị Ngọc',      '2001-08-07', '0901000009', 'ngoc.ngo09@email.com',    N'19 Hoàng Văn Thụ, Tân Bình, TP.HCM'),
('HV010', N'Đỗ Văn Phúc',       '1998-02-28', '0901000010', 'phuc.do10@email.com',     N'52 Lý Thường Kiệt, Q10, TP.HCM');
GO

-- =========================================================
-- 3. GIANGVIEN
-- =========================================================
INSERT INTO GIANGVIEN (MaGV, HoTen, MaNN, SDT, Email, TrangThai) VALUES
('GV01', N'Nguyễn Văn An',      'ANH', '0912000001', 'an.nguyen@ttnn.edu.vn',   N'Đang công tác'),
('GV02', N'Trần Thị Bích',      'ANH', '0912000002', 'bich.tran@ttnn.edu.vn',   N'Đang công tác'),
('GV03', N'Lê Văn Cường',       'NHA', '0912000003', 'cuong.le@ttnn.edu.vn',    N'Đang công tác'),
('GV04', N'Phạm Thị Diễm',      'HAN', '0912000004', 'diem.pham@ttnn.edu.vn',   N'Đang công tác'),
('GV05', N'Hoàng Văn Em',       'TRU', '0912000005', 'em.hoang@ttnn.edu.vn',    N'Đang công tác'),
('GV06', N'Đỗ Thị Phượng',      'ANH', '0912000006', 'phuong.do@ttnn.edu.vn',   N'Tạm nghỉ');
GO

-- =========================================================
-- 4. KHOAHOC
-- =========================================================
-- Lưu ý: TrinhDo đang khai báo VARCHAR (không phải NVARCHAR) trong schema gốc,
-- nên dùng giá trị không dấu để tránh lỗi hiển thị ký tự tiếng Việt.
INSERT INTO KHOAHOC (MaKH, TenKhoa, MaNN, TrinhDo, SoBuoi, HocPhi, TrangThai) VALUES
('KH0001', N'Anh giao tiếp cơ bản', 'ANH', 'So cap',    24, 3000000, N'Đang giảng dạy'),
('KH0002', N'Luyện thi TOEIC',      'ANH', 'Trung cap', 30, 4500000, N'Đang giảng dạy'),
('KH0003', N'Tiếng Nhật N5',        'NHA', 'So cap',    36, 3500000, N'Đang giảng dạy'),
('KH0004', N'Tiếng Hàn sơ cấp',     'HAN', 'So cap',    30, 3200000, N'Đang giảng dạy'),
('KH0005', N'Tiếng Trung HSK1',     'TRU', 'So cap',    28, 3000000, N'Ngừng tuyển sinh');
GO

-- =========================================================
-- 5. LOP
-- =========================================================
INSERT INTO LOP (MaLop, MaKH, MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa, TrangThai) VALUES
('LOP001', 'KH0001', 'GV01', '2026-01-05', '2026-04-05', 20, N'Đang học'),
('LOP002', 'KH0002', 'GV02', '2026-02-01', '2026-05-30', 15, N'Đang học'),
('LOP003', 'KH0003', 'GV03', '2026-01-10', '2026-06-10', 18, N'Đang học'),
('LOP004', 'KH0004', 'GV04', '2026-03-01', '2026-06-01', 20, N'Đang tuyển sinh'),
('LOP005', 'KH0001', 'GV01', '2025-09-01', '2025-12-01', 20, N'Đã kết thúc');
GO

-- =========================================================
-- 6. DANGKY
-- =========================================================
INSERT INTO DANGKY (MaDK, MaHV, MaLop, NgayDangKy, DiemCuoiKy) VALUES
('DK001', 'HV001', 'LOP001', '2025-12-20', NULL),
('DK002', 'HV002', 'LOP001', '2025-12-20', NULL),
('DK003', 'HV003', 'LOP001', '2025-12-22', NULL),
('DK004', 'HV004', 'LOP002', '2026-01-25', NULL),
('DK005', 'HV005', 'LOP002', '2026-01-26', NULL),
('DK006', 'HV006', 'LOP003', '2025-12-30', NULL),
('DK007', 'HV007', 'LOP003', '2026-01-02', NULL),
('DK008', 'HV008', 'LOP004', '2026-02-20', NULL),
('DK009', 'HV009', 'LOP005', '2025-08-25', 8.5),
('DK010', 'HV010', 'LOP005', '2025-08-26', 7.0);
GO

-- =========================================================
-- 7. HOADON
-- =========================================================
INSERT INTO HOADON (MaHD, MaDK, SoTienCanThu, SoTienDaThu, NgayThanhToan, TrangThaiThanhToan) VALUES
('HD001', 'DK001', 3000000, 3000000, '2025-12-21', N'Đã thanh toán đủ'),
('HD002', 'DK002', 3000000, 1500000, '2025-12-22', N'Thanh toán một phần'),
('HD003', 'DK003', 3000000, 0,       NULL,          N'Chưa thanh toán'),
('HD004', 'DK004', 4500000, 4500000, '2026-01-26', N'Đã thanh toán đủ'),
('HD005', 'DK005', 4500000, 2000000, '2026-01-27', N'Thanh toán một phần'),
('HD006', 'DK006', 3500000, 3500000, '2025-12-31', N'Đã thanh toán đủ'),
('HD007', 'DK007', 3500000, 0,       NULL,          N'Chưa thanh toán'),
('HD008', 'DK008', 3200000, 1000000, '2026-02-21', N'Thanh toán một phần'),
('HD009', 'DK009', 3000000, 3000000, '2025-08-26', N'Đã thanh toán đủ'),
('HD010', 'DK010', 3000000, 3000000, '2025-08-27', N'Đã thanh toán đủ');
GO

-- =========================================================
-- 8. LICHHOC
-- Quy ước Thu: Chủ Nhật = 1, Thứ 2 = 2, ..., Thứ 7 = 7 (khớp DATEPART(dw,...) mặc định)
-- =========================================================
INSERT INTO LICHHOC (MaLich, MaLop, Thu, GioBatDau, GioKetThuc, PhongHoc) VALUES
('LH001', 'LOP001', 2, '18:00', '19:30', 'P101'),  -- Thứ 2
('LH002', 'LOP001', 5, '18:00', '19:30', 'P101'),  -- Thứ 5
('LH003', 'LOP002', 3, '19:30', '21:00', 'P102'),  -- Thứ 3
('LH004', 'LOP002', 6, '19:30', '21:00', 'P102'),  -- Thứ 6
('LH005', 'LOP003', 2, '08:00', '09:30', 'P201'),  -- Thứ 2
('LH006', 'LOP003', 4, '08:00', '09:30', 'P201'),  -- Thứ 4
('LH007', 'LOP004', 3, '18:00', '19:30', 'P103'),  -- Thứ 3
('LH008', 'LOP004', 6, '18:00', '19:30', 'P103'),  -- Thứ 6
('LH009', 'LOP005', 2, '19:30', '21:00', 'P104'),  -- Thứ 2 (lớp đã kết thúc)
('LH010', 'LOP005', 5, '19:30', '21:00', 'P104');  -- Thứ 5
GO

-- =========================================================
-- 9. BUOIHOC
-- =========================================================
INSERT INTO BUOIHOC (MaBuoi, MaLop, MaGV_Day, NgayHocThucTe, TrangThaiBuoiHoc) VALUES
('BH0001', 'LOP001', 'GV01', '2026-01-05', N'Đã diễn ra'),
('BH0002', 'LOP001', 'GV01', '2026-01-08', N'Đã diễn ra'),
('BH0003', 'LOP001', 'GV02', '2026-01-12', N'Đã diễn ra'),   -- GV02 dạy thay
('BH0004', 'LOP002', 'GV02', '2026-02-03', N'Đã diễn ra'),
('BH0005', 'LOP002', 'GV02', '2026-02-06', N'Hoãn'),
('BH0006', 'LOP003', 'GV03', '2026-01-12', N'Đã diễn ra'),
('BH0007', 'LOP004', 'GV04', '2026-03-03', N'Đã diễn ra'),
('BH0008', 'LOP005', 'GV01', '2025-09-01', N'Đã diễn ra'),
('BH0009', 'LOP005', 'GV01', '2025-09-04', N'Đã diễn ra');
GO

-- =========================================================
-- 10. DIEMDANH
-- =========================================================
INSERT INTO DIEMDANH (MaBuoi, MaDK, TrangThaiDiemDanh, GhiChu) VALUES
('BH0001', 'DK001', N'Có mặt', NULL),
('BH0001', 'DK002', N'Có mặt', NULL),
('BH0001', 'DK003', N'Có mặt', NULL),
('BH0002', 'DK001', N'Có mặt', NULL),
('BH0002', 'DK002', N'Vắng có phép', N'Xin nghỉ ốm'),
('BH0002', 'DK003', N'Có mặt', NULL),
('BH0003', 'DK001', N'Có mặt', NULL),
('BH0003', 'DK002', N'Có mặt', NULL),
('BH0003', 'DK003', N'Vắng không phép', NULL),
('BH0004', 'DK004', N'Có mặt', NULL),
('BH0004', 'DK005', N'Có mặt', NULL),
('BH0006', 'DK006', N'Có mặt', NULL),
('BH0006', 'DK007', N'Vắng có phép', N'Bận việc gia đình'),
('BH0007', 'DK008', N'Có mặt', NULL),
('BH0008', 'DK009', N'Có mặt', NULL),
('BH0008', 'DK010', N'Có mặt', NULL),
('BH0009', 'DK009', N'Có mặt', NULL),
('BH0009', 'DK010', N'Vắng không phép', NULL);
GO

-- =========================================================
-- 11. KIỂM TRA SỐ DÒNG DỮ LIỆU
-- =========================================================
SELECT 'NGONNGU' AS BangDuLieu, COUNT(*) AS SoDong FROM NGONNGU
UNION ALL SELECT 'HOCVIEN', COUNT(*) FROM HOCVIEN
UNION ALL SELECT 'GIANGVIEN', COUNT(*) FROM GIANGVIEN
UNION ALL SELECT 'KHOAHOC', COUNT(*) FROM KHOAHOC
UNION ALL SELECT 'LOP', COUNT(*) FROM LOP
UNION ALL SELECT 'DANGKY', COUNT(*) FROM DANGKY
UNION ALL SELECT 'HOADON', COUNT(*) FROM HOADON
UNION ALL SELECT 'LICHHOC', COUNT(*) FROM LICHHOC
UNION ALL SELECT 'BUOIHOC', COUNT(*) FROM BUOIHOC
UNION ALL SELECT 'DIEMDANH', COUNT(*) FROM DIEMDANH;
GO