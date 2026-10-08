package ttnn;

import ttnn.common.DbConfig;
import ttnn.common.DbErrors;
import ttnn.common.JpaUtil;
import ttnn.common.UiUtil;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import javax.swing.JOptionPane;
import java.awt.BorderLayout;
import java.awt.Cursor;
import java.awt.FlowLayout;
import java.awt.Frame;

/**
 * Dang nhap bang SQL Login that: moi lan dang nhap tao EntityManagerFactory voi user/password do.
 * (Khi ghep nhom, man hinh dang nhap theo Role do Kien dung se thay the lop nay.)
 */
public class LoginDialog extends JDialog {
    private final DbConfig config = DbConfig.load();
    private final JTextField txtHost = new JTextField(config.getHost(), 18);
    private final JTextField txtPort = new JTextField(config.getPort(), 6);
    private final JTextField txtDb = new JTextField(config.getDatabase(), 18);
    private final JTextField txtUser = new JTextField("", 18);
    private final JPasswordField txtPass = new JPasswordField(18);
    private boolean success;

    public LoginDialog(Frame owner) {
        super(owner, "Đăng nhập SQL Server - Quản lý trung tâm ngoại ngữ", true);
        JPanel form = UiUtil.formPanel("Kết nối CSDL");
        UiUtil.addField(form, 0, 0, "Máy chủ:", txtHost);
        UiUtil.addField(form, 1, 0, "Cổng:", txtPort);
        UiUtil.addField(form, 2, 0, "CSDL:", txtDb);
        UiUtil.addField(form, 3, 0, "Tài khoản:", txtUser);
        UiUtil.addField(form, 4, 0, "Mật khẩu:", txtPass);

        JButton btnOk = new JButton("Đăng nhập");
        JButton btnCancel = new JButton("Thoát");
        JPanel nut = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        nut.add(btnOk);
        nut.add(btnCancel);

        setLayout(new BorderLayout(6, 6));
        add(new JLabel("  Đăng nhập bằng SQL Login được cấp quyền trên CSDL " + config.getDatabase()), BorderLayout.NORTH);
        add(form, BorderLayout.CENTER);
        add(nut, BorderLayout.SOUTH);
        getRootPane().setDefaultButton(btnOk);
        pack();
        setLocationRelativeTo(owner);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);

        btnOk.addActionListener(e -> dangNhap());
        btnCancel.addActionListener(e -> dispose());
    }

    private void dangNhap() {
        String user = txtUser.getText().trim();
        if (user.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Hãy nhập tên tài khoản.", "Thiếu thông tin", JOptionPane.WARNING_MESSAGE);
            return;
        }
        config.setHost(txtHost.getText());
        config.setPort(txtPort.getText());
        config.setDatabase(txtDb.getText());
        setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
        try {
            JpaUtil.connect(config, user, new String(txtPass.getPassword()));
            success = true;
            dispose();
        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(this, "Không đăng nhập được:\n" + DbErrors.message(ex),
                    "Lỗi kết nối", JOptionPane.ERROR_MESSAGE);
        } finally {
            setCursor(Cursor.getDefaultCursor());
        }
    }

    /** Hien hop thoai; tra ve true neu dang nhap thanh cong. */
    public boolean showDialog() {
        setVisible(true);
        return success;
    }
}
