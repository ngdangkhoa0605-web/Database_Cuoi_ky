package ttnn;

import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/** Diem vao cua ung dung: dang nhap (theo vai tro) -> mo khung chinh. */
public final class Main {
    private Main() {
    }

    public static void main(String[] args) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {
            // dung giao dien mac dinh
        }
        SwingUtilities.invokeLater(Main::batDau);
    }

    /**
     * Hien man hinh dang nhap; thanh cong thi mo khung chinh, bam Thoat thi ket thuc ung dung.
     * Dung lai khi Dang xuat (MainFrame goi lai ham nay). Phai goi tren luong giao dien (EDT).
     */
    public static void batDau() {
        if (new LoginDialog(null).showDialog()) {
            new MainFrame().setVisible(true);
        } else {
            System.exit(0);
        }
    }
}


