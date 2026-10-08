package ttnn.common;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.Persistence;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * Lop tien ich JPA dung chung (khung toi thieu de ung dung chay duoc doc lap).
 * Neu Kien da dung khung rieng thi chi can cung cap hai ham read(...) va inTx(...) cung chu ky,
 * moi lop service cua Nguyễn Đăng Khoa (24110255) chi phu thuoc vao hai ham nay.
 *
 * Mau quan ly giao dich thong nhat: moi thao tac mo MOT EntityManager rieng (khong dung lai,
 * nen khong bi cache cu), goi thu tuc trong giao dich JPA; thu tuc cua Nguyễn Đăng Khoa (24110255) tu nhan biet
 * @@TRANCOUNT > 0 va chi dung SAVE TRANSACTION nen khong long sai. Loi -> rollback toan bo.
 */
public final class JpaUtil {
    public static final String PERSISTENCE_UNIT = "TTNgoaiNguPU";

    private static volatile EntityManagerFactory emf;
    private static volatile String currentUser;

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
        try {
            EntityManager em = factory.createEntityManager();
            try {
                em.createNativeQuery("SELECT 1").getSingleResult();
            } finally {
                em.close();
            }
        } catch (RuntimeException e) {
            factory.close();
            throw e;
        }
        emf = factory;
        currentUser = user;
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
        }
    }

    public static boolean isConnected() {
        return emf != null && emf.isOpen();
    }

    public static String getCurrentUser() {
        return currentUser;
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
