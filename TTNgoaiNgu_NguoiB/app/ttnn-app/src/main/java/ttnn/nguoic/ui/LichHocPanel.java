
package ttnn.nguoic.ui;

import ttnn.nguoic.service.LichHocService;
import ttnn.nguoic.service.LopService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Time;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

public class LichHocPanel extends JPanel {

    private final LichHocService lichService = new LichHocService();
    private final LopService lopService = new LopService();

    private final JTextField txtMaLop = new JTextField(12);

    private final JLabel lblTenKhoa = new JLabel("-");
    private final JLabel lblMaGV = new JLabel("-");
    private final JLabel lblTenGV = new JLabel("-");
    private final JLabel lblNgayKhaiGiang = new JLabel("-");
    private final JLabel lblNgayKetThuc = new JLabel("-");
    private final JLabel lblSiSo = new JLabel("-");
    private final JLabel lblTrangThai = new JLabel("-");

    private final DefaultTableModel model = new DefaultTableModel(
            new Object[]{
                    "Mã lịch", "Mã lớp", "Thứ",
                    "Bắt đầu", "Kết thúc", "Phòng học"
            }, 0
    ) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };

    private final JTable tblLich = new JTable(model);

    private String maLopDangXem;

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("HH:mm");

    public LichHocPanel() {
        setLayout(new BorderLayout(12, 12));
        setBackground(new Color(235, 248, 252));
        setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        add(createTopPanel(), BorderLayout.NORTH);
        add(createTablePanel(), BorderLayout.CENTER);
        add(createInfoPanel(), BorderLayout.SOUTH);

        tblLich.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tblLich.setRowHeight(28);
        tblLich.getTableHeader().setReorderingAllowed(false);
    }

    private JPanel createTopPanel() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(190, 220, 230)),
                BorderFactory.createEmptyBorder(12, 12, 12, 12)
        ));

        JPanel searchPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 5));
        searchPanel.setBackground(Color.WHITE);

        JLabel lblMaLopTitle = new JLabel("Mã lớp:");
        lblMaLopTitle.setFont(new Font("Arial", Font.BOLD, 14));

        JButton btnXem = new JButton("Xem lịch lớp");
        JButton btnThem = new JButton("Thêm lịch");
        JButton btnSua = new JButton("Sửa lịch");

        styleButton(btnXem, new Color(0, 130, 150));
        styleButton(btnThem, new Color(35, 145, 100));
        styleButton(btnSua, new Color(55, 115, 190));

        searchPanel.add(lblMaLopTitle);
        searchPanel.add(txtMaLop);
        searchPanel.add(btnXem);
        searchPanel.add(btnThem);
        searchPanel.add(btnSua);

        btnXem.addActionListener(e -> xemLichLop());
        btnThem.addActionListener(e -> themLich());
        btnSua.addActionListener(e -> suaLich());

        panel.add(searchPanel, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createTablePanel() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(190, 220, 230)),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        JLabel title = new JLabel("DANH SÁCH LỊCH HỌC");
        title.setFont(new Font("Arial", Font.BOLD, 16));
        title.setForeground(new Color(0, 110, 135));
        title.setBorder(BorderFactory.createEmptyBorder(0, 0, 8, 0));

        panel.add(title, BorderLayout.NORTH);
        panel.add(new JScrollPane(tblLich), BorderLayout.CENTER);

        return panel;
    }

    private JPanel createInfoPanel() {
        JPanel panel = new JPanel(new GridLayout(2, 4, 15, 8));
        panel.setBackground(Color.WHITE);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(190, 220, 230)),
                BorderFactory.createEmptyBorder(12, 12, 12, 12)
        ));

        panel.add(createInfoItem("Tên khóa học", lblTenKhoa));
        panel.add(createInfoItem("Mã giảng viên", lblMaGV));
        panel.add(createInfoItem("Tên giảng viên", lblTenGV));
        panel.add(createInfoItem("Sĩ số", lblSiSo));
        panel.add(createInfoItem("Ngày khai giảng", lblNgayKhaiGiang));
        panel.add(createInfoItem("Ngày kết thúc", lblNgayKetThuc));
        panel.add(createInfoItem("Trạng thái lớp", lblTrangThai));

        return panel;
    }

    private JPanel createInfoItem(String title, JLabel value) {
        JPanel panel = new JPanel(new BorderLayout(3, 5));
        panel.setBackground(Color.WHITE);

        JLabel lblTitle = new JLabel(title);
        lblTitle.setFont(new Font("Arial", Font.BOLD, 12));
        lblTitle.setForeground(new Color(80, 100, 110));

        value.setFont(new Font("Arial", Font.PLAIN, 13));
        value.setForeground(new Color(30, 70, 85));

        panel.add(lblTitle, BorderLayout.NORTH);
        panel.add(value, BorderLayout.CENTER);

        return panel;
    }

    private void styleButton(JButton button, Color color) {
        button.setBackground(color);
        button.setForeground(Color.WHITE);
        button.setFocusPainted(false);
        button.setFont(new Font("Arial", Font.BOLD, 12));
        button.setCursor(new Cursor(Cursor.HAND_CURSOR));
    }

    private void xemLichLop() {
        String maLop = txtMaLop.getText().trim();

        if (maLop.isEmpty()) {
            JOptionPane.showMessageDialog(
                    this,
                    "Vui lòng nhập mã lớp.",
                    "Thông báo",
                    JOptionPane.WARNING_MESSAGE
            );
            txtMaLop.requestFocus();
            return;
        }

        try {
            LopService.LopRow lop = lopService.timTheoMaLop(maLop);

            if (lop == null) {
                JOptionPane.showMessageDialog(
                        this,
                        "Không tìm thấy lớp có mã " + maLop + ".",
                        "Thông báo",
                        JOptionPane.INFORMATION_MESSAGE
                );
                xoaThongTinLop();
                model.setRowCount(0);
                maLopDangXem = null;
                return;
            }

            maLopDangXem = lop.maLop();

            lblTenKhoa.setText(giaTri(lop.tenKhoa()));
            lblMaGV.setText(giaTri(lop.maGV()));
            lblTenGV.setText(giaTri(lop.tenGiangVien()));
            lblNgayKhaiGiang.setText(giaTri(lop.ngayKhaiGiang()));
            lblNgayKetThuc.setText(giaTri(lop.ngayKetThuc()));
            lblSiSo.setText(lop.siSoHienTai() + " / " + lop.siSoToiDa());
            lblTrangThai.setText(giaTri(lop.trangThai()));

            taiDanhSachLich(maLopDangXem);

        } catch (Exception ex) {
            hienThongBaoLoi(ex, "Không thể tải lịch học");
        }
    }

    private void taiDanhSachLich(String maLop) {
        model.setRowCount(0);

        List<LichHocService.LichRow> danhSach =
                lichService.cuaLop(maLop);

        for (LichHocService.LichRow lich : danhSach) {
            model.addRow(new Object[]{
                    lich.maLich(),
                    lich.maLop(),
                    lich.tenThu(),
                    dinhDangGio(lich.gioBatDau()),
                    dinhDangGio(lich.gioKetThuc()),
                    lich.phongHoc()
            });
        }
    }

    private void themLich() {
        String maLop = txtMaLop.getText().trim();

        if (maLop.isEmpty()) {
            JOptionPane.showMessageDialog(
                    this,
                    "Vui lòng nhập mã lớp trước khi thêm lịch.",
                    "Thông báo",
                    JOptionPane.WARNING_MESSAGE
            );
            return;
        }

        JTextField txtMaLich = new JTextField();
        JComboBox<String> cboThu = taoComboThu();
        JTextField txtBatDau = new JTextField("18:00");
        JTextField txtKetThuc = new JTextField("19:30");
        JTextField txtPhong = new JTextField();

        JPanel form = taoFormLich(
                txtMaLich, cboThu, txtBatDau, txtKetThuc, txtPhong
        );

        int result = JOptionPane.showConfirmDialog(
                this,
                form,
                "Thêm lịch học",
                JOptionPane.OK_CANCEL_OPTION,
                JOptionPane.PLAIN_MESSAGE
        );

        if (result != JOptionPane.OK_OPTION) {
            return;
        }

        try {
            String maLich = txtMaLich.getText().trim();
            int thu = cboThu.getSelectedIndex() + 1;
            Time batDau = parseTime(txtBatDau.getText());
            Time ketThuc = parseTime(txtKetThuc.getText());
            String phong = txtPhong.getText().trim();

            lichService.themLich(
                    maLich, maLop, thu, batDau, ketThuc, phong
            );

            JOptionPane.showMessageDialog(
                    this,
                    "Thêm lịch học thành công.",
                    "Thông báo",
                    JOptionPane.INFORMATION_MESSAGE
            );

            maLopDangXem = maLop;
            taiDanhSachLich(maLop);

        } catch (Exception ex) {
            hienThongBaoLoi(ex, "Không thể thêm lịch học");
        }
    }

    private void suaLich() {
        int selectedRow = tblLich.getSelectedRow();

        if (selectedRow < 0) {
            JOptionPane.showMessageDialog(
                    this,
                    "Vui lòng chọn lịch học cần sửa.",
                    "Thông báo",
                    JOptionPane.WARNING_MESSAGE
            );
            return;
        }

        String maLich = String.valueOf(
                model.getValueAt(selectedRow, 0)
        );
        String maLop = String.valueOf(
                model.getValueAt(selectedRow, 1)
        );

        String thuHienTai = String.valueOf(
                model.getValueAt(selectedRow, 2)
        );
        String batDauHienTai = String.valueOf(
                model.getValueAt(selectedRow, 3)
        );
        String ketThucHienTai = String.valueOf(
                model.getValueAt(selectedRow, 4)
        );
        String phongHienTai = String.valueOf(
                model.getValueAt(selectedRow, 5)
        );

        JComboBox<String> cboThu = taoComboThu();
        chonThu(cboThu, thuHienTai);

        JTextField txtBatDau = new JTextField(batDauHienTai);
        JTextField txtKetThuc = new JTextField(ketThucHienTai);
        JTextField txtPhong = new JTextField(phongHienTai);

        JPanel form = new JPanel(new GridLayout(4, 2, 8, 8));
        form.add(new JLabel("Mã lịch:"));
        form.add(new JLabel(maLich));
        form.add(new JLabel("Thứ:"));
        form.add(cboThu);
        form.add(new JLabel("Giờ bắt đầu (HH:mm):"));
        form.add(txtBatDau);
        form.add(new JLabel("Giờ kết thúc (HH:mm):"));
        form.add(txtKetThuc);
        form.add(new JLabel("Phòng học:"));
        form.add(txtPhong);

        int result = JOptionPane.showConfirmDialog(
                this,
                form,
                "Sửa lịch học",
                JOptionPane.OK_CANCEL_OPTION,
                JOptionPane.PLAIN_MESSAGE
        );

        if (result != JOptionPane.OK_OPTION) {
            return;
        }

        try {
            int thu = cboThu.getSelectedIndex() + 1;
            Time batDau = parseTime(txtBatDau.getText());
            Time ketThuc = parseTime(txtKetThuc.getText());
            String phong = txtPhong.getText().trim();

            lichService.suaLich(
                    maLich, maLop, thu, batDau, ketThuc, phong
            );

            JOptionPane.showMessageDialog(
                    this,
                    "Cập nhật lịch học thành công.",
                    "Thông báo",
                    JOptionPane.INFORMATION_MESSAGE
            );

            maLopDangXem = maLop;
            taiDanhSachLich(maLop);

        } catch (Exception ex) {
            hienThongBaoLoi(ex, "Không thể sửa lịch học");
        }
    }

    private JPanel taoFormLich(
            JTextField txtMaLich,
            JComboBox<String> cboThu,
            JTextField txtBatDau,
            JTextField txtKetThuc,
            JTextField txtPhong
    ) {
        JPanel form = new JPanel(new GridLayout(5, 2, 8, 8));

        form.add(new JLabel("Mã lịch:"));
        form.add(txtMaLich);

        form.add(new JLabel("Thứ:"));
        form.add(cboThu);

        form.add(new JLabel("Giờ bắt đầu (HH:mm):"));
        form.add(txtBatDau);

        form.add(new JLabel("Giờ kết thúc (HH:mm):"));
        form.add(txtKetThuc);

        form.add(new JLabel("Phòng học:"));
        form.add(txtPhong);

        return form;
    }

    private JComboBox<String> taoComboThu() {
        return new JComboBox<>(new String[]{
                "Chủ nhật",
                "Thứ 2",
                "Thứ 3",
                "Thứ 4",
                "Thứ 5",
                "Thứ 6",
                "Thứ 7"
        });
    }

    private void chonThu(
            JComboBox<String> combo,
            String tenThu
    ) {
        for (int i = 0; i < combo.getItemCount(); i++) {
            if (combo.getItemAt(i).equalsIgnoreCase(tenThu)) {
                combo.setSelectedIndex(i);
                return;
            }
        }

        // Hỗ trợ dữ liệu hiển thị theo số thứ.
        try {
            int thu = Integer.parseInt(tenThu);
            if (thu >= 1 && thu <= 7) {
                combo.setSelectedIndex(thu - 1);
            }
        } catch (NumberFormatException ignored) {
            // Giữ lựa chọn mặc định nếu không nhận diện được thứ.
        }
    }

    private Time parseTime(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập giờ bắt đầu và giờ kết thúc."
            );
        }

        try {
            LocalTime time = LocalTime.parse(
                    value.trim(),
                    DateTimeFormatter.ofPattern("H:mm")
            );

            return Time.valueOf(time);
        } catch (Exception ex) {
            try {
                LocalTime time = LocalTime.parse(
                        value.trim(),
                        DateTimeFormatter.ofPattern("HH:mm:ss")
                );

                return Time.valueOf(time);
            } catch (Exception ignored) {
                throw new IllegalArgumentException(
                        "Giờ không hợp lệ. Hãy nhập theo dạng HH:mm, ví dụ 18:00."
                );
            }
        }
    }

    private String dinhDangGio(Object value) {
        if (value == null) {
            return "";
        }

        String text = value.toString();

        if (text.length() >= 5) {
            return text.substring(0, 5);
        }

        return text;
    }

    private String giaTri(Object value) {
        return value == null ? "-" : value.toString();
    }

    private void xoaThongTinLop() {
        lblTenKhoa.setText("-");
        lblMaGV.setText("-");
        lblTenGV.setText("-");
        lblNgayKhaiGiang.setText("-");
        lblNgayKetThuc.setText("-");
        lblSiSo.setText("-");
        lblTrangThai.setText("-");
    }

    private void hienThongBaoLoi(Throwable ex, String tieuDe) {
        String message = layThongBaoLoi(ex);

        JOptionPane.showMessageDialog(
                this,
                message,
                tieuDe,
                JOptionPane.WARNING_MESSAGE
        );
    }

    private String layThongBaoLoi(Throwable ex) {
        Throwable current = ex;

        while (current != null) {
            String message = current.getMessage();

            if (message != null) {
                String text = message.toUpperCase();

                // Lỗi vi phạm UNIQUE KEY của SQL Server.
                if (text.contains("UQ_LICHHOC_PHONG")) {
                    return "Khung giờ và phòng học này đã có lịch!\n"
                            + "Vui lòng chọn khung giờ khác hoặc phòng khác.";
                }

                // Lỗi do trigger kiểm tra trùng lịch.
                if (text.contains("53002")) {
                    return "Khung giờ và phòng học này đã có lịch!\n"
                            + "Vui lòng chọn khung giờ khác hoặc phòng khác.";
                }

                if (text.contains("53003")) {
                    return "Lớp này đã có lịch trùng khung giờ trong cùng thứ!\n"
                            + "Vui lòng chọn khung giờ khác.";
                }

                // Dự phòng nếu SQL Server trả thông báo tiếng Anh.
                if (text.contains("VIOLATION OF UNIQUE KEY")
                        || text.contains("DUPLICATE KEY")) {
                    return "Lịch học bị trùng với dữ liệu đã có trong hệ thống.\n"
                            + "Vui lòng kiểm tra mã lịch, phòng học và khung giờ.";
                }
            }

            current = current.getCause();
        }

        String message = ex.getMessage();

        if (message == null || message.isBlank()) {
            return "Đã xảy ra lỗi không xác định.";
        }

        return "Không thể thực hiện thao tác.\nChi tiết: " + message;
    }
}
