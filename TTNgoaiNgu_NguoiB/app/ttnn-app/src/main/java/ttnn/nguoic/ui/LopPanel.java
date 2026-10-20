
package ttnn.nguoic.ui;

import ttnn.common.PanelStyle;
import ttnn.nguoic.service.LopService;
import ttnn.nguoib.service.DangKyService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Date;
import java.util.List;

public class LopPanel extends JPanel {

    private final LopService service = new LopService();
    private final DangKyService dangKyService = new DangKyService();

    private final JTextField maKH = new JTextField(8);
    private final JTextField maGV = new JTextField(8);

    private final JComboBox<String> trangThai = new JComboBox<>(
            new String[]{
                    "Tất cả",
                    "Đang tuyển sinh",
                    "Đang học",
                    "Đã kết thúc"
            });

    private final DefaultTableModel model = new DefaultTableModel(
            new String[]{
                    "Mã lớp", "Mã khóa", "Tên khóa",
                    "Mã GV", "Giảng viên",
                    "Khai giảng", "Kết thúc",
                    "Sĩ số", "Tối đa", "Lấp đầy (%)", "Trạng thái"
            }, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };

    private final JTable table = new JTable(model);

    private final DefaultTableModel hocVienModel = new DefaultTableModel(
            new String[]{
                    "Mã học viên", "Họ tên", "Ngày sinh",
                    "Số điện thoại", "Email", "Địa chỉ",
                    "Ngày đăng ký"
            }, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };

    private final JTable hocVienTable = new JTable(hocVienModel);

    private final JLabel lblDanhSach = new JLabel(
            "Danh sách học viên: Chưa chọn lớp");

