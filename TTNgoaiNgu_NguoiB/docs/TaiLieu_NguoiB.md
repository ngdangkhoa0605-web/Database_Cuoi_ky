# Tài liệu kỹ thuật — Nguyễn Đăng Khoa, MSSV 24110255 (Học viên và tài chính)

## 1. Phạm vi và ràng buộc đã thống nhất
- Bảng phụ trách: `HOCVIEN`, `DANGKY`, `HOADON`. Schema của Người A **đóng băng**: không thêm/sửa cột hay bảng.
- Quy ước tên: `TRG_` / `V_` / `IX_` / `SP_` / `FN_`. Mọi trigger và procedure bắt đầu `SET NOCOUNT ON`.
- Mọi procedure có `TRY…CATCH`: lỗi thì `ROLLBACK` rồi `THROW` cho ứng dụng.
- Mã lỗi `THROW` của Nguyễn Đăng Khoa (24110255) dùng dải **52000–52999**, không trùng người khác (xem mục 5).
- Đối tượng của Nguyễn Đăng Khoa (24110255) **không gọi** đối tượng của người khác (ví dụ không dùng `FN_SiSoHienTai` của Người C mà đếm trực tiếp trên `DANGKY`), nên chạy độc lập, không phụ thuộc thứ tự ghép.

## 2. Mười hai đối tượng theo kế hoạch (+1 bổ sung)

