package ttnn.kien.ui;

import ttnn.common.JpaUtil;
import ttnn.common.SimpleTableModel;
import ttnn.common.UiUtil;
import ttnn.common.VaiTro;
import ttnn.kien.service.NgonNguService;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JTextField;
import java.awt.BorderLayout;
import java.awt.GridLayout;

/**
 * Man hinh QUAN LY NGON NGU (Kien).
 * Goi: VIEW V_THONGKE_NgonNgu (danh sach kem so khoa / lop / giang vien), CRUD entity NgonNgu.
 * Chi role_QuanTri thay form Them / Sua ten / Xoa; vai tro khac chi xem.
 */
public class NgonNguPanel extends JPanel {
    private final NgonNguService service = new NgonNguService();
    private final boolean duocSua = JpaUtil.coVaiTro(VaiTro.QUAN_TRI);

    private final SimpleTableModel modelNN = new SimpleTableModel(
            "Mã NN", "Tên ngôn ngữ", "Số khóa học", "Khóa đang giảng dạy", "Số lớp", "Số giảng viên", "GV đang công tác");
    private final JTable tblNN = UiUtil.newTable(modelNN);

    private final JTextField txtMa = new JTextField(5);
    private final JTextField txtTen = new JTextField(20);

    public NgonNguPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        JPanel ds = new JPanel(new BorderLayout());
        ds.setBorder(BorderFactory.createTitledBorder("Danh sách ngôn ngữ (V_THONGKE_NgonNgu)"));
        ds.add(UiUtil.scroll(tblNN, 300), BorderLayout.CENTER);
        add(ds, BorderLayout.CENTER);

        if (duocSua) {
            txtMa.setToolTipText("Tối đa 3 ký tự, ví dụ ANH. Chỉ nhập khi thêm mới; mã không sửa được.");
            JPanel form = UiUtil.formPanel("Thông tin ngôn ngữ");
            UiUtil.addField(form, 0, 0, "Mã ngôn ngữ:", txtMa);
            UiUtil.addField(form, 0, 2, "Tên ngôn ngữ:", txtTen);
            JPanel nut = new JPanel(new GridLayout(1, 0, 6, 0));
            JButton btnThem = new JButton("Thêm mới");
            JButton btnSua = new JButton("Cập nhật tên");
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

            btnThem.addActionListener(e -> them());
            btnSua.addActionListener(e -> suaTen());
            btnXoa.addActionListener(e -> xoa());
            btnMoi.addActionListener(e -> lamMoiForm());
            tblNN.getSelectionModel().addListSelectionListener(e -> {
                if (!e.getValueIsAdjusting()) {
                    chonDong();
                }
            });
        } else {
            add(new JLabel("  Chế độ chỉ xem (vai trò " + JpaUtil.getCurrentRole() + ")."), BorderLayout.SOUTH);
        }

        UiUtil.run(this, this::taiDanhSach);
    }

    /** Duoc goi lai khi tab nay hien ra de du lieu luon moi. */
    public void lamMoi() {
        UiUtil.run(this, this::taiDanhSach);
    }

    private String maDangChon() {
        int r = tblNN.getSelectedRow();
        return r < 0 ? null : modelNN.raw(tblNN.convertRowIndexToModel(r), 0).toString();
    }

    private void taiDanhSach() {
        String giuMa = maDangChon();
        modelNN.setRows(service.danhSach());
        if (giuMa != null) {
            chonTheoMa(giuMa);
        }
    }

    private void chonTheoMa(String ma) {
        for (int i = 0; i < modelNN.getRowCount(); i++) {
            if (ma.equalsIgnoreCase(String.valueOf(modelNN.raw(i, 0)))) {
                int v = tblNN.convertRowIndexToView(i);
                tblNN.setRowSelectionInterval(v, v);
                return;
            }
        }
    }

    private void chonDong() {
        String ma = maDangChon();
        if (ma == null) {
            return;
        }
        int r = tblNN.convertRowIndexToModel(tblNN.getSelectedRow());
        txtMa.setText(ma);
        txtMa.setEditable(false);
        txtTen.setText(String.valueOf(modelNN.raw(r, 1)));
    }

    private void them() {
        if (maDangChon() != null) {
            UiUtil.showInfo(this, "Đang chọn một ngôn ngữ có sẵn. Bấm \"Làm mới form\" rồi nhập ngôn ngữ mới.");
            return;
        }
        UiUtil.run(this, () -> {
            String ma = NgonNguService.chuanHoaMa(txtMa.getText());
            service.them(ma, txtTen.getText());
            UiUtil.showInfo(this, "Đã thêm ngôn ngữ " + ma + ".");
            lamMoiForm();
            taiDanhSach();
            chonTheoMa(ma);
        });
    }

    private void suaTen() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một ngôn ngữ trong danh sách để cập nhật tên.");
            return;
        }
        UiUtil.run(this, () -> {
            service.suaTen(ma, txtTen.getText());
            UiUtil.showInfo(this, "Đã cập nhật tên ngôn ngữ " + ma + ".");
            taiDanhSach();
        });
    }

    private void xoa() {
        String ma = maDangChon();
        if (ma == null) {
            UiUtil.showInfo(this, "Hãy chọn một ngôn ngữ trong danh sách để xóa.");
            return;
        }
        if (!UiUtil.confirm(this, "Xóa ngôn ngữ " + ma + "?")) {
            return;
        }
        UiUtil.run(this, () -> {
            service.xoa(ma);
            UiUtil.showInfo(this, "Đã xóa ngôn ngữ " + ma + ".");
            lamMoiForm();
            taiDanhSach();
        });
    }

    private void lamMoiForm() {
        tblNN.clearSelection();
        txtMa.setText("");
        txtMa.setEditable(true);
        txtTen.setText("");
    }
}
