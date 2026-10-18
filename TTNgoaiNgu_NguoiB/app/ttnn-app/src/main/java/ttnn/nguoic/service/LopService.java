package ttnn.nguoic.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;

import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;

public final class LopService {
    public record LopRow(String maLop, String maKH, String tenKhoa, String maGV,
                         String tenGiangVien, Date ngayKhaiGiang, Date ngayKetThuc,
                         Integer siSoHienTai, Integer siSoToiDa, BigDecimal tyLeLapDay,
                         String trangThai) {
        public Object[] toRow() {
            return new Object[]{maLop, maKH, tenKhoa, maGV, tenGiangVien,
                    ngayKhaiGiang, ngayKetThuc, siSoHienTai, siSoToiDa, tyLeLapDay, trangThai};
        }
    }

    public List<LopRow> timKiem(String maKH, String maGV, String trangThai,
                                Date tuNgay, Date denNgay) {
        return JpaUtil.read(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_TimKiemLop");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(4, Date.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(5, Date.class, ParameterMode.IN);
            q.setParameter(1, blankToNull(maKH));
            q.setParameter(2, blankToNull(maGV));
            q.setParameter(3, blankToNull(trangThai));
            q.setParameter(4, tuNgay);
            q.setParameter(5, denNgay);
            return Convert.rows(q.getResultList()).stream().map(r -> new LopRow(
                    Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                    Convert.str(r[3]), Convert.str(r[4]),
                    r[5] == null ? null : Date.valueOf(r[5].toString()),
                    r[6] == null ? null : Date.valueOf(r[6].toString()),
                    Convert.integer(r[7]), Convert.integer(r[8]),
                    Convert.money(r[9]), Convert.str(r[10])
            )).toList();
        });
    }

    public Integer siSoHienTai(String maLop) {
        return JpaUtil.read(em -> Convert.integer(
                em.createNativeQuery("SELECT dbo.FN_SiSoHienTai(:maLop)")
                        .setParameter("maLop", maLop.trim()).getSingleResult()));
    }

    public void ketThucLop(String maLop) {
        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException("Hãy chọn lớp cần kết thúc.");
        }
        JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_KetThucLop");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
            q.setParameter(1, maLop.trim());
            q.execute();
            return null;
        });
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
