package ttnn.nguoid.ui;

import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.common.VaiTro;
import ttnn.nguoid.entity.GiangVien;
import ttnn.nguoid.service.GiangVienService;
import ttnn.nguoid.service.Muc;

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

/**
 * Man hinh QUAN LY GIANG VIEN (Nguoi D).
 * QuanTri: them / sua / cho nghi + ban giao lop. GiaoVu, GiangVien: chi xem
 * (bang tai giang day chi hien cho QuanTri, GiaoVu vi GiangVien khong duoc cap SELECT tren V_GIANGVIEN_TaiTrong).
 *  - Bang ho so       : entity GiangVien.
 *  - Bang tai giang day: VIEW V_GIANGVIEN_TaiTrong.
 *  - Nut cho nghi     : SP_BanGiaoLop_KhiGVNghi (nguoi nhan chon tu FN_DSGiangVien_TheoNN).
 */
public class GiangVienPanel extends JPanel {
    private final GiangVienService service = new GiangVienService();
    private final boolean duocSua = JpaUtil.coVaiTro(VaiTro.QUAN_TRI);
    private final boolean xemTaiTrong = JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.GIAO_VU);

    private final SimpleTableModel model = new SimpleTableModel(
            "Mã GV", "Họ tên", "Ngôn ngữ", "SĐT", "Email", "Trạng thái");
    private final JTable table = UiUtil.newTable(model);
    private final SimpleTableModel modelTai = new SimpleTableModel(
            "Mã GV", "Họ tên", "Ngôn ngữ", "Trạng thái", "Số lớp chính", "Lớp đang phụ trách",
            "Buổi đã dạy", "Buổi dạy thay");
    private final JTable tableTai = UiUtil.newTable(modelTai);

    private final JTextField txtMa = new JTextField(6);
    private final JTextField txtHoTen = new JTextField(20);
    private final JComboBox<Muc> cboNN = new JComboBox<>();
    private final JTextField txtSdt = new JTextField(12);
    private final JTextField txtEmail = new JTextField(20);
    private final JComboBox<String> cboTrangThai = new JComboBox<>(new String[] {
            GiangVienService.DANG_CONG_TAC, GiangVienService.TAM_NGHI, GiangVienService.DA_NGHI_VIEC});
    private final JButton btnThem = new JButton("Thêm mới");
    private final JButton btnLuu = new JButton("Lưu thay đổi");
    private final JButton btnNghi = new JButton("Cho nghỉ và bàn giao lớp...");

    public GiangVienPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        txtMa.setEditable(false);
        txtMa.setToolTipText("Mã tự sinh khi thêm mới");

        JPanel giua = new JPanel(new GridLayout(xemTaiTrong ? 2 : 1, 1, 6, 6));
        JPanel pHoSo = new JPanel(new BorderLayout());
        pHoSo.setBorder(BorderFactory.createTitledBorder("Hồ sơ giảng viên"));
        pHoSo.add(UiUtil.scroll(table, 180), BorderLayout.CENTER);
        giua.add(pHoSo);
        if (xemTaiTrong) {
            JPanel pTai = new JPanel(new BorderLayout());
            pTai.setBorder(BorderFactory.createTitledBorder("Tải giảng dạy (V_GIANGVIEN_TaiTrong)"));
            pTai.add(UiUtil.scroll(tableTai, 160), BorderLayout.CENTER);
            giua.add(pTai);
        }
        add(giua, BorderLayout.CENTER);
        add(taoForm(), BorderLayout.SOUTH);

        table.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                napForm();
            }
        });
        btnThem.addActionListener(e -> UiUtil.run(this, this::them));
        btnLuu.addActionListener(e -> UiUtil.run(this, this::luu));
        btnNghi.addActionListener(e -> UiUtil.run(this, this::choNghi));
        capNhatNut();
        lamMoi();
    }

    private JPanel taoForm() {
        JPanel form = UiUtil.formPanel("Thông tin giảng viên" + (duocSua ? "" : " (chỉ xem)"));
        UiUtil.addField(form, 0, 0, "Mã GV:", txtMa);
        UiUtil.addField(form, 0, 2, "Họ tên:", txtHoTen);
        UiUtil.addField(form, 0, 4, "Ngôn ngữ:", cboNN);
        UiUtil.addField(form, 1, 0, "SĐT:", txtSdt);
        UiUtil.addField(form, 1, 2, "Email:", txtEmail);
        UiUtil.addField(form, 1, 4, "Trạng thái:", cboTrangThai);
        JPanel nut = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        JButton btnMoi = new JButton("Nhập mới");
        btnMoi.addActionListener(e -> xoaForm());
        JButton btnLam = new JButton("Làm mới");
        btnLam.addActionListener(e -> UiUtil.run(this, this::lamMoi));
        nut.add(btnMoi);
        nut.add(btnThem);
        nut.add(btnLuu);
        nut.add(btnNghi);
        nut.add(btnLam);
        JPanel p = new JPanel(new BorderLayout());
        p.add(form, BorderLayout.CENTER);
        p.add(nut, BorderLayout.SOUTH);
        return p;
    }

    private void capNhatNut() {
        boolean chon = !txtMa.getText().isBlank();
        btnThem.setEnabled(duocSua && !chon);
        btnLuu.setEnabled(duocSua && chon);
        btnNghi.setEnabled(duocSua && chon);
        boolean sua = duocSua;
        txtHoTen.setEditable(sua);
        txtSdt.setEditable(sua);
        txtEmail.setEditable(sua);
        cboNN.setEnabled(sua);
        cboTrangThai.setEnabled(sua && chon);
    }

    /** Duoc goi lai khi tab hien ra de du lieu luon moi. */
    public void lamMoi() {
        UiUtil.run(this, () -> {
            String giu = txtMa.getText();
            Object nn = cboNN.getSelectedItem();
            cboNN.removeAllItems();
            service.dsNgonNgu().forEach(cboNN::addItem);
            if (nn != null) {
                cboNN.setSelectedItem(nn);
            }
            model.setRows(service.danhSach());
            if (xemTaiTrong) {
                modelTai.setRows(service.taiTrong());
            }
            chonDong(giu);
        });
    }

    private void chonDong(String ma) {
        if (ma == null || ma.isBlank()) {
            xoaForm();
            return;
        }
        for (int i = 0; i < model.getRowCount(); i++) {
            if (ma.equals(model.raw(i, 0))) {
                table.setRowSelectionInterval(i, i);
                return;
            }
        }
        xoaForm();
    }

    private void napForm() {
        int r = table.getSelectedRow();
        if (r < 0) {
            return;
        }
        int m = table.convertRowIndexToModel(r);
        txtMa.setText(Convert.str(model.raw(m, 0)));
        txtHoTen.setText(Convert.str(model.raw(m, 1)));
        String nn = Convert.str(model.raw(m, 2));
        for (int i = 0; i < cboNN.getItemCount(); i++) {
            if (cboNN.getItemAt(i).ma().equals(nn)) {
                cboNN.setSelectedIndex(i);
            }
        }
        txtSdt.setText(Convert.str(model.raw(m, 3)));
        txtEmail.setText(Convert.str(model.raw(m, 4)));
        cboTrangThai.setSelectedItem(Convert.str(model.raw(m, 5)));
        capNhatNut();
    }

    private void xoaForm() {
        table.clearSelection();
        txtMa.setText("");
        txtHoTen.setText("");
        txtSdt.setText("");
        txtEmail.setText("");
        cboTrangThai.setSelectedItem(GiangVienService.DANG_CONG_TAC);
        if (cboNN.getItemCount() > 0) {
            cboNN.setSelectedIndex(0);
        }
        capNhatNut();
    }

    private String maNN() {
        Object o = cboNN.getSelectedItem();
        return o instanceof Muc m ? m.ma() : null;
    }

    private void them() {
        String ma = service.them(txtHoTen.getText(), maNN(), txtSdt.getText(), txtEmail.getText());
        UiUtil.showInfo(this, "Đã thêm giảng viên " + ma + ".");
        txtMa.setText(ma);
        lamMoi();
    }

    private void luu() {
        service.capNhat(txtMa.getText(), txtHoTen.getText(), maNN(), txtSdt.getText(), txtEmail.getText(),
                (String) cboTrangThai.getSelectedItem());
        UiUtil.showInfo(this, "Đã lưu thay đổi.");
        lamMoi();
    }

    /** Hop thoai chon nguoi nhan ban giao roi goi SP_BanGiaoLop_KhiGVNghi. */
    private void choNghi() {
        String maNghi = txtMa.getText();
        GiangVien gv = service.tim(maNghi);
        if (gv == null) {
            UiUtil.showInfo(this, "Giảng viên không còn tồn tại.");
            lamMoi();
            return;
        }
        JComboBox<Object> cboNhan = new JComboBox<>();
        cboNhan.addItem("(Không bàn giao - chỉ khi không còn lớp đang hoạt động)");
        for (Object[] r : service.nguoiNhan(gv.getMaNN())) {
            if (!maNghi.equals(Convert.str(r[0]))) {
                cboNhan.addItem(new Muc(Convert.str(r[0]), Convert.str(r[1]) + " (" + r[4] + " lớp)"));
            }
        }
        JComboBox<String> cboTT = new JComboBox<>(new String[] {
                GiangVienService.DA_NGHI_VIEC, GiangVienService.TAM_NGHI});
        JPanel p = new JPanel(new GridLayout(0, 2, 6, 6));
        p.add(new JLabel("Giảng viên nghỉ:"));
        p.add(new JLabel(gv.getMaGV() + " - " + gv.getHoTen()));
        p.add(new JLabel("Người nhận bàn giao:"));
        p.add(cboNhan);
        p.add(new JLabel("Trạng thái mới:"));
        p.add(cboTT);
        int kq = JOptionPane.showConfirmDialog(this, p, "Cho nghỉ và bàn giao lớp",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
        if (kq != JOptionPane.OK_OPTION) {
            return;
        }
        String maMoi = cboNhan.getSelectedItem() instanceof Muc m ? m.ma() : null;
        int soLop = service.banGiaoVaChoNghi(maNghi, maMoi, (String) cboTT.getSelectedItem());
        UiUtil.showInfo(this, "Đã bàn giao " + soLop + " lớp và chuyển " + maNghi + " sang \""
                + cboTT.getSelectedItem() + "\".");
        lamMoi();
    }
}
