# Quản lý Trung tâm Ngoại ngữ — Phần của Nguyễn Đăng Khoa — MSSV 24110255 (Học viên và tài chính)

Môn DBMS330284 · CSDL `QL_TTNgoaiNgu` · Bảng phụ trách: `HOCVIEN`, `DANGKY`, `HOADON`
Gói này nối tiếp `Schema_TTNgoaiNgu.zip` của Người A (schema **giữ nguyên, không sửa bảng nào**).

## 1. Cấu trúc gói

```
TTNgoaiNgu_NguoiB/
├── README.md                           (file này)
├── sql/
│   ├── Build_Full_B.sql                CHẠY MỘT LẦN: schema A + dữ liệu A + module B  (xóa & tạo lại CSDL)
│   ├── nguoi_A/                        2 file gốc của Người A (không sửa)
│   │   ├── QLTTNgoaiNgu.sql
│   │   └── DataQLTTNgoaiNgu.sql
│   ├── nguoi_B/
│   │   ├── Module_B_HocVien_TaiChinh.sql   12 đối tượng + SP_HuyDangKy  (chạy lại nhiều lần được)
│   │   ├── Test_Module_B.sql               kiểm thử tự động, xuất bảng PASS/FAIL
│   │   └── Grant_Module_B.sql              phân quyền gợi ý + login demo cho ứng dụng
│   └── demo/
│       ├── 01_Index_DuLieuLon_B.sql        demo index: 200k học viên + 500k đăng ký, so sánh trước/sau
│       ├── 02_TranhChap_Setup.sql          chuẩn bị demo tranh chấp "chỗ cuối"
│       ├── 02a_TranhChap_CuaSo1.sql        chạy ở cửa sổ SSMS thứ 1
│       ├── 02b_TranhChap_CuaSo2.sql        chạy ở cửa sổ SSMS thứ 2
│       └── 03_TranhChap_KiemTra_DonDep.sql kiểm tra kết quả + dọn dẹp
├── app/ttnn-app/                       Ứng dụng Java Swing + JPA/Hibernate (4 màn hình của B)
└── docs/TaiLieu_NguoiB.md              giải thích từng đối tượng, quy tắc, kịch bản demo, lưu ý ghép nhóm
```

## 2. Chạy phần SQL (SQL Server 2016 SP1 trở lên, khuyến nghị 2019/2022)

Cách nhanh nhất (máy trắng): mở `sql/Build_Full_B.sql` trong SSMS → **Execute**.
> ⚠ File này bắt đầu bằng `DROP DATABASE QL_TTNgoaiNgu` (do schema của Người A) — chỉ chạy trên máy thử nghiệm.

Cách từng bước: chạy lần lượt `nguoi_A/QLTTNgoaiNgu.sql` → `nguoi_A/DataQLTTNgoaiNgu.sql` → `nguoi_B/Module_B_HocVien_TaiChinh.sql`.

Sau đó:

| Việc | File | Kết quả mong đợi |
|---|---|---|
| Kiểm thử | `nguoi_B/Test_Module_B.sql` | bảng PASS/FAIL, cuối cùng `SoCaFAIL = 0`; dữ liệu mẫu không bị đổi |
| Phân quyền + login demo | `nguoi_B/Grant_Module_B.sql` | tạo login `ttnn_demo_b` (đổi mật khẩu nếu cần) |
| Demo index | `demo/01_Index_DuLieuLon_B.sql` | Messages: logical reads giảm mạnh sau khi có index; plan từ Scan → Seek |
| Demo tranh chấp | `demo/02_*`, `02a`, `02b`, `03` | không khóa: 3/2 chỗ (sai); có khóa: 2/2, người thứ hai nhận lỗi 52029 |

Hướng dẫn chi tiết từng demo nằm ở đầu mỗi file.

## 3. Chạy ứng dụng Java

Yêu cầu: JDK 17+, Maven 3.8+, SQL Server bật TCP/IP (cổng 1433) và đăng nhập SQL (Mixed Mode).

```bash
cd app/ttnn-app
mvn compile exec:java          # chạy thử
# hoặc đóng gói 1 file chạy được:
mvn clean package
java -jar target/ttnn-app-1.0.0.jar
```

Hộp thoại đăng nhập: máy chủ `localhost`, cổng `1433`, CSDL `QL_TTNgoaiNgu`, tài khoản `ttnn_demo_b`
(mật khẩu mặc định trong `Grant_Module_B.sql`; hoặc dùng login `sa`).
Dùng instance tên (SQLEXPRESS): nhập máy chủ `localhost\SQLEXPRESS` (bỏ qua cổng).
Có thể sửa mặc định trong `src/main/resources/db.properties`.

## 4. Bốn màn hình của Nguyễn Đăng Khoa (24110255)

| Màn hình | Thành phần CSDL được gọi |
|---|---|
| Quản lý học viên | `SP_TimKiemHocVien`, CRUD entity `HocVien`, view `V_HOCVIEN_LichSuHoc` |
| Đăng ký học | `SP_DangKy_VaTaoHoaDon`, `SP_HuyDangKy`, hàm `FN_DSDangKy_HocVien`, trigger `TRG_DANGKY_SiSo` (chạy khi UPDATE điểm) |
| Hóa đơn và thu tiền | `SP_ThanhToanHocPhi`, hàm `FN_TinhCongNo`, trigger `TRG_HOADON_TuDongTrangThai` |
| Báo cáo | view `V_CONGNO_HocPhi`, `SP_ThongKeDoanhThu` |

## 5. Những gì CHƯA được kiểm chứng trên SQL Server thật

Môi trường soạn gói này không có SQL Server/Maven nên:
- Toàn bộ T-SQL đã được **kiểm tra cú pháp bằng trình phân tích T-SQL** và đối chiếu số liệu mong đợi với dữ liệu mẫu bằng tay, nhưng **chưa thực thi trên SQL Server**.
- Mã Java đã **biên dịch sạch** (đối chiếu với bộ khai báo API JPA tối thiểu) và các lớp tiện ích không cần CSDL đã chạy thử; phần gọi Hibernate/SQL Server **chưa chạy thật**.

Vì vậy hãy chạy `Test_Module_B.sql` ngay sau khi cài; nếu có ca FAIL, cột `ChiTiet` cho biết giá trị thực tế. Xem thêm `docs/TaiLieu_NguoiB.md` mục 8.
