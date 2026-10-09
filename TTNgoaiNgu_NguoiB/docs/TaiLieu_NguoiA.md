# Tài liệu kỹ thuật — Kiên, MSSV 24110262 (Người A: Thiết kế CSDL, Danh mục khóa học, Bảo mật, Khung ứng dụng)

Môn DBMS330284 · CSDL `QL_TTNgoaiNgu` · Bảng phụ trách: `NGONNGU`, `KHOAHOC`
Phạm vi: schema và dữ liệu mẫu của cả nhóm, 12 đối tượng SQL trên hai bảng danh mục, phân quyền 4 role, demo index và khôi phục sau sự cố, khung ứng dụng dùng chung và 3 màn hình khóa học.

## 1. Phạm vi và ràng buộc đã thống nhất
- **Schema khóa cứng**: không thêm, sửa cột hay bảng. Mọi người chỉ thêm trigger, view, index, procedure, function.
- Quy ước tên: `TRG_` / `V_` / `IX_` / `SP_` / `FN_`. Mọi trigger và procedure bắt đầu `SET NOCOUNT ON`.
- Mọi procedure có `TRY…CATCH`: lỗi thì `ROLLBACK` rồi `THROW` cho ứng dụng.
- Mã lỗi `THROW` của Kiên dùng dải **51000–51999** (B dùng 52000–52999; C, D chọn dải riêng).
- Đối tượng của Kiên **chỉ đọc** bảng của người khác (`LOP`, `DANGKY`, `GIANGVIEN`). Ngoại lệ duy nhất: `SP_CapNhatHocPhiKhoa` cập nhật `HOADON.SoTienCanThu` (đã thống nhất với B).

## 2. Mười hai đối tượng SQL (`sql/nguoi_A/Module_A_KhoaHoc.sql`)

