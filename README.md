# Hệ thống quản lý trung tâm ngoại ngữ — Nhóm 18

Đồ án cuối kỳ học phần **Hệ quản trị cơ sở dữ liệu (DBMS330284)**
Cơ sở dữ liệu **SQL Server** `QL_TTNgoaiNgu` (10 bảng, 49 đối tượng SQL) và ứng dụng **Java Swing + JPA/Hibernate** kết nối trực tiếp SQL Server.

| Thành viên | MSSV | Phụ trách |
|---|---|---|
| Nguyễn Đăng Khoa (nhóm trưởng) | 24110255 | Module B: Học viên và tài chính |
| Hoàng Trọng Hoàn | 24110214 | Module C: Lớp học và lịch học |
| Đoàn Trung Kiên | 24110262 | Module A: Ngôn ngữ và khóa học; schema, bảo mật, sao lưu |
| Võ Tấn Phát | 24110299 | Module D: Giảng viên và giảng dạy |

## 1. Cấu trúc thư mục

```
TTNgoaiNgu_NguoiB/
├── app/ttnn-app/      Mã nguồn ứng dụng Java (Maven)
├── sql/
│   ├── Build_Full.sql     Script tạo lại TOÀN BỘ CSDL (chạy một lần, xem mục 3)
│   ├── nguoi_A … nguoi_D/ File SQL lẻ từng người: Module_*.sql, Grant_*.sql, Test_Module_*.sql
│   └── demo/              Các file demo: index, tranh chấp (giao dịch), phân quyền, sao lưu/phục hồi
└── docs/              Tài liệu từng thành viên
```

## 2. Yêu cầu cài đặt

- **SQL Server** 2016 SP1 trở lên (đã chạy trên SQL Server 2022 Express), kèm SSMS.
- SQL Server phải bật **chế độ đăng nhập hỗn hợp** (SQL Server and Windows Authentication mode) và **TCP/IP**
  (SQL Server Configuration Manager → Network Configuration → TCP/IP = Enabled, sau đó khởi động lại dịch vụ).
- **JDK 17** trở lên và **Maven 3.8** trở lên.

## 3. Tạo cơ sở dữ liệu

1. Mở SSMS, đăng nhập bằng tài khoản có quyền `sysadmin` (Windows Authentication của máy là đủ).
2. Mở file `sql/Build_Full.sql` → **Ctrl+A → F5** (chạy toàn bộ một lần, không cần chạy từng đoạn).
3. Mở tab **Messages**: không có dòng đỏ `Msg …, Level 16` là thành công.
   Các gạch đỏ do IntelliSense trong trình soạn thảo (ở các lệnh `THROW` của module C) không ảnh hưởng khi chạy.

> ⚠ File bắt đầu bằng `DROP DATABASE QL_TTNgoaiNgu` rồi tạo lại từ đầu. Chỉ chạy trên máy thử hoặc máy demo.

File này gồm theo thứ tự: tạo bảng → dữ liệu mẫu → Module A, B, C, D → tạo 4 role/login và phân quyền.
Bước kiểm tra (không bắt buộc): chạy từng file `sql/nguoi_X/Test_Module_X.sql` (X = A, B, C, D); mỗi file cho kết quả `SoCaFAIL = 0`.

## 4. Chạy ứng dụng

```bash
cd app/ttnn-app
mvn compile exec:java            # chạy trực tiếp
# hoặc đóng gói thành một file chạy được:
mvn clean package
java -jar target/ttnn-app-1.0.0.jar
```

Hộp thoại đăng nhập hiện ra, nhập:

| Ô | Giá trị |
|---|---|
| Máy chủ | `localhost` (cổng `1433`). Nếu dùng SQL Server Express có tên instance: `localhost\SQLEXPRESS` và bỏ trống cổng (cần bật dịch vụ SQL Server Browser) |
| Cơ sở dữ liệu | `QL_TTNgoaiNgu` |
| Tên đăng nhập / Mật khẩu | một trong các tài khoản ở mục 5 |

Giá trị mặc định có thể sửa trong `app/ttnn-app/src/main/resources/db.properties`
(hoặc biến môi trường `TTNN_DB_HOST`, `TTNN_DB_PORT`, `TTNN_DB_NAME`).

## 5. Tài khoản demo

Ứng dụng đăng nhập trực tiếp bằng login SQL Server; mỗi tài khoản thuộc đúng một role và chỉ thấy các tab được phép.

| Tài khoản | Mật khẩu | Role | Tab hiển thị / quyền |
|---|---|---|---|
| `ttnn_quantri` | `Ttnn@QuanTri_2026!` | Quản trị | Cả 4 tab, được thêm/sửa/xóa danh mục |
| `ttnn_giaovu` | `Ttnn@GiaoVu_2026!` | Giáo vụ | Khóa học (chỉ xem), Lớp học và lịch, Giảng dạy |
| `ttnn_ketoan` | `Ttnn@KeToan_2026!` | Kế toán | Khóa học (chỉ xem), Học viên và tài chính |
| `ttnn_giangvien` | `Ttnn@GiangVien_2026!` | Giảng viên | Giảng dạy (lịch dạy, điểm danh) |

(Mật khẩu chỉ dùng cho demo. Ngoài ra còn tài khoản `ttnn_demo_b` của module B.)

Bốn tab chính: **Khóa học** (module A), **Học viên và tài chính** (module B), **Lớp học và lịch** (module C), **Giảng dạy** (module D).

## 6. Xử lý lỗi trong ứng dụng

- **Mất kết nối CSDL**: ứng dụng bắt lỗi kết nối và hiển thị thông báo tiếng Việt, không bị treo hay văng ra (thử: tắt dịch vụ SQL Server rồi thao tác).
- **Sai tài khoản/mật khẩu** (lỗi 18456), **không đủ quyền** (229, 230), **vi phạm khóa ngoại/khóa duy nhất** (547, 2627): được dịch sang thông báo dễ hiểu.
- **Dữ liệu nhập không hợp lệ** (để trống, sai định dạng, ngoài khoảng cho phép): chặn ngay trên giao diện trước khi gửi xuống CSDL.
- **Lỗi nghiệp vụ** từ trigger/procedure (mã 51xxx–54xxx: ví dụ lớp đã đầy, lịch học trùng phòng) được hiển thị nguyên văn cho người dùng.

## 7. Các file demo (`sql/demo/`)

| File | Nội dung |
|---|---|
| `01_Index_DuLieuLon_B.sql`, `05_Index_DuLieuLon_A.sql`, `07_Index_DuLieuLon_D.sql` | So sánh trước/sau khi có index (logical reads, Scan → Seek) |
| `02_TranhChap_Setup.sql`, `02a`, `02b`, `03_TranhChap_KiemTra_DonDep.sql` | Tranh chấp "chỗ cuối" khi hai người cùng đăng ký (mở hai cửa sổ query) |
| `04_PhanQuyen_MinhHoa.sql` | Minh họa GRANT / REVOKE / DENY |
| `06_SaoLuu_KhoiPhuc_A.sql` | Sao lưu đầy đủ, tail-log, khôi phục đến thời điểm (STOPAT). Đóng ứng dụng trước khi chạy |

Hướng dẫn chi tiết nằm ở phần chú thích đầu mỗi file.

## 8. Quản lý mã nguồn

Mã nguồn được quản lý bằng Git trên GitHub; lịch sử commit của từng thành viên xem ở tab **Commits / Insights** của repository.