    public LopPanel() {
        setLayout(new BorderLayout(8, 8));

        // Bộ lọc và các nút chức năng.
        JPanel filters = new JPanel(
                new FlowLayout(FlowLayout.LEFT));

        filters.add(new JLabel("Mã khóa:"));
        filters.add(maKH);

        filters.add(new JLabel("Mã GV:"));
        filters.add(maGV);

        filters.add(new JLabel("Trạng thái:"));
        filters.add(trangThai);

        JButton search = new JButton("Tìm kiếm");
        JButton create = new JButton("Tạo lớp");
        JButton edit = new JButton("Sửa lớp");
        JButton finish = new JButton("Kết thúc lớp");

        filters.add(search);
        filters.add(create);
        filters.add(edit);
        filters.add(finish);

        // Bảng lớp học phía trên.
        table.setRowHeight(27);
        table.setAutoCreateRowSorter(true);
        table.setSelectionMode(
                ListSelectionModel.SINGLE_SELECTION);

        JPanel lopPanel = new JPanel(new BorderLayout(5, 5));
        lopPanel.add(filters, BorderLayout.NORTH);
        lopPanel.add(new JScrollPane(table), BorderLayout.CENTER);

        // Bảng học viên phía dưới.
        hocVienTable.setRowHeight(26);
        hocVienTable.setAutoCreateRowSorter(true);

        JPanel danhSachPanel = new JPanel(new BorderLayout(5, 5));
        danhSachPanel.setBorder(
                BorderFactory.createEmptyBorder(5, 5, 5, 5));

        lblDanhSach.setFont(
                lblDanhSach.getFont().deriveFont(Font.BOLD, 14f));

        danhSachPanel.add(lblDanhSach, BorderLayout.NORTH);
        danhSachPanel.add(
                new JScrollPane(hocVienTable),
                BorderLayout.CENTER);

        // Chia giao diện thành hai khung trên và dưới.
        JSplitPane splitPane = new JSplitPane(
                JSplitPane.VERTICAL_SPLIT,
                lopPanel,
                danhSachPanel
        );

        splitPane.setResizeWeight(0.55);
        splitPane.setOneTouchExpandable(true);
        splitPane.setContinuousLayout(true);
        splitPane.setDividerSize(8);

        add(splitPane, BorderLayout.CENTER);

        // Sự kiện các nút.
        search.addActionListener(e -> load());

        create.addActionListener(e -> {
            Window owner = SwingUtilities.getWindowAncestor(this);

            TaoLopDialog dialog = new TaoLopDialog(owner);
            dialog.setVisible(true);

            load();
        });
        edit.addActionListener(e -> editSelected());

        finish.addActionListener(e -> finishSelected());

        // Khi chọn một lớp, tải danh sách học viên của lớp đó.
        table.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                loadHocVienSelected();
            }
        });

        PanelStyle.apDung(this);

        // Tải danh sách lớp lúc mở giao diện.
        load();
    }

    private void load() {
        try {
            String status = (String) trangThai.getSelectedItem();

            if ("Tất cả".equals(status)) {
                status = null;
            }

            List<LopService.LopRow> rows = service.timKiem(
                    maKH.getText(),
                    maGV.getText(),
                    status,
                    (Date) null,
                    (Date) null
            );

            model.setRowCount(0);
            hocVienModel.setRowCount(0);
            lblDanhSach.setText(
                    "Danh sách học viên: Hãy chọn một lớp");

            rows.forEach(r -> model.addRow(r.toRow()));

        } catch (RuntimeException ex) {
            showError(ex);
        }
    }

    private void loadHocVienSelected() {
        int viewRow = table.getSelectedRow();

        hocVienModel.setRowCount(0);

        if (viewRow < 0) {
            lblDanhSach.setText(
                    "Danh sách học viên: Chưa chọn lớp");
            return;
        }

        int row = table.convertRowIndexToModel(viewRow);
        String maLop = String.valueOf(model.getValueAt(row, 0));

        lblDanhSach.setText(
                "Danh sách học viên của lớp " + maLop);

        try {
            List<Object[]> rows =
                    dangKyService.hocVienTheoLop(maLop);

            for (Object[] r : rows) {
                hocVienModel.addRow(r);
            }

            lblDanhSach.setText(
                    "Danh sách học viên lớp " + maLop
                            + " — Tổng số: " + rows.size());

        } catch (RuntimeException ex) {
            showError(ex);
        }
    }

    private void finishSelected() {
        int viewRow = table.getSelectedRow();

        if (viewRow < 0) {
            JOptionPane.showMessageDialog(
                    this, "Hãy chọn một lớp.");
            return;
        }

        int row = table.convertRowIndexToModel(viewRow);
        String maLop = String.valueOf(model.getValueAt(row, 0));

        int confirm = JOptionPane.showConfirmDialog(
                this,
                "Kết thúc lớp " + maLop + "?",
                "Xác nhận",
                JOptionPane.YES_NO_OPTION
        );

        if (confirm != JOptionPane.YES_OPTION) {
            return;
        }

        try {
            service.ketThucLop(maLop);
            load();

            JOptionPane.showMessageDialog(
                    this, "Đã xử lý kết thúc lớp.");

        } catch (RuntimeException ex) {
            showError(ex);
        }
    }

    private void showError(RuntimeException ex) {
        JOptionPane.showMessageDialog(
                this,
                ex.getMessage() == null
                        ? "Đã xảy ra lỗi."
                        : ex.getMessage(),
                "Lỗi",
                JOptionPane.ERROR_MESSAGE
        );
    }
    private void editSelected() {
        int viewRow = table.getSelectedRow();

        if (viewRow < 0) {
            JOptionPane.showMessageDialog(
                    this, "Hãy chọn lớp cần sửa.");
            return;
        }

        int row = table.convertRowIndexToModel(viewRow);
        String maLop = String.valueOf(model.getValueAt(row, 0));

        try {
            LopService.LopRow lop = service.timTheoMaLop(maLop);

            if (lop == null) {
                JOptionPane.showMessageDialog(
                        this, "Không tìm thấy lớp cần sửa.");
                load();
                return;
            }

            Window owner = SwingUtilities.getWindowAncestor(this);
            SuaLopDialog dialog = new SuaLopDialog(owner, lop);
            dialog.setVisible(true);

            load();

        } catch (RuntimeException ex) {
            showError(ex);
        }
    }
}
