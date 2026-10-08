package ttnn;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/** Diem vao cua ung dung: dang nhap -> mo khung chinh. */
public final class Main {
    private Main() {
    }

    public static void main(String[] args) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {
            // dung giao dien mac dinh
        }
        SwingUtilities.invokeLater(() -> {
            if (new LoginDialog(null).showDialog()) {
                new MainFrame().setVisible(true);
            } else {
                System.exit(0);
            }
        });
    }
}
