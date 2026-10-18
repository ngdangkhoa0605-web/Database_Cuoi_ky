TÀI LIỆU KỸ THUẬT --- NGƯỜI C Module C: Quản lý lớp học và lịch học

Môn DBMS330284 · CSDL QL_TTNgoaiNgu · Bảng phụ trách: LOP, LICHHOC

## 1. Phạm vi và ràng buộc đã thống nhất

-   Bảng phụ trách: LOP và LICHHOC. Các bảng liên quan để đọc dữ liệu
    gồm KHOAHOC, GIANGVIEN, DANGKY và BUOIHOC.

-   Schema chung của nhóm được xem là đóng băng: không tự ý thêm/sửa cột
    hoặc bảng. Module C bổ sung trigger, view, index, procedure và
    function.

-   Quy ước tên: TRG\_ / V\_ / IX\_ / SP\_ / FN\_. Mọi trigger và
    procedure trong Module C dùng SET NOCOUNT ON.

-   Các procedure có xử lý lỗi dùng TRY...CATCH và THROW để truyền lỗi
    về ứng dụng. Hai procedure giao dịch có xử lý giao dịch ngoài bằng
    @@TRANCOUNT và SAVE TRANSACTION.

-   Mã lỗi riêng của Module C: 53001--53099. Không dùng dải 51000--51999
    của Người A hoặc 52000--52999 của Người B.

-   File SQL chính: Module_C_Lop_LichHoc.sql. File phân quyền:
    Grant_Module_C.sql hoặc bản đã cập nhật Grant_Module_C_revised.sql.
    File kiểm thử: Test_Module_C.sql.

## 2. Mười hai đối tượng SQL

| \# \| Loại \| Tên \| Mục đích \|

| --- \| --- \| --- \| --- \|

| 1 \| Trigger \| TRG_LOP_KiemTraGV \| Khi INSERT/UPDATE LOP, kiểm tra
  giảng viên chính đang công tác và có cùng ngôn ngữ với khóa học của
  lớp. \|

| 2 \| Trigger \| TRG_LICHHOC_ChongLanGio \| Chặn khoảng thời gian lịch
  bị chồng lấn trong cùng phòng/cùng thứ; đồng thời chặn hai lịch của
  cùng lớp chồng lấn trong cùng thứ. \|

| 3 \| View \| V_LICH_HOC_TUAN \| Hiển thị lịch học kèm lớp, khóa học,
  giảng viên, thứ dạng chữ, giờ học, phòng và trạng thái lớp. \|

| 4 \| View \| V_LOP_TinhTrang \| Hiển thị thông tin lớp, khóa, giảng
  viên, sĩ số hiện tại, sĩ số tối đa và tỷ lệ lấp đầy. \|

| 5 \| Index \| IX_LOP_MaKH_TrangThai \| Index trên (MaKH, TrangThai),
  INCLUDE MaGV_Chinh, NgayKhaiGiang, NgayKetThuc, SiSoToiDa; hỗ trợ truy
  vấn lớp theo khóa và trạng thái. \|

| 6 \| Index \| IX_LOP_MaGV_Chinh \| Index trên MaGV_Chinh, INCLUDE
  MaKH, TrangThai, NgayKhaiGiang, NgayKetThuc; hỗ trợ lọc lớp theo giảng
  viên. \|

| 7 \| Procedure \| SP_TimKiemLop \| Tìm lớp theo mã khóa, mã GV chính,
  trạng thái và khoảng ngày khai giảng. \|

| 8 \| Procedure \| SP_LichHoc_TheoPhong \| Tra cứu lịch sử dụng một
  phòng, tùy chọn lọc theo thứ. \|

| 9 \| Function vô hướng \| FN_SiSoHienTai(@MaLop) \| Đếm số dòng đăng
  ký của lớp trong DANGKY; trả về 0 nếu không có đăng ký. \|

| 10 \| Function bảng \| FN_DSLichHoc_Lop(@MaLop) \| Trả về danh sách
  lịch học của một lớp. \|

| 11 \| Transaction procedure \| SP_TaoLop_VaLichHoc \| Tạo lớp và một
  hoặc nhiều lịch học trong cùng giao dịch; lỗi dữ liệu lịch sẽ làm
  rollback. \|

| 12 \| Transaction procedure \| SP_KetThucLop \| Kết thúc lớp khi không
  còn buổi học ở trạng thái chưa diễn ra/chưa hủy. \|

## 3. Quy tắc nghiệp vụ chính

-   Giảng viên chính của lớp phải có TrangThai = N'Đang công tác' và
    MaNN trùng với MaNN của KHOAHOC tương ứng; nếu sai, trigger phát
    sinh lỗi 53001.

