# Tài liệu kỹ thuật — Thành viên D (Giảng viên và giảng dạy)

## 1. Phạm vi và ràng buộc đã thống nhất

- Bảng phụ trách: `GIANGVIEN`, `BUOIHOC`, `DIEMDANH`. Schema đã đóng băng: chỉ **thêm** đối tượng, không sửa bảng.
- Quy ước chung: tiền tố `TRG_` / `V_` / `IX_` / `SP_` / `FN_`; `SET NOCOUNT ON`; trigger chỉ `THROW`; thủ tục giao dịch dùng mẫu `@@TRANCOUNT` + `SAVE TRANSACTION` (giống module B).
- Mã lỗi của D: **54001 – 54099**.
- Quy ước thứ trong tuần: Chủ Nhật = 1 … Thứ 7 = 7 (khớp `LICHHOC.Thu`); thủ tục không phụ thuộc `SET DATEFIRST`.
- Giao diện: Swing + JPA theo khung của Kiên (`JpaUtil`, `DbErrors`, `Convert`, `UiUtil`, `SimpleTableModel`).

## 2. Mười hai đối tượng

| # | Loại | Đối tượng | Mục đích |
|---|------|-----------|----------|
| 1 | Function (scalar) | `FN_TyLeChuyenCan(@MaDK)` | Tỷ lệ có mặt (%) của một đăng ký; `NULL` nếu chưa điểm danh |
| 2 | Function (inline TVF) | `FN_DSGiangVien_TheoNN(@MaNN)` | Giảng viên đang công tác của một ngôn ngữ + số lớp đang phụ trách |
| 3 | View | `V_CHUYEN_CAN` | Chuyên cần theo đăng ký, kèm tỷ lệ cả lớp (hàm cửa sổ) |
| 4 | View | `V_GIANGVIEN_TaiTrong` | Số lớp, số buổi đã dạy, số buổi dạy thay của từng giảng viên |
| 5 | Index | `IX_BUOIHOC_MaLop_Ngay` (MaLop, NgayHocThucTe) INCLUDE (MaGV_Day, TrangThaiBuoiHoc) | Tra buổi học theo lớp và khoảng ngày |
| 6 | Index | `IX_DIEMDANH_MaDK` (MaDK) INCLUDE (TrangThaiDiemDanh) | Tra điểm danh theo đăng ký (hàm, view chuyên cần, kiểm tra FK) |
| 7 | Trigger | `TRG_DIEMDANH_DungLop` | Điểm danh đúng lớp của buổi; chỉ buổi "Đã diễn ra" (54001, 54002) |
| 8 | Trigger | `TRG_GIANGVIEN_NghiViec` | Không cho nghỉ khi còn là GV chính của lớp đang tuyển sinh/đang học (54003) |
| 9 | Procedure | `SP_ThongKeChuyenCan_Lop(@MaLop, @NguongCanhBao=80)` | Báo cáo chuyên cần một lớp, cảnh báo dưới ngưỡng |
| 10 | Procedure | `SP_LichDay_GiangVien(@MaGV, @TuNgay, @DenNgay)` | Lịch dạy thực tế (kể cả dạy thay), mặc định tháng hiện tại |
| 11 | Transaction | `SP_DiemDanh_CaLop(@MaBuoi, @DanhSach JSON)` | Điểm danh cả buổi: tất cả hoặc không gì cả |
| 12 | Transaction | `SP_BanGiaoLop_KhiGVNghi(@MaGV_Nghi, @MaGV_Moi, @TrangThaiMoi)` | Bàn giao lớp rồi mới cho giảng viên nghỉ, trong một giao dịch |

Lưu ý thiết kế:
- Tỷ lệ chuyên cần = số lượt "Có mặt" / số lượt **đã điểm danh** của đăng ký (không phải số buổi của lớp), nên học viên vào muộn không bị tính thiếu; "Vắng có phép" vẫn không tính là có mặt. `V_CHUYEN_CAN` gọi `FN_TyLeChuyenCan` để định nghĩa này chỉ nằm một nơi.
- `V_GIANGVIEN_TaiTrong` dùng subquery tương quan riêng cho từng phép đếm để các số đếm không nhân dòng lẫn nhau.
- `SP_LichDay_GiangVien` lấy giờ/phòng từ `LICHHOC` bằng `OUTER APPLY` theo thứ trong tuần của ngày học; buổi học bù ngoài lịch có giờ/phòng `NULL`.

## 3. Mẫu giao dịch (2 thủ tục có giao dịch)

Giống `SP_DangKy_VaTaoHoaDon` của B, vì ứng dụng gọi qua `JpaUtil.inTx` (đã có giao dịch JDBC):

