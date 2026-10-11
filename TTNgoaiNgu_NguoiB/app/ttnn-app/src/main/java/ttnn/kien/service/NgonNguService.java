package ttnn.kien.service;

import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;
import ttnn.kien.entity.NgonNgu;

import java.util.List;
import java.util.Locale;

/**
 * Nghiep vu ngon ngu (Kien).
 *  - Danh sach kem so lieu : VIEW V_THONGKE_NgonNgu.
 *  - Them / sua ten / xoa  : CRUD entity NgonNgu (persist / find + set / remove).
 *    Rang buoc cua CSDL kiem tra lai: PK_NGONNGU, UQ_NGONNGU_TENNN (trung), FK_KHOAHOC_NGONNGU,
 *    FK_GIANGVIEN_NGONNGU (xoa khi dang duoc dung) -> DbErrors.message doi thanh thong bao tieng Viet.
 */
public final class NgonNguService {

    /** Mot muc trong o chon ngon ngu. ma = null nghia la "Tat ca" (khong loc). */
    public record NgonNguMuc(String ma, String ten) {
        public static final NgonNguMuc TAT_CA = new NgonNguMuc(null, "Tất cả");

        @Override
        public String toString() {
            return ma == null ? ten : ma + " - " + ten;
        }
    }

    /** Cot: MaNN, TenNN, SoKhoaHoc, SoKhoaDangGiangDay, SoLop, SoGiangVien, SoGVDangCongTac. */
    public List<Object[]> danhSach() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaNN, TenNN, SoKhoaHoc, SoKhoaDangGiangDay, SoLop, SoGiangVien, SoGVDangCongTac "
                        + "FROM dbo.V_THONGKE_NgonNgu ORDER BY MaNN").getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.integer(r[2]),
                        Convert.integer(r[3]), Convert.integer(r[4]), Convert.integer(r[5]), Convert.integer(r[6])})
                .toList());
    }

    /** Danh muc ngon ngu cho o chon (doc bang NGONNGU - moi vai tro deu duoc SELECT). */
    public List<NgonNguMuc> danhMuc() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaNN, TenNN FROM dbo.NGONNGU ORDER BY TenNN").getResultList()).stream()
                .map(r -> new NgonNguMuc(Convert.str(r[0]), Convert.str(r[1])))
                .toList());
    }

    /** Chuan hoa ma ngon ngu: bat buoc, toi da 3 ky tu, viet hoa (ANH, NHA...). */
    public static String chuanHoaMa(String maNN) {
        return Validator.required(maNN, "Mã ngôn ngữ", 3).toUpperCase(Locale.ROOT);
    }

    public void them(String maNN, String tenNN) {
        String ma = chuanHoaMa(maNN);
        String ten = Validator.required(tenNN, "Tên ngôn ngữ", 30);
        JpaUtil.inTx(em -> {
            em.persist(new NgonNgu(ma, ten));
            em.flush();
            return null;
        });
    }

    public void suaTen(String maNN, String tenNN) {
        String ten = Validator.required(tenNN, "Tên ngôn ngữ", 30);
        JpaUtil.inTx(em -> {
            NgonNgu n = em.find(NgonNgu.class, maNN);
            if (n == null) {
                throw new IllegalStateException("Ngôn ngữ " + maNN + " không còn tồn tại.");
            }
            n.setTenNN(ten);
            em.flush();
            return null;
        });
    }

    /** Xoa: neu con khoa hoc / giang vien thi CSDL tu choi (FK) va DbErrors bao ro ly do. */
    public void xoa(String maNN) {
        JpaUtil.inTx(em -> {
            NgonNgu n = em.find(NgonNgu.class, maNN);
            if (n == null) {
                throw new IllegalStateException("Ngôn ngữ " + maNN + " không còn tồn tại.");
            }
            em.remove(n);
            em.flush();
            return null;
        });
    }
}
