package ttnn.nguoid.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoid.service.BuoiHocService;
import ttnn.nguoid.service.DiemDanhService;
import ttnn.nguoid.service.Muc;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import java.util.List;

/**
 * Man hinh BAO CAO CHUYEN CAN (Nguoi D): chon lop va nguong canh bao (mac dinh 80%), goi SP_ThongKeChuyenCan_Lop.
 * Dong duoi nguong to mau. QuanTri, GiaoVu, GiangVien deu xem duoc.
 */
public class ChuyenCanPanel extends JPanel {
    private static final int COT_CANH_BAO = 9;

    private final BuoiHocService buoiService = new BuoiHocService();
    private final DiemDanhService service = new DiemDanhService();

    private final JComboBox<Muc> cboLop = new JComboBox<>();
    private final JTextField txtNguong = new JTextField("80", 5);
    private final SimpleTableModel model = new SimpleTableModel(
            "Mã ĐK", "Mã HV", "Học viên", "Số lượt", "Có mặt", "Vắng có phép", "Vắng không phép",
            "Tỷ lệ (%)", "Tỷ lệ cả lớp (%)", "Cảnh báo");
    private final JTable table = UiUtil.newTable(model);
    private final JLabel lblTong = new JLabel(" ");

    public ChuyenCanPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("SP_ThongKeChuyenCan_Lop"));
        loc.add(new JLabel("Lớp:"));
        loc.add(cboLop);
        loc.add(new JLabel("Ngưỡng cảnh báo (%):"));
        loc.add(txtNguong);
        JButton btnXem = new JButton("Xem báo cáo");
        btnXem.addActionListener(e -> UiUtil.run(this, this::tai));
        loc.add(btnXem);
        add(loc, BorderLayout.NORTH);

        table.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable t, Object v, boolean sel, boolean foc, int r, int c) {
                Component comp = super.getTableCellRendererComponent(t, v, sel, foc, r, c);
                int m = t.convertRowIndexToModel(r);
                boolean canhBao = Boolean.TRUE.equals(model.raw(m, COT_CANH_BAO));
                if (c == COT_CANH_BAO) {
                    setText(canhBao ? "Dưới ngưỡng" : "");
                }
                if (!sel) {
                    comp.setBackground(canhBao ? new Color(255, 225, 225) : t.getBackground());
                }
                return comp;
            }
        });
        add(UiUtil.scroll(table, 300), BorderLayout.CENTER);
        add(lblTong, BorderLayout.SOUTH);
        lamMoi();
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            Object lop = cboLop.getSelectedItem();
            cboLop.removeAllItems();
            buoiService.dsLop().forEach(cboLop::addItem);
            if (lop != null) {
                cboLop.setSelectedItem(lop);
            }
        });
    }

    private void tai() {
        if (!(cboLop.getSelectedItem() instanceof Muc lop)) {
            throw new IllegalArgumentException("Hãy chọn lớp.");
        }
        BigDecimal nguong;
        try {
            nguong = new BigDecimal(txtNguong.getText().trim().replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Ngưỡng cảnh báo phải là số từ 0 đến 100.");
        }
        if (nguong.signum() < 0 || nguong.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException("Ngưỡng cảnh báo phải là số từ 0 đến 100.");
        }
        List<Object[]> ds = service.thongKeLop(lop.ma(), nguong);
        // Cot "Canh bao" hien chu; giu Boolean goc de to mau
        model.setRows(ds);
        long nCanhBao = ds.stream().filter(r -> Boolean.TRUE.equals(r[9])).count();
        BigDecimal lopTyLe = ds.isEmpty() ? null : (BigDecimal) ds.get(0)[8];
        lblTong.setText("Lớp " + lop.ma() + ": " + ds.size() + " học viên, " + nCanhBao + " dưới ngưỡng "
                + nguong.stripTrailingZeros().toPlainString() + "%. Tỷ lệ chuyên cần cả lớp: "
                + (lopTyLe == null ? "chưa có dữ liệu" : UiUtil.formatNumber(lopTyLe) + "%"));
    }
}
