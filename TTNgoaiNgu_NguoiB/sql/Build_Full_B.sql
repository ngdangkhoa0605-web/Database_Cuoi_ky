/* =====================================================================
   BUILD_FULL_B.sql  -  FILE CHAY MOT LAN TREN MAY TRANG
   Sinh vien thuc hien module B: Nguyễn Đăng Khoa - MSSV 24110255
   Thu tu: (1) schema cua Nguoi A  ->  (2) du lieu mau cua Nguoi A  ->  (3) Module B.
   LUU Y: schema cua Nguoi A bat dau bang DROP DATABASE QL_TTNgoaiNgu neu da ton tai
          => chay file nay se XOA va TAO LAI CSDL. Chi chay tren may thu nghiem.
   File duoc ghep tu: nguoi_A/QLTTNgoaiNgu.sql, nguoi_A/DataQLTTNgoaiNgu.sql,
                      nguoi_B/Module_B_HocVien_TaiChinh.sql   (khong sua noi dung).
   Khi ghep nhom, Kien se them 3 module cua A/C/D vao SAU module B (cac module doc lap).
   ===================================================================== */

/* ########## (1) SCHEMA - NGUOI A ########## */
USE master;
GO

IF DB_ID('QL_TTNgoaiNgu') IS NOT NULL
BEGIN
    ALTER DATABASE QL_TTNgoaiNgu
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE QL_TTNgoaiNgu;
END
GO

CREATE DATABASE QL_TTNgoaiNgu;
GO

USE QL_TTNgoaiNgu;
GO

-- 1. BẢNG NGONNGU
CREATE TABLE NGONNGU
(
    MaNN        CHAR(3)          NOT NULL,
    TenNN       NVARCHAR(30)     NOT NULL,

    -- MaNN là khóa chính bảng NGONNGU
    CONSTRAINT PK_NGONNGU PRIMARY KEY (MaNN),

    -- Tên ngôn ngữ không được trùng
    CONSTRAINT UQ_NGONNGU_TENNN UNIQUE (TenNN)
);
GO

-- 2. BẢNG HOCVIEN

CREATE TABLE HOCVIEN
(
    MaHV        CHAR(5)          NOT NULL,
    HoTen       NVARCHAR(40)     NOT NULL,
    NgaySinh    DATE             NOT NULL,
    SDT         VARCHAR(15)      NOT NULL,
    Email       VARCHAR(50)      NOT NULL,
    DiaChi      NVARCHAR(100)    NOT NULL,

    -- MaHV là khóa chính bảng HOCVIEN
    CONSTRAINT PK_HOCVIEN PRIMARY KEY (MaHV),

    -- SDT không được trùng
    CONSTRAINT UQ_HOCVIEN_SDT UNIQUE (SDT),

    -- email không được trùng
    CONSTRAINT UQ_HOCVIEN_EMAIL UNIQUE (Email)
);
GO

-- 4. BẢNG GIANGVIEN

CREATE TABLE GIANGVIEN
(
    MaGV        CHAR(4)          NOT NULL,
    HoTen       NVARCHAR(40)     NOT NULL,
    MaNN        CHAR(3)          NOT NULL,
    SDT         VARCHAR(15)      NOT NULL,
    Email       VARCHAR(50)      NOT NULL,
    TrangThai   NVARCHAR(20)     NOT NULL DEFAULT (N'Đang công tác'),

    -- MaGV là khóa chính
    CONSTRAINT PK_GIANGVIEN PRIMARY KEY (MaGV),

    -- MaNN tham chiếu đến bảng NGONNGU
    CONSTRAINT FK_GIANGVIEN_NGONNGU FOREIGN KEY (MaNN) REFERENCES NGONNGU(MaNN),

    -- SDT không được trùng
    CONSTRAINT UQ_GIANGVIEN_SDT UNIQUE (SDT),

    -- email không được trùng
    CONSTRAINT UQ_GIANGVIEN_EMAIL UNIQUE (Email),

     -- Giới hạn trạng thái công tác hợp lệ
    CONSTRAINT CK_GIANGVIEN_TRANGTHAI
        CHECK (TrangThai IN (N'Đang công tác', N'Tạm nghỉ', N'Đã nghỉ việc'))
);
GO

-- 4. BẢNG KHOAHOC

CREATE TABLE KHOAHOC
(
    MaKH        VARCHAR(6)       NOT NULL,
    TenKhoa     NVARCHAR(50)     NOT NULL,
    MaNN        CHAR(3)          NOT NULL,
    TrinhDo     NVARCHAR(10)     NOT NULL,
    SoBuoi      TINYINT          NOT NULL,
    HocPhi      MONEY            NOT NULL,
    TrangThai   NVARCHAR(20)     NOT NULL,

    -- Mã khóa học là khóa chính
    CONSTRAINT PK_KHOAHOC PRIMARY KEY (MaKH),

    -- MaNN Tham chiếu tới NGONNGU
    CONSTRAINT FK_KHOAHOC_NGONNGU FOREIGN KEY (MaNN) REFERENCES NGONNGU(MaNN),

    -- Số buổi của khóa học phải lớn hơn 0
    CONSTRAINT CK_KHOAHOC_SOBUOI CHECK (SoBuoi > 0),

    -- Học phí không được âm
    CONSTRAINT CK_KHOAHOC_HOCPHI CHECK (HocPhi >= 0),

    -- Trạng thái khóa học chỉ gồm Đang giảng dạy hoặc Ngừng tuyển sinh
    CONSTRAINT CK_KHOAHOC_TRANGTHAI
        CHECK (TrangThai IN (N'Đang giảng dạy', N'Ngừng tuyển sinh'))
);
GO

-- 5. BẢNG LOP

CREATE TABLE LOP
(
    MaLop           VARCHAR(6)       NOT NULL,
    MaKH            VARCHAR(6)       NOT NULL,
    MaGV_Chinh      CHAR(4)          NOT NULL,
    NgayKhaiGiang   DATE             NOT NULL,
    NgayKetThuc     DATE             NOT NULL,
    SiSoToiDa       TINYINT          NOT NULL,
    TrangThai       NVARCHAR(20)     NOT NULL DEFAULT (N'Đang tuyển sinh'),

    -- Mã lớp là khóa chính định danh lớp học
    CONSTRAINT PK_LOP PRIMARY KEY (MaLop),

    -- MaKH Tham chiếu tới KHOAHOC, lớp học phải thuộc một khóa học cụ thể
    CONSTRAINT FK_LOP_KHOAHOC FOREIGN KEY (MaKH) REFERENCES KHOAHOC(MaKH),

    -- MaGV Tham chiếu tới GIANGVIEN, giáo viên chủ nhiệm/chính của lớp phải tồn tại
    CONSTRAINT FK_LOP_GIANGVIEN FOREIGN KEY (MaGV_Chinh) REFERENCES GIANGVIEN(MaGV),

    -- Ngày bế giảng phải sau ngày khai giảng
    CONSTRAINT CK_LOP_NGAY CHECK (NgayKetThuc > NgayKhaiGiang),

    -- Sĩ số lớp phải là số nguyên dương
    CONSTRAINT CK_LOP_SISOTOIDA CHECK (SiSoToiDa > 0),

    -- Các giai đoạn hợp lệ của một lớp học
    CONSTRAINT CK_LOP_TRANGTHAI
        CHECK (TrangThai IN (N'Đang tuyển sinh', N'Đang học', N'Đã kết thúc'))
);
GO

