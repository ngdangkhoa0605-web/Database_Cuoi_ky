package ttnn.nguoic.ui;



import ttnn.common.PanelStyle;import ttnn.nguoic.service.LopService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Date;
import java.util.List;

public class LopPanel extends JPanel {
    private final LopService service = new LopService();
    private final JTextField maKH = new JTextField(8);
    private final JTextField maGV = new JTextField(8);
    private final JComboBox<String> trangThai = new JComboBox<>(new String[]{"Tất cả", "Đang tuyển sinh", "Đang học", "Đã kết thúc"});
    private final DefaultTableModel model = new DefaultTableModel(
            new String[]{"Mã lớp", "Mã khóa", "Tên khóa", "Mã GV", "Giảng viên", "Khai giảng", "Kết thúc", "Sĩ số", "Tối đa", "Lấp đầy (%)", "Trạng thái"}, 0) {
        @Override public boolean isCellEditable(int row, int column) { return false; }
    };
    private final JTable table = new JTable(model);

    public LopPanel() {
        setLayout(new BorderLayout(8, 8));
        JPanel filters = new JPanel(new FlowLayout(FlowLayout.LEFT));
        filters.add(new JLabel("Mã khóa:")); filters.add(maKH);
        filters.add(new JLabel("Mã GV:")); filters.add(maGV);
        filters.add(new JLabel("Trạng thái:")); filters.add(trangThai);
        JButton search = new JButton("Tìm kiếm");
        JButton finish = new JButton("Kết thúc lớp");
        filters.add(search); filters.add(finish);
        add(filters, BorderLayout.NORTH);
        add(new JScrollPane(table), BorderLayout.CENTER);
        search.addActionListener(e -> load());
        finish.addActionListener(e -> finishSelected());
    
        PanelStyle.apDung(this);
    }

    private void load() {
        try {
            String status = (String) trangThai.getSelectedItem();
            if ("Tất cả".equals(status)) status = null;
            List<LopService.LopRow> rows = service.timKiem(maKH.getText(), maGV.getText(), status, (Date) null, (Date) null);
            model.setRowCount(0);
            rows.forEach(r -> model.addRow(r.toRow()));
        } catch (RuntimeException ex) {
            showError(ex);
        }
    }

    private void finishSelected() {
        int row = table.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(this, "Hãy chọn một lớp.");
            return;
        }
        String maLop = String.valueOf(table.getValueAt(row, 0));
        int confirm = JOptionPane.showConfirmDialog(this, "Kết thúc lớp " + maLop + "?", "Xác nhận", JOptionPane.YES_NO_OPTION);
        if (confirm == JOptionPane.YES_OPTION) {
            try {
                service.ketThucLop(maLop);
                load();
                JOptionPane.showMessageDialog(this, "Đã xử lý kết thúc lớp.");
            } catch (RuntimeException ex) { showError(ex); }
        }
    }

    private void showError(RuntimeException ex) {
        JOptionPane.showMessageDialog(this, ex.getMessage(), "Lỗi", JOptionPane.ERROR_MESSAGE);
    }
}
