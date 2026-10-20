package ttnn.nguoid.ui;



import ttnn.common.PanelStyle;import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.common.VaiTro;
import ttnn.nguoid.service.BuoiHocService;
import ttnn.nguoid.service.Muc;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.time.LocalDate;

/**
 * Man hinh BUOI HOC (Nguoi D): xem cac buoi cua mot lop; QuanTri, GiaoVu them / doi giang vien day,
 * ngay, trang thai (Da dien ra / Hoan / Huy). GiangVien chi xem.
 */
public class BuoiHocPanel extends JPanel {
    private final BuoiHocService service = new BuoiHocService();
    private final boolean duocSua = JpaUtil.coVaiTro(VaiTro.QUAN_TRI, VaiTro.GIAO_VU);

    private final JComboBox<Muc> cboLop = new JComboBox<>();
    private final SimpleTableModel model = new SimpleTableModel(
            "Mã buổi", "Ngày học", "Mã GV", "Giảng viên đứng lớp", "Trạng thái");
    private final JTable table = UiUtil.newTable(model);

    private final JTextField txtMa = new JTextField(8);
    private final JComboBox<Muc> cboGV = new JComboBox<>();
    private final JTextField txtNgay = new JTextField(10);
    private final JComboBox<String> cboTrangThai = new JComboBox<>(new String[] {
            BuoiHocService.DA_DIEN_RA, BuoiHocService.HOAN, BuoiHocService.HUY});
    private final JButton btnThem = new JButton("Thêm buổi");
    private final JButton btnLuu = new JButton("Lưu thay đổi");

    public BuoiHocPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));
        txtMa.setEditable(false);
        txtNgay.setToolTipText("dd/MM/yyyy");

        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.add(new JLabel("Lớp:"));
        loc.add(cboLop);
        JButton btnXem = new JButton("Xem");
        btnXem.addActionListener(e -> UiUtil.run(this, this::taiBuoi));
        loc.add(btnXem);
        cboLop.addActionListener(e -> {
            if (cboLop.getSelectedItem() != null) {
                UiUtil.run(this, this::taiBuoi);
            }
        });
        add(loc, BorderLayout.NORTH);
        add(UiUtil.scroll(table, 260), BorderLayout.CENTER);

        JPanel form = UiUtil.formPanel("Buổi học" + (duocSua ? "" : " (chỉ xem)"));
        UiUtil.addField(form, 0, 0, "Mã buổi:", txtMa);
        UiUtil.addField(form, 0, 2, "Giảng viên đứng lớp:", cboGV);
        UiUtil.addField(form, 1, 0, "Ngày học:", txtNgay);
        UiUtil.addField(form, 1, 2, "Trạng thái:", cboTrangThai);
        JPanel nut = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        JButton btnMoi = new JButton("Nhập mới");
        btnMoi.addActionListener(e -> xoaForm());
        nut.add(btnMoi);
        nut.add(btnThem);
        nut.add(btnLuu);
        JPanel duoi = new JPanel(new BorderLayout());
        duoi.add(form, BorderLayout.CENTER);
        duoi.add(nut, BorderLayout.SOUTH);
        add(duoi, BorderLayout.SOUTH);

        table.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                napForm();
            }
        });
        btnThem.addActionListener(e -> UiUtil.run(this, this::them));
        btnLuu.addActionListener(e -> UiUtil.run(this, this::luu));
        capNhatNut();
        lamMoi();
    
        PanelStyle.apDung(this);
    }

    private void capNhatNut() {
        boolean chon = !txtMa.getText().isBlank();
        btnThem.setEnabled(duocSua && !chon);
        btnLuu.setEnabled(duocSua && chon);
        cboGV.setEnabled(duocSua);
        txtNgay.setEditable(duocSua);
        cboTrangThai.setEnabled(duocSua);
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            Object lop = cboLop.getSelectedItem();
            cboLop.removeAllItems();
            service.dsLop().forEach(cboLop::addItem);
            if (lop != null) {
                cboLop.setSelectedItem(lop);
            }
            cboGV.removeAllItems();
            service.dsGiangVienDangCongTac().forEach(cboGV::addItem);
            taiBuoi();
        });
    }

    private String maLop() {
        return cboLop.getSelectedItem() instanceof Muc m ? m.ma() : null;
    }

    private void taiBuoi() {
        String lop = maLop();
        model.setRows(lop == null ? java.util.List.of() : service.theoLop(lop));
        xoaForm();
    }

    private void napForm() {
        int r = table.getSelectedRow();
        if (r < 0) {
            return;
        }
        int m = table.convertRowIndexToModel(r);
        txtMa.setText(Convert.str(model.raw(m, 0)));
        txtNgay.setText(UiUtil.formatDate((LocalDate) model.raw(m, 1)));
        String gv = Convert.str(model.raw(m, 2));
        boolean thay = false;
        for (int i = 0; i < cboGV.getItemCount(); i++) {
            if (cboGV.getItemAt(i).ma().equals(gv)) {
                cboGV.setSelectedIndex(i);
                thay = true;
            }
        }
        if (!thay) {   // giang vien da nghi: van hien dung nguoi da day buoi nay
            cboGV.addItem(new Muc(gv, Convert.str(model.raw(m, 3))));
            cboGV.setSelectedIndex(cboGV.getItemCount() - 1);
        }
        cboTrangThai.setSelectedItem(Convert.str(model.raw(m, 4)));
        capNhatNut();
    }

    private void xoaForm() {
        table.clearSelection();
        txtMa.setText("");
        txtNgay.setText(UiUtil.formatDate(LocalDate.now()));
        cboTrangThai.setSelectedItem(BuoiHocService.DA_DIEN_RA);
        capNhatNut();
    }

    private String maGV() {
        return cboGV.getSelectedItem() instanceof Muc m ? m.ma() : null;
    }

    private void them() {
        String lop = maLop();
        if (lop == null) {
            throw new IllegalArgumentException("Hãy chọn lớp.");
        }
        LocalDate ngay = UiUtil.parseDate(txtNgay.getText(), "Ngày học");
        String ma = service.them(lop, maGV(), ngay, (String) cboTrangThai.getSelectedItem());
        UiUtil.showInfo(this, "Đã thêm buổi học " + ma + ".");
        taiBuoi();
    }

    private void luu() {
        LocalDate ngay = UiUtil.parseDate(txtNgay.getText(), "Ngày học");
        service.capNhat(txtMa.getText(), maGV(), ngay, (String) cboTrangThai.getSelectedItem());
        UiUtil.showInfo(this, "Đã lưu thay đổi.");
        taiBuoi();
    }
}