```
DECLARE @TranCount INT = @@TRANCOUNT;
BEGIN TRY
    IF @TranCount = 0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION SV_...;
    ... kiểm tra, ghi ...
    IF @TranCount = 0 COMMIT TRANSACTION;        -- lệnh cuối của TRY
END TRY
BEGIN CATCH
    IF XACT_STATE() = -1 ROLLBACK TRANSACTION;
    ELSE IF XACT_STATE() = 1 BEGIN
        IF @TranCount = 0 ROLLBACK TRANSACTION; ELSE ROLLBACK TRANSACTION SV_...;
    END;
    THROW;
END CATCH
```
Gọi từ SSMS (không có giao dịch) thì thủ tục tự `BEGIN/COMMIT`. Hai thủ tục tra cứu chỉ đọc nên `CATCH` chỉ `THROW`, không đụng giao dịch của nơi gọi.

`SP_DiemDanh_CaLop` làm hai pha: (1) kiểm tra hết (buổi tồn tại và đã diễn ra, JSON hợp lệ, không rỗng, không trùng mã, trạng thái hợp lệ, mọi đăng ký thuộc đúng lớp, ghi chú ≤ 100 ký tự) rồi (2) ghi: cập nhật dòng đã có, thêm dòng chưa có. Một dòng sai thì không ghi gì và thông báo nêu đúng mã sai. Cần SQL Server 2016 trở lên, compatibility level ≥ 130 (`OPENJSON`).

`SP_BanGiaoLop_KhiGVNghi`: khóa các lớp cần bàn giao (`UPDLOCK, HOLDLOCK`) rồi đếm; người nhận phải nằm trong `FN_DSGiangVien_TheoNN` của ngôn ngữ giảng viên nghỉ (khớp quy tắc `TRG_LOP_KiemTraGV` của C); thứ tự bắt buộc là chuyển lớp **trước**, đổi trạng thái giảng viên **sau** (đổi ngược sẽ bị `TRG_GIANGVIEN_NghiViec` chặn). Lớp "Đã kết thúc" giữ nguyên để lưu lịch sử. `@MaGV_Moi` được `NULL` khi không còn lớp cần bàn giao.

## 4. Mã lỗi `THROW` của D (54001 – 54099)

| Mã | Nguồn | Ý nghĩa |
|----|-------|---------|
| 54001 / 54002 | `TRG_DIEMDANH_DungLop` | Đăng ký không thuộc lớp của buổi / buổi không ở trạng thái "Đã diễn ra" |
| 54003 | `TRG_GIANGVIEN_NghiViec` | Giảng viên còn là GV chính của lớp đang hoạt động |
| 54010 / 54011 | `SP_ThongKeChuyenCan_Lop` | Lớp không tồn tại / ngưỡng ngoài 0..100 |
| 54020 / 54021 | `SP_LichDay_GiangVien` | Giảng viên không tồn tại / khoảng ngày ngược |
| 54030 – 54037 | `SP_DiemDanh_CaLop` | Buổi không tồn tại; buổi không diễn ra; JSON sai; danh sách rỗng; trùng mã; trạng thái sai; đăng ký sai lớp; ghi chú quá dài |
| 54040 – 54044 | `SP_BanGiaoLop_KhiGVNghi` | GV nghỉ không tồn tại; trạng thái mới sai; người nhận trùng người nghỉ; thiếu người nhận; người nhận không hợp lệ |

`DbErrors.message` trả nguyên thông báo tiếng Việt cho mọi mã ≥ 50000 nên màn hình không cần xử lý riêng.

## 5. Phân quyền (`Grant_Module_D.sql`)

| Đối tượng | QuanTri | GiaoVu | KeToan | GiangVien |
|-----------|---------|--------|--------|-----------|
| `GIANGVIEN` | S/I/U/D | S | — | S |
| `BUOIHOC` | S/I/U/D | S/I/U | — | S |
| `DIEMDANH` | S/I/U/D | S/I/U | DENY I/U/D | S/I/U, DENY D |
| `V_CHUYEN_CAN`, `FN_TyLeChuyenCan`, `SP_ThongKeChuyenCan_Lop`, `SP_LichDay_GiangVien` | có | có | — | có |
| `V_GIANGVIEN_TaiTrong`, `FN_DSGiangVien_TheoNN` | có | có | — | — |
| `SP_DiemDanh_CaLop` | EXECUTE | EXECUTE | DENY | EXECUTE |
| `SP_BanGiaoLop_KhiGVNghi` | EXECUTE | DENY | DENY | DENY |

Thủ tục/view/hàm thuộc `dbo` cùng chủ với bảng nên nhờ ownership chaining chỉ cần `EXECUTE`/`SELECT` trên đối tượng. Màn hình D còn đọc `LOP`, `KHOAHOC` để chọn lớp nên file cấp `SELECT` cho GiaoVu và GiangVien (cấp lại không xung đột với C). **Chạy sau `Security_Roles.sql`.**

## 6. Kịch bản kiểm thử (`Test_Module_D.sql`)

