package ttnn.common;

import javax.swing.*;
import javax.swing.border.AbstractBorder;
import javax.swing.plaf.basic.BasicTabbedPaneUI;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.RoundRectangle2D;
import java.util.Locale;

/** Giao diện xanh lơ dùng chung cho toàn bộ màn hình Swing. Không thay đổi xử lý nghiệp vụ. */
public final class PanelStyle {
    private static final Color CYAN = new Color(28, 177, 202);
    private static final Color CYAN_DARK = new Color(10, 132, 158);
    private static final Color CYAN_PALE = new Color(225, 248, 251);
    private static final Color TEXT = new Color(37, 55, 66);
    private static final Color RED = new Color(220, 53, 69);
    private static final Color GREEN = new Color(32, 151, 99);
    private static final Color ORANGE = new Color(232, 145, 42);
    private static final Color PURPLE = new Color(119, 91, 177);
    private static final Color BLUE = new Color(30, 136, 190);
    private static final Color SLATE = new Color(91, 112, 126);

    private PanelStyle() {}

    public static void apDung(Component component) {
        if (component == null) return;
        try { UIManager.put("TabbedPane.selected", CYAN_PALE); } catch (Exception ignored) { }
        style(component);
        if (component instanceof JComponent jc) jc.revalidate();
        if (component instanceof Container c) c.repaint();
    }

