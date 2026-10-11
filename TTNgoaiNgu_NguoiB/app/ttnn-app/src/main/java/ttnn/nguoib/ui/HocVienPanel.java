package ttnn.nguoib.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoib.service.BaoCaoService;
import ttnn.nguoib.service.HocVienService;
import ttnn.nguoib.service.HocVienService.HocVienRow;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridLayout;
import java.util.List;

/**
 * Man hinh QUAN LY HOC VIEN.
 * Goi: SP_TimKiemHocVien (tim kiem), CRUD entity HocVien (them/sua/xoa),
 *      V_HOCVIEN_LichSuHoc (lich su hoc cua hoc vien dang chon).
 */
public class HocVienPanel extends JPanel {
    private final HocVienService service = new HocVienService();
    private final BaoCaoService baoCao = new BaoCaoService();

    private final JTextField txtTimTen = new JTextField(14);
    private final JTextField txtTimSdt = new JTextField(10);
    private final JTextField txtTimEmail = new JTextField(14);

    private final SimpleTableModel modelHV = new SimpleTableModel(
            "Mã HV", "Họ tên", "Ngày sinh", "SĐT", "Email", "Địa chỉ", "Số lớp");
    private final JTable tblHV = UiUtil.newTable(modelHV);
    private final SimpleTableModel modelLichSu = new SimpleTableModel(
            "Mã ĐK", "Lớp", "Khóa học", "Trạng thái lớp", "Ngày ĐK", "Điểm", "Cần thu", "Đã thu", "Thanh toán");
    private final JTable tblLichSu = UiUtil.newTable(modelLichSu);

    private final JTextField txtMa = new JTextField(8);
    private final JTextField txtTen = new JTextField(20);
    private final JTextField txtNgaySinh = new JTextField(10);
    private final JTextField txtSdt = new JTextField(12);
    private final JTextField txtEmail = new JTextField(20);
    private final JTextField txtDiaChi = new JTextField(30);

    public HocVienPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        txtMa.setEditable(false);
        txtMa.setToolTipText("Mã tự sinh khi thêm mới");
        txtNgaySinh.setToolTipText("dd/MM/yyyy");

        // --- tim kiem ---
        JPanel tim = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        tim.setBorder(BorderFactory.createTitledBorder("Tìm kiếm (SP_TimKiemHocVien)"));
        tim.add(new javax.swing.JLabel("Họ tên:"));
        tim.add(txtTimTen);
        tim.add(new javax.swing.JLabel("SĐT:"));
        tim.add(txtTimSdt);
        tim.add(new javax.swing.JLabel("Email:"));
        tim.add(txtTimEmail);
        JButton btnTim = new JButton("Tìm");
        JButton btnTatCa = new JButton("Hiện tất cả");
        tim.add(btnTim);
        tim.add(btnTatCa);
        add(tim, BorderLayout.NORTH);

