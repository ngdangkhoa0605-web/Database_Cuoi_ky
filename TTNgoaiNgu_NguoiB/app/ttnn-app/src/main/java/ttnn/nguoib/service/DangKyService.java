package ttnn.nguoib.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;
import ttnn.nguoib.entity.DangKy;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Nghiep vu dang ky hoc.
 *  - dangKy      : STORED PROCEDURE SP_DangKy_VaTaoHoaDon (them dang ky + hoa don, khoa chong tranh chap cho cuoi)
 *  - huyDangKy   : STORED PROCEDURE SP_HuyDangKy
 *  - lichSuHocVien: TABLE-VALUED FUNCTION FN_DSDangKy_HocVien
 *  - capNhatDiem : cap nhat entity DangKy (trigger TRG_DANGKY_SiSo chay tu dong khi UPDATE)
 *  - lopDangMo   : danh sach lop de chon (chi DOC bang LOP/KHOAHOC cua nguoi khac bang native query)
 */
public final class DangKyService {

    public record KetQuaDangKy(String maDK, String maHD) {
    }

    /** Mot lop co the dang ky (hien trong combo). */
    public record LopMo(String maLop, String tenKhoa, String trangThai, int siSoToiDa, int daDangKy, BigDecimal hocPhi) {
        public int conCho() {
            return siSoToiDa - daDangKy;
        }

        @Override
        public String toString() {
            return maLop + " - " + tenKhoa + " (" + daDangKy + "/" + siSoToiDa + ", " + trangThai + ")";
        }
    }

    public KetQuaDangKy dangKy(String maHV, String maLop, LocalDate ngayDangKy, BigDecimal soTienThuNgay) {
        if (Convert.blank(maHV)) {
            throw new IllegalArgumentException("Hãy chọn học viên cần đăng ký.");
        }
        if (Convert.blank(maLop)) {
            throw new IllegalArgumentException("Hãy chọn lớp cần đăng ký.");
        }
        Validator.notFuture(ngayDangKy, "Ngày đăng ký");
        BigDecimal thu = Validator.nonNegativeMoney(soTienThuNgay, "Số tiền thu ngay");

        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_DangKy_VaTaoHoaDon");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @MaHV
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);      // @MaLop
            q.registerStoredProcedureParameter(3, LocalDate.class, ParameterMode.IN);   // @NgayDangKy
            q.registerStoredProcedureParameter(4, BigDecimal.class, ParameterMode.IN);  // @SoTienThuNgay
            q.registerStoredProcedureParameter(5, String.class, ParameterMode.OUT);     // @MaDK
            q.registerStoredProcedureParameter(6, String.class, ParameterMode.OUT);     // @MaHD
            q.setParameter(1, maHV.trim());
            q.setParameter(2, maLop.trim());
            q.setParameter(3, ngayDangKy);
            q.setParameter(4, thu);
            q.execute();
            return new KetQuaDangKy(Convert.str(q.getOutputParameterValue(5)),
                                    Convert.str(q.getOutputParameterValue(6)));
        });
    }

    public void huyDangKy(String maDK) {
        if (Convert.blank(maDK)) {
            throw new IllegalArgumentException("Hãy chọn đăng ký cần hủy.");
        }
        JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_HuyDangKy");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
            q.setParameter(1, maDK.trim());
            q.execute();
            return null;
        });
    }

    /**
     * Lich su dang ky cua mot hoc vien (FN_DSDangKy_HocVien). Cot tra ve:
     * MaDK, MaLop, TenKhoa, TrangThaiLop, NgayDangKy, DiemCuoiKy, MaHD, SoTienCanThu, SoTienDaThu, CongNo, TrangThaiThanhToan
     */
    public List<Object[]> lichSuHocVien(String maHV) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaDK, MaLop, TenKhoa, TrangThaiLop, NgayDangKy, DiemCuoiKy, MaHD, "
                        + "SoTienCanThu, SoTienDaThu, CongNo, TrangThaiThanhToan "
                        + "FROM dbo.FN_DSDangKy_HocVien(:ma) ORDER BY NgayDangKy DESC, MaDK")
                .setParameter("ma", maHV.trim()).getResultList())
                .stream().map(DangKyService::chuanHoaDong).toList());
    }

    private static Object[] chuanHoaDong(Object[] r) {
        return new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]), Convert.str(r[3]),
                Convert.date(r[4]), Convert.money(r[5]), Convert.str(r[6]),
                Convert.money(r[7]), Convert.money(r[8]), Convert.money(r[9]), Convert.str(r[10])};
    }

    /** Cap nhat (hoac xoa, neu diem == null) diem cuoi ky cua mot dang ky. */
    public void capNhatDiem(String maDK, BigDecimal diem) {
        BigDecimal d = Validator.score(diem);
        JpaUtil.inTx(em -> {
            DangKy dk = em.find(DangKy.class, maDK);
            if (dk == null) {
                throw new IllegalStateException("Đăng ký " + maDK + " không còn tồn tại.");
            }
            dk.setDiemCuoiKy(d);
            em.flush();
            return null;
        });
    }

    /** Lop dang tuyen sinh / dang hoc thuoc khoa hoc dang giang day (chi doc). */
    public List<LopMo> lopDangMo() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT l.MaLop, kh.TenKhoa, l.TrangThai, l.SiSoToiDa, "
                        + "(SELECT COUNT(*) FROM dbo.DANGKY dk WHERE dk.MaLop = l.MaLop) AS DaDangKy, kh.HocPhi "
                        + "FROM dbo.LOP l JOIN dbo.KHOAHOC kh ON kh.MaKH = l.MaKH "
                        + "WHERE l.TrangThai IN (N'Đang tuyển sinh', N'Đang học') AND kh.TrangThai = N'Đang giảng dạy' "
                        + "ORDER BY l.MaLop").getResultList())
                .stream()
                .map(r -> new LopMo(Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                        Convert.integer(r[3]), Convert.integer(r[4]), Convert.money(r[5])))
                .toList());
    }
}