-   Lịch bị chồng lấn khi cùng phòng và cùng thứ, với điều kiện
    GioBatDau_mới \< GioKetThuc_cũ và GioBatDau_cũ \< GioKetThuc_mới.
    Lịch của cùng lớp cũng không được chồng lấn trong cùng thứ.

-   Quy ước Thu: 1 = Chủ Nhật, 2 = Thứ 2, ..., 7 = Thứ 7.

-   SP_TimKiemLop hỗ trợ các tham số tùy chọn @MaKH, @MaGV_Chinh,
    @TrangThai, @TuNgay, @DenNgay. Nếu cả hai ngày được truyền vào thì
    @DenNgay không được nhỏ hơn @TuNgay.

-   SP_LichHoc_TheoPhong yêu cầu phòng không rỗng; nếu truyền @Thu thì
    giá trị phải nằm trong khoảng 1--7.

-   SP_TaoLop_VaLichHoc yêu cầu danh sách XML có ít nhất một lịch, ngày
    kết thúc sau ngày khai giảng, sĩ số tối đa lớn hơn 0, lịch đủ thông
    tin và giờ kết thúc sau giờ bắt đầu.

-   SP_KetThucLop từ chối mã lớp không tồn tại; cũng từ chối kết thúc
    nếu lớp còn buổi học có trạng thái khác Đã diễn ra hoặc Hủy.

## 4. Giao dịch và tính toàn vẹn

SP_TaoLop_VaLichHoc và SP_KetThucLop kiểm tra @@TRANCOUNT khi bắt đầu:

-   @@TRANCOUNT = 0: procedure tự mở giao dịch và COMMIT khi thành công.

-   @@TRANCOUNT \> 0: procedure tạo SAVE TRANSACTION và không COMMIT
    thay giao dịch ngoài.

-   Khi lỗi, procedure rollback toàn bộ giao dịch do chính nó mở hoặc
    rollback về savepoint nếu giao dịch ngoài còn có thể rollback; sau
    đó THROW lại lỗi.

-   SP_TaoLop_VaLichHoc nhận @DanhSachLich dạng XML. Ví dụ cấu trúc:
    `<LichHoc>`{=html}`<Lich MaLich="LH000001" Thu="2" GioBatDau="08:00" GioKetThuc="10:00" PhongHoc="P101" />`{=html}`</LichHoc>`{=html}.

-   Lưu ý: trigger vẫn bảo vệ khi có thao tác INSERT/UPDATE trực tiếp
    vào LOP/LICHHOC, không chỉ khi gọi procedure. Không thử dữ liệu sai
    trên cơ sở dữ liệu thật nếu chưa sao lưu.

## 5. Mã lỗi THROW của Module C

| Mã lỗi \| Nơi phát sinh \| Ý nghĩa \|

| --- \| --- \| --- \|

| 53001 \| TRG_LOP_KiemTraGV \| Giảng viên chính không đang công tác
  hoặc không cùng ngôn ngữ với khóa học. \|

| 53002 \| TRG_LICHHOC_ChongLanGio \| Lịch bị chồng khoảng thời gian
  trong cùng phòng và cùng thứ. \|

| 53003 \| TRG_LICHHOC_ChongLanGio \| Một lớp có hai lịch chồng khoảng
  thời gian trong cùng thứ. \|

| 53004 \| SP_TimKiemLop \| Ngày kết thúc tìm kiếm nhỏ hơn ngày bắt đầu.
  \|

| 53005 \| SP_LichHoc_TheoPhong \| Phòng học không được để trống. \|

| 53006 \| SP_LichHoc_TheoPhong \| Thứ phải nằm trong khoảng 1--7. \|

| 53007 \| SP_TaoLop_VaLichHoc \| Danh sách lịch học không được để
  trống. \|

| 53008 \| SP_TaoLop_VaLichHoc \| Ngày kết thúc phải sau ngày khai
  giảng. \|

| 53009 \| SP_TaoLop_VaLichHoc \| Sĩ số tối đa phải lớn hơn 0. \|

| 53010 \| SP_TaoLop_VaLichHoc \| Danh sách có lịch thiếu thông tin hoặc
  thời gian không hợp lệ. \|

| 53011 \| SP_TaoLop_VaLichHoc \| Phải cung cấp ít nhất một lịch học. \|

| 53012 \| SP_KetThucLop \| Lớp học không tồn tại. \|

| 53013 \| SP_KetThucLop \| Còn buổi học chưa diễn ra hoặc chưa hủy nên
  chưa thể kết thúc lớp. \|

## 6. Phân quyền và tài khoản

| Role \| Quyền trong Module C \| Ý nghĩa \|

| --- \| --- \| --- \|