        // --- bang hoc vien + lich su hoc ---
        JPanel lichSu = new JPanel(new BorderLayout());
        lichSu.setBorder(BorderFactory.createTitledBorder("Lịch sử học của học viên đang chọn (V_HOCVIEN_LichSuHoc)"));
        lichSu.add(UiUtil.scroll(tblLichSu, 120), BorderLayout.CENTER);
        JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, UiUtil.scroll(tblHV, 220), lichSu);
        split.setResizeWeight(0.65);
        add(split, BorderLayout.CENTER);

        // --- form + nut ---
        JPanel form = UiUtil.formPanel("Thông tin học viên");
        UiUtil.addField(form, 0, 0, "Mã HV:", txtMa);
        UiUtil.addField(form, 0, 2, "Họ tên:", txtTen);
        UiUtil.addField(form, 1, 0, "Ngày sinh:", txtNgaySinh);
        UiUtil.addField(form, 1, 2, "SĐT:", txtSdt);
        UiUtil.addField(form, 2, 0, "Email:", txtEmail);
        UiUtil.addField(form, 2, 2, "Địa chỉ:", txtDiaChi);
        JPanel nut = new JPanel(new GridLayout(1, 0, 6, 0));
        JButton btnThem = new JButton("Thêm mới");
        JButton btnSua = new JButton("Cập nhật");
        JButton btnXoa = new JButton("Xóa");
        JButton btnMoi = new JButton("Làm mới form");
        nut.add(btnThem);
        nut.add(btnSua);
        nut.add(btnXoa);
        nut.add(btnMoi);
        JPanel south = new JPanel(new BorderLayout(4, 4));
        south.add(form, BorderLayout.CENTER);
        south.add(nut, BorderLayout.SOUTH);
        add(south, BorderLayout.SOUTH);

        btnTim.addActionListener(e -> timKiem());
        btnTatCa.addActionListener(e -> {
            txtTimTen.setText("");
            txtTimSdt.setText("");
            txtTimEmail.setText("");
            timKiem();
        });
        btnThem.addActionListener(e -> them());
        btnSua.addActionListener(e -> sua());
        btnXoa.addActionListener(e -> xoa());
        btnMoi.addActionListener(e -> lamMoiForm());
        tblHV.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                chonDong();
            }
        });
        txtTimTen.addActionListener(e -> timKiem());
        txtTimSdt.addActionListener(e -> timKiem());
        txtTimEmail.addActionListener(e -> timKiem());

        UiUtil.run(this, this::timKiem);
    }

    /** Duoc goi lai khi tab nay hien ra de du lieu luon moi. */
    public void lamMoi() {
        UiUtil.run(this, this::timKiem);
    }

    private String maDangChon() {
        int r = tblHV.getSelectedRow();
        return r < 0 ? null : modelHV.raw(tblHV.convertRowIndexToModel(r), 0).toString();
    }

    private void timKiem() {
        String giuMa = maDangChon();
        List<HocVienRow> ds = service.timKiem(txtTimTen.getText(), txtTimSdt.getText(), txtTimEmail.getText());
        modelHV.setRows(ds.stream().map(HocVienRow::toRow).toList());
        modelLichSu.setRows(List.of());
        if (giuMa != null) {
            for (int i = 0; i < modelHV.getRowCount(); i++) {
                if (giuMa.equals(modelHV.raw(i, 0))) {
                    tblHV.setRowSelectionInterval(i, i);
                    break;
                }
            }
        }
    }

    private void chonDong() {
        String ma = maDangChon();
        if (ma == null) {
            return;
        }
        int r = tblHV.convertRowIndexToModel(tblHV.getSelectedRow());
        txtMa.setText(ma);
        txtTen.setText(modelHV.raw(r, 1).toString());
        txtNgaySinh.setText(UiUtil.formatDate((java.time.LocalDate) modelHV.raw(r, 2)));
        txtSdt.setText(String.valueOf(modelHV.raw(r, 3)));
        txtEmail.setText(String.valueOf(modelHV.raw(r, 4)));
        txtDiaChi.setText(String.valueOf(modelHV.raw(r, 5)));
        UiUtil.run(this, () -> modelLichSu.setRows(baoCao.lichSuHoc(ma)));
    }

    private void them() {
        UiUtil.run(this, () -> {
            var hv = service.them(txtTen.getText(), UiUtil.parseDate(txtNgaySinh.getText(), "Ngày sinh"),
                    txtSdt.getText(), txtEmail.getText(), txtDiaChi.getText());
            UiUtil.showInfo(this, "Đã thêm học viên " + hv.getMaHV() + ".");
            lamMoiForm();
            timKiem();
        });
    }

    private void sua() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một học viên trong danh sách để cập nhật.");
            return;
        }
        UiUtil.run(this, () -> {
            service.sua(ma, txtTen.getText(), UiUtil.parseDate(txtNgaySinh.getText(), "Ngày sinh"),
                    txtSdt.getText(), txtEmail.getText(), txtDiaChi.getText());
            UiUtil.showInfo(this, "Đã cập nhật học viên " + ma + ".");
            timKiem();
        });
    }

    private void xoa() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một học viên trong danh sách để xóa.");
            return;
        }
        if (!UiUtil.confirm(this, "Xóa học viên " + ma + "?")) {
            return;
        }
        UiUtil.run(this, () -> {
            service.xoa(ma);
            UiUtil.showInfo(this, "Đã xóa học viên " + ma + ".");
            lamMoiForm();
            timKiem();
        });
    }

    private void lamMoiForm() {
        tblHV.clearSelection();
        txtMa.setText("");
        txtTen.setText("");
        txtNgaySinh.setText("");
        txtSdt.setText("");
        txtEmail.setText("");
        txtDiaChi.setText("");
        modelLichSu.setRows(List.of());
    }
}