-- 6. BẢNG DANGKY
CREATE TABLE DANGKY
(
    MaDK         VARCHAR(8)      NOT NULL,
    MaHV         CHAR(5)         NOT NULL,
    MaLop        VARCHAR(6)      NOT NULL,
    NgayDangKy   DATE            NOT NULL DEFAULT (GETDATE()),
    DiemCuoiKy   NUMERIC(4,2)    NULL,

    -- Mã đăng ký là khóa chính
    CONSTRAINT PK_DANGKY PRIMARY KEY (MaDK),

    -- MaHV tham chiếu đến HOCVIEN Học viên đăng ký phải tồn tại trong bảng HOCVIEN
    CONSTRAINT FK_DANGKY_HOCVIEN FOREIGN KEY (MaHV) REFERENCES HOCVIEN(MaHV),

    -- Lớp đăng ký phải tồn tại trong bảng LOP
    CONSTRAINT FK_DANGKY_LOP FOREIGN KEY (MaLop) REFERENCES LOP(MaLop),

    -- Một học viên không được đăng ký cùng một lớp 2 lần
    CONSTRAINT UQ_DANGKY_HOCVIEN_LOP UNIQUE (MaHV, MaLop),

    -- Điểm cuối kỳ có thể để trống (NULL - chưa thi) hoặc nằm trong thang điểm 0 đến 10
    CONSTRAINT CK_DANGKY_DIEM
        CHECK (DiemCuoiKy IS NULL OR DiemCuoiKy BETWEEN 0 AND 10)
);
GO

-- 7. BẢNG HOADON
CREATE TABLE HOADON
(
    MaHD                  VARCHAR(8)       NOT NULL,
    MaDK                  VARCHAR(8)       NOT NULL,
    SoTienCanThu          MONEY            NOT NULL,
    SoTienDaThu           MONEY            NOT NULL DEFAULT (0),
    NgayThanhToan         DATE             NULL,
    TrangThaiThanhToan    NVARCHAR(30)     NOT NULL DEFAULT (N'Chưa thanh toán'),

    -- Mã hóa đơn là khóa chính
    CONSTRAINT PK_HOADON PRIMARY KEY (MaHD),

    -- Tham chiếu tới DANGKY, mỗi hóa đơn gắn chặt với 1 phiếu đăng ký
    CONSTRAINT FK_HOADON_DANGKY FOREIGN KEY (MaDK) REFERENCES DANGKY(MaDK),

    -- Mỗi phiếu đăng ký chỉ có một hóa đơn
    CONSTRAINT UQ_HOADON_MADK UNIQUE (MaDK),

    -- Kiểm tra tài chính: Tiền không âm và số tiền đã thu không vượt quá mức cần thu
    CONSTRAINT CK_HOADON_SOTIEN
        CHECK (SoTienCanThu >= 0 AND SoTienDaThu >= 0 AND SoTienDaThu <= SoTienCanThu),

    -- Các trạng thái thanh toán hợp lệ của hóa đơn
    CONSTRAINT CK_HOADON_TRANGTHAI
        CHECK (TrangThaiThanhToan IN (N'Chưa thanh toán', N'Thanh toán một phần', N'Đã thanh toán đủ'))
);
GO

-- 8. BẢNG LICHHOC
CREATE TABLE LICHHOC
(
    MaLich       VARCHAR(8)      NOT NULL,
    MaLop        VARCHAR(6)      NOT NULL,
    Thu          TINYINT         NOT NULL,
    GioBatDau    TIME            NOT NULL,
    GioKetThuc   TIME            NOT NULL,
    PhongHoc     VARCHAR(10)     NOT NULL,

    -- Mã lịch học là khóa chính
    CONSTRAINT PK_LICHHOC PRIMARY KEY (MaLich),

    -- Tham chiếu tới LOP, lịch học phải thuộc về một lớp xác định
    CONSTRAINT FK_LICHHOC_LOP FOREIGN KEY (MaLop) REFERENCES LOP(MaLop),

    -- Một lớp không được có hai lịch giống nhau
    CONSTRAINT UQ_LICHHOC UNIQUE (MaLop, Thu, GioBatDau),

    -- Hai lớp khác nhau không được học chung 1 phòng vào cùng 1 thời điểm
    CONSTRAINT UQ_LICHHOC_PHONG UNIQUE (PhongHoc, Thu, GioBatDau),

    -- Chủ Nhật = 1, Thứ 2 = 2,... Thứ 7 = 7
    CONSTRAINT CK_LICHHOC_THU CHECK (Thu BETWEEN 1 AND 7),

    -- Thời gian kết thúc ca học phải diễn ra sau giờ bắt đầu
    CONSTRAINT CK_LICHHOC_GIO CHECK (GioKetThuc > GioBatDau)
);
GO

-- 9. BẢNG BUOIHOC
CREATE TABLE BUOIHOC
(
    MaBuoi              VARCHAR(8)       NOT NULL,
    MaLop               VARCHAR(6)       NOT NULL,
    MaGV_Day            CHAR(4)          NOT NULL,
    NgayHocThucTe       DATE             NOT NULL,
    TrangThaiBuoiHoc    NVARCHAR(20)     NOT NULL,

    -- Mã buổi học là khóa chính
    CONSTRAINT PK_BUOIHOC PRIMARY KEY (MaBuoi),

    -- Tham chiếu tới LOP, buổi học phải gắn với một lớp xác định
    CONSTRAINT FK_BUOIHOC_LOP FOREIGN KEY (MaLop) REFERENCES LOP(MaLop),

    -- Tham chiếu tới GIANGVIEN, ghi nhận giáo viên đứng lớp thực tế (có thể dạy thay)
    CONSTRAINT FK_BUOIHOC_GIANGVIEN FOREIGN KEY (MaGV_Day) REFERENCES GIANGVIEN(MaGV),

    -- Trạng thái thực tế của buổi học
    CONSTRAINT CK_BUOIHOC_TRANGTHAI CHECK (TrangThaiBuoiHoc IN (N'Đã diễn ra', N'Hoãn', N'Hủy'))
);
GO