| role_QuanTri \| CRUD trên LOP/LICHHOC; SELECT view/function bảng;
  EXECUTE các procedure/function được cấp. \| Quản lý lớp và lịch. \|

| role_GiaoVu \| CRUD trên LOP/LICHHOC; SELECT view/function bảng;
  EXECUTE các procedure/function được cấp. \| Vai trò dùng để kiểm thử
  Module C. \|

| role_GiangVien \| Đọc view, function và procedure tra cứu; DENY
  INSERT/UPDATE/DELETE trên LOP/LICHHOC. \| Chỉ xem lớp và lịch, không
  sửa bảng. \|

| role_KeToan \| SELECT trên LOP. \| Đọc thông tin lớp phục vụ nghiệp vụ
  đăng ký. \|

Tài khoản kiểm thử ứng dụng: login ttnn_giaovu; mật khẩu demo
Ttnn@GiaoVu_2026!; database QL_TTNgoaiNgu; máy chủ HOANPC (theo cấu hình
hiện tại). Mật khẩu chỉ đúng nếu login chưa được tạo trước với mật khẩu
khác. Cần chạy Security_Roles.sql trước Grant_Module_C.sql.

Lưu ý kỹ thuật: trong script Grant_Module_C, FN_SiSoHienTai được cấp
EXECUTE; FN_DSLichHoc_Lop và các view được cấp SELECT. Không nên đổi
quyền tùy tiện nếu chưa kiểm tra cách SQL Server áp dụng quyền trên từng
loại function.

## 7. Kịch bản kiểm thử (Test_Module_C.sql)

| Ca \| Nội dung \| Kết quả mong đợi / ghi chú \|

| --- \| --- \| --- \|

| C01 \| Kiểm tra tồn tại 12 đối tượng \| Danh sách trả về đủ 2 trigger,
  2 view, 2 index, 4 procedure và 2 function. \|

| C02 \| Đọc V_LOP_TinhTrang \| Hiển thị tối đa 50 lớp, sĩ số và tỷ lệ
  lấp đầy; số dòng phụ thuộc dữ liệu mẫu. \|

| C03 \| Đọc V_LICH_HOC_TUAN \| Hiển thị tối đa 100 lịch học; dữ liệu
  sắp theo thứ, giờ và phòng. \|

| C04 \| Kiểm tra FN_SiSoHienTai và FN_DSLichHoc_Lop \| Tự lấy một mã
  lớp hiện có; nếu không có lớp thì in thông báo bỏ qua. \|

| C05 \| Chạy SP_TimKiemLop không truyền tham số \| Trả về các lớp theo
  thứ tự ngày khai giảng và mã lớp. \|

| C06 \| Chạy SP_LichHoc_TheoPhong \| Tự lấy một phòng hiện có rồi tra
  cứu lịch của phòng; nếu không có lịch thì in thông báo bỏ qua. \|

| C07 \| Kết thúc lớp không tồn tại ZZTEST \| Mong đợi lỗi 53012; không
  thay đổi dữ liệu. \|

| C08 \| Tạo lớp với ngày kết thúc trước ngày khai giảng \| Mong đợi lỗi
  53008 và không tạo lớp ZCTEST; xác nhận rollback. \|

| C09 \| Liệt kê các lịch đang chồng giờ cùng phòng/cùng thứ \| Kết quả
  bình thường cần rỗng; nếu có dòng thì dữ liệu hiện tại đã có lịch xung
  đột. \|

Test_Module_C.sql chủ yếu là script kiểm tra/đối chiếu: các phần 1--4
chỉ đọc dữ liệu; phần 5--6 cố ý gọi lỗi để kiểm tra; phần 7 truy vấn các
cặp lịch chồng giờ. Script hiện tại không tự tổng hợp PASS/FAIL cho tất
cả ca, nên cần đọc kết quả và thông báo trong SSMS.

## 8. Demo và kiểm thử giao diện Java

| Màn hình \| Cách thử \| Đối tượng CSDL liên quan \|

| --- \| --- \| --- \|

| Quản lý lớp \| Để bộ lọc trống và nhấn Tìm kiếm; thử lọc theo mã khóa,
  mã GV và trạng thái; chọn lớp hợp lệ rồi thử Kết thúc lớp. \|
  SP_TimKiemLop, V_LOP_TinhTrang, SP_KetThucLop \|

| Lịch học theo lớp \| Tra cứu mã lớp đang tồn tại; đối chiếu thứ, giờ
  bắt đầu/kết thúc, phòng. \| FN_DSLichHoc_Lop hoặc truy vấn được dùng
  trong LichHocService \|

| Lịch học tuần \| Tải lịch và đối chiếu lớp, khóa, giảng viên, thứ,
  giờ, phòng. \| V_LICH_HOC_TUAN \|