Mỗi ca chạy trong giao dịch riêng rồi `ROLLBACK`, kết thúc bằng bảng PASS/FAIL; mong đợi `SoCaFAIL = 0` (41 ca). Số liệu kỳ vọng tính tay từ dữ liệu mẫu, ví dụ `DK002` = 66.67%, LOP001 = 77.78%, GV02 = (1 lớp chính, 1 đang phụ trách, 2 buổi đã dạy, 1 buổi dạy thay).

| Ca | Nội dung |
|----|----------|
| D01 | Có đủ 2 index |
| D02 – D05 | 2 hàm và 2 view đúng số liệu mẫu |
| D06 – D07 | 2 thủ tục tra cứu: kết quả đúng, cảnh báo, mặc định ngày, lỗi 54010/54011/54020/54021 |
| D08 – D09 | Trigger điểm danh: sai lớp (INSERT và UPDATE), buổi Hoãn bị chặn; điểm danh hợp lệ được chấp nhận |
| D10 | Trigger nghỉ việc: GV02/GV04 bị chặn; GV05 nghỉ được, sửa họ tên và kích hoạt lại GV06 được |
| D11 – D12 | `SP_DiemDanh_CaLop`: thêm rồi cập nhật, sửa buổi cũ; 8 loại lỗi; dòng sai thì buổi không đổi |
| D13 | `SP_BanGiaoLop_KhiGVNghi`: thành công, không cần người nhận, 6 loại lỗi, lỗi trong giao dịch ngoài |
| D14 | Dữ liệu mẫu không đổi sau toàn bộ các ca |

## 7. Demo cho báo cáo (Chương 3 và 5)

- `sql/demo/07_Index_DuLieuLon_D.sql`: giống cách của B, **không đụng bảng thật**. Tạo `DEMO_D_BUOIHOC` (100.000 dòng) và `DEMO_D_DIEMDANH` (1.000.000 dòng) chỉ có khóa chính, đo 3 truy vấn trước/sau khi tạo đúng 2 index của D (Scan → Seek), có bước xem dung lượng index và bước xóa bảng tạm.
- `Grant_Module_D.sql` mục 4: kịch bản `EXECUTE AS USER` chứng minh phân quyền (đã comment sẵn).
- Ảnh cần chụp cho Chương 5: 5 màn hình của tab "Giảng dạy" (Giảng viên, Buổi học, Điểm danh, Báo cáo chuyên cần, Lịch dạy) với từng role; hộp thoại "Cho nghỉ và bàn giao lớp"; thông báo lỗi khi cho GV02 nghỉ trực tiếp (54003).

## 8. Giới hạn thiết kế và điều cần biết

- Phân quyền theo bảng/thủ tục, chưa theo hàng: một tài khoản `role_GiangVien` xem được lịch dạy và điểm danh của mọi giảng viên. Hệ thống cũng chưa gắn tài khoản đăng nhập với một mã giảng viên cụ thể nên màn "Lịch dạy" chọn giảng viên thủ công. Hướng phát triển: Row-Level Security.
- Chưa có trigger chặn đổi một buổi **đã có điểm danh** sang "Hoãn"/"Hủy"; hiện phụ thuộc quy trình giáo vụ.
- Chưa phát hiện giảng viên bị xếp trùng giờ; `SP_BanGiaoLop_KhiGVNghi` chưa kiểm tra lịch của người nhận.
- Màn "Điểm danh" mặc định học viên chưa có bản ghi là "Có mặt" để giáo viên chỉ phải đổi người vắng; nhắc người dùng kiểm tra lại trước khi bấm Lưu.
- Ứng dụng đặt mã buổi/mã giảng viên bằng `MAX(...)+1` có `UPDLOCK, HOLDLOCK`; đủ cho đồ án, môi trường thật nên dùng `SEQUENCE`.
- Cột `CHAR(n)` ánh xạ bằng `columnDefinition = "CHAR(n)"`; `hbm2ddl.auto = none`.

## 9. Ghép với nhóm — tránh xung đột

- Chỉ **thêm** thư mục `sql/nguoi_D/`, `…/ttnn/nguoid/`, `docs/TaiLieu_NguoiD.md`, `sql/demo/07_Index_DuLieuLon_D.sql`; sửa chung đúng 2 chỗ: 4 dòng `<class>` trong `persistence.xml` và bỏ comment khối "D - Giang day" trong `MainFrame.taoCacTab()`.
- Thứ tự chạy SQL: schema → dữ liệu mẫu → Module A, B, C, D → `Security_Roles.sql` → `Grant_Module_*.sql` → `Test_Module_*.sql`.
- Việc cần C xác nhận: (1) `TRG_LOP_KiemTraGV` có khớp quy tắc "GV chính phải đang công tác và cùng ngôn ngữ" mà `SP_BanGiaoLop_KhiGVNghi` giả định; (2) C có trigger nào trên `BUOIHOC` hoặc `LOP` có thể chặn các ca test D09, D11, D13 không; (3) dải mã lỗi của C (dự kiến 530xx).