-- 10. BẢNG DIEMDANH
CREATE TABLE DIEMDANH
(
    MaBuoi              VARCHAR(8)       NOT NULL,
    MaDK                VARCHAR(8)       NOT NULL,
    TrangThaiDiemDanh   NVARCHAR(20)     NOT NULL,
    GhiChu              NVARCHAR(100)    NULL,

    -- Khóa chính phức hợp gồm (MaBuoi, MaDK), mỗi học viên chỉ có 1 lượt điểm danh/buổi
    CONSTRAINT PK_DIEMDANH PRIMARY KEY (MaBuoi, MaDK),

    -- Tham chiếu BUOIHOC, việc điểm danh phải gắn vào buổi học có thật
    CONSTRAINT FK_DIEMDANH_BUOIHOC FOREIGN KEY (MaBuoi) REFERENCES BUOIHOC(MaBuoi),

    -- Tham chiếu DANGKY, điểm danh cho đúng lượt học viên đã ghi danh
    CONSTRAINT FK_DIEMDANH_DANGKY FOREIGN KEY (MaDK) REFERENCES DANGKY(MaDK),

    -- Trạng thái điểm danh hợp lệ của học viên
    CONSTRAINT CK_DIEMDANH_TRANGTHAI
        CHECK (TrangThaiDiemDanh IN (N'Có mặt', N'Vắng có phép', N'Vắng không phép'))
);
GO

-- KIỂM TRA CÁC BẢNG

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
/* ########## (2) DU LIEU MAU - NGUOI A ########## */
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
/* ########## (3) MODULE B - HOC VIEN VA TAI CHINH ########## */
/* =====================================================================
   MODULE B - HỌC VIÊN VÀ TÀI CHÍNH
   Sinh viên thực hiện: Nguyễn Đăng Khoa - MSSV 24110255
   Đề tài : Hệ thống quản lý trung tâm ngoại ngữ (DBMS330284)
   CSDL   : QL_TTNgoaiNgu  (schema của Người A đã đóng băng - KHÔNG sửa bảng)
   Bảng phụ trách: HOCVIEN, DANGKY, HOADON

   12 đối tượng theo kế hoạch (mỗi loại 2) + 1 thủ tục bổ sung (SP_HuyDangKy):
     Trigger     : TRG_DANGKY_SiSo, TRG_HOADON_TuDongTrangThai
     View        : V_CONGNO_HocPhi, V_HOCVIEN_LichSuHoc
     Index       : IX_DANGKY_MaLop, IX_HOCVIEN_HoTen
     Procedure   : SP_TimKiemHocVien, SP_ThongKeDoanhThu
     Function    : FN_TinhCongNo (scalar), FN_DSDangKy_HocVien (table-valued)
     Transaction : SP_DangKy_VaTaoHoaDon, SP_ThanhToanHocPhi   (+ SP_HuyDangKy)

   QUY ƯỚC ĐÃ THỐNG NHẤT TRONG KẾ HOẠCH:
     - Tiền tố TRG_/V_/IX_/SP_/FN_ ; mọi trigger/procedure bắt đầu SET NOCOUNT ON.
     - Mọi procedure có TRY...CATCH, lỗi thì ROLLBACK rồi THROW cho ứng dụng.
     - Mã lỗi THROW của Nguyễn Đăng Khoa (24110255) dùng dải 52000 - 52999 để không trùng người khác.
     - Procedure có giao dịch riêng dùng mẫu "lồng an toàn" (xem chú thích bên dưới)
       để gọi được cả khi JPA đã mở sẵn một giao dịch (không lồng sai).

   FILE CHẠY LẠI NHIỀU LẦN KHÔNG LỖI (CREATE OR ALTER, kiểm tra tồn tại trước khi
   tạo index). Yêu cầu SQL Server 2016 SP1 trở lên.

   THỨ TỰ: Index -> Function -> View -> Trigger -> Procedure -> Transaction.
   ===================================================================== */

USE QL_TTNgoaiNgu;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   1. INDEX
   ===================================================================== */

-- IX_DANGKY_MaLop
-- Mục đích : đếm sĩ số / liệt kê học viên theo lớp. Ràng buộc UNIQUE(MaHV, MaLop) có
--            sẵn bắt đầu bằng MaHV nên KHÔNG hỗ trợ tìm theo MaLop; khóa ngoại MaLop
--            cũng chưa có index. Dùng trong TRG_DANGKY_SiSo, SP_DangKy_VaTaoHoaDon,
--            V_CONGNO_HocPhi. INCLUDE (MaHV) để truy vấn "học viên của lớp" không cần
--            quay lại bảng.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_DANGKY_MaLop' AND object_id = OBJECT_ID(N'dbo.DANGKY'))
    CREATE NONCLUSTERED INDEX IX_DANGKY_MaLop
        ON dbo.DANGKY (MaLop) INCLUDE (MaHV);
GO

-- IX_HOCVIEN_HoTen
-- Mục đích : tra cứu học viên theo họ tên (bảng HOCVIEN chỉ có index theo MaHV, SDT,
--            Email). Hiệu quả rõ nhất với tìm khớp hoàn toàn hoặc khớp phần đầu của tên.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_HOCVIEN_HoTen' AND object_id = OBJECT_ID(N'dbo.HOCVIEN'))
    CREATE NONCLUSTERED INDEX IX_HOCVIEN_HoTen
        ON dbo.HOCVIEN (HoTen);
GO

/* =====================================================================
   2. FUNCTION
   ===================================================================== */

-- FN_TinhCongNo (scalar)
-- Công nợ của một đăng ký = SoTienCanThu - SoTienDaThu của hóa đơn gắn với đăng ký đó.
-- Trả về NULL nếu đăng ký chưa có hóa đơn (để phân biệt với "nợ 0 đồng").
CREATE OR ALTER FUNCTION dbo.FN_TinhCongNo (@MaDK VARCHAR(8))
RETURNS MONEY
AS
BEGIN
    RETURN (SELECT hd.SoTienCanThu - hd.SoTienDaThu
            FROM dbo.HOADON AS hd
            WHERE hd.MaDK = @MaDK);
END;
GO

