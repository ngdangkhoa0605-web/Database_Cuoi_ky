package ttnn.nguoid.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;
import ttnn.nguoid.entity.GiangVien;

import java.util.List;

/**
 * Giang vien (Nguoi D).
 *  - CRUD            : entity GiangVien (trigger TRG_GIANGVIEN_NghiViec chay khi doi trang thai).
 *  - taiTrong        : VIEW V_GIANGVIEN_TaiTrong.
 *  - nguoiNhan       : TABLE-VALUED FUNCTION FN_DSGiangVien_TheoNN.
 *  - banGiaoVaChoNghi: STORED PROCEDURE co giao dich SP_BanGiaoLop_KhiGVNghi.
 */
public final class GiangVienService {
    public static final String DANG_CONG_TAC = "Đang công tác";
    public static final String TAM_NGHI = "Tạm nghỉ";
    public static final String DA_NGHI_VIEC = "Đã nghỉ việc";

    public List<Muc> dsNgonNgu() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaNN, TenNN FROM dbo.NGONNGU ORDER BY MaNN").getResultList()).stream()
                .map(r -> new Muc(Convert.str(r[0]), Convert.str(r[1]))).toList());
    }

    /** Cot: MaGV, HoTen, MaNN, SDT, Email, TrangThai. */
    public List<Object[]> danhSach() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaGV, HoTen, MaNN, SDT, Email, TrangThai FROM dbo.GIANGVIEN ORDER BY MaGV").getResultList())
                .stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                        Convert.str(r[3]), Convert.str(r[4]), Convert.str(r[5])})
                .toList());
    }

    /** Cot: MaGV, HoTen, TenNN, TrangThai, SoLopChinh, SoLopDangPhuTrach, SoBuoiDaDay, SoBuoiDayThay. */
    public List<Object[]> taiTrong() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaGV, HoTen, TenNN, TrangThai, SoLopChinh, SoLopDangPhuTrach, SoBuoiDaDay, SoBuoiDayThay "
                        + "FROM dbo.V_GIANGVIEN_TaiTrong ORDER BY MaGV").getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]), Convert.str(r[3]),
                        Convert.integer(r[4]), Convert.integer(r[5]), Convert.integer(r[6]), Convert.integer(r[7])})
                .toList());
    }

    /** Giang vien dang cong tac cua mot ngon ngu. Cot: MaGV, HoTen, SDT, Email, SoLopDangPhuTrach. */
    public List<Object[]> nguoiNhan(String maNN) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaGV, HoTen, SDT, Email, SoLopDangPhuTrach FROM dbo.FN_DSGiangVien_TheoNN(:nn) ORDER BY MaGV")
                .setParameter("nn", maNN.trim()).getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                        Convert.str(r[3]), Convert.integer(r[4])})
                .toList());
    }

    public GiangVien tim(String maGV) {
        return JpaUtil.read(em -> em.find(GiangVien.class, maGV));
    }

    /** Them giang vien moi (ma tu sinh GV01, GV02...). Tra ve ma vua tao. */
    public String them(String hoTen, String maNN, String sdt, String email) {
        String ten = Validator.required(hoTen, "Họ tên", 40);
        String sd = Validator.phone(sdt);
        String mail = Validator.email(email);
        if (Convert.blank(maNN)) {
            throw new IllegalArgumentException("Hãy chọn ngôn ngữ giảng dạy.");
        }
        return JpaUtil.inTx(em -> {
            Object so = em.createNativeQuery(
                    "SELECT ISNULL(MAX(TRY_CAST(SUBSTRING(MaGV, 3, 2) AS INT)), 0) + 1 "
                            + "FROM dbo.GIANGVIEN WITH (UPDLOCK, HOLDLOCK) WHERE MaGV LIKE 'GV[0-9][0-9]'")
                    .getSingleResult();
            int n = Convert.integer(so);
            if (n > 99) {
                throw new IllegalStateException("Đã hết mã giảng viên (GV01 đến GV99).");
            }
            String ma = String.format("GV%02d", n);
            em.persist(new GiangVien(ma, ten, maNN.trim(), sd, mail, DANG_CONG_TAC));
            em.flush();
            return ma;
        });
    }

    /**
     * Sua ho so. trangThai co the khac trang thai cu: neu giang vien con la GV chinh cua lop dang hoat dong
     * ma doi sang Tam nghi / Da nghi viec thi TRG_GIANGVIEN_NghiViec tu choi (loi 54003).
     */
    public void capNhat(String maGV, String hoTen, String maNN, String sdt, String email, String trangThai) {
        String ten = Validator.required(hoTen, "Họ tên", 40);
        String sd = Validator.phone(sdt);
        String mail = Validator.email(email);
        JpaUtil.inTx(em -> {
            GiangVien gv = em.find(GiangVien.class, maGV);
            if (gv == null) {
                throw new IllegalArgumentException("Giảng viên " + maGV + " không còn tồn tại.");
            }
            gv.setHoTen(ten);
            gv.setMaNN(maNN.trim());
            gv.setSdt(sd);
            gv.setEmail(mail);
            gv.setTrangThai(trangThai);
            em.flush();
            return null;
        });
    }

    /**
     * Cho giang vien nghi va ban giao cac lop dang tuyen sinh/dang hoc cho nguoi nhan.
     * maMoi co the null khi khong con lop nao can ban giao. Tra ve so lop da ban giao.
     */
    public int banGiaoVaChoNghi(String maNghi, String maMoi, String trangThaiMoi) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_BanGiaoLop_KhiGVNghi");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);   // @MaGV_Nghi
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);   // @MaGV_Moi
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);   // @TrangThaiMoi
            q.setParameter(1, maNghi);
            q.setParameter(2, maMoi);
            q.setParameter(3, trangThaiMoi);
            Object[] r = Convert.row(q.getSingleResult());
            return Convert.integer(r[2]);
        });
    }
}
