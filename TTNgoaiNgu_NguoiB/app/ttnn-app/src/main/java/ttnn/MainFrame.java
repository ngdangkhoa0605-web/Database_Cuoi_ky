package ttnn;



import ttnn.common.PanelStyle;import ttnn.common.JpaUtil;
import ttnn.common.VaiTro;
import ttnn.kien.ui.ModuleAPanel;
import ttnn.nguoib.ui.ModuleBPanel;

import javax.swing.BorderFactory;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.SwingConstants;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import javax.swing.JButton;

/**
 * Khung chinh cua nhom. Chi TAO tab ma vai tro dang dang nhap duoc phep dung: cac panel tai du lieu
 * ngay khi duoc tao, neu tao panel cho vai tro khong co quyen se hien loi "khong co quyen" hang loat.
 * Quyen that van do CSDL kiem tra (GRANT/DENY); an tab chi de giao dien dung voi quyen.
 *
 * Bang tab theo vai tro (da chot):
 *     Tab                       QuanTri  GiaoVu        KeToan       GiangVien
 *     Khoa hoc (Kien)           day du   xem/thong ke  chi xem      -
 *     Hoc vien & tai chinh (B)  co       -             co           -
 *     Lop hoc & lich (C)        co       co            -            -     (C xac nhan)
 *     Giang day (D)             co       co            -            co    (D xac nhan)
 *
 * KHI GHEP NHOM: moi nguoi bo comment dong addTab cua minh trong taoCacTab(); vai tro duoc phep da ghi san.
 */
public class MainFrame extends JFrame {

    public MainFrame() {
        super("Quản lý trung tâm ngoại ngữ  |  " + JpaUtil.getCurrentUser() + " (" + JpaUtil.getCurrentRole() + ")");
        setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
        setMinimumSize(new Dimension(1050, 650));

        JPanel noiDung = new JPanel(new BorderLayout());
        JTabbedPane tabs = taoCacTab();
        if (tabs.getTabCount() > 0) {
            noiDung.add(tabs, BorderLayout.CENTER);
        } else {
            JLabel chuaCo = new JLabel("Các chức năng dành cho vai trò " + JpaUtil.getCurrentRole()
                    + " đang được hoàn thiện.", SwingConstants.CENTER);
            noiDung.add(chuaCo, BorderLayout.CENTER);
        }
        noiDung.add(taoThanhTrangThai(), BorderLayout.SOUTH);
        setContentPane(noiDung);
        setJMenuBar(taoMenu());

        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                thoat();
            }
        });
        PanelStyle.apDung(getContentPane());
        pack();
        setLocationRelativeTo(null);
    }

    private JTabbedPane taoCacTab() {
        JTabbedPane tabs = new JTabbedPane(JTabbedPane.LEFT);

        // Kien - Khoa hoc: QuanTri day du; GiaoVu, KeToan chi xem (panel tu an nut theo JpaUtil.coVaiTro)
        if (JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.GIAO_VU, VaiTro.KE_TOAN)) {
            tabs.addTab("Khóa học", new ModuleAPanel());
        }

        // B - Hoc vien & tai chinh
        if (JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.KE_TOAN)) {
            tabs.addTab("Học viên và tài chính", new ModuleBPanel());
        }

        // C - Lop hoc & lich (C xac nhan vai tro)
         if (JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.GIAO_VU)) {
            tabs.addTab("Lớp học và lịch", new ttnn.nguoic.ui.ModuleCPanel());
         }

        // D - Giang day: QuanTri day du; GiaoVu, GiangVien dung cac man hinh theo quyen (panel tu khoa nut)
        if (JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.GIAO_VU, VaiTro.GIANG_VIEN)) {
            tabs.addTab("Giảng dạy", new ttnn.nguoid.ui.ModuleDPanel());
        }
        return tabs;
    }

    /** Thanh trang thai: may chu / CSDL / tai khoan / vai tro thuc te cua phien (minh chung ket noi that). */
    /** Thanh dưới cùng: nút đăng xuất bên trái và thông tin kết nối bên phải. */
    private JPanel taoThanhTrangThai() {
        JPanel thanhDuoi = new JPanel(new BorderLayout(10, 0));

        thanhDuoi.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(
                        1, 0, 0, 0, thanhDuoi.getForeground().brighter()),
                BorderFactory.createEmptyBorder(5, 8, 5, 8)
        ));

        // Nút đăng xuất để chuyển tài khoản
        JButton btnDangXuat = new JButton("Đăng xuất / Đổi tài khoản");
        btnDangXuat.setFocusPainted(false);
        btnDangXuat.addActionListener(e -> dangXuat());

        // Thông tin kết nối hiện tại
        JLabel lblThongTin = new JLabel(
                "Máy chủ: " + JpaUtil.getCurrentServer()
                        + "   |   CSDL: " + JpaUtil.getCurrentDatabase()
                        + "   |   Tài khoản: " + JpaUtil.getCurrentUser()
                        + "   |   Vai trò: " + JpaUtil.getCurrentRole()
        );

        thanhDuoi.add(btnDangXuat, BorderLayout.WEST);
        thanhDuoi.add(lblThongTin, BorderLayout.CENTER);

        return thanhDuoi;
    }

    private JMenuBar taoMenu() {
        JMenuBar bar = new JMenuBar();
        JMenu he = new JMenu("Hệ thống");
        JMenuItem dangXuat = new JMenuItem("Đăng xuất");
        dangXuat.addActionListener(e -> dangXuat());
        JMenuItem thoat = new JMenuItem("Thoát");
        thoat.addActionListener(e -> thoat());
        he.add(dangXuat);
        he.addSeparator();
        he.add(thoat);
        bar.add(he);
        return bar;
    }

    /** Dong ket noi cua tai khoan hien tai roi quay lai man hinh dang nhap. */
    private void dangXuat() {
        JpaUtil.close();
        dispose();
        Main.batDau();
    }

    private void thoat() {
        JpaUtil.close();
        dispose();
        System.exit(0);
    }
}
