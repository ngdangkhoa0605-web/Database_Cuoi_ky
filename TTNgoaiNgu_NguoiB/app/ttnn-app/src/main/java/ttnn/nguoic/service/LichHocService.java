package ttnn.nguoic.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;
import ttnn.common.Validator;

import java.sql.Time;
import java.util.List;

public final class LichHocService {
    public record LichRow(String maLich, String maLop, String maKH, String tenKhoa,
                          String tenGiangVien, Integer thu, String tenThu,
                          Time gioBatDau, Time gioKetThuc, String phongHoc, String trangThaiLop) {
        public Object[] toRow() {
            return new Object[]{maLich, maLop, maKH, tenKhoa, tenGiangVien, thu,
                    tenThu, gioBatDau, gioKetThuc, phongHoc, trangThaiLop};
        }
    }

    public List<LichRow> lichTuan() {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                        "SELECT MaLich, MaLop, MaKH, TenKhoa, TenGiangVien, Thu, TenThu, " +
                                "GioBatDau, GioKetThuc, PhongHoc, TrangThaiLop " +
                                "FROM dbo.V_LICH_HOC_TUAN ORDER BY Thu, GioBatDau").getResultList())
                .stream().map(LichHocService::mapRow).toList());
    }

    public List<LichRow> theoPhong(String phongHoc, Integer thu) {
        if (phongHoc == null || phongHoc.isBlank()) {
            throw new IllegalArgumentException("Phòng học không được để trống.");
        }
        return JpaUtil.read(em -> {
            StoredProcedureQuery q = em.createStoredProcedureQuery("dbo.SP_LichHoc_TheoPhong");
            q.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(2, Integer.class, ParameterMode.IN);
            q.setParameter(1, phongHoc.trim());
            q.setParameter(2, thu);
            return Convert.rows(q.getResultList()).stream().map(r -> new LichRow(
                    Convert.str(r[5]), Convert.str(r[6]), null, Convert.str(r[7]),
                    null, Convert.integer(r[1]), Convert.str(r[2]),
                    toTime(r[3]), toTime(r[4]), Convert.str(r[0]), Convert.str(r[8])
            )).toList();
        });
    }

    public List<LichRow> cuaLop(String maLop) {
        return JpaUtil.read(em -> Convert.rows(em.createNativeQuery(
                                "SELECT MaLich, MaLop, Thu, GioBatDau, GioKetThuc, PhongHoc " +
                                        "FROM dbo.FN_DSLichHoc_Lop(:maLop) ORDER BY Thu, GioBatDau")
                        .setParameter("maLop", maLop.trim()).getResultList()).stream()
                .map(r -> new LichRow(Convert.str(r[0]), Convert.str(r[1]), null, null, null,
                        Convert.integer(r[2]), tenThu(Convert.integer(r[2])),
                        toTime(r[3]), toTime(r[4]), Convert.str(r[5]), null)).toList());
    }

    private static LichRow mapRow(Object[] r) {
        return new LichRow(Convert.str(r[0]), Convert.str(r[1]), Convert.str(r[2]),
                Convert.str(r[3]), Convert.str(r[4]), Convert.integer(r[5]),
                Convert.str(r[6]), toTime(r[7]), toTime(r[8]), Convert.str(r[9]), Convert.str(r[10]));
    }

    private static Time toTime(Object value) {
        if (value == null) return null;
        if (value instanceof Time t) return t;
        return Time.valueOf(value.toString());
    }

    private static String tenThu(Integer thu) {
        return switch (thu == null ? 0 : thu) {
            case 1 -> "Chủ Nhật"; case 2 -> "Thứ 2"; case 3 -> "Thứ 3";
            case 4 -> "Thứ 4"; case 5 -> "Thứ 5"; case 6 -> "Thứ 6"; case 7 -> "Thứ 7";
            default -> "";
        };
    }

    public void themLich(String maLich, String maLop, Integer thu,
                         Time gioBatDau, Time gioKetThuc, String phongHoc) {

        kiemTraLich(maLich, maLop, thu, gioBatDau, gioKetThuc, phongHoc);

        JpaUtil.inTx(em -> {
            em.createNativeQuery(
                            "INSERT INTO dbo.LICHHOC " +
                                    "(MaLich, MaLop, Thu, GioBatDau, GioKetThuc, PhongHoc) " +
                                    "VALUES (:maLich, :maLop, :thu, :batDau, :ketThuc, :phong)"
                    )
                    .setParameter("maLich", maLich.trim())
                    .setParameter("maLop", maLop.trim())
                    .setParameter("thu", thu)
                    .setParameter("batDau", gioBatDau)
                    .setParameter("ketThuc", gioKetThuc)
                    .setParameter("phong", phongHoc.trim())
                    .executeUpdate();

            return null;
        });
    }

    public void suaLich(String maLich, String maLop, Integer thu,
                        Time gioBatDau, Time gioKetThuc, String phongHoc) {

        kiemTraLich(maLich, maLop, thu, gioBatDau, gioKetThuc, phongHoc);

        JpaUtil.inTx(em -> {
            int affected = em.createNativeQuery(
                            "UPDATE dbo.LICHHOC " +
                                    "SET Thu = :thu, GioBatDau = :batDau, " +
                                    "GioKetThuc = :ketThuc, PhongHoc = :phong " +
                                    "WHERE MaLich = :maLich AND MaLop = :maLop"
                    )
                    .setParameter("thu", thu)
                    .setParameter("batDau", gioBatDau)
                    .setParameter("ketThuc", gioKetThuc)
                    .setParameter("phong", phongHoc.trim())
                    .setParameter("maLich", maLich.trim())
                    .setParameter("maLop", maLop.trim())
                    .executeUpdate();

            if (affected == 0) {
                throw new IllegalStateException(
                        "Không tìm thấy lịch học cần sửa."
                );
            }

            return null;
        });
    }

    private void kiemTraLich(String maLich, String maLop, Integer thu,
                             Time gioBatDau, Time gioKetThuc, String phongHoc) {

        if (maLich == null || maLich.isBlank()) {
            throw new IllegalArgumentException("Mã lịch không được để trống.");
        }

        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException("Mã lớp không được để trống.");
        }

        if (thu == null || thu < 2 || thu > 7) {
            throw new IllegalArgumentException("Thứ phải nằm trong khoảng 2 đến 7.");
        }

        if (gioBatDau == null || gioKetThuc == null
                || !gioKetThuc.after(gioBatDau)) {
            throw new IllegalArgumentException(
                    "Giờ kết thúc phải sau giờ bắt đầu."
            );
        }

        if (phongHoc == null || phongHoc.isBlank()) {
            throw new IllegalArgumentException("Phòng học không được để trống.");
        }
    }
}
