
package ttnn.nguoic.ui;

import ttnn.nguoic.service.LopService;

import javax.swing.*;
import java.awt.*;
import java.sql.Date;

public class SuaLopDialog extends JDialog {

    private final LopService service = new LopService();
    private final LopService.LopRow lop;

    private final JTextField maLop = new JTextField(15);
    private final JTextField maKH = new JTextField(15);
    private final JTextField maGV = new JTextField(15);
    private final JTextField ngayKhaiGiang = new JTextField(15);
    private final JTextField ngayKetThuc = new JTextField(15);
    private final JTextField siSoToiDa = new JTextField(15);

    public SuaLopDialog(Window owner, LopService.LopRow lop) {
        super(owner, "Sửa thông tin lớp", ModalityType.APPLICATION_MODAL);
        this.lop = lop;

        setLayout(new BorderLayout(10, 10));

        JPanel form = new JPanel(new GridBagLayout());
        form.setBorder(BorderFactory.createEmptyBorder(15, 15, 5, 15));

        maLop.setEditable(false);
        maKH.setEditable(false);

        maLop.setText(lop.maLop());
        maKH.setText(lop.maKH());
        maGV.setText(lop.maGV());
        ngayKhaiGiang.setText(String.valueOf(lop.ngayKhaiGiang()));
        ngayKetThuc.setText(String.valueOf(lop.ngayKetThuc()));
        siSoToiDa.setText(String.valueOf(lop.siSoToiDa()));

        int row = 0;
        addField(form, row++, "Mã lớp:", maLop);
        addField(form, row++, "Mã khóa học:", maKH);
        addField(form, row++, "Mã giảng viên chính:", maGV);
        addField(form, row++, "Ngày khai giảng:", ngayKhaiGiang);
        addField(form, row++, "Ngày kết thúc:", ngayKetThuc);
        addField(form, row++, "Sĩ số tối đa:", siSoToiDa);

        JLabel note = new JLabel(
                "Ngày nhập theo định dạng yyyy-MM-dd");
        GridBagConstraints noteGbc = new GridBagConstraints();
        noteGbc.gridx = 0;
        noteGbc.gridy = row;
        noteGbc.gridwidth = 2;
        noteGbc.anchor = GridBagConstraints.WEST;
        noteGbc.insets = new Insets(8, 5, 5, 5);
        form.add(note, noteGbc);

        JButton save = new JButton("Lưu thay đổi");
        JButton cancel = new JButton("Hủy");

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttons.add(save);
        buttons.add(cancel);

        save.addActionListener(e -> save());
        cancel.addActionListener(e -> dispose());

        add(form, BorderLayout.CENTER);
        add(buttons, BorderLayout.SOUTH);

        pack();
        setMinimumSize(new Dimension(390, getHeight()));
        setLocationRelativeTo(owner);
    }

    private void addField(
            JPanel panel, int row, String label, JTextField field) {

        GridBagConstraints left = new GridBagConstraints();
        left.gridx = 0;
        left.gridy = row;
        left.anchor = GridBagConstraints.WEST;
        left.insets = new Insets(5, 5, 5, 10);
        panel.add(new JLabel(label), left);

        GridBagConstraints right = new GridBagConstraints();
        right.gridx = 1;
        right.gridy = row;
        right.weightx = 1;
        right.fill = GridBagConstraints.HORIZONTAL;
        right.insets = new Insets(5, 5, 5, 5);
        panel.add(field, right);
    }

    private void save() {
        try {
            Date start = Date.valueOf(ngayKhaiGiang.getText().trim());
            Date end = Date.valueOf(ngayKetThuc.getText().trim());
            int capacity = Integer.parseInt(siSoToiDa.getText().trim());

            service.capNhatLop(
                    lop.maLop(),
                    maGV.getText().trim(),
                    start,
                    end,
                    capacity
            );

            JOptionPane.showMessageDialog(
                    this, "Cập nhật lớp thành công.");

            dispose();

        } catch (IllegalArgumentException ex) {
            JOptionPane.showMessageDialog(
                    this,
                    ex.getMessage() == null
                            ? "Dữ liệu nhập không hợp lệ."
                            : ex.getMessage(),
                    "Không thể cập nhật",
                    JOptionPane.ERROR_MESSAGE
            );

        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(
                    this,
                    ex.getMessage() == null
                            ? "Không thể cập nhật lớp."
                            : ex.getMessage(),
                    "Lỗi cập nhật",
                    JOptionPane.ERROR_MESSAGE
            );
        }
    }
}