| # | Loại | Tên | Mục đích |
|---|---|---|---|
| 1 | Trigger | `TRG_KHOAHOC_NgungTuyenSinh` | Không cho chuyển khóa sang *Ngừng tuyển sinh* khi khóa còn lớp *Đang tuyển sinh* (lớp *Đang học* không bị chặn). |
| 2 | Trigger | `TRG_KHOAHOC_KhoaNgonNgu` | Không cho đổi `MaNN` của khóa đã có lớp. Nếu đổi, giảng viên các lớp cũ sẽ sai ngôn ngữ, mà `TRG_LOP_KiemTraGV` của C chỉ kiểm khi ghi vào `LOP`. |
| 3 | View | `V_KHOAHOC_ThongKe` | Mỗi khóa: ngôn ngữ, số lớp, số lớp đang mở, số học viên (gọi hàm #9). |
| 4 | View | `V_THONGKE_NgonNgu` | Mỗi ngôn ngữ: số khóa (tổng / đang giảng dạy), số lớp, số giảng viên (tổng / đang công tác). |
| 5 | Index | `IX_KHOAHOC_MaNN_TrangThai` (`MaNN, TrangThai` INCLUDE `TenKhoa, TrinhDo, SoBuoi, HocPhi`) | FK `MaNN` chưa có index. Index phục vụ lọc theo ngôn ngữ + trạng thái và đủ cột cho hàm #10 (không Key Lookup). |
| 6 | Index | `IX_KHOAHOC_HocPhi` (`HocPhi` INCLUDE các cột tìm kiếm) | Tìm theo khoảng học phí trong #7 → Index Seek. |
| 7 | Procedure | `SP_TimKiemKhoaHoc` | Tìm theo tên (khớp một phần, escape `% _ [ \`), ngôn ngữ, trạng thái, khoảng học phí; `OPTION (RECOMPILE)` để dùng đúng index. |
| 8 | Procedure | `SP_ThongKeDangKy_TheoKhoa` | Số lớp có đăng ký, số đăng ký, số học viên, tỷ lệ % theo khóa trong khoảng ngày. Khóa không có đăng ký hiện số 0. |
| 9 | Function (vô hướng) | `FN_SoHocVien_KhoaHoc(@MaKH)` | Số học viên khác nhau của một khóa; `NULL` nếu khóa không tồn tại. |
| 10 | Function (bảng) | `FN_DSKhoaHoc_TheoNN(@MaNN)` | Các khóa *Đang giảng dạy* của một ngôn ngữ. |
| 11 | Transaction | `SP_CapNhatHocPhiKhoa` | Đổi học phí khóa **và** `SoTienCanThu` của mọi hóa đơn *Chưa thanh toán* (chưa thu đồng nào) thuộc khóa đó, kể cả lớp đã kết thúc. |
| 12 | Transaction | `SP_ThemKhoaHoc_VaNgonNgu` | Thêm ngôn ngữ (nếu chưa có) và khóa học trong một giao dịch; mã `KHxxxx` sinh trong thủ tục. |

**Hai thay đổi so với gợi ý trong kế hoạch (đã thống nhất):**
- `TRG_KHOAHOC_GhiLogHocPhi` → `TRG_KHOAHOC_KhoaNgonNgu`. Trigger ghi log cần bảng `LOG_HOCPHI` mới, trái với schema khóa cứng.
- `IX_KHOAHOC_TenKhoa` → `IX_KHOAHOC_HocPhi`. Tìm tên theo kiểu `LIKE N'%...%'` không Seek được index trên `TenKhoa`. Có minh chứng ở bước 6 của `demo/05_Index_DuLieuLon_A.sql`.

## 3. Giao dịch và tranh chấp
- Hai procedure #11, #12 dùng **mẫu "lồng an toàn" giống hệt Module B**: `@@TRANCOUNT = 0` thì tự `BEGIN/COMMIT`; `> 0` thì `SAVE TRANSACTION` và lỗi chỉ rollback về savepoint; `XACT_STATE() = -1` thì rollback toàn bộ; `CATCH` luôn `THROW`. Nhờ vậy gọi được từ `JpaUtil.inTx(...)` lẫn chạy thẳng trong SSMS.
- `SP_CapNhatHocPhiKhoa` khóa dòng `KHOAHOC` bằng `UPDLOCK, HOLDLOCK`. `SP_DangKy_VaTaoHoaDon` của B đọc học phí bằng `HOLDLOCK`, nên hai thủ tục xếp hàng: đăng ký mới lấy học phí cũ (và hóa đơn đó sẽ được thủ tục đổi học phí cập nhật), hoặc lấy học phí mới. Không có trường hợp lẫn lộn.
- `SP_ThemKhoaHoc_VaNgonNgu` khóa `NGONNGU` bằng `UPDLOCK, HOLDLOCK` (chống hai phiên cùng thêm một mã ngôn ngữ) và sinh mã bằng `sp_getapplock` (cùng cách B sinh mã DK/HD).

## 4. Mã lỗi `THROW` của Kiên (24110262)

| Mã | Nơi phát sinh | Ý nghĩa |
|---|---|---|
| 51001 | `TRG_KHOAHOC_NgungTuyenSinh` | khóa còn lớp đang tuyển sinh |
| 51002 | `TRG_KHOAHOC_KhoaNgonNgu` | khóa đã có lớp, không đổi được ngôn ngữ |
| 51010–51012 | `SP_TimKiemKhoaHoc` | học phí âm / từ > đến / trạng thái sai |
| 51020 | `SP_ThongKeDangKy_TheoKhoa` | từ ngày > đến ngày |
| 51030–51033 | `SP_CapNhatHocPhiKhoa` | thiếu mã / học phí trống hoặc âm / khóa không tồn tại / học phí mới trùng học phí cũ |
| 51040–51047 | `SP_ThemKhoaHoc_VaNgonNgu` | thiếu tham số / số buổi ngoài 1–255 / học phí âm / ngôn ngữ mới thiếu tên / tên ngôn ngữ đã dùng cho mã khác / mã ngôn ngữ có sẵn với tên khác / bận sinh mã / hết dải KH9999 |

## 5. Bảo mật và phân quyền (`sql/nguoi_A/Security_Roles.sql`)

**4 role và 4 login** (SQL Server Authentication; mỗi login thuộc **đúng một** role):

| Login | Role | Mật khẩu demo |
|---|---|---|
| `ttnn_quantri` | `role_QuanTri` | `Ttnn@QuanTri_2026!` |
| `ttnn_giaovu` | `role_GiaoVu` | `Ttnn@GiaoVu_2026!` |
| `ttnn_ketoan` | `role_KeToan` | `Ttnn@KeToan_2026!` |
| `ttnn_giangvien` | `role_GiangVien` | `Ttnn@GiangVien_2026!` |

Đổi mật khẩu trước khi dùng thật. Script tạo role, login, user; sau đó `REVOKE` toàn bộ quyền cũ trên đối tượng của Kiên rồi cấp lại. Nhờ vậy sửa chính sách rồi chạy lại là ra đúng.

**Quyền trên đối tượng của Kiên:**

| Đối tượng | QuanTri | GiaoVu | KeToan | GiangVien |
|---|---|---|---|---|
| `NGONNGU`, `KHOAHOC` | SELECT/INSERT/UPDATE/DELETE | SELECT | SELECT | SELECT |
| cột `KHOAHOC.HocPhi` | **DENY UPDATE** | – | – | – |
| 2 view, `FN_SoHocVien_KhoaHoc`, `SP_ThongKeDangKy_TheoKhoa` | ✓ | ✓ | ✓ | – |
| `SP_TimKiemKhoaHoc`, `FN_DSKhoaHoc_TheoNN` | ✓ | ✓ | ✓ | ✓ |
| `SP_CapNhatHocPhiKhoa`, `SP_ThemKhoaHoc_VaNgonNgu` | ✓ | **DENY** | **DENY** | **DENY** |

Không role nào có quyền DDL.

**Điểm thiết kế chính:** quản trị viên **không** sửa trực tiếp được `HocPhi` trên bảng (lỗi 230), nên không ai đổi học phí mà quên cập nhật hóa đơn. Gọi `SP_CapNhatHocPhiKhoa` thì vẫn được, vì thủ tục và bảng cùng chủ `dbo` (ownership chaining bỏ qua kiểm tra quyền bên trong thủ tục).

**Thứ tự:** file này chạy **sau** các module và **trước** các file `Grant_Module_X.sql`. Các file Grant chỉ GRANT khi role đã tồn tại.

## 6. Kiểm thử và demo

| File | Nội dung | Kết quả mong đợi |
|---|---|---|
| `sql/nguoi_A/Test_Module_A.sql` | 24 ca (A01–A12): index, 2 hàm, 2 view, tìm kiếm (kể cả escape `%` và lỗi 51011), thống kê, 2 trigger (chặn/cho phép), đổi học phí (1 hóa đơn đổi, 4 hóa đơn đã thu giữ nguyên, 3 lỗi), thêm khóa + ngôn ngữ (thành công, rollback cả hai khi lỗi, mã trùng tên khác), gọi không có giao dịch ngoài | `SoCaPASS = 24`, `SoCaFAIL = 0`; dữ liệu mẫu không đổi |
| `sql/demo/04_PhanQuyen_MinhHoa.sql` | 12 ca dùng `EXECUTE AS USER`: GRANT, không cấp quyền, DENY, DENY mức cột (230), ownership chaining, REVOKE (và trả lại sau ROLLBACK), DENY thắng GRANT, không có quyền DDL (262) | `SoCaFAIL = 0`; quyền và dữ liệu không đổi |
| `sql/demo/05_Index_DuLieuLon_A.sql` | Bảng tạm 300.000 khóa học; đo `STATISTICS IO/TIME` và plan trước/sau 2 index; bước 6 chứng minh index trên `TenKhoa` không Seek được khi tìm chứa | Clustered Index Scan → Index Seek; logical reads giảm mạnh |
| `sql/demo/06_SaoLuu_KhoiPhuc_A.sql` | FULL recovery → full backup → thêm khóa hợp lệ → **DELETE nhầm** `DIEMDANH` → tail-log backup → `RESTORE … STOPAT` | 3 ca PASS: điểm danh được lấy lại, khóa hợp lệ **không mất**, CSDL ONLINE |

**Lưu ý demo 06:** script ngắt mọi kết nối khác tới CSDL (SINGLE_USER), nên phải đóng ứng dụng trước. Chạy cả file trong một cửa sổ query. File `.bak`/`.trn` lưu ở thư mục backup mặc định của SQL Server.

## 7. Ứng dụng Java

### 7.1 Khung dùng chung (`ttnn.common`, `Main`, `LoginDialog`, `MainFrame`)
- **Đăng nhập theo vai trò:** `JpaUtil.connect(...)` tạo EntityManagerFactory bằng chính SQL Login, rồi trong một câu lệnh lấy `@@SERVERNAME`, `DB_NAME()` và role qua `IS_ROLEMEMBER`. Tài khoản **không thuộc 4 role** (kể cả `sa` / sysadmin) **bị từ chối**, kèm thông báo lý do.
- **Tab theo vai trò** (chỉ *tạo* panel mà vai trò được dùng, vì panel tải dữ liệu ngay khi tạo):

| Tab | QuanTri | GiaoVu | KeToan | GiangVien |
|---|---|---|---|---|
| Khóa học (Kiên) | đầy đủ | chỉ xem, thống kê | chỉ xem, thống kê | – |
| Học viên và tài chính (B) | ✓ | – | ✓ | – |
| Lớp học và lịch (C) | ✓ | ✓ | – | – |
| Giảng dạy (D) | ✓ | ✓ | – | ✓ |

- Thanh trạng thái hiện máy chủ, CSDL, tài khoản, vai trò của phiên thật. Menu **Hệ thống → Đăng xuất / Thoát**.
- API mới cho các module: `JpaUtil.getCurrentRole()`, `JpaUtil.coVaiTro(VaiTro...)`, `getCurrentServer()`, `getCurrentDatabase()`; enum `ttnn.common.VaiTro`.

### 7.2 Màn hình khóa học (`ttnn.kien.*`)

| Màn hình | Thao tác | Đối tượng CSDL |
|---|---|---|
| Quản lý khóa học | Tìm theo tên / ngôn ngữ / trạng thái / khoảng học phí | `SP_TimKiemKhoaHoc` |
| | Thêm khóa (chọn "+ Ngôn ngữ mới..." để thêm luôn ngôn ngữ) — **đường duy nhất để thêm khóa** | `SP_ThemKhoaHoc_VaNgonNgu` |
| | Sửa tên, ngôn ngữ, trình độ, số buổi, trạng thái | entity `KhoaHoc` + 2 trigger |
| | Đổi học phí (báo số hóa đơn đã cập nhật) | `SP_CapNhatHocPhiKhoa` |
| | Xóa | entity `KhoaHoc` (FK chặn khóa đã có lớp) |
| Quản lý ngôn ngữ | Danh sách kèm số khóa / lớp / giảng viên | `V_THONGKE_NgonNgu` |
| | Thêm, sửa tên, xóa | entity `NgonNgu` |
| Thống kê khóa học | Tổng hợp khóa học | `V_KHOAHOC_ThongKe` (+ `FN_SoHocVien_KhoaHoc`) |
| | Số đăng ký theo khoảng ngày | `SP_ThongKeDangKy_TheoKhoa` |
| | Khóa đang giảng dạy theo ngôn ngữ | `FN_DSKhoaHoc_TheoNN` |

- Entity `KhoaHoc` khai báo `HocPhi` là `insertable = false, updatable = false`, nên Hibernate không bao giờ ghi vào cột bị DENY. Thêm khóa luôn qua thủ tục; đổi học phí luôn qua thủ tục.
- Không phải QuanTri thì form và các nút ghi bị **ẩn**, màn hình ghi "Chế độ chỉ xem".

## 8. Những gì Kiên đã thay đổi trong code gốc của B

Nguyên tắc: **giữ khung của B làm baseline**. Code trong `ttnn.nguoib.*` **không bị sửa dòng nào**. Chữ ký `JpaUtil.connect / read / inTx` và `DbErrors.message` **giữ nguyên**. Chi tiết từng dòng: `ThayDoi_SoVoiBanCuaB_PhanD_E.diff`.

| File | Thay đổi | Lý do |
|---|---|---|
| `common/JpaUtil.java` | Sau `SELECT 1`, lấy server/CSDL/role; từ chối tài khoản ngoài 4 role; thêm `getCurrentRole`, `coVaiTro`, `getCurrentServer`, `getCurrentDatabase`; `close()` xóa thêm thông tin phiên | Đăng nhập theo vai trò (rubric: đăng nhập/phân quyền đúng theo Role trong CSDL) |
| `common/VaiTro.java` | **Mới**: enum 4 vai trò ↔ tên role SQL ↔ tên hiển thị | Dùng chung cho `MainFrame` và các module A, B, C, D |
| `common/DbErrors.java` | Thêm thông báo cho `PK_NGONNGU`, `UQ_NGONNGU_TENNN`, `PK_KHOAHOC`, FK khi xóa ngôn ngữ/khóa học, 3 CHECK của `KHOAHOC`, lỗi 230 trên cột `HocPhi`. Câu mặc định lỗi 547 khi xóa bỏ phần "(đăng ký, hóa đơn...)" | Câu cũ chỉ đúng với bảng của B |
| `LoginDialog.java` | Đổi lời hướng dẫn; đăng nhập lỗi thì xóa ô mật khẩu và đặt con trỏ vào lại; Javadoc hướng dẫn SQLEXPRESS | Sửa, **không thay thế** như comment cũ của B dự tính |
| `MainFrame.java` | Tiêu đề chung; tab theo vai trò; thanh trạng thái; menu Đăng xuất; dòng thêm tab của C, D để sẵn dạng comment | Khung chính cho cả nhóm |
| `Main.java` | Tách hàm `batDau()` | Đăng xuất quay lại màn hình đăng nhập |
| `META-INF/persistence.xml` | Thêm `<class>` `ttnn.kien.entity.NgonNgu`, `KhoaHoc` | Entity của Kiên |

**Thay đổi hành vi B cần biết:**
- Login `sa` và `ttnn_demo_b` trước khi có role **không còn dùng** để đăng nhập ứng dụng. `ttnn_demo_b` vẫn dùng được vì thuộc `role_KeToan`.
- Phải chạy `Security_Roles.sql` trước, nếu không mọi tài khoản đều bị từ chối.
- README của B (dòng "hoặc dùng login `sa`") cần sửa.

## 9. Ghép với nhóm — hướng dẫn cho B, C, D
- **Thứ tự chạy SQL đầy đủ (máy trắng):**
  1. `nguoi_A/QLTTNgoaiNgu.sql` (⚠ `DROP DATABASE`)
  2. `nguoi_A/DataQLTTNgoaiNgu.sql`
  3. `nguoi_A/Module_A_KhoaHoc.sql`
  4. `nguoi_B/Module_B_HocVien_TaiChinh.sql`
  5. Module C, Module D
  6. `nguoi_A/Security_Roles.sql`
  7. `nguoi_B/Grant_Module_B.sql`, Grant C, Grant D
  8. Các file `Test_Module_X.sql`

  Chạy lại bước 1 thì phải chạy lại cả chuỗi. Login vẫn còn (cấp máy chủ), còn user và role được script tự tạo lại.
- **C, D:**
  - Viết `Grant_Module_X.sql` theo mẫu của B, cấp quyền cho cả 4 role trên đối tượng của mình.
  - Đặt code trong `ttnn.nguoic.*` / `ttnn.nguoid.*`, thêm `<class>` vào `persistence.xml`.
  - Trong `MainFrame.taoCacTab()`, bỏ comment dòng của mình và xác nhận vai trò được phép.
  - Trong màn hình, dùng `JpaUtil.coVaiTro(VaiTro.QUAN_TRI, …)` để ẩn hoặc hiện nút.
  - Thêm thông báo cho ràng buộc của mình vào `DbErrors` (thêm `case`, không đổi cấu trúc).
- **Mã lỗi:** 51000–51999 chỉ dùng cho Kiên.
- Đối tượng của Kiên không gọi đối tượng của người khác, nên chạy độc lập, không phụ thuộc thứ tự ghép module.

## 10. Giới hạn thiết kế và quyết định đã chốt
- Đổi học phí cập nhật **mọi** hóa đơn *Chưa thanh toán* của khóa, **kể cả lớp đã kết thúc**. Hóa đơn đã thu một phần hoặc thu đủ giữ nguyên.
- Đổi học phí về **0**: trigger của B sẽ tự chuyển các hóa đơn chưa thu sang *Đã thanh toán đủ*. Đã chấp nhận (khóa miễn phí coi như đã đủ).
- Mã khóa `VARCHAR(6)` → tối đa `KH9999`. Mã ngôn ngữ `CHAR(3)`, ứng dụng tự viết hoa. Trình độ là chữ tự do (tối đa 10 ký tự, gợi ý "So cap / Trung cap / Cao cap" như dữ liệu mẫu).
- Mỗi login chỉ nên thuộc một role. Nếu thuộc nhiều role, ứng dụng lấy role theo thứ tự QuanTri → GiaoVu → KeToan → GiangVien, nhưng CSDL vẫn áp dụng DENY của mọi role (DENY thắng GRANT).

## 11. Tiến độ và mức độ kiểm chứng (cập nhật 07/10/2026)

| Hạng mục | Trạng thái |
|---|---|
| Schema + dữ liệu mẫu | Xong, đang dùng chung |
| Module A (12 đối tượng) | Xong, **đã chạy trên SQL Server thật**: `Test_Module_A` được 24/24 PASS.
| Phân quyền + demo 04 | Xong; demo 04 cần chạy lại sau khi có đủ Module B |
| Demo 05 (index), 06 (khôi phục) | Xong; chưa chạy thật |
| Khung ứng dụng (D) + 3 màn hình (E) | Xong; biên dịch sạch toàn bộ ứng dụng bằng JDK 17 (đối chiếu API JPA tối thiểu), phần kiểm tra dữ liệu nhập đã chạy thử; **phần gọi Hibernate/SQL Server chưa chạy thật** |
| Báo cáo Chương 1, 2, 4 + slide | Chưa làm |

Nếu một câu lệnh hay màn hình báo lỗi trên máy của bạn, gửi thông báo lỗi cho Kiên.