-- FN_DSDangKy_HocVien (inline table-valued)
-- Lịch sử đăng ký của một học viên: lớp, khóa học, điểm, hóa đơn, công nợ.
CREATE OR ALTER FUNCTION dbo.FN_DSDangKy_HocVien (@MaHV CHAR(5))
RETURNS TABLE
AS
RETURN
(
    SELECT dk.MaDK,
           dk.MaLop,
           l.MaKH,
           kh.TenKhoa,
           l.TrangThai          AS TrangThaiLop,
           dk.NgayDangKy,
           dk.DiemCuoiKy,
           hd.MaHD,
           hd.SoTienCanThu,
           hd.SoTienDaThu,
           hd.SoTienCanThu - hd.SoTienDaThu AS CongNo,
           hd.TrangThaiThanhToan
    FROM dbo.DANGKY AS dk
    JOIN dbo.LOP AS l       ON l.MaLop = dk.MaLop
    JOIN dbo.KHOAHOC AS kh  ON kh.MaKH = l.MaKH
    LEFT JOIN dbo.HOADON AS hd ON hd.MaDK = dk.MaDK
    WHERE dk.MaHV = @MaHV
);
GO

/* =====================================================================
   3. VIEW
   ===================================================================== */

-- V_CONGNO_HocPhi : học viên còn nợ học phí (mỗi dòng là một đăng ký còn nợ).
-- Cột SoTienNo dùng FN_TinhCongNo; điều kiện lọc viết trực tiếp trên cột của HOADON
-- để tối ưu truy vấn.
CREATE OR ALTER VIEW dbo.V_CONGNO_HocPhi
AS
SELECT hv.MaHV,
       hv.HoTen,
       hv.SDT,
       hv.Email,
       dk.MaDK,
       dk.MaLop,
       kh.MaKH,
       kh.TenKhoa,
       dk.NgayDangKy,
       hd.MaHD,
       hd.SoTienCanThu,
       hd.SoTienDaThu,
       dbo.FN_TinhCongNo(dk.MaDK) AS SoTienNo,
       hd.TrangThaiThanhToan,
       DATEDIFF(DAY, dk.NgayDangKy, CAST(GETDATE() AS DATE)) AS SoNgayKeTuDangKy
FROM dbo.HOADON AS hd
JOIN dbo.DANGKY AS dk   ON dk.MaDK = hd.MaDK
JOIN dbo.HOCVIEN AS hv  ON hv.MaHV = dk.MaHV
JOIN dbo.LOP AS l       ON l.MaLop = dk.MaLop
JOIN dbo.KHOAHOC AS kh  ON kh.MaKH = l.MaKH
WHERE hd.SoTienDaThu < hd.SoTienCanThu;
GO

-- V_HOCVIEN_LichSuHoc : học viên - các lớp đã đăng ký - điểm cuối kỳ - thanh toán.
-- Dùng LEFT JOIN HOADON để vẫn hiện đăng ký chưa có hóa đơn.
CREATE OR ALTER VIEW dbo.V_HOCVIEN_LichSuHoc
AS
SELECT hv.MaHV,
       hv.HoTen,
       dk.MaDK,
       dk.MaLop,
       kh.MaKH,
       kh.TenKhoa,
       l.TrangThai AS TrangThaiLop,
       l.NgayKhaiGiang,
       l.NgayKetThuc,
       dk.NgayDangKy,
       dk.DiemCuoiKy,
       hd.SoTienCanThu,
       hd.SoTienDaThu,
       hd.TrangThaiThanhToan
FROM dbo.HOCVIEN AS hv
JOIN dbo.DANGKY AS dk   ON dk.MaHV = hv.MaHV
JOIN dbo.LOP AS l       ON l.MaLop = dk.MaLop
JOIN dbo.KHOAHOC AS kh  ON kh.MaKH = l.MaKH
LEFT JOIN dbo.HOADON AS hd ON hd.MaDK = dk.MaDK;
GO

/* =====================================================================
   4. TRIGGER
   ===================================================================== */

-- TRG_DANGKY_SiSo
-- Chỉ cho đăng ký khi lớp đang tuyển sinh hoặc đang học và chưa vượt sĩ số tối đa.
-- Chỉ kiểm tra các dòng MỚI THÊM hoặc dòng bị ĐỔI SANG LỚP KHÁC. Việc cập nhật điểm
-- (Hibernate gửi UPDATE đủ cột, MaLop giữ nguyên) không bị chặn khi lớp đã kết thúc.
-- Đếm trực tiếp trên DANGKY (không phụ thuộc FN_SiSoHienTai của Người C), có IX_DANGKY_MaLop hỗ trợ.
-- Lưu ý: trigger là lớp kiểm tra cuối; chống tranh chấp "chỗ cuối" nằm ở
-- SP_DangKy_VaTaoHoaDon (UPDLOCK, HOLDLOCK).
CREATE OR ALTER TRIGGER dbo.TRG_DANGKY_SiSo
ON dbo.DANGKY
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DKCanKiemTra TABLE (MaDK VARCHAR(8) NOT NULL PRIMARY KEY, MaLop VARCHAR(6) NOT NULL);

    INSERT INTO @DKCanKiemTra (MaDK, MaLop)
    SELECT i.MaDK, i.MaLop
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.MaDK = i.MaDK
    WHERE d.MaDK IS NULL OR d.MaLop <> i.MaLop;

    IF NOT EXISTS (SELECT 1 FROM @DKCanKiemTra)
        RETURN;

    -- 1) Trạng thái lớp phải là 'Đang tuyển sinh' hoặc 'Đang học'
    IF EXISTS (SELECT 1
               FROM @DKCanKiemTra AS x
               JOIN dbo.LOP AS l ON l.MaLop = x.MaLop
               WHERE l.TrangThai NOT IN (N'Đang tuyển sinh', N'Đang học'))
        THROW 52001, N'Chỉ được đăng ký vào lớp đang tuyển sinh hoặc đang học.', 1;

    -- 2) Sĩ số sau khi thêm không được vượt SiSoToiDa
    IF EXISTS (SELECT 1
               FROM (SELECT DISTINCT MaLop FROM @DKCanKiemTra) AS x
               JOIN dbo.LOP AS l ON l.MaLop = x.MaLop
               WHERE (SELECT COUNT(*) FROM dbo.DANGKY AS dk WHERE dk.MaLop = x.MaLop) > l.SiSoToiDa)
        THROW 52002, N'Lớp đã đủ sĩ số tối đa, không thể đăng ký thêm.', 1;
END;
GO

