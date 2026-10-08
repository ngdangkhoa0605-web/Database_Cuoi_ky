package ttnn.nguoib.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoib.service.HoaDonService;
import ttnn.nguoib.service.HoaDonService.KetQuaThanhToan;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Man hinh HOA DON VA THU TIEN.
 * Goi: native query dung FN_TinhCongNo (danh sach hoa don + cong no),
 *      SP_ThanhToanHocPhi (ghi nhan thu tien, chong thu vuot).
 */
public class HoaDonPanel extends JPanel {
    private static final String TAT_CA = "(Tất cả)";

    private final HoaDonService service = new HoaDonService();

    private final JTextField txtTim = new JTextField(16);
    private final JComboBox<String> cboTrangThai = new JComboBox<>(new String[] {
            TAT_CA, "Chưa thanh toán", "Thanh toán một phần", "Đã thanh toán đủ"});
    private final JCheckBox chkConNo = new JCheckBox("Chỉ hóa đơn còn nợ");

    private final SimpleTableModel model = new SimpleTableModel(
            "Mã HD", "Mã ĐK", "Mã HV", "Học viên", "Lớp", "Cần thu", "Đã thu", "Còn nợ", "Ngày thu cuối", "Trạng thái");
    private final JTable tbl = UiUtil.newTable(model);

    private final JLabel lblChon = new JLabel("Chưa chọn hóa đơn");
    private final JTextField txtSoTien = new JTextField(12);
    private final JTextField txtNgay = new JTextField(10);

    public HoaDonPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        txtNgay.setText(UiUtil.formatDate(LocalDate.now()));

        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("Lọc hóa đơn"));
        loc.add(new JLabel("Mã HD / ĐK / HV / tên:"));
        loc.add(txtTim);
        loc.add(new JLabel("Trạng thái:"));
        loc.add(cboTrangThai);
        loc.add(chkConNo);
        JButton btnLoc = new JButton("Lọc");
        loc.add(btnLoc);
        add(loc, BorderLayout.NORTH);

        add(UiUtil.scroll(tbl, 300), BorderLayout.CENTER);

        JPanel thu = UiUtil.formPanel("Thu tiền học phí (SP_ThanhToanHocPhi)");
        UiUtil.addField(thu, 0, 0, "Hóa đơn:", lblChon);
        UiUtil.addField(thu, 1, 0, "Số tiền thu (đ):", txtSoTien);
        UiUtil.addField(thu, 1, 2, "Ngày thu:", txtNgay);
        JButton btnThu = new JButton("Ghi nhận thu tiền");
        JButton btnThuHet = new JButton("Điền số còn nợ");
        JPanel nut = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        nut.add(btnThu);
        nut.add(btnThuHet);
        JPanel south = new JPanel(new BorderLayout());
        south.add(thu, BorderLayout.CENTER);
        south.add(nut, BorderLayout.SOUTH);
        add(south, BorderLayout.SOUTH);

        btnLoc.addActionListener(e -> UiUtil.run(this, this::taiDuLieu));
        txtTim.addActionListener(e -> UiUtil.run(this, this::taiDuLieu));
        tbl.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                capNhatChon();
            }
        });
        btnThu.addActionListener(e -> UiUtil.run(this, this::thuTien));
        btnThuHet.addActionListener(e -> {
            int r = tbl.getSelectedRow();
            if (r >= 0) {
                BigDecimal no = (BigDecimal) model.raw(tbl.convertRowIndexToModel(r), 7);
                txtSoTien.setText(no == null ? "" : no.toBigInteger().toString());
            }
        });

        UiUtil.run(this, this::taiDuLieu);
    }

    public void lamMoi() {
        UiUtil.run(this, this::taiDuLieu);
    }

    private String maHDDangChon() {
        int r = tbl.getSelectedRow();
        return r < 0 ? null : model.raw(tbl.convertRowIndexToModel(r), 0).toString();
    }

    private void taiDuLieu() {
        String giu = maHDDangChon();
        String tt = String.valueOf(cboTrangThai.getSelectedItem());
        model.setRows(service.timHoaDon(txtTim.getText(), TAT_CA.equals(tt) ? null : tt, chkConNo.isSelected()));
        if (giu != null) {
            for (int i = 0; i < model.getRowCount(); i++) {
                if (giu.equals(model.raw(i, 0))) {
                    tbl.setRowSelectionInterval(i, i);
                    break;
                }
            }
        }
        capNhatChon();
    }

    private void capNhatChon() {
        int r = tbl.getSelectedRow();
        if (r < 0) {
            lblChon.setText("Chưa chọn hóa đơn");
            return;
        }
        int m = tbl.convertRowIndexToModel(r);
        lblChon.setText(model.raw(m, 0) + " - " + model.raw(m, 3) + " (còn nợ "
                + UiUtil.formatMoney((BigDecimal) model.raw(m, 7)) + ")");
    }

    private void thuTien() {
        String maHD = maHDDangChon();
        if (maHD == null) {
            UiUtil.showInfo(this, "Hãy chọn một hóa đơn trong bảng.");
            return;
        }
        BigDecimal soTien = UiUtil.parseMoney(txtSoTien.getText(), "Số tiền thu");
        LocalDate ngay = UiUtil.parseDate(txtNgay.getText(), "Ngày thu");
        KetQuaThanhToan kq = service.thuTien(maHD, soTien, ngay);
        UiUtil.showInfo(this, "Đã ghi nhận thu " + UiUtil.formatMoney(soTien) + " cho hóa đơn " + maHD
                + ".\nTrạng thái: " + kq.trangThai() + "\nCòn nợ: " + UiUtil.formatMoney(kq.conNo()));
        txtSoTien.setText("");
        taiDuLieu();
    }
}
