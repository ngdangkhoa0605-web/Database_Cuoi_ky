package ttnn.common;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/** Ep kieu an toan cho ket qua native query / thu tuc (tuy phien ban Hibernate/driver tra java.sql.Date hay LocalDate). */
public final class Convert {
    private Convert() {
    }

    public static String str(Object o) {
        return o == null ? null : o.toString().trim();
    }

    public static Integer integer(Object o) {
        return o == null ? null : ((Number) o).intValue();
    }

    public static BigDecimal money(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof BigDecimal b) {
            return b;
        }
        return new BigDecimal(o.toString());
    }

    public static LocalDate date(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof LocalDate d) {
            return d;
        }
        if (o instanceof java.sql.Date d) {
            return d.toLocalDate();
        }
        if (o instanceof Timestamp t) {
            return t.toLocalDateTime().toLocalDate();
        }
        if (o instanceof LocalDateTime t) {
            return t.toLocalDate();
        }
        if (o instanceof java.util.Date d) {
            return new java.sql.Date(d.getTime()).toLocalDate();
        }
        return LocalDate.parse(o.toString().substring(0, 10));
    }

    /** Moi phan tu ket qua thanh mang Object[] (mot cot thi boc lai thanh mang 1 phan tu). */
    public static Object[] row(Object o) {
        return (o instanceof Object[] arr) ? arr : new Object[] {o};
    }

    public static List<Object[]> rows(List<?> list) {
        return list.stream().map(Convert::row).toList();
    }

    /** Escape ky tu dac biet cua LIKE voi ky tu thoat '!' (khong dung '\' vi bo phan tich native query cua Hibernate xu ly '\'). */
    public static String likeContains(String s) {
        String e = s.trim().replace("!", "!!").replace("%", "!%").replace("_", "!_").replace("[", "![");
        return "%" + e + "%";
    }

    public static boolean blank(String s) {
        return s == null || s.isBlank();
    }
}