-- TRG_HOADON_TuDongTrangThai
-- Tự cập nhật TrangThaiThanhToan (và NgayThanhToan) theo SoTienDaThu / SoTienCanThu:
--   đã thu >= cần thu  -> 'Đã thanh toán đủ'
--   đã thu  = 0        -> 'Chưa thanh toán'  (NgayThanhToan = NULL)
--   còn lại            -> 'Thanh toán một phần'
-- Chạy cả khi Người A/Kiên đổi SoTienCanThu (SP_CapNhatHocPhiKhoa). Chỉ UPDATE các dòng
-- thực sự sai nên không lặp vô hạn; thêm TRIGGER_NESTLEVEL để chặn đệ quy.
CREATE OR ALTER TRIGGER dbo.TRG_HOADON_TuDongTrangThai
ON dbo.HOADON
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'dbo.TRG_HOADON_TuDongTrangThai'), 'AFTER', 'DML') > 1
        RETURN;

    UPDATE hd
    SET hd.TrangThaiThanhToan = c.TrangThaiMoi,
        hd.NgayThanhToan      = c.NgayMoi
    FROM dbo.HOADON AS hd
    JOIN inserted AS i ON i.MaHD = hd.MaHD
    CROSS APPLY (SELECT CASE WHEN hd.SoTienDaThu >= hd.SoTienCanThu THEN N'Đã thanh toán đủ'
                             WHEN hd.SoTienDaThu <= 0               THEN N'Chưa thanh toán'
                             ELSE N'Thanh toán một phần'
                        END AS TrangThaiMoi,
                        CASE WHEN hd.SoTienDaThu <= 0 THEN CAST(NULL AS DATE)
                             ELSE ISNULL(hd.NgayThanhToan, CAST(GETDATE() AS DATE))
                        END AS NgayMoi) AS c
    WHERE hd.TrangThaiThanhToan <> c.TrangThaiMoi
       OR (hd.NgayThanhToan IS NULL     AND c.NgayMoi IS NOT NULL)
       OR (hd.NgayThanhToan IS NOT NULL AND c.NgayMoi IS NULL);
END;
GO

/* =====================================================================
   5. STORED PROCEDURE (truy vấn / thống kê)
   ===================================================================== */

