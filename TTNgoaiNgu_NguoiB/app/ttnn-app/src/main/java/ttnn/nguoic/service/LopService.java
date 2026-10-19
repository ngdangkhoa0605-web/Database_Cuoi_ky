
package ttnn.nguoic.service;

import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import ttnn.common.Convert;
import ttnn.common.JpaUtil;

import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;

public final class LopService {

    public record LopRow(
            String maLop,
            String maKH,
            String tenKhoa,
            String maGV,
            String tenGiangVien,
            Date ngayKhaiGiang,
            Date ngayKetThuc,
            Integer siSoHienTai,
            Integer siSoToiDa,
            BigDecimal tyLeLapDay,
            String trangThai) {

        public Object[] toRow() {
            return new Object[]{
                    maLop,
                    maKH,
                    tenKhoa,
                    maGV,
                    tenGiangVien,
                    ngayKhaiGiang,
                    ngayKetThuc,
                    siSoHienTai,
                    siSoToiDa,
                    tyLeLapDay,
                    trangThai
            };
        }
    }

    // ==================== TÌM KIẾM LỚP ====================

    public List<LopRow> timKiem(
            String maKH,
            String maGV,
            String trangThai,
            Date tuNgay,
            Date denNgay) {

        return JpaUtil.read(em -> {
            StoredProcedureQuery q =
                    em.createStoredProcedureQuery("dbo.SP_TimKiemLop");

            q.registerStoredProcedureParameter(
                    1, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(
                    2, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(
                    3, String.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(
                    4, Date.class, ParameterMode.IN);
            q.registerStoredProcedureParameter(
                    5, Date.class, ParameterMode.IN);

            q.setParameter(1, blankToNull(maKH));
            q.setParameter(2, blankToNull(maGV));
            q.setParameter(3, blankToNull(trangThai));
            q.setParameter(4, tuNgay);
            q.setParameter(5, denNgay);

            return Convert.rows(q.getResultList()).stream()
                    .map(r -> new LopRow(
                            Convert.str(r[0]),
                            Convert.str(r[1]),
                            Convert.str(r[2]),
                            Convert.str(r[3]),
                            Convert.str(r[4]),
                            r[5] == null
                                    ? null
                                    : Date.valueOf(r[5].toString()),
                            r[6] == null
                                    ? null
                                    : Date.valueOf(r[6].toString()),
                            Convert.integer(r[7]),
                            Convert.integer(r[8]),
                            Convert.money(r[9]),
                            Convert.str(r[10])
                    ))
                    .toList();
        });
    }

    // ==================== LẤY SĨ SỐ LỚP ====================

    public Integer siSoHienTai(String maLop) {
        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException("Hãy nhập mã lớp.");
        }

        return JpaUtil.read(em ->
                Convert.integer(
                        em.createNativeQuery(
                                        "SELECT dbo.FN_SiSoHienTai(:maLop)")
                                .setParameter("maLop", maLop.trim())
                                .getSingleResult()
                )
        );
    }

    // ==================== KẾT THÚC LỚP ====================

    public void ketThucLop(String maLop) {
        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException(
                    "Hãy chọn lớp cần kết thúc.");
        }

        JpaUtil.inTx(em -> {
            StoredProcedureQuery q =
                    em.createStoredProcedureQuery("dbo.SP_KetThucLop");

            q.registerStoredProcedureParameter(
                    1, String.class, ParameterMode.IN);
            q.setParameter(1, maLop.trim());
            q.execute();

            return null;
        });
    }

    // ==================== TẠO LỚP VÀ LỊCH HỌC ====================


    public void taoLopVaLichHoc(
            String maLop,
            String maKH,
            String maGV,
            Date ngayKhaiGiang,
            Date ngayKetThuc,
            int siSoToiDa,
            String trangThai,
            String danhSachLichXml) {

        if (blankToNull(maLop) == null
                || blankToNull(maKH) == null
                || blankToNull(maGV) == null) {
            throw new IllegalArgumentException(
                    "Mã lớp, mã khóa học và mã giảng viên không được để trống.");
        }

        if (ngayKhaiGiang == null || ngayKetThuc == null) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập ngày khai giảng và ngày kết thúc.");
        }

        if (!ngayKetThuc.after(ngayKhaiGiang)) {
            throw new IllegalArgumentException(
                    "Ngày kết thúc phải sau ngày khai giảng.");
        }

        if (siSoToiDa <= 0 || siSoToiDa > 255) {
            throw new IllegalArgumentException(
                    "Sĩ số tối đa phải từ 1 đến 255.");
        }

        if (danhSachLichXml == null
                || danhSachLichXml.isBlank()
                || !danhSachLichXml.contains("<Lich ")) {
            throw new IllegalArgumentException(
                    "Phải nhập ít nhất một lịch học.");
        }

        String status = blankToNull(trangThai);
        if (status == null) {
            status = "Đang tuyển sinh";
        }

        final String xml = danhSachLichXml;
        final String trangThaiLop = status;

        // Chỉ sử dụng MỘT giao dịch.
        JpaUtil.inTx(em -> {
            var query = em.createNativeQuery(
                    "DECLARE @DanhSachLich XML; "
                            + "SET @DanhSachLich = CAST(? AS XML); "
                            + "EXEC dbo.SP_TaoLop_VaLichHoc "
                            + "@MaLop = ?, "
                            + "@MaKH = ?, "
                            + "@MaGV_Chinh = ?, "
                            + "@NgayKhaiGiang = ?, "
                            + "@NgayKetThuc = ?, "
                            + "@SiSoToiDa = ?, "
                            + "@TrangThai = ?, "
                            + "@DanhSachLich = @DanhSachLich;"
            );

            query.setParameter(1, xml);
            query.setParameter(2, maLop.trim());
            query.setParameter(3, maKH.trim());
            query.setParameter(4, maGV.trim());
            query.setParameter(5, ngayKhaiGiang);
            query.setParameter(6, ngayKetThuc);
            query.setParameter(7, siSoToiDa);
            query.setParameter(8, trangThaiLop);

            query.executeUpdate();
            return null;
        });
    }


