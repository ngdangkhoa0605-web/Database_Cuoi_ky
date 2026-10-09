package ttnn.kien.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.Query;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;

import java.time.LocalDate;
import java.util.List;

/**
 * Thong ke khoa hoc (Kien).
 *  - tongHop          : VIEW V_KHOAHOC_ThongKe (ben trong dung ham FN_SoHocVien_KhoaHoc).
 *  - dangKyTheoKhoa   : STORED PROCEDURE SP_ThongKeDangKy_TheoKhoa (khoang ngay dang ky).
 *  - khoaDangGiangDay : TABLE-VALUED FUNCTION FN_DSKhoaHoc_TheoNN.
 */
public final class ThongKeKhoaHocService {

    /** maNN null = tat ca. Cot: MaKH, TenKhoa, TenNN, TrinhDo, HocPhi, TrangThai, SoLop, SoLopDangMo, SoHocVien. */
    public List<Object[]> tongHop(String maNN) {
        return JpaUtil.read(em -> {
            boolean loc = !Convert.blank(maNN);
            Query q = em.createNativeQuery(
                    "SELECT MaKH, TenKhoa, TenNN, TrinhDo, HocPhi, TrangThai, SoLop, SoLopDangMo, SoHocVien "
                            + "FROM dbo.V_KHOAHOC_ThongKe"
                            + (loc ? " WHERE MaNN = :ma" : "")
                            + " ORDER BY SoHocVien DESC, MaKH");
            if (loc) {
                q.setParameter("ma", maNN.trim());
            }
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                            Convert.str(r[3]), Convert.money(r[4]), Convert.str(r[5]), Convert.integer(r[6]),
                            Convert.integer(r[7]), Convert.integer(r[8])})
                    .toList();
        });
    }

    /**
     * So dang ky theo khoa trong khoang ngay (null = khong gioi han phia do).
     * Cot: MaKH, TenKhoa, TenNN, SoLopCoDangKy, SoDangKy, SoHocVien, TyLePhanTram.
     */
    public List<Object[]> dangKyTheoKhoa(LocalDate tuNgay, LocalDate denNgay) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_ThongKeDangKy_TheoKhoa");
            q.registerStoredProcedureParameter(1, LocalDate.class, ParameterMode.IN);   // @TuNgay
            q.registerStoredProcedureParameter(2, LocalDate.class, ParameterMode.IN);   // @DenNgay
            q.setParameter(1, tuNgay);
            q.setParameter(2, denNgay);
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                            Convert.integer(r[3]), Convert.integer(r[4]), Convert.integer(r[5]),
                            Convert.money(r[6])})
                    .toList();
        });
    }

    /** Khoa 'Dang giang day' cua mot ngon ngu. Cot: MaKH, TenKhoa, TrinhDo, SoBuoi, HocPhi. */
    public List<Object[]> khoaDangGiangDay(String maNN) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaKH, TenKhoa, TrinhDo, SoBuoi, HocPhi FROM dbo.FN_DSKhoaHoc_TheoNN(:ma) ORDER BY TenKhoa")
                .setParameter("ma", maNN.trim()).getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                        Convert.integer(r[3]), Convert.money(r[4])})
                .toList());
    }
}
