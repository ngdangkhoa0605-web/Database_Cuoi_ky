package ttnn.kien.ui;

import javax.swing.JTabbedPane;

/**
 * Gom 3 man hinh cua Kien thanh MOT thanh phan de nhung vao menu chinh (MainFrame):
 *     tabs.addTab("Khóa học", new ModuleAPanel());
 * Vai tro: QuanTri day du; GiaoVu, KeToan chi xem / tim kiem / thong ke (moi panel tu an form sua theo vai tro).
 * (can goi JpaUtil.connect(...) truoc khi tao panel).
 */
public class ModuleAPanel extends JTabbedPane {
    private final KhoaHocPanel khoaHoc = new KhoaHocPanel();
    private final NgonNguPanel ngonNgu = new NgonNguPanel();
    private final ThongKeKhoaHocPanel thongKe = new ThongKeKhoaHocPanel();

    public ModuleAPanel() {
        addTab("Quản lý khóa học", khoaHoc);
        addTab("Quản lý ngôn ngữ", ngonNgu);
        addTab("Thống kê khóa học", thongKe);
        // Moi lan chuyen tab thi tai lai du lieu de thay thay doi cua tab khac
        addChangeListener(e -> {
            switch (getSelectedIndex()) {
                case 0 -> khoaHoc.lamMoi();
                case 1 -> ngonNgu.lamMoi();
                case 2 -> thongKe.lamMoi();
                default -> { }
            }
        });
    }
}
