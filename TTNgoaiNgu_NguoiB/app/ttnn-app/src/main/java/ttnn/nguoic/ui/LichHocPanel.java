package ttnn.nguoic.ui;



import ttnn.common.PanelStyle;import ttnn.nguoic.service.LichHocService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.List;

public class LichHocPanel extends JPanel {
    private final LichHocService service = new LichHocService();
    private final JTextField maLop = new JTextField(8);
    private final DefaultTableModel model = new DefaultTableModel(
            new String[]{"Mã lịch", "Mã lớp", "Thứ", "Bắt đầu", "Kết thúc", "Phòng"}, 0) {
        @Override public boolean isCellEditable(int row, int column) { return false; }
    };

    public LichHocPanel() {
        setLayout(new BorderLayout(8, 8));
        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT));
        top.add(new JLabel("Mã lớp:")); top.add(maLop);
        JButton xem = new JButton("Xem lịch lớp");
        top.add(xem);
        add(top, BorderLayout.NORTH);
        add(new JScrollPane(new JTable(model)), BorderLayout.CENTER);
        xem.addActionListener(e -> load());
    
        PanelStyle.apDung(this);
    }

    private void load() {
        if (maLop.getText().isBlank()) {
            JOptionPane.showMessageDialog(this, "Nhập mã lớp cần xem.");
            return;
        }
        try {
            List<LichHocService.LichRow> rows = service.cuaLop(maLop.getText().trim());
            model.setRowCount(0);
            for (var r : rows) {
                model.addRow(new Object[]{r.maLich(), r.maLop(), r.tenThu(), r.gioBatDau(), r.gioKetThuc(), r.phongHoc()});
            }
        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(this, ex.getMessage(), "Lỗi", JOptionPane.ERROR_MESSAGE);
        }
    }
}
