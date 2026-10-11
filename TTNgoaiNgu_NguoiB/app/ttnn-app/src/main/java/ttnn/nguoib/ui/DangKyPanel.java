package ttnn.nguoib.ui;

import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.nguoib.service.DangKyService;
import ttnn.nguoib.service.DangKyService.KetQuaDangKy;
import ttnn.nguoib.service.DangKyService.LopMo;
import ttnn.nguoib.service.HocVienService;
import ttnn.nguoib.service.HocVienService.HocVienRow;

import javax.swing.BorderFactory;
import javax.swing.DefaultComboBoxModel;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Man hinh DANG KY HOC.
 * Goi: SP_TimKiemHocVien (chon hoc vien), SP_DangKy_VaTaoHoaDon (dang ky + hoa don),
 *      SP_HuyDangKy (huy), FN_DSDangKy_HocVien (lich su dang ky), cap nhat diem (entity DangKy).
 */
public class DangKyPanel extends JPanel {
    private final HocVienService hocVienService = new HocVienService();
    private final DangKyService service = new DangKyService();

    private final JTextField txtTim = new JTextField(16);
    private final SimpleTableModel modelHV = new SimpleTableModel("Mã HV", "Họ tên", "SĐT", "Email");
    private final JTable tblHV = UiUtil.newTable(modelHV);

    private final JComboBox<LopMo> cboLop = new JComboBox<>();
    private final JLabel lblHocPhi = new JLabel(" ");
    private final JTextField txtNgay = new JTextField(10);
    private final JTextField txtThuNgay = new JTextField(12);

    private final SimpleTableModel modelDK = new SimpleTableModel(
            "Mã ĐK", "Lớp", "Khóa học", "Trạng thái lớp", "Ngày ĐK", "Điểm",
            "Mã HD", "Cần thu", "Đã thu", "Còn nợ", "Thanh toán");
    private final JTable tblDK = UiUtil.newTable(modelDK);
    private final JTextField txtDiem = new JTextField(6);

    public DangKyPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        txtNgay.setText(UiUtil.formatDate(LocalDate.now()));
        txtThuNgay.setToolTipText("Để trống hoặc 0 nếu chưa thu tiền ngay");

        // --- trai: tim va chon hoc vien ---
        JPanel trai = new JPanel(new BorderLayout(4, 4));
        trai.setBorder(BorderFactory.createTitledBorder("1. Chọn học viên"));
        JPanel tim = new JPanel(new FlowLayout(FlowLayout.LEFT, 4, 2));
        tim.add(new JLabel("Tên / SĐT / email:"));
        tim.add(txtTim);
        JButton btnTim = new JButton("Tìm");
        tim.add(btnTim);
        trai.add(tim, BorderLayout.NORTH);
        trai.add(UiUtil.scroll(tblHV, 200), BorderLayout.CENTER);

        // --- phai: chon lop va dang ky ---
        JPanel phai = UiUtil.formPanel("2. Chọn lớp và đăng ký");
        UiUtil.addField(phai, 0, 0, "Lớp:", cboLop);
        UiUtil.addField(phai, 1, 0, "Học phí:", lblHocPhi);
        UiUtil.addField(phai, 2, 0, "Ngày đăng ký:", txtNgay);
        UiUtil.addField(phai, 3, 0, "Thu ngay (đ):", txtThuNgay);
        JButton btnDangKy = new JButton("Đăng ký và tạo hóa đơn");
        JButton btnTaiLaiLop = new JButton("Tải lại danh sách lớp");
        JPanel nutPhai = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        nutPhai.add(btnDangKy);
        nutPhai.add(btnTaiLaiLop);
        JPanel phaiBox = new JPanel(new BorderLayout());
        phaiBox.add(phai, BorderLayout.CENTER);
        phaiBox.add(nutPhai, BorderLayout.SOUTH);

