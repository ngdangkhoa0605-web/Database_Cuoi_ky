package ttnn.nguoib.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Bang DANGKY. Chi anh xa cot (MaHV, MaLop la chuoi) - KHONG khai bao quan he toi LOP/HOCVIEN
 * de khong phu thuoc entity cua Nguoi C (LOP). Them moi qua SP_DangKy_VaTaoHoaDon;
 * entity nay dung de tim (find) va cap nhat diem cuoi ky.
 */
@Entity
@Table(name = "DANGKY")
public class DangKy {
    @Id
    @Column(name = "MaDK", nullable = false, length = 8)
    private String maDK;

    @Column(name = "MaHV", nullable = false, length = 5, columnDefinition = "CHAR(5)")
    private String maHV;

    @Column(name = "MaLop", nullable = false, length = 6)
    private String maLop;

    @Column(name = "NgayDangKy", nullable = false)
    private LocalDate ngayDangKy;

    @Column(name = "DiemCuoiKy", precision = 4, scale = 2)
    private BigDecimal diemCuoiKy;

    protected DangKy() {
    }

    public String getMaDK() { return maDK; }
    public String getMaHV() { return maHV == null ? null : maHV.trim(); }
    public String getMaLop() { return maLop; }
    public LocalDate getNgayDangKy() { return ngayDangKy; }
    public BigDecimal getDiemCuoiKy() { return diemCuoiKy; }

    public void setDiemCuoiKy(BigDecimal diemCuoiKy) { this.diemCuoiKy = diemCuoiKy; }
}
