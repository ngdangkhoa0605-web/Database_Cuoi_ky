package ttnn.kien.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.kien.service.NgonNguService;
import ttnn.kien.service.NgonNguService.NgonNguMuc;
import ttnn.kien.service.ThongKeKhoaHocService;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.util.List;

/**
 * Man hinh THONG KE KHOA HOC (Kien) - 3 tab:
 *  1. Tong hop khoa hoc          : VIEW V_KHOAHOC_ThongKe (so lop, lop dang mo, so hoc vien qua FN_SoHocVien_KhoaHoc)
 *  2. So dang ky theo khoa hoc   : STORED PROCEDURE SP_ThongKeDangKy_TheoKhoa (khoang ngay dang ky)
 *  3. Khoa dang giang day        : TABLE-VALUED FUNCTION FN_DSKhoaHoc_TheoNN
 * Mo cho QuanTri, GiaoVu, KeToan (deu duoc cap quyen tren cac doi tuong nay).
 */
public class ThongKeKhoaHocPanel extends JPanel {
    private final ThongKeKhoaHocService service = new ThongKeKhoaHocService();
    private final NgonNguService ngonNgu = new NgonNguService();

    // ----- tab 1 -----
    private final JComboBox<NgonNguMuc> cboNNTongHop = new JComboBox<>();
    private final SimpleTableModel modelTongHop = new SimpleTableModel(
            "Mã KH", "Tên khóa học", "Ngôn ngữ", "Trình độ", "Học phí", "Trạng thái", "Số lớp", "Lớp đang mở", "Số học viên");
    private final JTable tblTongHop = UiUtil.newTable(modelTongHop);

    // ----- tab 2 -----
    private final JTextField txtTuNgay = new JTextField(10);
    private final JTextField txtDenNgay = new JTextField(10);
    private final SimpleTableModel modelDangKy = new SimpleTableModel(
            "Mã KH", "Tên khóa học", "Ngôn ngữ", "Số lớp có ĐK", "Số đăng ký", "Số học viên", "Tỷ lệ (%)");
    private final JTable tblDangKy = UiUtil.newTable(modelDangKy);
    private final JLabel lblTongDangKy = new JLabel(" ");

    // ----- tab 3 -----
    private final JComboBox<NgonNguMuc> cboNNDangDay = new JComboBox<>();
    private final SimpleTableModel modelDangDay = new SimpleTableModel(
            "Mã KH", "Tên khóa học", "Trình độ", "Số buổi", "Học phí");
    private final JTable tblDangDay = UiUtil.newTable(modelDangDay);

    public ThongKeKhoaHocPanel() {
        super(new BorderLayout());
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Tổng hợp khóa học", taoTabTongHop());
        tabs.addTab("Số đăng ký theo khóa", taoTabDangKy());
        tabs.addTab("Khóa đang giảng dạy theo ngôn ngữ", taoTabDangDay());
        add(tabs, BorderLayout.CENTER);
        lamMoi();
    }

    private JPanel taoTabTongHop() {
        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("V_KHOAHOC_ThongKe (số học viên tính bằng FN_SoHocVien_KhoaHoc)"));
        loc.add(new JLabel("Ngôn ngữ:"));
        loc.add(cboNNTongHop);
        JButton btnXem = new JButton("Xem");
        loc.add(btnXem);
        btnXem.addActionListener(e -> UiUtil.run(this, this::taiTongHop));

        JPanel p = new JPanel(new BorderLayout(4, 4));
        p.add(loc, BorderLayout.NORTH);
        p.add(UiUtil.scroll(tblTongHop, 300), BorderLayout.CENTER);
        return p;
    }

    private JPanel taoTabDangKy() {
        txtTuNgay.setToolTipText("dd/MM/yyyy - để trống = không giới hạn");
        txtDenNgay.setToolTipText("dd/MM/yyyy - để trống = không giới hạn");
        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("SP_ThongKeDangKy_TheoKhoa (để trống ngày = toàn bộ)"));
        loc.add(new JLabel("Từ ngày:"));
        loc.add(txtTuNgay);
        loc.add(new JLabel("Đến ngày:"));
        loc.add(txtDenNgay);
        JButton btnTK = new JButton("Thống kê");
        loc.add(btnTK);
        btnTK.addActionListener(e -> UiUtil.run(this, this::taiDangKy));

        JPanel p = new JPanel(new BorderLayout(4, 4));
        p.add(loc, BorderLayout.NORTH);
        p.add(UiUtil.scroll(tblDangKy, 300), BorderLayout.CENTER);
        p.add(lblTongDangKy, BorderLayout.SOUTH);
        return p;
    }

    private JPanel taoTabDangDay() {
        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("FN_DSKhoaHoc_TheoNN"));
        loc.add(new JLabel("Ngôn ngữ:"));
        loc.add(cboNNDangDay);
        JButton btnXem = new JButton("Xem");
        loc.add(btnXem);
        btnXem.addActionListener(e -> UiUtil.run(this, this::taiDangDay));

        JPanel p = new JPanel(new BorderLayout(4, 4));
        p.add(loc, BorderLayout.NORTH);
        p.add(UiUtil.scroll(tblDangDay, 300), BorderLayout.CENTER);
        return p;
    }

    /** Duoc goi lai khi tab nay hien ra de du lieu luon moi. */
    public void lamMoi() {
        UiUtil.run(this, () -> {
            napNgonNgu();
            taiTongHop();
            taiDangKy();
            taiDangDay();
        });
    }

    private void napNgonNgu() {
        List<NgonNguMuc> ds = ngonNgu.danhMuc();
        String giu1 = maChon(cboNNTongHop);
        cboNNTongHop.removeAllItems();
        cboNNTongHop.addItem(NgonNguMuc.TAT_CA);
        ds.forEach(cboNNTongHop::addItem);
        chonMa(cboNNTongHop, giu1);

        String giu3 = maChon(cboNNDangDay);
        cboNNDangDay.removeAllItems();
        ds.forEach(cboNNDangDay::addItem);
        chonMa(cboNNDangDay, giu3);
    }

    private static String maChon(JComboBox<NgonNguMuc> cbo) {
        Object o = cbo.getSelectedItem();
        return o instanceof NgonNguMuc m ? m.ma() : null;
    }

    private static void chonMa(JComboBox<NgonNguMuc> cbo, String ma) {
        for (int i = 0; i < cbo.getItemCount(); i++) {
            if (ma != null && ma.equalsIgnoreCase(cbo.getItemAt(i).ma())) {
                cbo.setSelectedIndex(i);
                return;
            }
        }
        if (cbo.getItemCount() > 0) {
            cbo.setSelectedIndex(0);
        }
    }

    private void taiTongHop() {
        modelTongHop.setRows(service.tongHop(maChon(cboNNTongHop)));
    }

    private void taiDangKy() {
        List<Object[]> ds = service.dangKyTheoKhoa(UiUtil.parseDate(txtTuNgay.getText(), "Từ ngày"),
                UiUtil.parseDate(txtDenNgay.getText(), "Đến ngày"));
        modelDangKy.setRows(ds);
        int tong = ds.stream().mapToInt(r -> r[4] == null ? 0 : (Integer) r[4]).sum();
        lblTongDangKy.setText("  Tổng số đăng ký trong kỳ: " + tong);
    }

    private void taiDangDay() {
        String ma = maChon(cboNNDangDay);
        modelDangDay.setRows(ma == null ? List.of() : service.khoaDangGiangDay(ma));
    }
}