        JSplitPane tren = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, trai, phaiBox);
        tren.setResizeWeight(0.5);

        // --- duoi: lich su dang ky ---
        JPanel duoi = new JPanel(new BorderLayout(4, 4));
        duoi.setBorder(BorderFactory.createTitledBorder("3. Lịch sử đăng ký của học viên đang chọn (FN_DSDangKy_HocVien)"));
        duoi.add(UiUtil.scroll(tblDK, 150), BorderLayout.CENTER);
        JPanel nutDuoi = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        JButton btnHuy = new JButton("Hủy đăng ký đang chọn");
        JButton btnDiem = new JButton("Lưu điểm cuối kỳ");
        nutDuoi.add(btnHuy);
        nutDuoi.add(new JLabel("Điểm (0-10, trống = xóa điểm):"));
        nutDuoi.add(txtDiem);
        nutDuoi.add(btnDiem);
        duoi.add(nutDuoi, BorderLayout.SOUTH);

        JSplitPane all = new JSplitPane(JSplitPane.VERTICAL_SPLIT, tren, duoi);
        all.setResizeWeight(0.5);
        add(all, BorderLayout.CENTER);

        btnTim.addActionListener(e -> UiUtil.run(this, this::timHocVien));
        txtTim.addActionListener(e -> UiUtil.run(this, this::timHocVien));
        btnTaiLaiLop.addActionListener(e -> UiUtil.run(this, this::taiLop));
        cboLop.addActionListener(e -> hienHocPhi());
        tblHV.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                UiUtil.run(this, this::taiLichSu);
            }
        });
        tblDK.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting() && tblDK.getSelectedRow() >= 0) {
                Object diem = modelDK.raw(tblDK.convertRowIndexToModel(tblDK.getSelectedRow()), 5);
                txtDiem.setText(diem == null ? "" : UiUtil.formatNumber((BigDecimal) diem));
            }
        });
        btnDangKy.addActionListener(e -> UiUtil.run(this, this::dangKy));
        btnHuy.addActionListener(e -> UiUtil.run(this, this::huy));
        btnDiem.addActionListener(e -> UiUtil.run(this, this::luuDiem));

        UiUtil.run(this, () -> {
            timHocVien();
            taiLop();
        });
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            timHocVien();
            taiLop();
        });
    }

    private String maHocVienDangChon() {
        int r = tblHV.getSelectedRow();
        return r < 0 ? null : modelHV.raw(tblHV.convertRowIndexToModel(r), 0).toString();
    }

    private void timHocVien() {
        List<HocVienRow> ds;
        String t = txtTim.getText().trim();
        if (t.isEmpty()) {
            ds = hocVienService.timKiem(null, null, null);
        } else {
            // gop ket qua tim theo ten, SDT, email (loai trung theo ma)
            java.util.Map<String, HocVienRow> gop = new java.util.LinkedHashMap<>();
            for (HocVienRow r : hocVienService.timKiem(t, null, null)) {
                gop.putIfAbsent(r.maHV(), r);
            }
            for (HocVienRow r : hocVienService.timKiem(null, t, null)) {
                gop.putIfAbsent(r.maHV(), r);
            }
            for (HocVienRow r : hocVienService.timKiem(null, null, t)) {
                gop.putIfAbsent(r.maHV(), r);
            }
            ds = new java.util.ArrayList<>(gop.values());
        }
        modelHV.setRows(ds.stream().map(r -> new Object[] {r.maHV(), r.hoTen(), r.sdt(), r.email()}).toList());
        modelDK.setRows(List.of());
    }

    private void taiLop() {
        Object giu = cboLop.getSelectedItem();
        List<LopMo> ds = service.lopDangMo();
        cboLop.setModel(new DefaultComboBoxModel<>(ds.toArray(new LopMo[0])));
        if (giu instanceof LopMo g) {
            for (LopMo l : ds) {
                if (l.maLop().equals(g.maLop())) {
                    cboLop.setSelectedItem(l);
                    break;
                }
            }
        }
        hienHocPhi();
    }

    private void hienHocPhi() {
        Object o = cboLop.getSelectedItem();
        if (o instanceof LopMo l) {
            lblHocPhi.setText(UiUtil.formatMoney(l.hocPhi()) + "   (còn " + l.conCho() + " chỗ)");
        } else {
            lblHocPhi.setText(" ");
        }
    }

    private void taiLichSu() {
        String ma = maHocVienDangChon();
        modelDK.setRows(ma == null ? List.of() : service.lichSuHocVien(ma));
        txtDiem.setText("");
    }

    private void dangKy() {
        String ma = maHocVienDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một học viên ở bảng bên trái.");
            return;
        }
        if (!(cboLop.getSelectedItem() instanceof LopMo lop)) {
            UiUtil.showInfo(this, "Hãy chọn lớp cần đăng ký.");
            return;
        }
        LocalDate ngay = UiUtil.parseDate(txtNgay.getText(), "Ngày đăng ký");
        BigDecimal thu = UiUtil.parseMoney(txtThuNgay.getText(), "Số tiền thu ngay");
        KetQuaDangKy kq = service.dangKy(ma, lop.maLop(), ngay, thu);
        UiUtil.showInfo(this, "Đăng ký thành công.\nMã đăng ký: " + kq.maDK() + "\nMã hóa đơn: " + kq.maHD());
        txtThuNgay.setText("");
        taiLop();
        taiLichSu();
    }

    private void huy() {
        int r = tblDK.getSelectedRow();
        if (r < 0) {
            UiUtil.showInfo(this, "Hãy chọn một dòng đăng ký ở bảng lịch sử.");
            return;
        }
        String maDK = modelDK.raw(tblDK.convertRowIndexToModel(r), 0).toString();
        if (!UiUtil.confirm(this, "Hủy đăng ký " + maDK + " và hóa đơn của nó?")) {
            return;
        }
        service.huyDangKy(maDK);
        UiUtil.showInfo(this, "Đã hủy đăng ký " + maDK + ".");
        taiLop();
        taiLichSu();
    }

    private void luuDiem() {
        int r = tblDK.getSelectedRow();
        if (r < 0) {
            UiUtil.showInfo(this, "Hãy chọn một dòng đăng ký ở bảng lịch sử.");
            return;
        }
        String maDK = modelDK.raw(tblDK.convertRowIndexToModel(r), 0).toString();
        String s = txtDiem.getText().trim().replace(',', '.');
        BigDecimal diem;
        try {
            diem = s.isEmpty() ? null : new BigDecimal(s);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Điểm không hợp lệ (nhập số từ 0 đến 10).");
        }
        service.capNhatDiem(maDK, diem);
        UiUtil.showInfo(this, "Đã lưu điểm cho đăng ký " + maDK + ".");
        taiLichSu();
    }
}
