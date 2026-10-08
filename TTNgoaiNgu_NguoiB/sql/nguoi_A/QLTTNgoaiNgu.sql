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