| Tạo lớp và lịch \| Nếu phiên bản giao diện hiện tại có chức năng này,
  tạo lớp với lịch hợp lệ; sau đó thử lịch trùng giờ hoặc ngày kết thúc
  sai trong môi trường kiểm thử. \| SP_TaoLop_VaLichHoc,
  TRG_LOP_KiemTraGV, TRG_LICHHOC_ChongLanGio \|

Trong ảnh giao diện hiện có, ứng dụng đăng nhập bằng ttnn_giaovu và hiển
thị các tab Quản lý lớp, Lịch học theo lớp, Lịch học tuần; bảng Quản lý
lớp đang trống. Vì vậy chưa thể kết luận chức năng tải danh sách đã chạy
đúng. Nếu bảng trống, kiểm tra theo thứ tự: SELECT \* FROM LOP; SELECT
\* FROM V_LOP_TinhTrang; EXEC dbo.SP_TimKiemLop; quyền EXECUTE/SELECT;
ánh xạ kết quả trong LopService.

``` sql
USE QL_TTNgoaiNgu;
GO
SELECT * FROM dbo.LOP;
SELECT * FROM dbo.LICHHOC;
SELECT * FROM dbo.V_LOP_TinhTrang;
SELECT * FROM dbo.V_LICH_HOC_TUAN;
EXEC dbo.SP_TimKiemLop;
GO
```

## 9. Ghép với nhóm và thứ tự triển khai

-   Trên CSDL mới, chạy theo thứ tự chung: QLTTNgoaiNgu.sql →
    DataQLTTNgoaiNgu.sql → Module A → Module B → Module C → Module D →
    Security_Roles.sql → Grant_Module_B/C/D → các file
    Test_Module_X.sql.

-   Nếu script dựng CSDL có DROP DATABASE, sao lưu trước khi chạy lại;
    chạy lại bước dựng CSDL đồng nghĩa cần chạy lại các script sau đó.

-   Chạy Module_C_Lop_LichHoc.sql trước Grant_Module_C.sql. Chạy
    Security_Roles.sql trước các file Grant để role đã tồn tại.

-   Trong Java, package module C theo cấu trúc dự kiến là
    ttnn.nguoic.\*; kiểm tra persistence.xml nếu các entity LOP/LICHHOC
    được ánh xạ bằng JPA, và xác nhận MainFrame tạo tab C cho
    role_QuanTri và role_GiaoVu.

-   Nếu ứng dụng đăng nhập được nhưng bảng lớp trống, kiểm tra dữ liệu
    bảng, view, stored procedure, quyền SQL và mapping cột trong
    LopService; không mặc định lỗi do giao diện.

-   Tên file phân quyền có cả Grant_Module_C.sql và
    Grant_Module_C_revised.sql trong thư mục hiện tại. Dùng đúng bản mà
    nhóm thống nhất, tránh chạy hai phiên bản không rõ khác biệt.

-   Trạng thái kiểm chứng: script SQL và test file đã được đọc để lập
    tài liệu; chưa có bằng chứng rằng toàn bộ test đã chạy thành công
    trên SQL Server thực tế. Cần ghi lại kết quả thực tế trước khi báo
    cáo hoàn tất.

## 10. Trạng thái hiện tại và các điểm cần xác nhận

| Hạng mục \| Trạng thái \|

| --- \| --- \|

| Đăng nhập ttnn_giaovu \| Đã thấy ứng dụng mở trong ảnh người dùng cung
  cấp. \|

| Tab Quản lý lớp / Lịch học theo lớp / Lịch học tuần \| Đã thấy trên
  giao diện. \|

| Danh sách lớp \| Bảng đang trống trong ảnh; chưa xác định nguyên nhân.
  \|

| 12 đối tượng SQL \| Được định nghĩa trong Module_C_Lop_LichHoc.sql;
  cần chạy Test_Module_C.sql trên máy để xác nhận triển khai thực tế. \|

| Phân quyền \| Có script Grant Module C; cần xác nhận chạy sau
  Security_Roles.sql và role tồn tại. \|

| Java và thao tác giao diện \| Chưa xác nhận toàn bộ chức năng được
  biên dịch/chạy và kết nối SQL Server thành công. \|

Tài liệu này được lập theo cấu trúc và mức độ chi tiết của mẫu tài liệu
kỹ thuật Người B, dựa trên Module_C_Lop_LichHoc.sql,
Grant_Module_C_revised.sql, Test_Module_C.sql và thông tin giao diện
hiện có. Những kết quả chưa chạy thực tế được ghi là cần xác nhận, không
ghi nhận PASS thay cho kết quả kiểm thử.
