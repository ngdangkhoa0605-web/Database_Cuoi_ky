
package ttnn.nguoic.ui;

import ttnn.nguoic.service.LopService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Date;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.EventObject;

public class TaoLopDialog extends JDialog {

    private final LopService service = new LopService();

    private final JTextField maLop = new JTextField(12);
    private final JTextField maKH = new JTextField(12);
    private final JTextField maGV = new JTextField(12);
    private final JTextField ngayKhaiGiang = new JTextField(12);
    private final JTextField ngayKetThuc = new JTextField(12);

    private final JSpinner siSoToiDa =
            new JSpinner(new SpinnerNumberModel(30, 1, 255, 1));

    private final JComboBox<String> trangThai = new JComboBox<>(
            new String[]{
                    "Đang tuyển sinh",
                    "Đang học",
                    "Đã kết thúc"
            });

    private final DefaultTableModel model = new DefaultTableModel(
            new String[]{
                    "Mã lịch",
                    "Thứ (1-7)",
                    "Giờ bắt đầu",
                    "Giờ kết thúc",
                    "Phòng học"
            }, 0) {

        @Override
        public boolean isCellEditable(int row, int column) {
            return true;
        }
    };

    private final JTable table = new JTable(model) {

        @Override
        public boolean editCellAt(
                int row, int column, EventObject event) {

            boolean result = super.editCellAt(row, column, event);

            if (result && getEditorComponent() != null) {
                getEditorComponent().requestFocusInWindow();
            }

            return result;
        }
    };

    public TaoLopDialog(Window owner) {
        super(owner, "Tạo lớp kèm lịch học",
                ModalityType.APPLICATION_MODAL);

        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout(10, 10));

        add(createInfoPanel(), BorderLayout.NORTH);
        add(createSchedulePanel(), BorderLayout.CENTER);
        add(createButtons(), BorderLayout.SOUTH);

        // Khởi tạo một dòng lịch mẫu.
        model.addRow(new Object[]{
                "", 2, "18:00:00", "20:00:00", ""
        });