-- SP_TimKiemHocVien : tìm học viên theo tên / SĐT / email (khớp một phần, không phân
-- biệt hoa thường, các tiêu chí để NULL hoặc rỗng thì bỏ qua, nhiều tiêu chí là AND).
-- Ký tự đặc biệt của LIKE (% _ [ \) được escape nên người dùng gõ gì cũng tìm đúng chữ đó.
-- OPTION (RECOMPILE) để kế hoạch thực thi phù hợp với tiêu chí thật sự được nhập.
CREATE OR ALTER PROCEDURE dbo.SP_TimKiemHocVien
    @HoTen NVARCHAR(100) = NULL,
    @SDT   VARCHAR(30)   = NULL,
    @Email VARCHAR(100)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @pHoTen NVARCHAR(220) = NULL,
                @pSDT   VARCHAR(70)   = NULL,
                @pEmail VARCHAR(220)  = NULL;

        SET @HoTen = NULLIF(LTRIM(RTRIM(@HoTen)), N'');
        SET @SDT   = NULLIF(LTRIM(RTRIM(@SDT)), '');
        SET @Email = NULLIF(LTRIM(RTRIM(@Email)), '');

        IF @HoTen IS NOT NULL
            SET @pHoTen = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@HoTen, N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';
        IF @SDT IS NOT NULL
            SET @pSDT = '%' + REPLACE(REPLACE(REPLACE(REPLACE(@SDT, '\', '\\'), '%', '\%'), '_', '\_'), '[', '\[') + '%';
        IF @Email IS NOT NULL
            SET @pEmail = '%' + REPLACE(REPLACE(REPLACE(REPLACE(@Email, '\', '\\'), '%', '\%'), '_', '\_'), '[', '\[') + '%';

        SELECT hv.MaHV,
               hv.HoTen,
               hv.NgaySinh,
               hv.SDT,
               hv.Email,
               hv.DiaChi,
               (SELECT COUNT(*) FROM dbo.DANGKY AS dk WHERE dk.MaHV = hv.MaHV) AS SoLopDangKy
        FROM dbo.HOCVIEN AS hv
        WHERE (@pHoTen IS NULL OR hv.HoTen LIKE @pHoTen ESCAPE N'\')
          AND (@pSDT   IS NULL OR hv.SDT   LIKE @pSDT   ESCAPE '\')
          AND (@pEmail IS NULL OR hv.Email LIKE @pEmail ESCAPE '\')
        ORDER BY hv.MaHV
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

-- SP_ThongKeDoanhThu : doanh thu (số tiền đã thu) theo tháng và/hoặc theo khóa học.
--   @Nam, @Thang : lọc theo ngày thanh toán (NULL = tất cả; chọn tháng thì phải chọn năm)
--   @MaKH        : lọc một khóa học (NULL = tất cả)
--   @NhomTheo    : 'THANG' | 'KHOA' | 'THANG_KHOA'
-- Mọi kiểu nhóm trả về CÙNG một bộ cột:
--   Nam, Thang, MaKH, TenKhoa, SoHoaDon, TongPhaiThu, DoanhThu, ConPhaiThu
-- LƯU Ý THIẾT KẾ: HOADON chỉ lưu tổng số đã thu và NGÀY THU GẦN NHẤT (không lưu từng
-- đợt thu) nên doanh thu của hóa đơn được tính vào tháng của lần thu gần nhất.
CREATE OR ALTER PROCEDURE dbo.SP_ThongKeDoanhThu
    @Nam      INT         = NULL,
    @Thang    INT         = NULL,
    @MaKH     VARCHAR(6)  = NULL,
    @NhomTheo VARCHAR(12) = 'THANG'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @NhomTheo = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@NhomTheo)), ''), 'THANG'));
        SET @MaKH     = NULLIF(LTRIM(RTRIM(@MaKH)), '');

        IF @NhomTheo NOT IN ('THANG', 'KHOA', 'THANG_KHOA')
            THROW 52010, N'Tham số @NhomTheo chỉ nhận THANG, KHOA hoặc THANG_KHOA.', 1;
        IF @Thang IS NOT NULL AND (@Thang < 1 OR @Thang > 12)
            THROW 52011, N'Tháng phải nằm trong khoảng từ 1 đến 12.', 1;
        IF @Thang IS NOT NULL AND @Nam IS NULL
            THROW 52012, N'Phải chọn năm khi lọc theo tháng.', 1;
        IF @Nam IS NOT NULL AND (@Nam < 2000 OR @Nam > 2100)
            THROW 52013, N'Năm không hợp lệ (2000 - 2100).', 1;

        -- Đổi (năm, tháng) thành khoảng ngày [@TuNgay, @DenNgay) để điều kiện dùng được index
        DECLARE @TuNgay DATE = NULL, @DenNgay DATE = NULL;
        IF @Nam IS NOT NULL
        BEGIN
            SET @TuNgay  = DATEFROMPARTS(@Nam, ISNULL(@Thang, 1), 1);
            SET @DenNgay = CASE WHEN @Thang IS NULL THEN DATEFROMPARTS(@Nam + 1, 1, 1)
                                ELSE DATEADD(MONTH, 1, @TuNgay) END;
        END;

        CREATE TABLE #ThuTien
        (
            Nam          INT          NOT NULL,
            Thang        INT          NOT NULL,
            MaKH         VARCHAR(6)   NOT NULL,
            TenKhoa      NVARCHAR(50) NOT NULL,
            SoTienCanThu MONEY        NOT NULL,
            SoTienDaThu  MONEY        NOT NULL
        );

        INSERT INTO #ThuTien (Nam, Thang, MaKH, TenKhoa, SoTienCanThu, SoTienDaThu)
        SELECT YEAR(hd.NgayThanhToan), MONTH(hd.NgayThanhToan),
               kh.MaKH, kh.TenKhoa, hd.SoTienCanThu, hd.SoTienDaThu
        FROM dbo.HOADON AS hd
        JOIN dbo.DANGKY AS dk  ON dk.MaDK = hd.MaDK
        JOIN dbo.LOP AS l      ON l.MaLop = dk.MaLop
        JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH
        WHERE hd.SoTienDaThu > 0
          AND hd.NgayThanhToan IS NOT NULL
          AND (@TuNgay  IS NULL OR hd.NgayThanhToan >= @TuNgay)
          AND (@DenNgay IS NULL OR hd.NgayThanhToan <  @DenNgay)
          AND (@MaKH    IS NULL OR kh.MaKH = @MaKH)
        OPTION (RECOMPILE);

        IF @NhomTheo = 'THANG'
            SELECT t.Nam, t.Thang,
                   CAST(NULL AS VARCHAR(6))   AS MaKH,
                   CAST(NULL AS NVARCHAR(50)) AS TenKhoa,
                   COUNT(*)                          AS SoHoaDon,
                   SUM(t.SoTienCanThu)               AS TongPhaiThu,
                   SUM(t.SoTienDaThu)                AS DoanhThu,
                   SUM(t.SoTienCanThu - t.SoTienDaThu) AS ConPhaiThu
            FROM #ThuTien AS t
            GROUP BY t.Nam, t.Thang
            ORDER BY t.Nam, t.Thang;
        ELSE IF @NhomTheo = 'KHOA'
            SELECT CAST(NULL AS INT) AS Nam,
                   CAST(NULL AS INT) AS Thang,
                   t.MaKH, t.TenKhoa,
                   COUNT(*)                          AS SoHoaDon,
                   SUM(t.SoTienCanThu)               AS TongPhaiThu,
                   SUM(t.SoTienDaThu)                AS DoanhThu,
                   SUM(t.SoTienCanThu - t.SoTienDaThu) AS ConPhaiThu
            FROM #ThuTien AS t
            GROUP BY t.MaKH, t.TenKhoa
            ORDER BY SUM(t.SoTienDaThu) DESC, t.MaKH;
        ELSE
            SELECT t.Nam, t.Thang, t.MaKH, t.TenKhoa,
                   COUNT(*)                          AS SoHoaDon,
                   SUM(t.SoTienCanThu)               AS TongPhaiThu,
                   SUM(t.SoTienDaThu)                AS DoanhThu,
                   SUM(t.SoTienCanThu - t.SoTienDaThu) AS ConPhaiThu
            FROM #ThuTien AS t
            GROUP BY t.Nam, t.Thang, t.MaKH, t.TenKhoa
            ORDER BY t.Nam, t.Thang, t.MaKH;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* =====================================================================
   6. TRANSACTION (stored procedure có giao dịch)

   MẪU "LỒNG AN TOÀN" dùng chung cho 3 thủ tục bên dưới:
     - @TranCount = 0 : thủ tục tự BEGIN TRANSACTION và COMMIT ở lệnh CUỐI TRY.
     - @TranCount > 0 : đã có giao dịch bên ngoài (JPA/SSMS) -> chỉ SAVE TRANSACTION;
                        khi lỗi chỉ ROLLBACK về savepoint, KHÔNG COMMIT hộ giao dịch ngoài.
     - XACT_STATE() = -1 (giao dịch hỏng, không commit được) -> ROLLBACK toàn bộ.
     - Cuối CATCH luôn THROW để ứng dụng nhận lỗi.
   Việc BEGIN/SAVE nằm ĐẦU khối TRY để CATCH luôn biết savepoint đã tồn tại.
   ===================================================================== */

-- SP_DangKy_VaTaoHoaDon : thêm đăng ký + tạo hóa đơn trong MỘT giao dịch.
--   Quy tắc : học viên tồn tại; lớp tồn tại, đang tuyển sinh/đang học; khóa học chưa
--             ngừng tuyển sinh; chưa đăng ký lớp này; lớp chưa đầy.
--   Chống tranh chấp "chỗ cuối": khóa dòng LOP bằng UPDLOCK, HOLDLOCK (các phiên đăng
--   ký cùng lớp phải xếp hàng), rồi đếm sĩ số trên DANGKY cũng bằng UPDLOCK, HOLDLOCK
--   (khóa dải khóa -> không phiên khác chèn thêm dòng của lớp này khi ta chưa xong).
--   Học phí đọc bằng HOLDLOCK để SP_CapNhatHocPhiKhoa (Kiên) không đổi học phí giữa chừng.
--   Mã DK/HD sinh trong thủ tục (DK001, HD001, ...) và được tuần tự hóa bằng sp_getapplock.
--   @SoTienThuNgay : số tiền thu ngay lúc đăng ký (0 hoặc NULL = chưa thu).
--   OUTPUT         : @MaDK, @MaHD vừa tạo.
CREATE OR ALTER PROCEDURE dbo.SP_DangKy_VaTaoHoaDon
    @MaHV          CHAR(5),
    @MaLop         VARCHAR(6),
    @NgayDangKy    DATE  = NULL,
    @SoTienThuNgay MONEY = NULL,
    @MaDK          VARCHAR(8) OUTPUT,
    @MaHD          VARCHAR(8) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SV_DangKyHoaDon;
        END;

        DECLARE @TrangThaiLop  NVARCHAR(20),
                @SiSoToiDa     INT,
                @MaKH          VARCHAR(6),
                @HocPhi        MONEY,
                @TrangThaiKhoa NVARCHAR(20),
                @SiSoHienTai   INT,
                @Msg           NVARCHAR(300),
                @Rc            INT,
                @SoDK          INT,
                @SoHD          INT,
                @TrangThaiHD   NVARCHAR(30),
                @Homnay        DATE = CAST(GETDATE() AS DATE);

        SET @MaDK = NULL;
        SET @MaHD = NULL;
        SET @MaHV = LTRIM(RTRIM(@MaHV));
        SET @MaLop = LTRIM(RTRIM(@MaLop));
        SET @NgayDangKy = ISNULL(@NgayDangKy, @Homnay);
        SET @SoTienThuNgay = ISNULL(@SoTienThuNgay, 0);

        -- 1) Kiểm tra tham số
        IF ISNULL(@MaHV, '') = '' OR ISNULL(@MaLop, '') = ''
            THROW 52020, N'Thiếu mã học viên hoặc mã lớp.', 1;
        IF @NgayDangKy > @Homnay
            THROW 52021, N'Ngày đăng ký không được ở tương lai.', 1;
        IF @SoTienThuNgay < 0
            THROW 52022, N'Số tiền thu ngay không được âm.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.HOCVIEN WHERE MaHV = @MaHV)
            THROW 52023, N'Học viên không tồn tại.', 1;

        -- 2) Khóa dòng LỚP: các phiên đăng ký cùng lớp phải xếp hàng từ đây
        SELECT @TrangThaiLop = l.TrangThai,
               @SiSoToiDa    = l.SiSoToiDa,
               @MaKH         = l.MaKH
        FROM dbo.LOP AS l WITH (UPDLOCK, HOLDLOCK)
        WHERE l.MaLop = @MaLop;

        IF @TrangThaiLop IS NULL
            THROW 52024, N'Lớp không tồn tại.', 1;
        IF @TrangThaiLop NOT IN (N'Đang tuyển sinh', N'Đang học')
            THROW 52025, N'Lớp không còn nhận đăng ký (chỉ nhận lớp đang tuyển sinh hoặc đang học).', 1;

        -- 3) Khóa học: chưa ngừng tuyển sinh; lấy học phí (giữ khóa đọc tới hết giao dịch)
        SELECT @HocPhi = kh.HocPhi, @TrangThaiKhoa = kh.TrangThai
        FROM dbo.KHOAHOC AS kh WITH (HOLDLOCK)
        WHERE kh.MaKH = @MaKH;

        IF @TrangThaiKhoa = N'Ngừng tuyển sinh'
            THROW 52026, N'Khóa học của lớp này đã ngừng tuyển sinh.', 1;
        IF @SoTienThuNgay > @HocPhi
            THROW 52027, N'Số tiền thu ngay vượt học phí của khóa học.', 1;

        -- 4) Chưa đăng ký lớp này (kiểm tra SAU khi giữ khóa lớp nên chống được bấm đúp)
        IF EXISTS (SELECT 1 FROM dbo.DANGKY WHERE MaHV = @MaHV AND MaLop = @MaLop)
            THROW 52028, N'Học viên đã đăng ký lớp này rồi.', 1;

        -- 5) Kiểm tra sĩ số có khóa dải khóa
        SELECT @SiSoHienTai = COUNT(*)
        FROM dbo.DANGKY WITH (UPDLOCK, HOLDLOCK)
        WHERE MaLop = @MaLop;

        IF @SiSoHienTai >= @SiSoToiDa
        BEGIN
            SET @Msg = N'Lớp ' + @MaLop + N' đã đủ sĩ số (' + CAST(@SiSoHienTai AS NVARCHAR(10))
                     + N'/' + CAST(@SiSoToiDa AS NVARCHAR(10)) + N'), không thể đăng ký thêm.';
            THROW 52029, @Msg, 1;
        END;

        -- 6) Sinh mã DK / HD (tuần tự hóa bằng khóa ứng dụng, tự nhả khi hết giao dịch)
        EXEC @Rc = sys.sp_getapplock @Resource = N'TTNN_SinhMa_DangKy_HoaDon',
                                     @LockMode = N'Exclusive',
                                     @LockOwner = N'Transaction',
                                     @LockTimeout = 10000;
        IF @Rc < 0
            THROW 52030, N'Hệ thống đang bận sinh mã đăng ký, vui lòng thử lại.', 1;

        SELECT @SoDK = ISNULL(MAX(TRY_CAST(SUBSTRING(MaDK, 3, 6) AS INT)), 0) + 1
        FROM dbo.DANGKY
        WHERE MaDK LIKE 'DK[0-9]%';

        SELECT @SoHD = ISNULL(MAX(TRY_CAST(SUBSTRING(MaHD, 3, 6) AS INT)), 0) + 1
        FROM dbo.HOADON
        WHERE MaHD LIKE 'HD[0-9]%';

        SET @MaDK = 'DK' + RIGHT('000' + CAST(@SoDK AS VARCHAR(6)),
                                 CASE WHEN @SoDK > 999 THEN LEN(CAST(@SoDK AS VARCHAR(6))) ELSE 3 END);
        SET @MaHD = 'HD' + RIGHT('000' + CAST(@SoHD AS VARCHAR(6)),
                                 CASE WHEN @SoHD > 999 THEN LEN(CAST(@SoHD AS VARCHAR(6))) ELSE 3 END);

        -- 7) Ghi dữ liệu: đăng ký rồi hóa đơn (học phí lưu tại thời điểm đăng ký)
        INSERT INTO dbo.DANGKY (MaDK, MaHV, MaLop, NgayDangKy, DiemCuoiKy)
        VALUES (@MaDK, @MaHV, @MaLop, @NgayDangKy, NULL);

        SET @TrangThaiHD = CASE WHEN @SoTienThuNgay >= @HocPhi THEN N'Đã thanh toán đủ'
                                WHEN @SoTienThuNgay <= 0       THEN N'Chưa thanh toán'
                                ELSE N'Thanh toán một phần' END;

        INSERT INTO dbo.HOADON (MaHD, MaDK, SoTienCanThu, SoTienDaThu, NgayThanhToan, TrangThaiThanhToan)
        VALUES (@MaHD, @MaDK, @HocPhi, @SoTienThuNgay,
                CASE WHEN @SoTienThuNgay > 0 THEN @NgayDangKy ELSE NULL END,
                @TrangThaiHD);

        -- COMMIT là lệnh cuối của khối TRY
        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @MaDK = NULL;
        SET @MaHD = NULL;
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_DangKyHoaDon;
        END;
        THROW;
    END CATCH;
END;
GO

-- SP_ThanhToanHocPhi : ghi nhận một lần thu tiền học phí.
--   Chống thu vượt: SoTienDaThu + @SoTienThu không được lớn hơn SoTienCanThu.
--   Khóa dòng hóa đơn (UPDLOCK, HOLDLOCK) để hai thu ngân cùng thu một hóa đơn không
--   ghi đè nhau. NgayThanhToan = ngày thu gần nhất. Trạng thái cập nhật ngay trong
--   thủ tục (trigger TRG_HOADON_TuDongTrangThai là lớp bảo vệ thứ hai).
--   OUTPUT: @SoTienConNo (còn nợ sau khi thu), @TrangThai (trạng thái thanh toán mới).
CREATE OR ALTER PROCEDURE dbo.SP_ThanhToanHocPhi
    @MaHD        VARCHAR(8),
    @SoTienThu   MONEY,
    @NgayThu     DATE = NULL,
    @SoTienConNo MONEY        OUTPUT,
    @TrangThai   NVARCHAR(30) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SV_ThanhToan;
        END;

        DECLARE @CanThu      MONEY,
                @DaThu       MONEY,
                @NgayCu      DATE,
                @MaDK        VARCHAR(8),
                @NgayDangKy  DATE,
                @Msg         NVARCHAR(300),
                @Homnay      DATE = CAST(GETDATE() AS DATE);

        SET @SoTienConNo = NULL;
        SET @TrangThai = NULL;
        SET @MaHD = LTRIM(RTRIM(@MaHD));
        SET @NgayThu = ISNULL(@NgayThu, @Homnay);

        IF ISNULL(@MaHD, '') = ''
            THROW 52040, N'Thiếu mã hóa đơn.', 1;
        IF @SoTienThu IS NULL OR @SoTienThu <= 0
            THROW 52041, N'Số tiền thu phải lớn hơn 0.', 1;
        IF @NgayThu > @Homnay
            THROW 52042, N'Ngày thu tiền không được ở tương lai.', 1;

        SELECT @CanThu = hd.SoTienCanThu,
               @DaThu  = hd.SoTienDaThu,
               @NgayCu = hd.NgayThanhToan,
               @MaDK   = hd.MaDK
        FROM dbo.HOADON AS hd WITH (UPDLOCK, HOLDLOCK)
        WHERE hd.MaHD = @MaHD;

        IF @CanThu IS NULL
            THROW 52043, N'Hóa đơn không tồn tại.', 1;

        SELECT @NgayDangKy = dk.NgayDangKy FROM dbo.DANGKY AS dk WHERE dk.MaDK = @MaDK;
        IF @NgayThu < @NgayDangKy
            THROW 52044, N'Ngày thu tiền không được trước ngày đăng ký.', 1;

        IF @DaThu + @SoTienThu > @CanThu
        BEGIN
            SET @Msg = N'Thu vượt số tiền cần thu. Hóa đơn ' + @MaHD + N' chỉ còn nợ '
                     + FORMAT(@CanThu - @DaThu, N'N0', N'vi-VN') + N' đồng.';
            THROW 52045, @Msg, 1;
        END;

        SET @DaThu = @DaThu + @SoTienThu;
        SET @TrangThai = CASE WHEN @DaThu >= @CanThu THEN N'Đã thanh toán đủ'
                              ELSE N'Thanh toán một phần' END;

        UPDATE dbo.HOADON
        SET SoTienDaThu        = @DaThu,
            NgayThanhToan      = CASE WHEN @NgayCu IS NULL OR @NgayCu < @NgayThu THEN @NgayThu ELSE @NgayCu END,
            TrangThaiThanhToan = @TrangThai
        WHERE MaHD = @MaHD;

        SET @SoTienConNo = @CanThu - @DaThu;

        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @SoTienConNo = NULL;
        SET @TrangThai = NULL;
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_ThanhToan;
        END;
        THROW;
    END CATCH;
END;
GO

-- SP_HuyDangKy (BỔ SUNG ngoài 12 đối tượng): hủy một đăng ký và hóa đơn của nó.
--   Chỉ hủy khi: chưa thu đồng nào, chưa có điểm cuối kỳ, chưa có dữ liệu điểm danh
--   (DIEMDANH có khóa ngoại tới DANGKY). Xóa HOADON trước rồi DANGKY, cùng một giao dịch.
CREATE OR ALTER PROCEDURE dbo.SP_HuyDangKy
    @MaDK VARCHAR(8)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0
        BEGIN
            BEGIN TRANSACTION;
        END
        ELSE
        BEGIN
            SAVE TRANSACTION SV_HuyDangKy;
        END;

        DECLARE @MaLop VARCHAR(6), @Diem NUMERIC(4,2), @DaThu MONEY;

        SET @MaDK = LTRIM(RTRIM(@MaDK));
        IF ISNULL(@MaDK, '') = ''
            THROW 52050, N'Thiếu mã đăng ký.', 1;

        SELECT @MaLop = dk.MaLop, @Diem = dk.DiemCuoiKy
        FROM dbo.DANGKY AS dk WITH (UPDLOCK, HOLDLOCK)
        WHERE dk.MaDK = @MaDK;

        IF @MaLop IS NULL
            THROW 52051, N'Đăng ký không tồn tại.', 1;
        IF @Diem IS NOT NULL
            THROW 52052, N'Đăng ký đã có điểm cuối kỳ, không thể hủy.', 1;
        IF EXISTS (SELECT 1 FROM dbo.DIEMDANH WHERE MaDK = @MaDK)
            THROW 52053, N'Đăng ký đã có dữ liệu điểm danh, không thể hủy.', 1;

        SELECT @DaThu = hd.SoTienDaThu FROM dbo.HOADON AS hd WITH (UPDLOCK, HOLDLOCK) WHERE hd.MaDK = @MaDK;
        IF ISNULL(@DaThu, 0) > 0
            THROW 52054, N'Hóa đơn đã thu tiền, cần xử lý hoàn tiền trước khi hủy đăng ký.', 1;

        DELETE FROM dbo.HOADON WHERE MaDK = @MaDK;
        DELETE FROM dbo.DANGKY WHERE MaDK = @MaDK;

        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCount = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION SV_HuyDangKy;
        END;
        THROW;
    END CATCH;
END;
GO

/* =====================================================================
   7. KIỂM TRA: liệt kê các đối tượng của Nguyễn Đăng Khoa (24110255) đã được tạo
   ===================================================================== */
SELECT o.type_desc AS LoaiDoiTuong, o.name AS TenDoiTuong
FROM sys.objects AS o
WHERE o.name IN (N'TRG_DANGKY_SiSo', N'TRG_HOADON_TuDongTrangThai',
                 N'V_CONGNO_HocPhi', N'V_HOCVIEN_LichSuHoc',
                 N'SP_TimKiemHocVien', N'SP_ThongKeDoanhThu',
                 N'FN_TinhCongNo', N'FN_DSDangKy_HocVien',
                 N'SP_DangKy_VaTaoHoaDon', N'SP_ThanhToanHocPhi', N'SP_HuyDangKy')
UNION ALL
SELECT N'INDEX', i.name
FROM sys.indexes AS i
WHERE i.name IN (N'IX_DANGKY_MaLop', N'IX_HOCVIEN_HoTen')
ORDER BY 1, 2;
GO
