package ttnn.nguoib.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.Query;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Nghiep vu hoa don va thu tien.
 *  - timHoaDon : native query co goi SCALAR FUNCTION FN_TinhCongNo
 *  - thuTien   : STORED PROCEDURE SP_ThanhToanHocPhi (chong thu vuot, khoa dong hoa don)
 */
public final class HoaDonService {

    public record KetQuaThanhToan(BigDecimal conNo, String trangThai) {
    }

    /**
     * Danh sach hoa don. Cot: MaHD, MaDK, MaHV, HoTen, MaLop, SoTienCanThu, SoTienDaThu, CongNo, NgayThanhToan, TrangThai.
     *
     * @param tuKhoa   tim theo ma HD / ma DK / ma HV / ho ten (khop mot phan), rong = tat ca
     * @param trangThai trang thai thanh toan chinh xac, rong = tat ca
     * @param chiConNo  true = chi hoa don con no
     */
    public List<Object[]> timHoaDon(String tuKhoa, String trangThai, boolean chiConNo) {
        return JpaUtil.read(em -> {
            StringBuilder sql = new StringBuilder(
                    "SELECT hd.MaHD, hd.MaDK, hv.MaHV, hv.HoTen, dk.MaLop, hd.SoTienCanThu, hd.SoTienDaThu, "
                            + "dbo.FN_TinhCongNo(hd.MaDK) AS CongNo, hd.NgayThanhToan, hd.TrangThaiThanhToan "
                            + "FROM dbo.HOADON hd "
                            + "JOIN dbo.DANGKY dk ON dk.MaDK = hd.MaDK "
                            + "JOIN dbo.HOCVIEN hv ON hv.MaHV = dk.MaHV WHERE 1 = 1");
            boolean coTuKhoa = !Convert.blank(tuKhoa);
            boolean coTrangThai = !Convert.blank(trangThai);
            if (coTuKhoa) {
                sql.append(" AND (hd.MaHD LIKE :kw ESCAPE '!' OR hd.MaDK LIKE :kw ESCAPE '!' "
                        + "OR hv.MaHV LIKE :kw ESCAPE '!' OR hv.HoTen LIKE :kw ESCAPE '!')");
            }
            if (coTrangThai) {
                sql.append(" AND hd.TrangThaiThanhToan = :tt");
            }
            if (chiConNo) {
                sql.append(" AND hd.SoTienDaThu < hd.SoTienCanThu");
            }
            sql.append(" ORDER BY hd.MaHD");
            Query q = em.createNativeQuery(sql.toString());
            if (coTuKhoa) {
                q.setParameter("kw", Convert.likeContains(tuKhoa));
            }
            if (coTrangThai) {
                q.setParameter("tt", trangThai);
            }
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]), Convert.str(r[3]),
                            Convert.str(r[4]), Convert.money(r[5]), Convert.money(r[6]), Convert.money(r[7]),
                            Convert.date(r[8]), Convert.str(r[9])})
                    .toList();
        });
    }

    public KetQuaThanhToan thuTien(String maHD, BigDecimal soTien, LocalDate ngayThu) {
        if (Convert.blank(maHD)) {
            throw new IllegalArgumentException("Hãy chọn hóa đơn cần thu tiền.");
        }
        Validator.positiveMoney(soTien, "Số tiền thu");
        Validator.notFuture(ngayThu, "Ngày thu tiền");
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_ThanhToanHocPhi");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @MaHD
            q.registerStoredProcedureParameter(2, BigDecimal.class, ParameterMode.IN);  // @SoTienThu
            q.registerStoredProcedureParameter(3, LocalDate.class, ParameterMode.IN);   // @NgayThu
            q.registerStoredProcedureParameter(4, BigDecimal.class, ParameterMode.OUT); // @SoTienConNo
            q.registerStoredProcedureParameter(5, String.class, ParameterMode.OUT);     // @TrangThai
            q.setParameter(1, maHD.trim());
            q.setParameter(2, soTien);
            q.setParameter(3, ngayThu);
            q.execute();
            return new KetQuaThanhToan(Convert.money(q.getOutputParameterValue(4)),
                                       Convert.str(q.getOutputParameterValue(5)));
        });
    }
}
