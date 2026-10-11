package ttnn.nguoid.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoid.service.BuoiHocService;
import ttnn.nguoid.service.Muc;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.time.LocalDate;
import java.util.List;

/**
 * Man hinh LICH DAY GIANG VIEN (Nguoi D): goi SP_LichDay_GiangVien theo giang vien va khoang ngay
 * (mac dinh thang hien tai). Gom ca buoi day thay. QuanTri, GiaoVu, GiangVien deu xem duoc.
 * Luu y: he thong chua gan tai khoan dang nhap voi mot giang vien cu the nen chon giang vien thu cong.
 */
public class LichDayPanel extends JPanel {
    private final BuoiHocService service = new BuoiHocService();

    private final JComboBox<Muc> cboGV = new JComboBox<>();
    private final JTextField txtTu = new JTextField(10);
    private final JTextField txtDen = new JTextField(10);
    private final SimpleTableModel model = new SimpleTableModel(
            "Mã buổi", "Ngày", "Thứ", "Lớp", "Khóa học", "Vai trò", "Trạng thái", "Từ", "Đến", "Phòng");
    private final JTable table = UiUtil.newTable(model);
    private final JLabel lblTong = new JLabel(" ");

    public LichDayPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        LocalDate dauThang = LocalDate.now().withDayOfMonth(1);
        txtTu.setText(UiUtil.formatDate(dauThang));
        txtDen.setText(UiUtil.formatDate(dauThang.plusMonths(1).minusDays(1)));
        txtTu.setToolTipText("dd/MM/yyyy");
        txtDen.setToolTipText("dd/MM/yyyy");

        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("SP_LichDay_GiangVien"));
        loc.add(new JLabel("Giảng viên:"));
        loc.add(cboGV);
        loc.add(new JLabel("Từ ngày:"));
        loc.add(txtTu);
        loc.add(new JLabel("Đến ngày:"));
        loc.add(txtDen);
        JButton btnXem = new JButton("Xem lịch");
        btnXem.addActionListener(e -> UiUtil.run(this, this::tai));
        loc.add(btnXem);
        add(loc, BorderLayout.NORTH);
        add(UiUtil.scroll(table, 300), BorderLayout.CENTER);
        add(lblTong, BorderLayout.SOUTH);
        lamMoi();
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            Object gv = cboGV.getSelectedItem();
            cboGV.removeAllItems();
            service.dsGiangVienTatCa().forEach(cboGV::addItem);
            if (gv != null) {
                cboGV.setSelectedItem(gv);
            }
        });
    }

    private void tai() {
        if (!(cboGV.getSelectedItem() instanceof Muc gv)) {
            throw new IllegalArgumentException("Hãy chọn giảng viên.");
        }
        LocalDate tu = UiUtil.parseDate(txtTu.getText(), "Từ ngày");
        LocalDate den = UiUtil.parseDate(txtDen.getText(), "Đến ngày");
        List<Object[]> ds = service.lichDay(gv.ma(), tu, den);
        model.setRows(ds);
        long thay = ds.stream().filter(r -> "Dạy thay".equals(r[5])).count();
        lblTong.setText(gv.ma() + ": " + ds.size() + " buổi từ " + UiUtil.formatDate(tu) + " đến "
                + UiUtil.formatDate(den) + " (trong đó dạy thay " + thay + ").");
    }
}