| # | Loại | Tên | Mục đích |
|---|---|---|---|
| 1 | Trigger | `TRG_DANGKY_SiSo` | Chỉ cho đăng ký vào lớp *Đang tuyển sinh/Đang học* và chưa vượt `SiSoToiDa`. Chỉ kiểm dòng **mới thêm hoặc đổi sang lớp khác** → sửa điểm ở lớp đã kết thúc vẫn được. |
| 2 | Trigger | `TRG_HOADON_TuDongTrangThai` | Tự đặt `TrangThaiThanhToan` và `NgayThanhToan` theo `SoTienDaThu`/`SoTienCanThu` (đủ / một phần / chưa). |
| 3 | View | `V_CONGNO_HocPhi` | Mỗi đăng ký còn nợ: học viên, lớp, khóa, số tiền nợ (`FN_TinhCongNo`), số ngày kể từ ngày đăng ký. |
| 4 | View | `V_HOCVIEN_LichSuHoc` | Học viên – lớp – khóa – điểm – thanh toán (LEFT JOIN hóa đơn nên đăng ký chưa có hóa đơn vẫn hiện). |
| 5 | Index | `IX_DANGKY_MaLop` (`MaLop` INCLUDE `MaHV`) | `UNIQUE(MaHV, MaLop)` có sẵn bắt đầu bằng `MaHV` nên **không** phục vụ tìm theo lớp; FK `MaLop` cũng chưa có index. |
| 6 | Index | `IX_HOCVIEN_HoTen` (`HoTen`) | Tra cứu theo họ tên (bảng chỉ có index theo `MaHV`, `SDT`, `Email`). |
| 7 | Procedure | `SP_TimKiemHocVien` | Tìm theo tên/SĐT/email, khớp một phần, bỏ qua tiêu chí rỗng, escape ký tự `% _ [ \`. |
| 8 | Procedure | `SP_ThongKeDoanhThu` | Doanh thu theo tháng / khóa / tháng+khóa; mọi kiểu nhóm trả cùng một bộ cột. |
| 9 | Function (vô hướng) | `FN_TinhCongNo(@MaDK)` | Còn nợ của một đăng ký; `NULL` nếu chưa có hóa đơn. |
| 10 | Function (bảng) | `FN_DSDangKy_HocVien(@MaHV)` | Lịch sử đăng ký + hóa đơn + công nợ của một học viên. |
| 11 | Transaction | `SP_DangKy_VaTaoHoaDon` | Thêm đăng ký + tạo hóa đơn trong **một** giao dịch, chống tranh chấp "chỗ cuối". |
| 12 | Transaction | `SP_ThanhToanHocPhi` | Ghi nhận thu tiền, chống thu vượt, khóa dòng hóa đơn. |
| + | Transaction | `SP_HuyDangKy` | Hủy đăng ký + hóa đơn (chỉ khi chưa thu tiền, chưa có điểm/điểm danh). |

## 3. Mẫu giao dịch "lồng an toàn" (dùng cho 3 procedure có giao dịch)

JPA/SSMS có thể đã mở sẵn giao dịch khi gọi procedure. Mỗi procedure:
1. Ghi `@TranCount = @@TRANCOUNT` ở đầu.
2. `@TranCount = 0` → tự `BEGIN TRANSACTION` và `COMMIT` ở **lệnh cuối khối TRY**.
3. `@TranCount > 0` → chỉ `SAVE TRANSACTION`; khi lỗi chỉ rollback về savepoint, **không** commit hộ giao dịch ngoài.
4. `XACT_STATE() = -1` (giao dịch hỏng) → rollback toàn bộ.
5. `CATCH` luôn `THROW` lại.

Nhờ đó cùng một procedure chạy đúng khi gọi từ ứng dụng (đã có giao dịch JPA) lẫn khi chạy thẳng trong SSMS.

## 4. Chống tranh chấp "chỗ cuối" trong `SP_DangKy_VaTaoHoaDon`
Tình huống: lớp còn 1 chỗ, hai nhân viên cùng đăng ký hai học viên khác nhau.
- Khóa dòng `LOP` bằng `UPDLOCK, HOLDLOCK` ngay đầu: các phiên đăng ký **cùng lớp xếp hàng** (khóa U không tương thích nhau nên không deadlock).
- Đếm sĩ số trên `DANGKY` bằng `UPDLOCK, HOLDLOCK` (khóa dải) → không phiên khác chèn thêm dòng của lớp này khi chưa xong.
- Đọc học phí `KHOAHOC` bằng `HOLDLOCK` → `SP_CapNhatHocPhiKhoa` (Kiên) không đổi học phí giữa chừng.
- Sinh mã `DKxxx`/`HDxxx` tuần tự bằng `sp_getapplock` (khóa theo giao dịch, tự nhả khi commit/rollback).
- `TRG_DANGKY_SiSo` là lớp bảo vệ **cuối cùng** (chặn ghi trực tiếp vào bảng).

`SP_ThanhToanHocPhi`: khóa dòng hóa đơn `UPDLOCK, HOLDLOCK` rồi mới cộng tiền → hai thu ngân không ghi đè nhau.

## 5. Mã lỗi `THROW` của Nguyễn Đăng Khoa (24110255)

| Mã | Nơi phát sinh | Ý nghĩa |
|---|---|---|
| 52001 / 52002 | `TRG_DANGKY_SiSo` | lớp không nhận đăng ký / vượt sĩ số |
| 52010–52013 | `SP_ThongKeDoanhThu` | nhóm sai / tháng sai / thiếu năm / năm sai |
| 52020–52030 | `SP_DangKy_VaTaoHoaDon` | thiếu tham số, ngày tương lai, tiền âm, học viên/lớp không tồn tại, lớp không nhận, khóa ngừng tuyển sinh, thu ngay vượt học phí, đăng ký trùng, hết chỗ (52029), bận sinh mã |
| 52040–52045 | `SP_ThanhToanHocPhi` | thiếu mã, tiền ≤ 0, ngày tương lai, hóa đơn không tồn tại, thu trước ngày đăng ký, thu vượt (52045) |
| 52050–52054 | `SP_HuyDangKy` | không tồn tại, đã có điểm, đã có điểm danh, đã thu tiền |

Ứng dụng đổi lỗi này (và các lỗi hệ thống thường gặp: trùng khóa 2627, FK 547, deadlock 1205, sai mật khẩu 18456…) thành thông báo tiếng Việt trong `ttnn.common.DbErrors`.

## 6. Kịch bản kiểm thử (`Test_Module_B.sql`)
Số liệu mong đợi tính tay từ dữ liệu mẫu của Người A:

| Ca | Nội dung | Kỳ vọng |
|---|---|---|
| T01 | Có 2 index | 2 |
| T02 | `FN_TinhCongNo` | DK002 = 1.500.000; DK003 = 3.000.000; DK001 = 0; DK999 = NULL |
| T03 | `FN_DSDangKy_HocVien('HV001')` | 1 dòng DK001/LOP001, nợ 0 |
| T04 | `V_CONGNO_HocPhi` | 5 dòng, tổng nợ 12.700.000 |
| T05 | `V_HOCVIEN_LichSuHoc` | 10 dòng; DK009 điểm 8.5 |
| T06 | `SP_TimKiemHocVien` | theo tên/SĐT/email đúng; `%` được escape (0 dòng); không tiêu chí = 10 dòng |
| T07 | `SP_ThongKeDoanhThu` | tổng 21.500.000; 01/2026 = 6.500.000 (2 HĐ); KH0001 = 10.500.000; tháng 13 → lỗi 52011 |
| T08 | `TRG_HOADON_TuDongTrangThai` | một phần → đủ → chưa thanh toán (ngày thu về NULL) |
| T09a–c | `TRG_DANGKY_SiSo` | lớp kết thúc bị chặn (52001); vượt sĩ số bị chặn (52002); sửa điểm lớp kết thúc vẫn được |
| T10 | đăng ký thành công | mã DK012/HD012 sau hai lần gọi; đúng học phí; thu ngay một phần |
| T11a–f | đăng ký phải lỗi | trùng 52028; lớp kết thúc 52025; học viên 52023; lớp 52024; đầy 52029; khóa ngừng tuyển 52026 |
| T12 | không giao dịch ngoài | tự COMMIT; `SP_HuyDangKy` xóa sạch; `@@TRANCOUNT = 0` |
| T13a–e | thu tiền | thu đủ/một phần đúng; thu vượt 52045; thu 0 → 52041; hóa đơn lạ → 52043 |
| T14 | hủy đăng ký có điểm | lỗi 52052 |

Mọi ca chạy trong giao dịch riêng rồi `ROLLBACK`, **trừ T12** tạo rồi hủy một đăng ký thật (kết quả cuối bằng 0).

## 7. Demo cho báo cáo (Chương 3 và 5)
- **Index** (`demo/01_…`): tạo bảng tạm 200.000 học viên / 500.000 đăng ký (không đụng bảng thật), đo `STATISTICS IO/TIME` và plan *trước* và *sau* khi tạo index; xuất kích thước index để nêu đánh đổi (tốn dung lượng, ghi chậm hơn). Chụp tab Messages và Execution Plan.
- **Tranh chấp** (`demo/02_…`, `03_…`): lớp `LCC001` còn 1 chỗ. PHẦN 1 dùng thủ tục mẫu **không khóa** → hai cửa sổ cùng thành công, lớp 3/2 (sai). PHẦN 2 dùng `SP_DangKy_VaTaoHoaDon` → cửa sổ 2 bị chặn rồi nhận lỗi 52029, lớp 2/2 (đúng). Script tạm tắt `TRG_DANGKY_SiSo` để lộ lỗi của cách viết không khóa và bật lại ở bước dọn dẹp.

## 8. Giới hạn thiết kế và điều cần biết
- `HOADON` chỉ lưu **tổng đã thu** và **ngày thu gần nhất** (không lưu từng đợt). Vì vậy `SP_ThongKeDoanhThu` tính doanh thu của hóa đơn vào tháng của lần thu gần nhất. Muốn doanh thu chính xác theo từng đợt thu phải thêm bảng phiếu thu — thay đổi schema, cần Người A đồng ý.
- Mã học viên `CHAR(5)` nên tối đa `HV999`; ứng dụng báo rõ khi hết dải. Mã `DK`/`HD` sinh trong procedure.
- Chưa có mục "hoàn tiền"; `SP_HuyDangKy` từ chối hủy hóa đơn đã thu tiền.
- Ứng dụng tìm lớp mở bằng truy vấn **chỉ đọc** trên `LOP`/`KHOAHOC` của người khác (không dùng entity của họ). Nếu Người C có view/hàm tiện hơn, thay trong `DangKyService.lopDangMo()`.
- **Chưa thực thi trên SQL Server thật** (môi trường soạn gói không có SQL Server/Maven): T-SQL đã qua kiểm tra cú pháp, Java đã biên dịch sạch. Hãy chạy `Test_Module_B.sql` và thử từng màn hình sau khi cài. Nếu một câu lệnh báo lỗi trên phiên bản SQL Server của bạn, gửi lại thông báo để sửa.

## 9. Ghép với nhóm — tránh xung đột
- **Tên đối tượng**: tiền tố thống nhất, không trùng danh sách của A/C/D trong kế hoạch.
- **Mã lỗi**: 52000–52999 chỉ dùng cho B.
- **Module SQL độc lập**: chỉ tạo đối tượng của B; chạy lại nhiều lần không lỗi (`CREATE OR ALTER`, kiểm tra tồn tại trước khi tạo index). `Grant_Module_B.sql` không tạo role (chỉ GRANT khi role đã có).
- **Java**: mã của B nằm trong `ttnn.nguoib.*`; hạ tầng dùng chung ở `ttnn.common.*` (khung tối thiểu để chạy độc lập). Khi ghép với khung của Kiên, chỉ cần cung cấp lại `JpaUtil.read(...)` / `JpaUtil.inTx(...)` cùng chữ ký (và `DbErrors.message`) rồi xóa `ttnn.common` của gói này; thêm `<class>` của B vào `persistence.xml` chung; gắn `new ModuleBPanel()` vào menu chính.
- **Entity**: `DangKy` không khai báo quan hệ tới `Lop`, nên không phụ thuộc entity của Người C.
