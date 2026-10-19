
package ttnn.nguoic.ui;

import ttnn.common.PanelStyle;
import ttnn.nguoic.service.LichHocService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;

public class LichHocTuanPanel extends JPanel {

    private final LichHocService service = new LichHocService();

    private final DefaultTableModel model = new DefaultTableModel(
            new String[]{
                    "Mã lịch",
                    "Mã lớp",
                    "Mã khóa",
                    "Tên khóa",
                    "Giảng viên",
                    "Thứ",
                    "Bắt đầu",
                    "Kết thúc",
                    "Phòng",
                    "Trạng thái lớp"
            }, 0) {

        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };

    private final JTable table = new JTable(model);

    public LichHocTuanPanel() {
        setLayout(new BorderLayout(8, 8));

        JButton refresh = new JButton("Tải lịch học tuần");

        JPanel top = new JPanel(
                new FlowLayout(FlowLayout.LEFT));

        top.add(refresh);

        add(top, BorderLayout.NORTH);

        table.setRowHeight(30);
        table.setAutoCreateRowSorter(true);

        add(new JScrollPane(table), BorderLayout.CENTER);

        refresh.addActionListener(e -> load());

        PanelStyle.apDung(this);

        load();
    }

    private void load() {
        try {
            model.setRowCount(0);

            service.lichTuan().forEach(r ->
                    model.addRow(new Object[]{
                            r.maLich(),
                            r.maLop(),
                            r.maKH(),
                            r.tenKhoa(),
                            r.tenGiangVien(),
                            r.tenThu(),
                            r.gioBatDau(),
                            r.gioKetThuc(),
                            r.phongHoc(),
                            r.trangThaiLop()
                    })
            );

        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(
                    this,
                    ex.getMessage() == null
                            ? "Không thể tải lịch học tuần."
                            : ex.getMessage(),
                    "Lỗi",
                    JOptionPane.ERROR_MESSAGE
            );
        }
    }
}
