package ttnn.nguoid.ui;



import ttnn.common.PanelStyle;import javax.swing.JTabbedPane;

/**
 * Gom 5 man hinh cua Nguoi D thanh MOT thanh phan de nhung vao menu chinh (MainFrame):
 *     tabs.addTab("Giảng dạy", new ttnn.nguoid.ui.ModuleDPanel());
 * Vai tro: QuanTri day du; GiaoVu sua buoi hoc, diem danh, xem bao cao; GiangVien xem, diem danh, xem bao cao
 * (moi panel tu khoa o nhap theo JpaUtil.coVaiTro). Can goi JpaUtil.connect(...) truoc khi tao panel.
 */
public class ModuleDPanel extends JTabbedPane {
    private final GiangVienPanel giangVien = new GiangVienPanel();
    private final BuoiHocPanel buoiHoc = new BuoiHocPanel();
    private final DiemDanhPanel diemDanh = new DiemDanhPanel();
    private final ChuyenCanPanel chuyenCan = new ChuyenCanPanel();
    private final LichDayPanel lichDay = new LichDayPanel();

    public ModuleDPanel() {
        addTab("Giảng viên", giangVien);
        addTab("Buổi học", buoiHoc);
        addTab("Điểm danh", diemDanh);
        addTab("Báo cáo chuyên cần", chuyenCan);
        addTab("Lịch dạy", lichDay);
        // Moi lan chuyen tab thi tai lai danh muc de thay thay doi cua tab khac
        addChangeListener(e -> {
            switch (getSelectedIndex()) {
                case 0 -> giangVien.lamMoi();
                case 1 -> buoiHoc.lamMoi();
                case 2 -> diemDanh.lamMoi();
                case 3 -> chuyenCan.lamMoi();
                case 4 -> lichDay.lamMoi();
                default -> { }
            }
        });
    
        PanelStyle.apDung(this);
    }
}
