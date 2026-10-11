package ttnn.common;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.regex.Pattern;

/**
 * Kiem tra du lieu dau vao o tang giao dien TRUOC khi goi CSDL (email, SDT, so am, ngay hop le).
 * Vi pham -> IllegalArgumentException voi thong bao tieng Viet (DbErrors.message tra nguyen van).
 * Cac rang buoc tuong ung van duoc CSDL (CHECK/UNIQUE/trigger/thu tuc) kiem tra lai.
 */
public final class Validator {
    private static final Pattern EMAIL = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PHONE = Pattern.compile("^0\\d{9,10}$");

    private Validator() {
    }

    public static String required(String value, String fieldName, int maxLen) {
        String v = value == null ? "" : value.trim();
        if (v.isEmpty()) {
            throw new IllegalArgumentException(fieldName + " không được để trống.");
        }
        if (v.length() > maxLen) {
            throw new IllegalArgumentException(fieldName + " tối đa " + maxLen + " ký tự.");
        }
        return v;
    }

    public static String phone(String value) {
        String v = required(value, "Số điện thoại", 15);
        if (!PHONE.matcher(v).matches()) {
            throw new IllegalArgumentException("Số điện thoại phải bắt đầu bằng 0 và gồm 10-11 chữ số.");
        }
        return v;
    }

    public static String email(String value) {
        String v = required(value, "Email", 50);
        if (!EMAIL.matcher(v).matches()) {
            throw new IllegalArgumentException("Email không đúng định dạng (ví dụ ten@email.com).");
        }
        return v;
    }

    public static LocalDate birthDate(LocalDate d) {
        if (d == null) {
            throw new IllegalArgumentException("Ngày sinh không được để trống.");
        }
        LocalDate today = LocalDate.now();
        if (d.isAfter(today)) {
            throw new IllegalArgumentException("Ngày sinh không được ở tương lai.");
        }
        if (d.isBefore(today.minusYears(100))) {
            throw new IllegalArgumentException("Ngày sinh không hợp lệ (quá 100 tuổi).");
        }
        return d;
    }

    public static LocalDate notFuture(LocalDate d, String fieldName) {
        if (d != null && d.isAfter(LocalDate.now())) {
            throw new IllegalArgumentException(fieldName + " không được ở tương lai.");
        }
        return d;
    }

    public static BigDecimal positiveMoney(BigDecimal m, String fieldName) {
        if (m == null || m.signum() <= 0) {
            throw new IllegalArgumentException(fieldName + " phải lớn hơn 0.");
        }
        return m;
    }

    public static BigDecimal nonNegativeMoney(BigDecimal m, String fieldName) {
        if (m == null) {
            return BigDecimal.ZERO;
        }
        if (m.signum() < 0) {
            throw new IllegalArgumentException(fieldName + " không được âm.");
        }
        return m;
    }

    public static BigDecimal score(BigDecimal d) {
        if (d == null) {
            return null;
        }
        if (d.signum() < 0 || d.compareTo(BigDecimal.TEN) > 0) {
            throw new IllegalArgumentException("Điểm phải nằm trong khoảng từ 0 đến 10.");
        }
        return d;
    }
}
