package ttnn.nguoib.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoib.service.BaoCaoService;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSpinner;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.SpinnerNumberModel;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Man hinh BAO CAO: cong no hoc phi va doanh thu.
 * Goi: view V_CONGNO_HocPhi (cong no), SP_ThongKeDoanhThu (doanh thu theo thang / khoa hoc).
 */
public class BaoCaoPanel extends JPanel {
    private static final String TAT_CA = "(Tất cả)";

    private final BaoCaoService service = new BaoCaoService();

    // ----- cong no -----
    private final JTextField txtCongNo = new JTextField(16);
    private final SimpleTableModel modelCongNo = new SimpleTableModel(
            "Mã HV", "Học viên", "SĐT", "Mã ĐK", "Lớp", "Khóa học", "Ngày ĐK",
            "Cần thu", "Đã thu", "Còn nợ", "Trạng thái", "Số ngày");
    private final JTable tblCongNo = UiUtil.newTable(modelCongNo);
    private final JLabel lblTongNo = new JLabel(" ");

    // ----- doanh thu -----
    private final JComboBox<String> cboNhom = new JComboBox<>(new String[] {
            "Theo tháng", "Theo khóa học", "Theo tháng và khóa học"});
    private final JCheckBox chkNam = new JCheckBox("Lọc năm:", true);
    private final JSpinner spnNam = new JSpinner(new SpinnerNumberModel(LocalDate.now().getYear(), 2000, 2100, 1));
    private final JComboBox<String> cboThang = new JComboBox<>();
    private final JComboBox<String> cboKhoa = new JComboBox<>();
    private final List<String> maKhoa = new ArrayList<>();
    private final SimpleTableModel modelDoanhThu = new SimpleTableModel(
            "Năm", "Tháng", "Mã khóa", "Khóa học", "Số HĐ", "Tổng phải thu", "Doanh thu (đã thu)", "Còn phải thu");
    private final JTable tblDoanhThu = UiUtil.newTable(modelDoanhThu);
    private final JLabel lblTongDoanhThu = new JLabel(" ");

    public BaoCaoPanel() {
        super(new BorderLayout());
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Công nợ học phí", taoTabCongNo());
        tabs.addTab("Doanh thu", taoTabDoanhThu());
        add(tabs, BorderLayout.CENTER);
        lamMoi();
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            taiKhoaHoc();
            taiCongNo();
            taiDoanhThu();
        });
    }

    // ================= cong no =================
    private JPanel taoTabCongNo() {
        JPanel p = new JPanel(new BorderLayout(6, 6));
        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("Học viên còn nợ học phí (V_CONGNO_HocPhi)"));
        loc.add(new JLabel("Tên / mã HV / lớp / khóa:"));
        loc.add(txtCongNo);
        JButton btn = new JButton("Xem");
        loc.add(btn);
        p.add(loc, BorderLayout.NORTH);
        p.add(UiUtil.scroll(tblCongNo, 320), BorderLayout.CENTER);
        p.add(lblTongNo, BorderLayout.SOUTH);
        btn.addActionListener(e -> UiUtil.run(this, this::taiCongNo));
        txtCongNo.addActionListener(e -> UiUtil.run(this, this::taiCongNo));
        return p;
    }

    private void taiCongNo() {
        List<Object[]> rows = service.congNo(txtCongNo.getText());
        modelCongNo.setRows(rows);
        BigDecimal tong = BigDecimal.ZERO;
        for (Object[] r : rows) {
            tong = tong.add((BigDecimal) r[9]);
        }
        lblTongNo.setText("  " + rows.size() + " khoản nợ - tổng còn nợ: " + UiUtil.formatMoney(tong));
    }

    // ================= doanh thu =================
    private JPanel taoTabDoanhThu() {
        cboThang.addItem(TAT_CA);
        for (int i = 1; i <= 12; i++) {
            cboThang.addItem("Tháng " + i);
        }
        cboKhoa.addItem(TAT_CA);

        JPanel p = new JPanel(new BorderLayout(6, 6));
        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("Thống kê doanh thu (SP_ThongKeDoanhThu)"));
        loc.add(new JLabel("Nhóm:"));
        loc.add(cboNhom);
        loc.add(chkNam);
        loc.add(spnNam);
        loc.add(new JLabel("Tháng:"));
        loc.add(cboThang);
        loc.add(new JLabel("Khóa học:"));
        loc.add(cboKhoa);
        JButton btn = new JButton("Thống kê");
        loc.add(btn);
        p.add(loc, BorderLayout.NORTH);
        p.add(UiUtil.scroll(tblDoanhThu, 320), BorderLayout.CENTER);
        p.add(lblTongDoanhThu, BorderLayout.SOUTH);
        btn.addActionListener(e -> UiUtil.run(this, this::taiDoanhThu));
        chkNam.addActionListener(e -> spnNam.setEnabled(chkNam.isSelected()));
        return p;
    }

    private void taiKhoaHoc() {
        int giu = cboKhoa.getSelectedIndex();
        List<String[]> ds = service.khoaHoc();
        cboKhoa.removeAllItems();
        maKhoa.clear();
        cboKhoa.addItem(TAT_CA);
        for (String[] k : ds) {
            cboKhoa.addItem(k[0] + " - " + k[1]);
            maKhoa.add(k[0]);
        }
        cboKhoa.setSelectedIndex(giu >= 0 && giu < cboKhoa.getItemCount() ? giu : 0);
    }

    private void taiDoanhThu() {
        Integer nam = chkNam.isSelected() ? (Integer) spnNam.getValue() : null;
        int t = cboThang.getSelectedIndex(); // 0 = tat ca, 1..12 = thang
        Integer thang = t > 0 ? t : null;
        if (thang != null && nam == null) {
            throw new IllegalArgumentException("Muốn lọc theo tháng thì phải chọn năm.");
        }
        int k = cboKhoa.getSelectedIndex();
        String ma = (k > 0 && k - 1 < maKhoa.size()) ? maKhoa.get(k - 1) : null;
        String nhom = switch (cboNhom.getSelectedIndex()) {
            case 1 -> "KHOA";
            case 2 -> "THANG_KHOA";
            default -> "THANG";
        };
        List<Object[]> rows = service.doanhThu(nam, thang, ma, nhom);
        modelDoanhThu.setRows(rows);
        BigDecimal tong = BigDecimal.ZERO;
        int soHD = 0;
        for (Object[] r : rows) {
            tong = tong.add((BigDecimal) r[6]);
            soHD += (Integer) r[4];
        }
        lblTongDoanhThu.setText("  " + soHD + " hóa đơn - tổng doanh thu: " + UiUtil.formatMoney(tong)
                + "   (doanh thu tính theo tháng của lần thu gần nhất của hóa đơn)");
    }
}
