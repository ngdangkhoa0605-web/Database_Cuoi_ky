package ttnn.kien.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;
import ttnn.kien.entity.KhoaHoc;

import java.math.BigDecimal;
import java.util.List;

/**
 * Nghiep vu khoa hoc (Kien).
 *  - timKiem    : STORED PROCEDURE SP_TimKiemKhoaHoc (ten / ngon ngu / trang thai / khoang hoc phi).
 *  - them       : STORED PROCEDURE SP_ThemKhoaHoc_VaNgonNgu (giao dich: them ngon ngu moi neu can + khoa hoc;
 *                 ma KHxxxx sinh trong thu tuc) - la DUONG DUY NHAT de them khoa hoc.
 *  - sua        : entity KhoaHoc (HocPhi khong nam trong cau UPDATE); trigger TRG_KHOAHOC_NgungTuyenSinh,
 *                 TRG_KHOAHOC_KhoaNgonNgu kiem tra -> loi 51001 / 51002 hien nguyen van.
 *  - doiHocPhi  : STORED PROCEDURE SP_CapNhatHocPhiKhoa (giao dich: hoc phi + hoa don chua thanh toan).
 *  - xoa        : entity KhoaHoc; khoa da co lop -> FK_LOP_KHOAHOC -> DbErrors bao ro.
 * Moi thu tuc goi trong JpaUtil.inTx: thu tuc thay @@TRANCOUNT > 0 nen dung SAVE TRANSACTION (mau long an toan).
 */
public final class KhoaHocService {

    public static final String DANG_GIANG_DAY = "Đang giảng dạy";
    public static final String NGUNG_TUYEN_SINH = "Ngừng tuyển sinh";
    public static final List<String> TRANG_THAI = List.of(DANG_GIANG_DAY, NGUNG_TUYEN_SINH);
    /** Gia tri trinh do dang dung trong du lieu mau (o nhap van cho go gia tri khac, toi da 10 ky tu). */
    public static final List<String> TRINH_DO_GOI_Y = List.of("So cap", "Trung cap", "Cao cap");

    /** Mot dong ket qua tim kiem (cot cua SP_TimKiemKhoaHoc). */
    public record KhoaHocRow(String maKH, String tenKhoa, String maNN, String tenNN, String trinhDo,
                             Integer soBuoi, BigDecimal hocPhi, String trangThai) {
        public Object[] toRow() {
            return new Object[] {maKH, tenKhoa, maNN, tenNN, trinhDo, soBuoi, hocPhi, trangThai};
        }
    }

    public record KetQuaThem(String maKH, boolean daThemNgonNgu) {
    }

