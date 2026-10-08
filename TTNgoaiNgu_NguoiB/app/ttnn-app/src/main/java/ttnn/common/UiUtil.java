package ttnn.common;

import javax.swing.BorderFactory;
import javax.swing.JComponent;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.ListSelectionModel;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.Locale;
import java.util.function.Supplier;

/** Ham tien ich giao dien dung chung: dinh dang, doc so/ngay nhap tay, hop thoai thong bao, bo cuc form. */
public final class UiUtil {
    // STRICT: tu choi ngay khong ton tai (31/02/2025) thay vi tu doi thanh 28/02
    public static final DateTimeFormatter DATE_FMT =
            DateTimeFormatter.ofPattern("dd/MM/uuuu").withResolverStyle(ResolverStyle.STRICT);
    private static final DateTimeFormatter ISO = DateTimeFormatter.ISO_LOCAL_DATE;

    private UiUtil() {
    }

    // ---------- dinh dang ----------
    public static String formatNumber(BigDecimal b) {
        DecimalFormatSymbols sym = new DecimalFormatSymbols(Locale.ROOT);
        sym.setGroupingSeparator('.');
        sym.setDecimalSeparator(',');
        // tien dong khong co phan le; diem (so thap phan) giu toi da 2 chu so
        boolean integral = b.stripTrailingZeros().scale() <= 0;
        return new DecimalFormat(integral ? "#,##0" : "#,##0.##", sym).format(b);
    }

    public static String formatMoney(BigDecimal b) {
        return b == null ? "" : formatNumber(b) + " đ";
    }

    public static String formatDate(LocalDate d) {
        return d == null ? "" : d.format(DATE_FMT);
    }

    // ---------- doc du lieu nhap tay ----------
    /** Chap nhan 1500000, 1.500.000, 1,500,000, "1.500.000 đ". Rong -> null. */
    public static BigDecimal parseMoney(String s, String fieldName) {
        if (s == null || s.isBlank()) {
            return null;
        }
        String t = s.replace("đ", "").replace("VND", "").replace("vnd", "")
                    .replace(".", "").replace(",", "").replace(" ", "").trim();
        try {
            return new BigDecimal(t);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(fieldName + " không hợp lệ (chỉ nhập số, ví dụ 1500000).");
        }
    }

    /** Doc ngay dd/MM/yyyy hoac yyyy-MM-dd. Rong -> null. */
    public static LocalDate parseDate(String s, String fieldName) {
        if (s == null || s.isBlank()) {
            return null;
        }
        String t = s.trim();
        try {
            return t.contains("-") ? LocalDate.parse(t, ISO) : LocalDate.parse(t, DATE_FMT);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException(fieldName + " không hợp lệ (định dạng dd/MM/yyyy).");
        }
    }

    // ---------- hop thoai ----------
    public static void showError(Component parent, Throwable t) {
        JOptionPane.showMessageDialog(parent, DbErrors.message(t), "Lỗi", JOptionPane.ERROR_MESSAGE);
    }

    public static void showInfo(Component parent, String message) {
        JOptionPane.showMessageDialog(parent, message, "Thông báo", JOptionPane.INFORMATION_MESSAGE);
    }

    public static boolean confirm(Component parent, String message) {
        return JOptionPane.showConfirmDialog(parent, message, "Xác nhận",
                JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE) == JOptionPane.YES_OPTION;
    }

    /** Chay mot thao tac co the nem loi: hien con tro cho, loi thi hien thong bao thay vi sap ung dung. */
    public static void run(Component parent, Runnable action) {
        Component top = parent == null ? null : javax.swing.SwingUtilities.getRoot(parent);
        if (top != null) {
            top.setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
        }
        try {
            action.run();
        } catch (RuntimeException e) {
            showError(parent, e);
        } finally {
            if (top != null) {
                top.setCursor(Cursor.getDefaultCursor());
            }
        }
    }

    public static <T> T call(Component parent, Supplier<T> action, T onError) {
        Object[] holder = new Object[] {onError};
        run(parent, () -> holder[0] = action.get());
        @SuppressWarnings("unchecked")
        T result = (T) holder[0];
        return result;
    }

    // ---------- bo cuc ----------
    public static JTable newTable(SimpleTableModel model) {
        JTable t = new JTable(model);
        t.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        t.setRowHeight(24);
        t.getTableHeader().setReorderingAllowed(false);
        t.setFillsViewportHeight(true);
        return t;
    }

    public static JScrollPane scroll(JTable t, int height) {
        JScrollPane sp = new JScrollPane(t);
        sp.setPreferredSize(new Dimension(400, height));
        return sp;
    }

    public static JPanel formPanel(String title) {
        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(BorderFactory.createTitledBorder(title));
        return p;
    }

    /** Them mot cap "nhan - o nhap" vao form GridBagLayout o hang row, cot colBase va colBase+1. */
    public static void addField(JPanel form, int row, int colBase, String label, JComponent field) {
        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(3, 6, 3, 6);
        c.gridy = row;
        c.gridx = colBase;
        c.anchor = GridBagConstraints.LINE_END;
        form.add(new JLabel(label), c);
        c.gridx = colBase + 1;
        c.weightx = 1;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.anchor = GridBagConstraints.LINE_START;
        form.add(field, c);
    }
}
