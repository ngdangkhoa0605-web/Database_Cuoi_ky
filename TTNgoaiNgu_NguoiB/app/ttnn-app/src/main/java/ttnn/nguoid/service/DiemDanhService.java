package ttnn.nguoid.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;

import java.math.BigDecimal;
import java.util.List;

/**
 * Diem danh va bao cao chuyen can (Nguoi D).
 *  - danhSach       : VIEW V_CHUYEN_CAN (ben trong dung ham FN_TyLeChuyenCan) noi voi DIEMDANH.
 *  - luu            : STORED PROCEDURE co giao dich SP_DiemDanh_CaLop (truyen ca lop dang JSON).
 *  - thongKeLop     : STORED PROCEDURE SP_ThongKeChuyenCan_Lop.
 * Trigger TRG_DIEMDANH_DungLop bao ve o tang CSDL (dung lop, buoi da dien ra).
 */
public final class DiemDanhService {
    public static final String CO_MAT = "Có mặt";
    public static final String VANG_CO_PHEP = "Vắng có phép";
    public static final String VANG_KHONG_PHEP = "Vắng không phép";
    public static final String[] TRANG_THAI = {CO_MAT, VANG_CO_PHEP, VANG_KHONG_PHEP};

    /** Mot dong gui len SP_DiemDanh_CaLop. */
    public record MucDiemDanh(String maDK, String trangThai, String ghiChu) { }

    /** Ket qua ghi: so dong them moi va so dong cap nhat. */
    public record KetQua(int soThem, int soCapNhat) { }

    /**
     * Hoc vien cua lop kem diem danh hien tai cua buoi (trang thai null = chua diem danh).
     * Cot: MaDK, MaHV, HoTenHV, TrangThaiDiemDanh, GhiChu, TyLeCoMat.
     */
    public List<Object[]> danhSach(String maBuoi) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                "SELECT v.MaDK, v.MaHV, v.HoTenHV, dd.TrangThaiDiemDanh, dd.GhiChu, v.TyLeCoMat "
                        + "FROM dbo.BUOIHOC AS b "
                        + "JOIN dbo.V_CHUYEN_CAN AS v ON v.MaLop = b.MaLop "
                        + "LEFT JOIN dbo.DIEMDANH AS dd ON dd.MaBuoi = b.MaBuoi AND dd.MaDK = v.MaDK "
                        + "WHERE b.MaBuoi = :mb ORDER BY v.MaHV").setParameter("mb", maBuoi).getResultList()).stream()
                .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                        Convert.str(r[3]), Convert.str(r[4]), Convert.money(r[5])})
                .toList());
    }

    /** Ghi diem danh ca buoi: tat ca hoac khong gi ca (loi mot dong thi huy ca buoi, thong bao neu ro dong sai). */
    public KetQua luu(String maBuoi, List<MucDiemDanh> ds) {
        if (Convert.blank(maBuoi)) {
            throw new IllegalArgumentException("Hãy chọn buổi học cần điểm danh.");
        }
        if (ds == null || ds.isEmpty()) {
            throw new IllegalArgumentException("Lớp chưa có học viên nào để điểm danh.");
        }
        String json = toJson(ds);
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_DiemDanh_CaLop");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);   // @MaBuoi
            q.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);   // @DanhSach (JSON)
            q.setParameter(1, maBuoi);
            q.setParameter(2, json);
            Object[] r = Convert.row(q.getSingleResult());
            return new KetQua(Convert.integer(r[1]), Convert.integer(r[2]));
        });
    }

    /**
     * SP_ThongKeChuyenCan_Lop. Cot: MaDK, MaHV, HoTenHV, SoLuotDiemDanh, SoCoMat, SoVangCoPhep,
     * SoVangKhongPhep, TyLeCoMat, TyLeCoMatLop, CanhBao (Boolean).
     */
    public List<Object[]> thongKeLop(String maLop, BigDecimal nguong) {
        return JpaUtil.inTx(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_ThongKeChuyenCan_Lop");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);       // @MaLop
            q.registerStoredProcedureParameter(2, BigDecimal.class, ParameterMode.IN);   // @NguongCanhBao
            q.setParameter(1, maLop);
            q.setParameter(2, nguong);
            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new Object[] {Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                            Convert.integer(r[3]), Convert.integer(r[4]), Convert.integer(r[5]),
                            Convert.integer(r[6]), Convert.money(r[7]), Convert.money(r[8]), bool(r[9])})
                    .toList();
        });
    }

    private static Boolean bool(Object o) {
        if (o == null) {
            return Boolean.FALSE;
        }
        if (o instanceof Boolean b) {
            return b;
        }
        return ((Number) o).intValue() != 0;
    }

    /** Dung chuoi JSON [{"MaDK":..,"TrangThai":..,"GhiChu":..}] cho OPENJSON, co thoat ky tu dac biet. */
    static String toJson(List<MucDiemDanh> ds) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < ds.size(); i++) {
            MucDiemDanh m = ds.get(i);
            if (i > 0) {
                sb.append(',');
            }
            sb.append("{\"MaDK\":").append(quote(m.maDK()))
              .append(",\"TrangThai\":").append(quote(m.trangThai()))
              .append(",\"GhiChu\":").append(quote(m.ghiChu())).append('}');
        }
        return sb.append(']').toString();
    }

    private static String quote(String s) {
        if (s == null || s.isBlank()) {
            return "null";
        }
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.trim().toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.append('"').toString();
    }
}
