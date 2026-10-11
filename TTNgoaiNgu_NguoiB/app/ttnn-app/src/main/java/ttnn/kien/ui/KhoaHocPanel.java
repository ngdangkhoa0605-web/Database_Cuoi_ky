package ttnn.kien.ui;

import ttnn.common.JpaUtil;
import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.common.VaiTro;
import ttnn.kien.service.KhoaHocService;
import ttnn.kien.service.KhoaHocService.KetQuaThem;
import ttnn.kien.service.KhoaHocService.KhoaHocRow;
import ttnn.kien.service.NgonNguService;
import ttnn.kien.service.NgonNguService.NgonNguMuc;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridLayout;
import java.math.BigDecimal;
import java.util.List;

/**
 * Man hinh QUAN LY KHOA HOC (Kien).
 * Goi: SP_TimKiemKhoaHoc (tim kiem), SP_ThemKhoaHoc_VaNgonNgu (them - giao dich),
 *      entity KhoaHoc (sua / xoa; trigger TRG_KHOAHOC_NgungTuyenSinh, TRG_KHOAHOC_KhoaNgonNgu),
 *      SP_CapNhatHocPhiKhoa (doi hoc phi - giao dich, cap nhat ca hoa don chua thanh toan).
 * Chi role_QuanTri thay form va cac nut ghi; GiaoVu / KeToan chi tim kiem va xem.
 */
public class KhoaHocPanel extends JPanel {
    private static final String TAT_CA = "Tất cả";
    /** Muc dac biet trong o chon ngon ngu cua form: them khoa hoc kem ngon ngu moi. */
    private static final NgonNguMuc NGON_NGU_MOI = new NgonNguMuc(null, "+ Ngôn ngữ mới...");

    private final KhoaHocService service = new KhoaHocService();
    private final NgonNguService ngonNgu = new NgonNguService();
    private final boolean duocSua = JpaUtil.coVaiTro(VaiTro.QUAN_TRI);

    // ----- tim kiem -----
    private final JTextField txtTimTen = new JTextField(14);
    private final JComboBox<NgonNguMuc> cboTimNN = new JComboBox<>();
    private final JComboBox<String> cboTimTT = new JComboBox<>();
    private final JTextField txtTimMin = new JTextField(9);
    private final JTextField txtTimMax = new JTextField(9);

    private final SimpleTableModel modelKH = new SimpleTableModel(
            "Mã KH", "Tên khóa học", "Mã NN", "Ngôn ngữ", "Trình độ", "Số buổi", "Học phí", "Trạng thái");
    private final JTable tblKH = UiUtil.newTable(modelKH);

    // ----- form (chi QuanTri) -----
    private final JTextField txtMa = new JTextField(8);
    private final JTextField txtTen = new JTextField(22);
    private final JComboBox<NgonNguMuc> cboNN = new JComboBox<>();
    private final JTextField txtMaNNMoi = new JTextField(4);
    private final JTextField txtTenNNMoi = new JTextField(14);
    private final JComboBox<String> cboTrinhDo = new JComboBox<>(KhoaHocService.TRINH_DO_GOI_Y.toArray(new String[0]));
    private final JTextField txtSoBuoi = new JTextField(5);
    private final JTextField txtHocPhi = new JTextField(10);
    private final JComboBox<String> cboTrangThai = new JComboBox<>(KhoaHocService.TRANG_THAI.toArray(new String[0]));

    public KhoaHocPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        // --- tim kiem ---
        cboTimTT.addItem(TAT_CA);
        KhoaHocService.TRANG_THAI.forEach(cboTimTT::addItem);
        txtTimMin.setToolTipText("Để trống = không giới hạn");
        txtTimMax.setToolTipText("Để trống = không giới hạn");
        JPanel tim = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        tim.setBorder(BorderFactory.createTitledBorder("Tìm kiếm (SP_TimKiemKhoaHoc)"));
        tim.add(new JLabel("Tên khóa:"));
        tim.add(txtTimTen);
        tim.add(new JLabel("Ngôn ngữ:"));
        tim.add(cboTimNN);
        tim.add(new JLabel("Trạng thái:"));
        tim.add(cboTimTT);
        tim.add(new JLabel("Học phí từ:"));
        tim.add(txtTimMin);
        tim.add(new JLabel("đến:"));
        tim.add(txtTimMax);
        JButton btnTim = new JButton("Tìm");
        JButton btnTatCa = new JButton("Hiện tất cả");
        tim.add(btnTim);
        tim.add(btnTatCa);
        add(tim, BorderLayout.NORTH);