        setSize(1050, 620);
        setLocationRelativeTo(owner);
    }

    // ==================== THÔNG TIN LỚP ====================

    private JPanel createInfoPanel() {
        JPanel panel = new JPanel(new GridLayout(0, 4, 8, 8));
        panel.setBorder(BorderFactory.createTitledBorder(
                "Thông tin lớp học"));

        panel.add(new JLabel("Mã lớp:"));
        panel.add(maLop);

        panel.add(new JLabel("Mã khóa học:"));
        panel.add(maKH);

        panel.add(new JLabel("Mã GV chính:"));
        panel.add(maGV);

        panel.add(new JLabel("Sĩ số tối đa:"));
        panel.add(siSoToiDa);

        panel.add(new JLabel("Ngày khai giảng:"));
        panel.add(ngayKhaiGiang);

        panel.add(new JLabel("Ngày kết thúc:"));
        panel.add(ngayKetThuc);

        panel.add(new JLabel("Trạng thái:"));
        panel.add(trangThai);

        panel.add(new JLabel("Định dạng ngày:"));
        panel.add(new JLabel("yyyy-MM-dd"));

        return panel;
    }

    // ==================== DANH SÁCH LỊCH HỌC ====================

    private JPanel createSchedulePanel() {
        JPanel panel = new JPanel(new BorderLayout(6, 6));
        panel.setBorder(BorderFactory.createTitledBorder(
                "Danh sách lịch học"));

        table.setRowHeight(26);
        table.setCellSelectionEnabled(true);
        table.setSurrendersFocusOnKeystroke(true);

        JTextField editorField = new JTextField();
        DefaultCellEditor cellEditor =
                new DefaultCellEditor(editorField);

        cellEditor.setClickCountToStart(1);
        table.setDefaultEditor(Object.class, cellEditor);

        panel.add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel buttons = new JPanel(
                new FlowLayout(FlowLayout.LEFT));

        JButton add = new JButton("Thêm lịch");
        JButton remove = new JButton("Xóa dòng đã chọn");

        add.addActionListener(e -> {
            model.addRow(new Object[]{
                    "", 2, "18:00:00", "20:00:00", ""
            });

            int lastRow = table.getRowCount() - 1;
            table.setRowSelectionInterval(lastRow, lastRow);
            table.setColumnSelectionInterval(0, 0);
            table.editCellAt(lastRow, 0);
            table.requestFocusInWindow();
        });

        remove.addActionListener(e -> {
            int row = table.getSelectedRow();

            if (row >= 0) {
                if (table.isEditing()) {
                    table.getCellEditor().stopCellEditing();
                }

                model.removeRow(table.convertRowIndexToModel(row));
            } else {
                JOptionPane.showMessageDialog(
                        this,
                        "Hãy chọn dòng lịch muốn xóa.",
                        "Thông báo",
                        JOptionPane.INFORMATION_MESSAGE);
            }
        });

        buttons.add(add);
        buttons.add(remove);

        panel.add(buttons, BorderLayout.SOUTH);

        return panel;
    }

    // ==================== NÚT LƯU / HỦY ====================

    private JPanel createButtons() {
        JPanel panel = new JPanel(
                new FlowLayout(FlowLayout.RIGHT));

        JButton save = new JButton("Lưu lớp");
        JButton cancel = new JButton("Hủy");

        save.addActionListener(e -> save());
        cancel.addActionListener(e -> dispose());

        panel.add(save);
        panel.add(cancel);

        return panel;
    }

    // ==================== LƯU LỚP ====================

    private void save() {
        try {
            // Kết thúc chỉnh sửa ô hiện tại trước khi đọc dữ liệu.
            if (table.isEditing()) {
                if (!table.getCellEditor().stopCellEditing()) {
                    throw new IllegalArgumentException(
                            "Vui lòng kiểm tra dữ liệu trong bảng lịch học.");
                }
            }

            Date startDate = Date.valueOf(
                    LocalDate.parse(
                            ngayKhaiGiang.getText().trim()));

            Date endDate = Date.valueOf(
                    LocalDate.parse(
                            ngayKetThuc.getText().trim()));

            String xml = buildScheduleXml();

            service.taoLopVaLichHoc(
                    maLop.getText().trim(),
                    maKH.getText().trim(),
                    maGV.getText().trim(),
                    startDate,
                    endDate,
                    (Integer) siSoToiDa.getValue(),
                    (String) trangThai.getSelectedItem(),
                    xml
            );

            JOptionPane.showMessageDialog(
                    this,
                    "Tạo lớp và lịch học thành công.",
                    "Thành công",
                    JOptionPane.INFORMATION_MESSAGE);

            dispose();

        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(
                    this,
                    layThongBaoLoi(ex),
                    "Không thể lưu lớp",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    // ==================== TẠO XML LỊCH HỌC ====================

    private String buildScheduleXml() {
        if (model.getRowCount() == 0) {
            throw new IllegalArgumentException(
                    "Phải nhập ít nhất một lịch học.");
        }

        StringBuilder xml = new StringBuilder("<LichHoc>");

        for (int i = 0; i < model.getRowCount(); i++) {
            String maLich = cell(i, 0);
            String thuText = cell(i, 1);
            String batDau = cell(i, 2);
            String ketThuc = cell(i, 3);
            String phong = cell(i, 4);

            if (maLich.isBlank() || phong.isBlank()) {
                throw new IllegalArgumentException(
                        "Dòng lịch " + (i + 1)
                                + ": mã lịch và phòng học không được để trống.");
            }

            int thu;

            try {
                thu = Integer.parseInt(thuText);
            } catch (NumberFormatException ex) {
                throw new IllegalArgumentException(
                        "Dòng lịch " + (i + 1)
                                + ": thứ phải là số từ 1 đến 7.");
            }

            if (thu < 1 || thu > 7) {
                throw new IllegalArgumentException(
                        "Dòng lịch " + (i + 1)
                                + ": thứ phải từ 1 đến 7.");
            }

            LocalTime start;
            LocalTime end;

            try {
                start = LocalTime.parse(batDau);
                end = LocalTime.parse(ketThuc);
            } catch (RuntimeException ex) {
                throw new IllegalArgumentException(
                        "Dòng lịch " + (i + 1)
                                + ": giờ phải theo dạng HH:mm hoặc HH:mm:ss.");
            }

            if (!end.isAfter(start)) {
                throw new IllegalArgumentException(
                        "Dòng lịch " + (i + 1)
                                + ": giờ kết thúc phải sau giờ bắt đầu.");
            }

            Time.valueOf(start);
            Time.valueOf(end);

            // Kiểm tra lịch trùng nhau trong cùng lớp ngay trên giao diện.
            for (int j = 0; j < i; j++) {
                int thuTruoc = Integer.parseInt(cell(j, 1));
                LocalTime startTruoc =
                        LocalTime.parse(cell(j, 2));
                LocalTime endTruoc =
                        LocalTime.parse(cell(j, 3));

                boolean cungThu = thu == thuTruoc;

                boolean trungGio =
                        start.isBefore(endTruoc)
                                && end.isAfter(startTruoc);

                if (cungThu && trungGio) {
                    throw new IllegalArgumentException(
                            "Lịch học dòng " + (i + 1)
                                    + " bị trùng giờ với dòng " + (j + 1)
                                    + " trong cùng lớp.");
                }
            }

            xml.append("<Lich")
                    .append(" MaLich=\"")
                    .append(escapeXml(maLich))
                    .append("\"")
                    .append(" Thu=\"").append(thu).append("\"")
                    .append(" GioBatDau=\"").append(start).append("\"")
                    .append(" GioKetThuc=\"").append(end).append("\"")
                    .append(" PhongHoc=\"")
                    .append(escapeXml(phong))
                    .append("\"")
                    .append("/>");
        }

        xml.append("</LichHoc>");

        return xml.toString();
    }

    // ==================== ĐỌC Ô BẢNG ====================

    private String cell(int row, int column) {
        Object value = model.getValueAt(row, column);
        return value == null ? "" : value.toString().trim();
    }

    // ==================== ESCAPE XML ====================

    private String escapeXml(String value) {
        return value
                .replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("'", "&apos;");
    }

    // ==================== THÔNG BÁO LỖI ====================

    private String layThongBaoLoi(Throwable ex) {
        Throwable current = ex;

        while (current != null) {
            String message = current.getMessage();

            if (message != null) {
                if (message.contains("53001")
                        || message.contains(
                        "Giảng viên chính phải đang công tác")) {
                    return "Không thể lưu lớp!\n"
                            + "Giảng viên chính phải đang công tác "
                            + "và cùng ngôn ngữ với khóa học.";
                }

                if (message.contains("53002")) {
                    return "Không thể lưu lịch học!\n"
                            + "Phòng học đã có lịch trùng giờ "
                            + "vào cùng thứ.";
                }

                if (message.contains("53003")) {
                    return "Không thể lưu lịch học!\n"
                            + "Lớp đã có lịch trùng giờ "
                            + "vào cùng thứ.";
                }

                if (message.contains("Incorrect syntax near '@P7'")) {
                    return "Lỗi câu SQL khi truyền danh sách lịch học.\n"
                            + "Vui lòng kiểm tra câu gọi "
                            + "SP_TaoLop_VaLichHoc trong LopService.";
                }

                if (message.contains("UQ_LICHHOC_PHONG")) {
                    return "Không thể lưu lịch học!\n"
                            + "Phòng học đã có lịch trùng.";
                }
            }

            current = current.getCause();
        }

        // Tìm thông báo SQL Server trong toàn bộ chuỗi lỗi.
        String message = ex.getMessage();

        if (message == null || message.isBlank()) {
            return "Không thể tạo lớp và lịch học. "
                    + "Vui lòng kiểm tra dữ liệu hoặc kết nối SQL Server.";
        }

        return "Không thể tạo lớp và lịch học.\nChi tiết: " + message;
    }
}