    /** Tieu chi de trong = bo qua; tat ca de trong = tra ve tat ca khoa hoc. */
    public List<KhoaHocRow> timKiem(String tenKhoa, String maNN, String trangThai,
                                    BigDecimal hocPhiMin, BigDecimal hocPhiMax) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_TimKiemKhoaHoc");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @TenKhoa
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);      // @MaNN
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);      // @TrangThai
            q.registerStoredProcedureParameter(4, BigDecimal.class, ParameterMode.IN);  // @HocPhiMin
            q.registerStoredProcedureParameter(5, BigDecimal.class, ParameterMode.IN);  // @HocPhiMax
            q.setParameter(1, Convert.blank(tenKhoa) ? null : tenKhoa.trim());
            q.setParameter(2, Convert.blank(maNN) ? null : maNN.trim());
            q.setParameter(3, Convert.blank(trangThai) ? null : trangThai);
            q.setParameter(4, hocPhiMin);
            q.setParameter(5, hocPhiMax);
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new KhoaHocRow(Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                            Convert.str(r[3]), Convert.str(r[4]), Convert.integer(r[5]), Convert.money(r[6]),
                            Convert.str(r[7])))
                    .toList();
        });
    }

    public KhoaHoc tim(String maKH) {
        return JpaUtil.read(em -> em.find(KhoaHoc.class, maKH));
    }

    /**
     * Them khoa hoc qua SP_ThemKhoaHoc_VaNgonNgu.
     * tenNNMoi: null neu maNN la ngon ngu da co; bat buoc khi maNN la ngon ngu moi (thu tuc kiem tra).
     */
    public KetQuaThem them(String maNN, String tenNNMoi, String tenKhoa, String trinhDo,
                           Integer soBuoi, BigDecimal hocPhi) {
        String ma = NgonNguService.chuanHoaMa(maNN);
        String tenNN = Convert.blank(tenNNMoi) ? null : Validator.required(tenNNMoi, "Tên ngôn ngữ mới", 30);
        String ten = Validator.required(tenKhoa, "Tên khóa học", 50);
        String td = Validator.required(trinhDo, "Trình độ", 10);
        int sb = soBuoiHopLe(soBuoi);
        if (hocPhi == null) {
            throw new IllegalArgumentException("Học phí không được để trống.");
        }
        BigDecimal hp = Validator.nonNegativeMoney(hocPhi, "Học phí");

        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_ThemKhoaHoc_VaNgonNgu");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @MaNN
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);      // @TenNN
            q.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);      // @TenKhoa
            q.registerStoredProcedureParameter(4, String.class, ParameterMode.IN);      // @TrinhDo
            q.registerStoredProcedureParameter(5, Integer.class, ParameterMode.IN);     // @SoBuoi
            q.registerStoredProcedureParameter(6, BigDecimal.class, ParameterMode.IN);  // @HocPhi
            q.registerStoredProcedureParameter(7, String.class, ParameterMode.OUT);     // @MaKH
            q.registerStoredProcedureParameter(8, Boolean.class, ParameterMode.OUT);    // @DaThemNgonNgu
            q.setParameter(1, ma);
            q.setParameter(2, tenNN);
            q.setParameter(3, ten);
            q.setParameter(4, td);
            q.setParameter(5, sb);
            q.setParameter(6, hp);
            q.execute();
            Object daThem = q.getOutputParameterValue(8);
            return new KetQuaThem(Convert.str(q.getOutputParameterValue(7)),
                    daThem instanceof Boolean b ? b : daThem instanceof Number n && n.intValue() == 1);
        });
    }

    /** Sua thong tin (khong gom hoc phi). Trigger cua KHOAHOC kiem tra trang thai / doi ngon ngu. */
    public void sua(String maKH, String tenKhoa, String maNN, String trinhDo, Integer soBuoi, String trangThai) {
        String ten = Validator.required(tenKhoa, "Tên khóa học", 50);
        String ma = NgonNguService.chuanHoaMa(maNN);
        String td = Validator.required(trinhDo, "Trình độ", 10);
        int sb = soBuoiHopLe(soBuoi);
        if (!TRANG_THAI.contains(trangThai)) {
            throw new IllegalArgumentException("Trạng thái khóa học không hợp lệ.");
        }
        JpaUtil.inTx(em -> {
            KhoaHoc k = em.find(KhoaHoc.class, maKH);
            if (k == null) {
                throw new IllegalStateException("Khóa học " + maKH + " không còn tồn tại.");
            }
            k.setTenKhoa(ten);
            k.setMaNN(ma);
            k.setTrinhDo(td);
            k.setSoBuoi(sb);
            k.setTrangThai(trangThai);
            em.flush();
            return null;
        });
    }

    /** Doi hoc phi qua SP_CapNhatHocPhiKhoa. Tra ve so hoa don chua thanh toan da duoc cap nhat theo. */
    public int doiHocPhi(String maKH, BigDecimal hocPhiMoi) {
        if (Convert.blank(maKH)) {
            throw new IllegalArgumentException("Hãy chọn khóa học cần đổi học phí.");
        }
        if (hocPhiMoi == null) {
            throw new IllegalArgumentException("Học phí mới không được để trống.");
        }
        BigDecimal hp = Validator.nonNegativeMoney(hocPhiMoi, "Học phí mới");
        Integer n = JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_CapNhatHocPhiKhoa");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);      // @MaKH
            q.registerStoredProcedureParameter(2, BigDecimal.class, ParameterMode.IN);  // @HocPhiMoi
            q.registerStoredProcedureParameter(3, Integer.class, ParameterMode.OUT);    // @SoHoaDonCapNhat
            q.setParameter(1, maKH.trim());
            q.setParameter(2, hp);
            q.execute();
            return Convert.integer(q.getOutputParameterValue(3));
        });
        return n == null ? 0 : n;
    }

    public void xoa(String maKH) {
        JpaUtil.inTx(em -> {
            KhoaHoc k = em.find(KhoaHoc.class, maKH);
            if (k == null) {
                throw new IllegalStateException("Khóa học " + maKH + " không còn tồn tại.");
            }
            em.remove(k);
            em.flush();
            return null;
        });
    }

    private static int soBuoiHopLe(Integer soBuoi) {
        if (soBuoi == null || soBuoi < 1 || soBuoi > 255) {
            throw new IllegalArgumentException("Số buổi phải từ 1 đến 255.");
        }
        return soBuoi;
    }
}
