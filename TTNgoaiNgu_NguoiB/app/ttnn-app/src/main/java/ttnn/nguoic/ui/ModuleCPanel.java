package ttnn.nguoic.ui;



import ttnn.common.PanelStyle;import javax.swing.*;
import java.awt.*;

public class ModuleCPanel extends JPanel {
    public ModuleCPanel() {
        super(new BorderLayout());
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Quản lý lớp", new ttnn.nguoic.ui.LopPanel());
        tabs.addTab("Lịch học theo lớp", new ttnn.nguoic.ui.LichHocPanel());
        tabs.addTab("Lịch học tuần", new ttnn.nguoic.ui.LichHocTuanPanel());
        add(tabs, BorderLayout.CENTER);
    
        PanelStyle.apDung(this);
    }
}
