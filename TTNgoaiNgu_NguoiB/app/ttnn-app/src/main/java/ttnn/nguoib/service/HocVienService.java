package ttnn.nguoib.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.DbErrors;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;
import ttnn.nguoib.entity.HocVien;

import java.time.LocalDate;
import java.util.List;

/**
 * Nghiep vu hoc vien.
 *  - Tim kiem : goi STORED PROCEDURE SP_TimKiemHocVien (StoredProcedureQuery).
 *  - Them/sua/xoa/tim theo ma : CRUD bang entity HocVien (persist/merge/remove/find);
 *    trigger va rang buoc UNIQUE cua CSDL van kiem tra lai.
 */
public final class HocVienService {

    /** Mot dong ket qua tim kiem (cot cua SP_TimKiemHocVien). */
    public record HocVienRow(String maHV, String hoTen, LocalDate ngaySinh, String sdt,
                             String email, String diaChi, int soLopDangKy) {
        public Object[] toRow() {
            return new Object[] {maHV, hoTen, ngaySinh, sdt, email, diaChi, soLopDangKy};
        }
    }

    /** Tim theo ten / SDT / email (khop mot phan, de trong = bo qua). Tat ca de trong = tra ve tat ca. */
    public List<HocVienRow> timKiem(String hoTen, String sdt, String email) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_TimKiemHocVien");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);
            q.setParameter(1, Convert.blank(hoTen) ? null : hoTen.trim());
            q.setParameter(2, Convert.blank(sdt) ? null : sdt.trim());
            q.setParameter(3, Convert.blank(email) ? null : email.trim());
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new HocVienRow(Convert.str(r[0]), Convert.str(r[1]), Convert.date(r[2]),
                            Convert.str(r[3]), Convert.str(r[4]), Convert.str(r[5]),
                            r[6] == null ? 0 : Convert.integer(r[6])))
                    .toList();
        });
    }

    public HocVien tim(String maHV) {
        return JpaUtil.read(em -> em.find(HocVien.class, maHV));
    }

    /** Ma ke tiep: HV001, HV002, ... (cot MaHV la CHAR(5) nen toi da HV999). */
    private String maTiepTheo() {
        Number n = JpaUtil.read(em -> (Number) em.createNativeQuery(
                "SELECT ISNULL(MAX(TRY_CAST(SUBSTRING(MaHV, 3, 3) AS INT)), 0) + 1 "
                        + "FROM dbo.HOCVIEN WHERE MaHV LIKE 'HV[0-9][0-9][0-9]'").getSingleResult());
        int next = n.intValue();
        if (next > 999) {
            throw new IllegalStateException("Đã hết dải mã học viên HV001 - HV999 (cột MaHV là CHAR(5)).");
        }
        return String.format("HV%03d", next);
    }

    /** Them hoc vien moi, ma tu sinh. Hai may cung them -> thu lai neu trung khoa chinh. */
    public HocVien them(String hoTen, LocalDate ngaySinh, String sdt, String email, String diaChi) {
        String ten = Validator.required(hoTen, "Họ tên", 40);
        LocalDate ns = Validator.birthDate(ngaySinh);
        String dt = Validator.phone(sdt);
        String em1 = Validator.email(email);
        String dc = Validator.required(diaChi, "Địa chỉ", 100);

        RuntimeException last = null;
        for (int attempt = 0; attempt < 5; attempt++) {
            final String ma = maTiepTheo();
            try {
                return JpaUtil.inTx(em -> {
                    HocVien h = new HocVien(ma, ten, ns, dt, em1, dc);
                    em.persist(h);
                    em.flush();
                    return h;
                });
            } catch (RuntimeException e) {
                last = e;
                if (!DbErrors.mentions(e, "PK_HOCVIEN")) {
                    throw e;
                }
            }
        }
        throw last;
    }

    public void sua(String maHV, String hoTen, LocalDate ngaySinh, String sdt, String email, String diaChi) {
        String ten = Validator.required(hoTen, "Họ tên", 40);
        LocalDate ns = Validator.birthDate(ngaySinh);
        String dt = Validator.phone(sdt);
        String em1 = Validator.email(email);
        String dc = Validator.required(diaChi, "Địa chỉ", 100);
        JpaUtil.inTx(em -> {
            HocVien h = em.find(HocVien.class, maHV);
            if (h == null) {
                throw new IllegalStateException("Học viên " + maHV + " không còn tồn tại.");
            }
            h.setHoTen(ten);
            h.setNgaySinh(ns);
            h.setSdt(dt);
            h.setEmail(em1);
            h.setDiaChi(dc);
            em.flush();
            return null;
        });
    }

    public void xoa(String maHV) {
        JpaUtil.inTx(em -> {
            Number soDK = (Number) em.createNativeQuery("SELECT COUNT(*) FROM dbo.DANGKY WHERE MaHV = :ma")
                    .setParameter("ma", maHV).getSingleResult();
            if (soDK.intValue() > 0) {
                throw new IllegalStateException("Học viên " + maHV + " đã có " + soDK.intValue()
                        + " đăng ký học nên không thể xóa.");
            }
            HocVien h = em.find(HocVien.class, maHV);
            if (h == null) {
                throw new IllegalStateException("Học viên " + maHV + " không còn tồn tại.");
            }
            em.remove(h);
            em.flush();
            return null;
        });
    }
}
