package ttnn;

import ttnn.common.JpaUtil;
import ttnn.nguoib.ui.ModuleBPanel;

import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JTabbedPane;
import java.awt.Dimension;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

/**
 * Khung chinh toi thieu de chay doc lap phan Nguyễn Đăng Khoa (24110255).
 * KHI GHEP NHOM: Kien dung menu chinh; moi nguoi chi them mot dong vao khung do, vi du
 *     tabs.addTab("Hoc vien & Tai chinh", new ttnn.nguoib.ui.ModuleBPanel());
 */
public class MainFrame extends JFrame {

    public MainFrame() {
        super("Quản lý trung tâm ngoại ngữ - Học viên và tài chính (Nguyễn Đăng Khoa - 24110255)  |  Tài khoản: " + JpaUtil.getCurrentUser());
        setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
        setMinimumSize(new Dimension(1050, 650));

        JTabbedPane tabs = new JTabbedPane(JTabbedPane.LEFT);
        tabs.addTab("Học viên và tài chính", new ModuleBPanel());
        // tabs.addTab("Khóa học", ...);       // Kiên
        // tabs.addTab("Lớp học và lịch", ...); // C
        // tabs.addTab("Giảng dạy", ...);       // D
        setContentPane(tabs);

        JMenuBar bar = new JMenuBar();
        JMenu he = new JMenu("Hệ thống");
        JMenuItem thoat = new JMenuItem("Thoát");
        thoat.addActionListener(e -> thoat());
        he.add(thoat);
        bar.add(he);
        setJMenuBar(bar);

        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                thoat();
            }
        });
        pack();
        setLocationRelativeTo(null);
    }

    private void thoat() {
        JpaUtil.close();
        dispose();
        System.exit(0);
    }
}
