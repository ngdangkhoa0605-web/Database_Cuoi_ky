package ttnn.common;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.Persistence;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Lop tien ich JPA dung chung (khung toi thieu de ung dung chay duoc doc lap).
 * Neu Kien da dung khung rieng thi chi can cung cap hai ham read(...) va inTx(...) cung chu ky,
 * moi lop service cua Nguyễn Đăng Khoa (24110255) chi phu thuoc vao hai ham nay.
 *
 * Dang nhap theo vai tro (Kien): sau khi ket noi, connect(...) hoi IS_ROLEMEMBER de xac dinh VaiTro cua
 * tai khoan. Tai khoan khong thuoc 4 role cua he thong (vi du sa / sysadmin) bi TU CHOI dang nhap.
 * Chu ky connect / read / inTx giu nguyen nhu ban cua B.
 *
 * Mau quan ly giao dich thong nhat: moi thao tac mo MOT EntityManager rieng (khong dung lai,
 * nen khong bi cache cu), goi thu tuc trong giao dich JPA; thu tuc cua Nguyễn Đăng Khoa (24110255) tu nhan biet
 * @@TRANCOUNT > 0 va chi dung SAVE TRANSACTION nen khong long sai. Loi -> rollback toan bo.
 */
public final class JpaUtil {
    public static final String PERSISTENCE_UNIT = "TTNgoaiNguPU";

    private static volatile EntityManagerFactory emf;
    private static volatile String currentUser;
    private static volatile VaiTro currentRole;
    private static volatile String currentServer;
    private static volatile String currentDatabase;

    /** Mot cau lenh: ten may chu, ten CSDL va role dau tien (theo thu tu VaiTro) ma tai khoan la thanh vien. */
    private static final String SQL_THONG_TIN_PHIEN = buildSqlThongTinPhien();

    private static String buildSqlThongTinPhien() {
        StringBuilder sb = new StringBuilder("SELECT @@SERVERNAME, DB_NAME(), CASE");
        for (VaiTro v : VaiTro.values()) {
            sb.append(" WHEN IS_ROLEMEMBER(N'").append(v.getRoleSql()).append("') = 1 THEN N'")
                    .append(v.getRoleSql()).append('\'');
        }
        return sb.append(" END").toString();
    }

    private JpaUtil() {
    }

    /** Dang nhap: tao EntityManagerFactory theo tai khoan SQL Login (khong dung tai khoan chung). */
    public static synchronized void connect(DbConfig cfg, String user, String password) {
        close();
        Map<String, Object> props = new HashMap<>();
        props.put("jakarta.persistence.jdbc.url", cfg.url());
        props.put("jakarta.persistence.jdbc.user", user);
        props.put("jakarta.persistence.jdbc.password", password);
        props.put("jakarta.persistence.jdbc.driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver");
        props.put("hibernate.hbm2ddl.auto", "none");

        EntityManagerFactory factory = Persistence.createEntityManagerFactory(PERSISTENCE_UNIT, props);
        Object[] info;
        try {
            EntityManager em = factory.createEntityManager();
            try {
                em.createNativeQuery("SELECT 1").getSingleResult();
                info = (Object[]) em.createNativeQuery(SQL_THONG_TIN_PHIEN).getSingleResult();
            } finally {
                em.close();
            }
            if (VaiTro.tuRoleSql(Convert.str(info[2])) == null) {
                throw new IllegalStateException("Tài khoản \"" + user + "\" không thuộc vai trò nào của hệ thống "
                        + "(Quản trị viên, Giáo vụ, Kế toán, Giảng viên).\n"
                        + "Hãy đăng nhập bằng tài khoản được cấp hoặc liên hệ quản trị viên.");
            }
        } catch (RuntimeException e) {
            factory.close();
            throw e;
        }
        emf = factory;
        currentUser = user;
        currentServer = Convert.str(info[0]);
        currentDatabase = Convert.str(info[1]);
        currentRole = VaiTro.tuRoleSql(Convert.str(info[2]));
    }

    public static synchronized void close() {
        if (emf != null) {
            try {
                emf.close();
            } catch (RuntimeException ignored) {
                // bo qua loi khi dong
            }
            emf = null;
            currentUser = null;
            currentRole = null;
            currentServer = null;
            currentDatabase = null;
        }
    }

    public static boolean isConnected() {
        return emf != null && emf.isOpen();
    }

    public static String getCurrentUser() {
        return currentUser;
    }

    /** Vai tro cua tai khoan dang dang nhap (null neu chua dang nhap). */
    public static VaiTro getCurrentRole() {
        return currentRole;
    }

    /** Tai khoan dang dang nhap co thuoc mot trong cac vai tro nay khong. */
    public static boolean coVaiTro(VaiTro... cacVaiTro) {
        VaiTro r = currentRole;
        if (r == null) {
            return false;
        }
        return List.of(cacVaiTro).contains(r);
    }

    /** Ten may chu SQL Server thuc te (@@SERVERNAME) cua phien dang nhap. */
    public static String getCurrentServer() {
        return currentServer;
    }

    /** Ten CSDL thuc te (DB_NAME()) cua phien dang nhap. */
    public static String getCurrentDatabase() {
        return currentDatabase;
    }

    private static EntityManagerFactory factory() {
        EntityManagerFactory f = emf;
        if (f == null || !f.isOpen()) {
            throw new IllegalStateException("Chua ket noi CSDL. Hay dang nhap truoc.");
        }
        return f;
    }

    /** Doc du lieu (khong mo giao dich). */
    public static <T> T read(Function<EntityManager, T> work) {
        EntityManager em = factory().createEntityManager();
        try {
            return work.apply(em);
        } finally {
            em.close();
        }
    }

    /** Ghi du lieu / goi thu tuc co giao dich: thanh cong thi commit, loi thi rollback roi nem lai. */
    public static <T> T inTx(Function<EntityManager, T> work) {
        EntityManager em = factory().createEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            T result = work.apply(em);
            tx.commit();
            return result;
        } catch (RuntimeException e) {
            if (tx.isActive()) {
                try {
                    tx.rollback();
                } catch (RuntimeException ignored) {
                    // giu nguyen loi goc
                }
            }
            throw e;
        } finally {
            em.close();
        }
    }
}