    // ==================== TÌM LỚP THEO MÃ ====================

    public LopRow timTheoMaLop(String maLop) {
        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException("Hãy nhập mã lớp.");
        }

        String ma = maLop.trim();

        return timKiem(null, null, null, null, null)
                .stream()
                .filter(lop -> lop.maLop() != null
                        && lop.maLop().equalsIgnoreCase(ma))
                .findFirst()
                .orElse(null);
    }

    // ==================== CẬP NHẬT LỚP ====================

    public void capNhatLop(
            String maLop,
            String maGV,
            Date ngayKhaiGiang,
            Date ngayKetThuc,
            int siSoToiDa) {

        if (maLop == null || maLop.isBlank()) {
            throw new IllegalArgumentException(
                    "Hãy chọn lớp cần sửa.");
        }

        if (maGV == null || maGV.isBlank()) {
            throw new IllegalArgumentException(
                    "Mã giảng viên không được để trống.");
        }

        if (ngayKhaiGiang == null || ngayKetThuc == null) {
            throw new IllegalArgumentException(
                    "Vui lòng nhập ngày khai giảng và ngày kết thúc.");
        }

        if (!ngayKetThuc.after(ngayKhaiGiang)) {
            throw new IllegalArgumentException(
                    "Ngày kết thúc phải sau ngày khai giảng.");
        }

        if (siSoToiDa <= 0 || siSoToiDa > 255) {
            throw new IllegalArgumentException(
                    "Sĩ số tối đa phải từ 1 đến 255.");
        }

        JpaUtil.inTx(em -> {
            int affected = em.createNativeQuery("""
                    UPDATE dbo.LOP
                    SET MaGV_Chinh = :maGV,
                        NgayKhaiGiang = :ngayKhaiGiang,
                        NgayKetThuc = :ngayKetThuc,
                        SiSoToiDa = :siSoToiDa
                    WHERE MaLop = :maLop
                    """)
                    .setParameter("maGV", maGV.trim())
                    .setParameter("ngayKhaiGiang", ngayKhaiGiang)
                    .setParameter("ngayKetThuc", ngayKetThuc)
                    .setParameter("siSoToiDa", siSoToiDa)
                    .setParameter("maLop", maLop.trim())
                    .executeUpdate();

            if (affected == 0) {
                throw new IllegalArgumentException(
                        "Không tìm thấy lớp cần sửa.");
            }

            return null;
        });
    }

    // ==================== HÀM HỖ TRỢ ====================

    private static String blankToNull(String value) {
        return value == null || value.isBlank()
                ? null
                : value.trim();
    }
}