    private static void style(Component c) {
        if (c instanceof JTabbedPane tabs) {
            tabs.setUI(new CyanTabbedPaneUI());
            tabs.setFont(new Font("Segoe UI", Font.BOLD, 13));
            tabs.setForeground(TEXT);
            tabs.setBackground(Color.WHITE);
            tabs.setOpaque(true);
            tabs.setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createLineBorder(new Color(150, 222, 232), 1, true),
                    BorderFactory.createEmptyBorder(5, 5, 5, 5)));
            tabs.setTabLayoutPolicy(JTabbedPane.SCROLL_TAB_LAYOUT);
        } else if (c instanceof JButton b) {
            styleButton(b);
        } else if (c instanceof JTable table) {
            table.setFont(new Font("Segoe UI", Font.PLAIN, 13));
            table.setRowHeight(27);
            table.setForeground(TEXT);
            table.setBackground(Color.WHITE);
            table.setSelectionBackground(new Color(190, 239, 246));
            table.setSelectionForeground(TEXT);
            table.setShowHorizontalLines(true);
            table.setShowVerticalLines(false);
            table.setGridColor(new Color(225, 237, 240));
            table.setFillsViewportHeight(true);
            if (table.getTableHeader() != null) {
                table.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 12));
                table.getTableHeader().setBackground(CYAN_DARK);
                table.getTableHeader().setForeground(Color.WHITE);
                table.getTableHeader().setOpaque(true);
                table.getTableHeader().setPreferredSize(new Dimension(0, 32));
                table.getTableHeader().setDefaultRenderer(new javax.swing.table.DefaultTableCellRenderer() {
                    @Override public Component getTableCellRendererComponent(JTable t, Object value,
                            boolean isSelected, boolean hasFocus, int row, int column) {
                        JLabel label = (JLabel) super.getTableCellRendererComponent(
                                t, value, isSelected, hasFocus, row, column);
                        label.setOpaque(true);
                        label.setBackground(CYAN_DARK);
                        label.setForeground(Color.WHITE);
                        label.setFont(new Font("Segoe UI", Font.BOLD, 12));
                        label.setBorder(BorderFactory.createEmptyBorder(4, 8, 4, 8));
                        return label;
                    }
                });
            }
        } else if (c instanceof JTextField || c instanceof JPasswordField || c instanceof JComboBox<?> || c instanceof JTextArea) {
            c.setFont(new Font("Segoe UI", Font.PLAIN, 13));
            if (c instanceof JComponent jc) {
                jc.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(new Color(190, 214, 221), 1, true),
                        BorderFactory.createEmptyBorder(5, 7, 5, 7)));
                jc.setBackground(new Color(250, 254, 255));
            }
        } else if (c instanceof JLabel label) {
            label.setFont(new Font("Segoe UI", Font.PLAIN, 13));
            label.setForeground(TEXT);
        } else if (c instanceof JPanel panel) {
            panel.setBackground(Color.WHITE);
            if (panel.getBorder() == null) panel.setBorder(BorderFactory.createEmptyBorder(3, 3, 3, 3));
        }
        if (c instanceof Container container) {
            for (Component child : container.getComponents()) style(child);
        }
    }

    private static void styleButton(JButton b) {
        String text = b.getText() == null ? "" : b.getText().toLowerCase(Locale.ROOT);
        Color color = CYAN_DARK;
        if (contains(text, "xóa", "hủy", "thoát", "đăng xuất", "nghỉ", "kết thúc")) color = RED;
        else if (contains(text, "thêm", "đăng ký", "lưu", "ghi nhận", "thanh toán", "đăng nhập")) color = GREEN;
        else if (contains(text, "sửa", "cập nhật", "đổi", "chỉnh")) color = ORANGE;
        else if (contains(text, "tìm", "lọc", "xem", "thống kê", "báo cáo")) color = BLUE;
        else if (contains(text, "làm mới", "nhập mới", "tải lại", "tải danh sách", "hiện tất cả", "điền", "reset")) color = SLATE;
        else if (contains(text, "phân quyền", "mật khẩu")) color = PURPLE;
        final Color base = color;
        b.setFont(new Font("Segoe UI", Font.BOLD, 12));
        b.setForeground(Color.WHITE);
        b.setBackground(base);
        b.setOpaque(false);
        b.setContentAreaFilled(false);
        b.setUI(new RoundedButtonUI());
        b.setFocusPainted(false);
        b.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        b.setBorder(new RoundedButtonBorder(base, 12));
        b.setMargin(new Insets(7, 13, 7, 13));
        b.setPreferredSize(new Dimension(Math.max(b.getPreferredSize().width, 84), Math.max(b.getPreferredSize().height, 34)));
        for (var listener : b.getMouseListeners()) {
            if (listener instanceof ButtonHover) b.removeMouseListener(listener);
        }
        b.addMouseListener(new ButtonHover(b, base));
    }

    private static boolean contains(String text, String... words) {
        for (String word : words) if (text.contains(word)) return true;
        return false;
    }

    private static Color darker(Color c) { return c.darker(); }

    private static final class ButtonHover extends MouseAdapter {
        private final JButton button;
        private final Color base;
        ButtonHover(JButton button, Color base) { this.button = button; this.base = base; }
        @Override public void mouseEntered(MouseEvent e) { button.setBorder(new RoundedButtonBorder(darker(base), 12)); button.repaint(); }
        @Override public void mouseExited(MouseEvent e) { button.setBorder(new RoundedButtonBorder(base, 12)); button.repaint(); }
    }

    /** Vẽ nền bo góc trước, để chữ/icon của JButton luôn được vẽ phía trên nền. */
    private static final class RoundedButtonUI extends javax.swing.plaf.basic.BasicButtonUI {
        @Override public void update(Graphics g, JComponent c) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            JButton button = (JButton) c;
            Color fill = button.getBackground();
            ButtonModel model = button.getModel();
            if (model.isPressed() && model.isArmed()) fill = fill.darker();
            else if (model.isRollover()) fill = fill.darker();
            g2.setColor(fill);
            g2.fill(new RoundRectangle2D.Float(0, 0, c.getWidth() - 1, c.getHeight() - 1, 14, 14));
            g2.dispose();
            paint(g, c);
        }
    }

    private static final class RoundedButtonBorder extends AbstractBorder {
        private final Color color;
        private final int radius;
        RoundedButtonBorder(Color color, int radius) { this.color = color; this.radius = radius; }
        @Override public Insets getBorderInsets(Component c) { return new Insets(8, 14, 8, 14); }
        @Override public Insets getBorderInsets(Component c, Insets insets) {
            insets.set(8, 14, 8, 14); return insets;
        }
        @Override public void paintBorder(Component c, Graphics g, int x, int y, int w, int h) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setColor(color.darker());
            g2.draw(new RoundRectangle2D.Float(x, y, w - 1, h - 1, radius, radius));
            g2.dispose();
        }
    }

    private static final class CyanTabbedPaneUI extends BasicTabbedPaneUI {
        @Override protected void installDefaults() {
            super.installDefaults();
            tabAreaInsets = new Insets(4, 4, 4, 4);
            contentBorderInsets = new Insets(8, 8, 8, 8);
            tabInsets = new Insets(9, 14, 9, 14);
            selectedTabPadInsets = new Insets(0, 0, 0, 0);
        }
        @Override protected void paintTabBackground(Graphics g, int placement, int index,
                int x, int y, int w, int h, boolean selected) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            Color fill = selected ? CYAN : CYAN_PALE;
            g2.setColor(fill);
            g2.fill(new RoundRectangle2D.Float(x + 2, y + 2, w - 4, h - 4, 14, 14));
            g2.setColor(selected ? CYAN_DARK : new Color(144, 218, 229));
            g2.draw(new RoundRectangle2D.Float(x + 2, y + 2, w - 4, h - 4, 14, 14));
            g2.dispose();
        }
        @Override protected void paintTabBorder(Graphics g, int placement, int index,
                int x, int y, int w, int h, boolean selected) { }
        @Override protected void paintText(Graphics g, int placement, Font font, FontMetrics metrics,
                int index, String title, Rectangle textRect, boolean selected) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setFont(font);
            g2.setColor(selected ? Color.WHITE : CYAN_DARK);
            String text = title == null ? "" : title;
            int tx = textRect.x;
            int ty = textRect.y + metrics.getAscent();
            g2.drawString(text, tx, ty);
            g2.dispose();
        }
        @Override protected void paintContentBorder(Graphics g, int placement, int selectedIndex) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setColor(new Color(157, 224, 234));
            g2.draw(new RoundRectangle2D.Float(1, 1, tabPane.getWidth() - 3, tabPane.getHeight() - 3, 16, 16));
            g2.dispose();
        }
    }
}
