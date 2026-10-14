package ttnn.nguoid.ui;

import ttnn.common.Convert;
import ttnn.common.UiUtil;
import ttnn.nguoid.service.BuoiHocService;
import ttnn.nguoid.service.DiemDanhService;
import ttnn.nguoid.service.DiemDanhService.KetQua;
import ttnn.nguoid.service.DiemDanhService.MucDiemDanh;
import ttnn.nguoid.service.Muc;

import javax.swing.BorderFactory;
import javax.swing.DefaultCellEditor;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.AbstractTableModel;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Man hinh DIEM DANH (Nguoi D). Chon lop, chon buoi DA DIEN RA, dat trang thai cho tung hoc vien roi bam Luu:
 * ca lop duoc ghi bang MOT lan goi SP_DiemDanh_CaLop (loi mot dong thi khong ghi gi ca).
 * Cot "Ty le chuyen can" lay tu V_CHUYEN_CAN (dung FN_TyLeChuyenCan). QuanTri, GiaoVu, GiangVien deu dung duoc.
 */
public class DiemDanhPanel extends JPanel {
    private final BuoiHocService buoiService = new BuoiHocService();
    private final DiemDanhService service = new DiemDanhService();

    private final JComboBox<Muc> cboLop = new JComboBox<>();
    private final JComboBox<Muc> cboBuoi = new JComboBox<>();
    private final DiemDanhModel model = new DiemDanhModel();
    private final JTable table = new JTable(model);
    private final JLabel lblTrangThai = new JLabel(" ");

    public DiemDanhPanel() {
        super(new BorderLayout(6, 6));
        setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        JPanel loc = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        loc.setBorder(BorderFactory.createTitledBorder("Chọn buổi học đã diễn ra"));
        loc.add(new JLabel("Lớp:"));
        loc.add(cboLop);
        loc.add(new JLabel("Buổi:"));
        loc.add(cboBuoi);
        JButton btnTai = new JButton("Tải danh sách");
        btnTai.addActionListener(e -> UiUtil.run(this, this::taiDanhSach));
        loc.add(btnTai);
        add(loc, BorderLayout.NORTH);

        table.setRowHeight(24);
        table.setFillsViewportHeight(true);
        table.getTableHeader().setReorderingAllowed(false);
        table.getColumnModel().getColumn(3).setCellEditor(new DefaultCellEditor(
                new JComboBox<>(DiemDanhService.TRANG_THAI)));
        add(new JScrollPane(table), BorderLayout.CENTER);

        JPanel duoi = new JPanel(new BorderLayout());
        JPanel nut = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        JButton btnCoMat = new JButton("Tất cả có mặt");
        btnCoMat.addActionListener(e -> model.datTatCa(DiemDanhService.CO_MAT));
        JButton btnLuu = new JButton("Lưu điểm danh");
        btnLuu.addActionListener(e -> UiUtil.run(this, this::luu));
        nut.add(btnCoMat);
        nut.add(btnLuu);
        duoi.add(nut, BorderLayout.WEST);
        duoi.add(lblTrangThai, BorderLayout.CENTER);
        add(duoi, BorderLayout.SOUTH);

        cboLop.addActionListener(e -> {
            if (cboLop.getSelectedItem() != null) {
                UiUtil.run(this, this::taiBuoi);
            }
        });
        lamMoi();
    }

    public void lamMoi() {
        UiUtil.run(this, () -> {
            Object lop = cboLop.getSelectedItem();
            cboLop.removeAllItems();
            buoiService.dsLop().forEach(cboLop::addItem);
            if (lop != null) {
                cboLop.setSelectedItem(lop);
            }
            taiBuoi();
        });
    }

    private void taiBuoi() {
        cboBuoi.removeAllItems();
        if (cboLop.getSelectedItem() instanceof Muc l) {
            buoiService.buoiDaDienRa(l.ma()).forEach(cboBuoi::addItem);
        }
        model.setRows(new ArrayList<>());
        lblTrangThai.setText(cboBuoi.getItemCount() == 0 ? "Lớp này chưa có buổi học nào đã diễn ra." : " ");
    }

    private String maBuoi() {
        return cboBuoi.getSelectedItem() instanceof Muc m ? m.ma() : null;
    }

    private void taiDanhSach() {
        String mb = maBuoi();
        if (mb == null) {
            throw new IllegalArgumentException("Hãy chọn buổi học.");
        }
        List<Object[]> ds = service.danhSach(mb);
        model.setRows(ds);
        long daDiemDanh = ds.stream().filter(r -> r[3] != null).count();
        lblTrangThai.setText("Buổi " + mb + ": " + ds.size() + " học viên, đã điểm danh " + daDiemDanh
                + ". Học viên chưa điểm danh mặc định là \"Có mặt\" - kiểm tra lại rồi bấm Lưu.");
    }

    private void luu() {
        String mb = maBuoi();
        if (mb == null) {
            throw new IllegalArgumentException("Hãy chọn buổi học.");
        }
        if (table.isEditing()) {
            table.getCellEditor().stopCellEditing();
        }
        KetQua kq = service.luu(mb, model.layDanhSach());
        UiUtil.showInfo(this, "Đã lưu điểm danh buổi " + mb + ": thêm " + kq.soThem() + ", cập nhật "
                + kq.soCapNhat() + " dòng.");
        taiDanhSach();
    }

    /** Model co 2 cot sua duoc (Trang thai, Ghi chu). */
    private static final class DiemDanhModel extends AbstractTableModel {
        private static final String[] COT = {"Mã ĐK", "Mã HV", "Học viên", "Trạng thái", "Ghi chú", "Tỷ lệ chuyên cần (%)"};
        private final List<Object[]> rows = new ArrayList<>();

        void setRows(List<Object[]> data) {
            rows.clear();
            for (Object[] r : data) {
                Object[] c = r.clone();
                if (c[3] == null) {
                    c[3] = DiemDanhService.CO_MAT;   // chua diem danh: de san "Co mat"
                }
                rows.add(c);
            }
            fireTableDataChanged();
        }

        void datTatCa(String trangThai) {
            for (Object[] r : rows) {
                r[3] = trangThai;
            }
            fireTableDataChanged();
        }

        List<MucDiemDanh> layDanhSach() {
            List<MucDiemDanh> out = new ArrayList<>();
            for (Object[] r : rows) {
                out.add(new MucDiemDanh(Convert.str(r[0]), Convert.str(r[3]), Convert.str(r[4])));
            }
            return out;
        }

        @Override public int getRowCount() { return rows.size(); }
        @Override public int getColumnCount() { return COT.length; }
        @Override public String getColumnName(int c) { return COT[c]; }

        @Override
        public Object getValueAt(int r, int c) {
            Object v = rows.get(r)[c];
            if (v == null) {
                return c == 5 ? "chưa có" : "";
            }
            if (v instanceof BigDecimal b) {
                return UiUtil.formatNumber(b);
            }
            return v.toString();
        }

        @Override
        public void setValueAt(Object v, int r, int c) {
            if (c == 3 || c == 4) {
                rows.get(r)[c] = v;
                fireTableCellUpdated(r, c);
            }
        }

        @Override
        public boolean isCellEditable(int r, int c) {
            return c == 3 || c == 4;
        }
    }
}
