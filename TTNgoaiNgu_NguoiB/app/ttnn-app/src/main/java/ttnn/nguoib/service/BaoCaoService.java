package ttnn.nguoib.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.Query;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;

import java.util.List;

/**
 * Bao cao cong no (VIEW V_CONGNO_HocPhi), lich su hoc (VIEW V_HOCVIEN_LichSuHoc)
 * va doanh thu (STORED PROCEDURE SP_ThongKeDoanhThu).
 */
public final class BaoCaoService {

    /** Cong no theo hoc vien. Cot: MaHV, HoTen, SDT, MaDK, MaLop, TenKhoa, NgayDangKy, SoTienCanThu, SoTienDaThu, SoTienNo, TrangThai, SoNgay. */
    public List<Object[]> congNo(String tuKhoa) {
        return JpaUtil.read(em -> {
            boolean co = !Convert.blank(tuKhoa);
            String sql = "SELECT MaHV, HoTen, SDT, MaDK, MaLop, TenKhoa, NgayDangKy, SoTienCanThu, SoTienDaThu, "
                    + "SoTienNo, TrangThaiThanhToan, SoNgayKeTuDangKy FROM dbo.V_CONGNO_HocPhi"
                    + (co ? " WHERE (HoTen LIKE :kw ESCAPE '!' OR MaHV LIKE :kw ESCAPE '!' OR MaLop LIKE :kw ESCAPE '!' "
                            + "OR TenKhoa LIKE :kw ESCAPE '!')" : "")
                    + " ORDER BY SoTienNo DESC, MaHV, MaDK";
            Query q = em.createNativeQuery(sql);
            if (co) {
                q.setParameter("kw", Convert.likeContains(tuKhoa));
            }
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]), Convert.str(r[3]),
                            Convert.str(r[4]), Convert.str(r[5]), Convert.date(r[6]), Convert.money(r[7]),
                            Convert.money(r[8]), Convert.money(r[9]), Convert.str(r[10]), Convert.integer(r[11])})
                    .toList();
        });
    }

    /** Lich su hoc cua mot hoc vien. Cot: MaDK, MaLop, TenKhoa, TrangThaiLop, NgayDangKy, DiemCuoiKy, SoTienCanThu, SoTienDaThu, TrangThai. */
    public List<Object[]> lichSuHoc(String maHV) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaDK, MaLop, TenKhoa, TrangThaiLop, NgayDangKy, DiemCuoiKy, SoTienCanThu, SoTienDaThu, "
                        + "TrangThaiThanhToan FROM dbo.V_HOCVIEN_LichSuHoc WHERE MaHV = :ma "
                        + "ORDER BY NgayDangKy DESC, MaDK")
                .setParameter("ma", maHV.trim()).getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]), Convert.str(r[3]),
                        Convert.date(r[4]), Convert.money(r[5]), Convert.money(r[6]), Convert.money(r[7]),
                        Convert.str(r[8])})
                .toList());
    }

    /**
     * Thong ke doanh thu. nhomTheo: THANG | KHOA | THANG_KHOA.
     * Cot: Nam, Thang, MaKH, TenKhoa, SoHoaDon, TongPhaiThu, DoanhThu, ConPhaiThu.
     */
    public List<Object[]> doanhThu(Integer nam, Integer thang, String maKH, String nhomTheo) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_ThongKeDoanhThu");
            q.registerStoredProcedureParameter(1, Integer.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(2, Integer.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(4, String.class, ParameterMode.IN);
            q.setParameter(1, nam);
            q.setParameter(2, thang);
            q.setParameter(3, Convert.blank(maKH) ? null : maKH.trim());
            q.setParameter(4, Convert.blank(nhomTheo) ? "THANG" : nhomTheo);
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.integer(r[0]), Convert.integer(r[1]), Convert.str(r[2]),
                            Convert.str(r[3]), Convert.integer(r[4]), Convert.money(r[5]), Convert.money(r[6]),
                            Convert.money(r[7])})
                    .toList();
        });
    }

    /** Khoa hoc de loc bao cao: {MaKH, TenKhoa}. */
    public List<String[]> khoaHoc() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaKH, TenKhoa FROM dbo.KHOAHOC ORDER BY MaKH").getResultList()).stream()
                .map(r -> new String[] {Convert.str(r[0]), Convert.str(r[1])}).toList());
    }
}
