package ttnn.nguoib.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Bang HOADON. Entity CHI DOC (@Immutable): moi thay doi tien/trang thai di qua
 * SP_DangKy_VaTaoHoaDon va SP_ThanhToanHocPhi (co khoa, chong thu vuot) chu khong
 * sua truc tiep bang entity.
 */
@Entity
@Immutable
@Table(name = "HOADON")
public class HoaDon {
    @Id
    @Column(name = "MaHD", nullable = false, length = 8)
    private String maHD;

    @Column(name = "MaDK", nullable = false, length = 8)
    private String maDK;

    @Column(name = "SoTienCanThu", nullable = false)
    private BigDecimal soTienCanThu;

    @Column(name = "SoTienDaThu", nullable = false)
    private BigDecimal soTienDaThu;

    @Column(name = "NgayThanhToan")
    private LocalDate ngayThanhToan;

    @Column(name = "TrangThaiThanhToan", nullable = false, length = 30)
    private String trangThaiThanhToan;

    protected HoaDon() {
    }

    public String getMaHD() { return maHD; }
    public String getMaDK() { return maDK; }
    public BigDecimal getSoTienCanThu() { return soTienCanThu; }
    public BigDecimal getSoTienDaThu() { return soTienDaThu; }
    public LocalDate getNgayThanhToan() { return ngayThanhToan; }
    public String getTrangThaiThanhToan() { return trangThaiThanhToan; }
}