        add(UiUtil.scroll(tblKH, 260), BorderLayout.CENTER);

        btnTim.addActionListener(e -> UiUtil.run(this, this::timKiem));
        btnTatCa.addActionListener(e -> {
            txtTimTen.setText("");
            cboTimNN.setSelectedIndex(0);
            cboTimTT.setSelectedIndex(0);
            txtTimMin.setText("");
            txtTimMax.setText("");
            UiUtil.run(this, this::timKiem);
        });
        txtTimTen.addActionListener(e -> UiUtil.run(this, this::timKiem));

        // --- form + nut (chi quan tri) ---
        if (duocSua) {
            add(taoForm(), BorderLayout.SOUTH);
        } else {
            add(new JLabel("  Chế độ chỉ xem (vai trò " + JpaUtil.getCurrentRole()
                    + "): chỉ tìm kiếm và xem danh sách khóa học."), BorderLayout.SOUTH);
        }

        UiUtil.run(this, () -> {
            napNgonNgu();
            timKiem();
        });
    }

    private JPanel taoForm() {
        txtMa.setEditable(false);
        txtMa.setToolTipText("Mã tự sinh khi thêm mới (KH0001...)");
        cboTrinhDo.setEditable(true);
        txtMaNNMoi.setToolTipText("Mã ngôn ngữ mới, tối đa 3 ký tự (ví dụ PHA)");
        txtTenNNMoi.setToolTipText("Tên ngôn ngữ mới (ví dụ Tiếng Pháp)");
        txtHocPhi.setToolTipText("Chỉ nhập khi thêm mới. Đổi học phí khóa có sẵn: nút \"Đổi học phí\".");

        JPanel nnMoi = new JPanel(new FlowLayout(FlowLayout.LEFT, 4, 0));
        nnMoi.add(new JLabel("Mã:"));
        nnMoi.add(txtMaNNMoi);
        nnMoi.add(new JLabel("Tên:"));
        nnMoi.add(txtTenNNMoi);

        JPanel form = UiUtil.formPanel("Thông tin khóa học");
        UiUtil.addField(form, 0, 0, "Mã KH:", txtMa);
        UiUtil.addField(form, 0, 2, "Tên khóa học:", txtTen);
        UiUtil.addField(form, 1, 0, "Ngôn ngữ:", cboNN);
        UiUtil.addField(form, 1, 2, "Ngôn ngữ mới:", nnMoi);
        UiUtil.addField(form, 2, 0, "Trình độ:", cboTrinhDo);
        UiUtil.addField(form, 2, 2, "Số buổi:", txtSoBuoi);
        UiUtil.addField(form, 3, 0, "Học phí:", txtHocPhi);
        UiUtil.addField(form, 3, 2, "Trạng thái:", cboTrangThai);

        JPanel nut = new JPanel(new GridLayout(1, 0, 6, 0));
        JButton btnThem = new JButton("Thêm mới");
        JButton btnSua = new JButton("Cập nhật");
        JButton btnDoiHP = new JButton("Đổi học phí");
        JButton btnXoa = new JButton("Xóa");
        JButton btnMoi = new JButton("Làm mới form");
        btnThem.setToolTipText("SP_ThemKhoaHoc_VaNgonNgu");
        btnDoiHP.setToolTipText("SP_CapNhatHocPhiKhoa - cập nhật cả các hóa đơn chưa thanh toán");
        nut.add(btnThem);
        nut.add(btnSua);
        nut.add(btnDoiHP);
        nut.add(btnXoa);
        nut.add(btnMoi);

        btnThem.addActionListener(e -> them());
        btnSua.addActionListener(e -> sua());
        btnDoiHP.addActionListener(e -> doiHocPhi());
        btnXoa.addActionListener(e -> xoa());
        btnMoi.addActionListener(e -> lamMoiForm());
        cboNN.addActionListener(e -> capNhatTrangThaiForm());
        tblKH.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                chonDong();
            }
        });

        JPanel south = new JPanel(new BorderLayout(4, 4));
        south.add(form, BorderLayout.CENTER);
        south.add(nut, BorderLayout.SOUTH);
        lamMoiForm();
        return south;
    }

    /** Duoc goi lai khi tab nay hien ra de du lieu luon moi. */
    public void lamMoi() {
        UiUtil.run(this, () -> {
            napNgonNgu();
            timKiem();
        });
    }

    /** Nap lai danh muc ngon ngu vao o tim kiem va o cua form, giu lua chon hien tai. */
    private void napNgonNgu() {
        List<NgonNguMuc> ds = ngonNgu.danhMuc();
        String giuTim = maNNChon(cboTimNN);
        cboTimNN.removeAllItems();
        cboTimNN.addItem(NgonNguMuc.TAT_CA);
        ds.forEach(cboTimNN::addItem);
        chonMaNN(cboTimNN, giuTim);
        if (duocSua) {
            String giuForm = maNNChon(cboNN);
            boolean dangMoi = cboNN.getSelectedItem() == NGON_NGU_MOI;
            cboNN.removeAllItems();
            ds.forEach(cboNN::addItem);
            cboNN.addItem(NGON_NGU_MOI);
            if (dangMoi) {
                cboNN.setSelectedItem(NGON_NGU_MOI);
            } else {
                chonMaNN(cboNN, giuForm);
            }
        }
    }

    private static String maNNChon(JComboBox<NgonNguMuc> cbo) {
        Object o = cbo.getSelectedItem();
        return o instanceof NgonNguMuc m ? m.ma() : null;
    }

    private static void chonMaNN(JComboBox<NgonNguMuc> cbo, String ma) {
        for (int i = 0; i < cbo.getItemCount(); i++) {
            String m = cbo.getItemAt(i).ma();
            if (ma != null && ma.equalsIgnoreCase(m)) {
                cbo.setSelectedIndex(i);
                return;
            }
        }
        if (cbo.getItemCount() > 0) {
            cbo.setSelectedIndex(0);
        }
    }

    private String maDangChon() {
        int r = tblKH.getSelectedRow();
        return r < 0 ? null : modelKH.raw(tblKH.convertRowIndexToModel(r), 0).toString();
    }

    private void timKiem() {
        String giuMa = maDangChon();
        String tt = cboTimTT.getSelectedIndex() <= 0 ? null : (String) cboTimTT.getSelectedItem();
        List<KhoaHocRow> ds = service.timKiem(txtTimTen.getText(), maNNChon(cboTimNN), tt,
                UiUtil.parseMoney(txtTimMin.getText(), "Học phí từ"),
                UiUtil.parseMoney(txtTimMax.getText(), "Học phí đến"));
        modelKH.setRows(ds.stream().map(KhoaHocRow::toRow).toList());
        if (giuMa != null) {
            chonTheoMa(giuMa);
        }
    }

    private void chonTheoMa(String ma) {
        for (int i = 0; i < modelKH.getRowCount(); i++) {
            if (ma.equals(modelKH.raw(i, 0))) {
                int v = tblKH.convertRowIndexToView(i);
                tblKH.setRowSelectionInterval(v, v);
                return;
            }
        }
    }

    private void chonDong() {
        String ma = maDangChon();
        if (ma == null) {
            return;
        }
        int r = tblKH.convertRowIndexToModel(tblKH.getSelectedRow());
        txtMa.setText(ma);
        txtTen.setText(String.valueOf(modelKH.raw(r, 1)));
        chonMaNN(cboNN, String.valueOf(modelKH.raw(r, 2)));
        cboTrinhDo.setSelectedItem(String.valueOf(modelKH.raw(r, 4)));
        txtSoBuoi.setText(String.valueOf(modelKH.raw(r, 5)));
        Object hp = modelKH.raw(r, 6);
        txtHocPhi.setText(hp instanceof BigDecimal b ? UiUtil.formatNumber(b) : "");
        cboTrangThai.setSelectedItem(String.valueOf(modelKH.raw(r, 7)));
        capNhatTrangThaiForm();
    }

    /**
     * Che do THEM (chua chon dong): nhap duoc hoc phi, trang thai mac dinh 'Dang giang day', duoc chon ngon ngu moi.
     * Che do SUA (dang chon dong): hoc phi chi doi bang nut "Doi hoc phi"; duoc sua trang thai.
     */
    private void capNhatTrangThaiForm() {
        boolean dangSua = maDangChon() != null;
        boolean nnMoi = cboNN.getSelectedItem() == NGON_NGU_MOI;
        txtHocPhi.setEditable(!dangSua);
        cboTrangThai.setEnabled(dangSua);
        if (!dangSua) {
            cboTrangThai.setSelectedItem(KhoaHocService.DANG_GIANG_DAY);
        }
        txtMaNNMoi.setEnabled(nnMoi && !dangSua);
        txtTenNNMoi.setEnabled(nnMoi && !dangSua);
    }

    private Integer docSoBuoi() {
        String s = txtSoBuoi.getText().trim();
        if (s.isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(s);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Số buổi phải là số nguyên (1 - 255).");
        }
    }

    private String trinhDo() {
        Object o = cboTrinhDo.getEditor().getItem();
        return o == null ? null : o.toString();
    }

    private void them() {
        if (maDangChon() != null) {
            UiUtil.showInfo(this, "Đang chọn một khóa học có sẵn. Bấm \"Làm mới form\" rồi nhập khóa học mới.");
            return;
        }
        UiUtil.run(this, () -> {
            boolean nnMoi = cboNN.getSelectedItem() == NGON_NGU_MOI;
            String maNN = nnMoi ? txtMaNNMoi.getText() : maNNChon(cboNN);
            String tenNNMoi = nnMoi ? txtTenNNMoi.getText() : null;
            if (nnMoi && (tenNNMoi == null || tenNNMoi.isBlank())) {
                throw new IllegalArgumentException("Thêm ngôn ngữ mới: hãy nhập cả mã và tên ngôn ngữ.");
            }
            KetQuaThem kq = service.them(maNN, tenNNMoi, txtTen.getText(), trinhDo(), docSoBuoi(),
                    UiUtil.parseMoney(txtHocPhi.getText(), "Học phí"));
            UiUtil.showInfo(this, "Đã thêm khóa học " + kq.maKH()
                    + (kq.daThemNgonNgu() ? " và ngôn ngữ mới " + NgonNguService.chuanHoaMa(maNN) : "") + ".");
            lamMoiForm();
            napNgonNgu();
            timKiem();
            chonTheoMa(kq.maKH());
        });
    }

    private void sua() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một khóa học trong danh sách để cập nhật.");
            return;
        }
        UiUtil.run(this, () -> {
            if (cboNN.getSelectedItem() == NGON_NGU_MOI) {
                throw new IllegalArgumentException(
                        "Muốn chuyển khóa học sang ngôn ngữ mới, hãy thêm ngôn ngữ ở tab \"Quản lý ngôn ngữ\" trước.");
            }
            service.sua(ma, txtTen.getText(), maNNChon(cboNN), trinhDo(), docSoBuoi(),
                    (String) cboTrangThai.getSelectedItem());
            UiUtil.showInfo(this, "Đã cập nhật khóa học " + ma + ".");
            timKiem();
        });
    }

    private void doiHocPhi() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một khóa học trong danh sách để đổi học phí.");
            return;
        }
        String cu = txtHocPhi.getText();
        String nhap = (String) JOptionPane.showInputDialog(this,
                "Học phí mới cho khóa " + ma + " (hiện tại " + cu + " đ):", "Đổi học phí",
                JOptionPane.QUESTION_MESSAGE, null, null, cu);
        if (nhap == null) {
            return;
        }
        UiUtil.run(this, () -> {
            BigDecimal moi = UiUtil.parseMoney(nhap, "Học phí mới");
            if (!UiUtil.confirm(this, "Đổi học phí khóa " + ma + " từ " + cu + " đ thành " + UiUtil.formatMoney(moi)
                    + "?\nCác hóa đơn CHƯA THANH TOÁN của khóa này sẽ được cập nhật theo học phí mới.")) {
                return;
            }
            int n = service.doiHocPhi(ma, moi);
            UiUtil.showInfo(this, "Đã đổi học phí khóa " + ma + ".\nĐã cập nhật " + n + " hóa đơn chưa thanh toán.");
            timKiem();
        });
    }

    private void xoa() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một khóa học trong danh sách để xóa.");
            return;
        }
        if (!UiUtil.confirm(this, "Xóa khóa học " + ma + "?")) {
            return;
        }
        UiUtil.run(this, () -> {
            service.xoa(ma);
            UiUtil.showInfo(this, "Đã xóa khóa học " + ma + ".");
            lamMoiForm();
            timKiem();
        });
    }

    private void lamMoiForm() {
        tblKH.clearSelection();
        txtMa.setText("");
        txtTen.setText("");
        if (cboNN.getItemCount() > 0) {
            cboNN.setSelectedIndex(0);
        }
        txtMaNNMoi.setText("");
        txtTenNNMoi.setText("");
        cboTrinhDo.setSelectedIndex(0);
        txtSoBuoi.setText("");
        txtHocPhi.setText("");
        capNhatTrangThaiForm();
    }
}
