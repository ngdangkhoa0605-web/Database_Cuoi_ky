package ttnn.nguoib.ui;

import javax.swing.JTabbedPane;

/**
 * Gom 4 man hinh cua Nguyễn Đăng Khoa (24110255) thanh MOT thanh phan de nhung vao menu chinh cua nhom:
 *     mainTabs.addTab("Hoc vien & Tai chinh", new ModuleBPanel());
 * (can goi JpaUtil.connect(...) truoc khi tao panel).
 */
public class ModuleBPanel extends JTabbedPane {
    private final HocVienPanel hocVien = new HocVienPanel();
    private final DangKyPanel dangKy = new DangKyPanel();
    private final HoaDonPanel hoaDon = new HoaDonPanel();
    private final BaoCaoPanel baoCao = new BaoCaoPanel();

    public ModuleBPanel() {
        addTab("Quản lý học viên", hocVien);
        addTab("Đăng ký học", dangKy);
        addTab("Hóa đơn và thu tiền", hoaDon);
        addTab("Báo cáo công nợ / doanh thu", baoCao);
        // Moi lan chuyen tab thi tai lai du lieu de thay thay doi cua tab khac
        addChangeListener(e -> {
            switch (getSelectedIndex()) {
                case 0 -> hocVien.lamMoi();
                case 1 -> dangKy.lamMoi();
                case 2 -> hoaDon.lamMoi();
                case 3 -> baoCao.lamMoi();
                default -> { }
            }
        });
    }
}
