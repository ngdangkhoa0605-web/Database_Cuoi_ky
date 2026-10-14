package ttnn.nguoid.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.nguoid.entity.BuoiHoc;

import java.time.LocalDate;
import java.util.List;

/**
 * Buoi hoc va lich day (Nguoi D).
 *  - CRUD    : entity BuoiHoc.
 *  - lichDay : STORED PROCEDURE SP_LichDay_GiangVien (lich day thuc te, gom ca buoi day thay).
 */
public final class BuoiHocService {
    public static final String DA_DIEN_RA = "Đã diễn ra";
    public static final String HOAN = "Hoãn";
    public static final String HUY = "Hủy";

    /** Lop (chon lop): ma lop + ten khoa hoc. */
    public List<Muc> dsLop() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT l.MaLop, kh.TenKhoa FROM dbo.LOP AS l JOIN dbo.KHOAHOC AS kh ON kh.MaKH = l.MaKH "
                        + "ORDER BY l.MaLop").getResultList()).stream()
                .map(r -> new Muc(Convert.str(r[0]), Convert.str(r[1]))).toList());
    }

    /** Giang vien dang cong tac (chon nguoi day cho buoi hoc moi). */
    public List<Muc> dsGiangVienDangCongTac() {
        return dsGiangVien(true);
    }

    /** Moi giang vien (xem lich day cua bat ky ai, ke ca nguoi da nghi). */
    public List<Muc> dsGiangVienTatCa() {
        return dsGiangVien(false);
    }

    private List<Muc> dsGiangVien(boolean chiDangCongTac) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaGV, HoTen FROM dbo.GIANGVIEN"
                        + (chiDangCongTac ? " WHERE TrangThai = N'Đang công tác'" : "") + " ORDER BY MaGV")
                .getResultList()).stream()
                .map(r -> new Muc(Convert.str(r[0]), Convert.str(r[1]))).toList());
    }

    /** Cot: MaBuoi, NgayHocThucTe, MaGV_Day, HoTen giang vien day, TrangThaiBuoiHoc. */
    public List<Object[]> theoLop(String maLop) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT b.MaBuoi, b.NgayHocThucTe, b.MaGV_Day, gv.HoTen, b.TrangThaiBuoiHoc "
                        + "FROM dbo.BUOIHOC AS b JOIN dbo.GIANGVIEN AS gv ON gv.MaGV = b.MaGV_Day "
                        + "WHERE b.MaLop = :ml ORDER BY b.NgayHocThucTe, b.MaBuoi")
                .setParameter("ml", maLop).getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.date(r[1]), Convert.str(r[2]),
                        Convert.str(r[3]), Convert.str(r[4])})
                .toList());
    }

    /** Cac buoi DA DIEN RA cua lop (chi nhung buoi nay moi diem danh duoc). Moi muc: MaBuoi + ngay. */
    public List<Muc> buoiDaDienRa(String maLop) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT MaBuoi, NgayHocThucTe FROM dbo.BUOIHOC WHERE MaLop = :ml AND TrangThaiBuoiHoc = N'Đã diễn ra' "
                        + "ORDER BY NgayHocThucTe, MaBuoi").setParameter("ml", maLop).getResultList()).stream()
                .map(r -> new Muc(Convert.str(r[0]), ttnn.common.UiUtil.formatDate(Convert.date(r[1]))))
                .toList());
    }

    /** Them buoi hoc (ma tu sinh BH0001...). Tra ve ma buoi vua tao. */
    public String them(String maLop, String maGV, LocalDate ngay, String trangThai) {
        kiemTra(maGV, ngay, trangThai);
        return JpaUtil.inTx(em -> {
            Object so = em.createNativeQuery(
                    "SELECT ISNULL(MAX(TRY_CAST(SUBSTRING(MaBuoi, 3, 6) AS INT)), 0) + 1 "
                            + "FROM dbo.BUOIHOC WITH (UPDLOCK, HOLDLOCK) WHERE MaBuoi LIKE 'BH[0-9]%'").getSingleResult();
            int n = Convert.integer(so);
            String ma = "BH" + (n > 9999 ? String.valueOf(n) : String.format("%04d", n));
            if (ma.length() > 8) {
                throw new IllegalStateException("Đã hết mã buổi học.");
            }
            em.persist(new BuoiHoc(ma, maLop, maGV.trim(), ngay, trangThai));
            em.flush();
            return ma;
        });
    }

    public void capNhat(String maBuoi, String maGV, LocalDate ngay, String trangThai) {
        kiemTra(maGV, ngay, trangThai);
        JpaUtil.inTx(em -> {
            BuoiHoc b = em.find(BuoiHoc.class, maBuoi);
            if (b == null) {
                throw new IllegalArgumentException("Buổi học " + maBuoi + " không còn tồn tại.");
            }
            b.setMaGVDay(maGV.trim());
            b.setNgayHocThucTe(ngay);
            b.setTrangThaiBuoiHoc(trangThai);
            em.flush();
            return null;
        });
    }

    private static void kiemTra(String maGV, LocalDate ngay, String trangThai) {
        if (Convert.blank(maGV)) {
            throw new IllegalArgumentException("Hãy chọn giảng viên đứng lớp.");
        }
        if (ngay == null) {
            throw new IllegalArgumentException("Ngày học không được để trống.");
        }
        if (!List.of(DA_DIEN_RA, HOAN, HUY).contains(trangThai)) {
            throw new IllegalArgumentException("Trạng thái buổi học không hợp lệ.");
        }
    }

    /**
     * SP_LichDay_GiangVien. tuNgay/denNgay null = thang hien tai.
     * Cot: MaBuoi, Ngay, Thu, MaLop, TenKhoa, VaiTro, TrangThai, GioBatDau, GioKetThuc, Phong.
     */
    public List<Object[]> lichDay(String maGV, LocalDate tuNgay, LocalDate denNgay) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_LichDay_GiangVien");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @MaGV
            q.registerStoredProcedureParameter(2, LocalDate.class, ParameterMode.IN);   // @TuNgay
            q.registerStoredProcedureParameter(3, LocalDate.class, ParameterMode.IN);   // @DenNgay
            q.setParameter(1, maGV);
            q.setParameter(2, tuNgay);
            q.setParameter(3, denNgay);
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.date(r[1]), thu(Convert.integer(r[2])),
                            Convert.str(r[3]), Convert.str(r[4]), Convert.str(r[5]), Convert.str(r[6]),
                            gio(r[7]), gio(r[8]), Convert.str(r[9])})
                    .toList();
        });
    }

    /** Thu 1 = Chu Nhat ... 7 = Thu 7 (cung quy uoc LICHHOC.Thu). */
    private static String thu(Integer t) {
        if (t == null) {
            return null;
        }
        return t == 1 ? "Chủ nhật" : "Thứ " + t;
    }

    /** TIME tu JDBC co the la java.sql.Time hoac LocalTime: cat lay HH:mm. */
    private static String gio(Object o) {
        if (o == null) {
            return null;
        }
        String s = o.toString();
        return s.length() >= 5 ? s.substring(0, 5) : s;
    }
}
