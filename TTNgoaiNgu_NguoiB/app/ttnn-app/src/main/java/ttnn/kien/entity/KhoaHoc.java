package ttnn.kien.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

/**
 * Bang KHOAHOC (Kien).
 *  - THEM khoa hoc KHONG dung entity: luon qua SP_ThemKhoaHoc_VaNgonNgu (ma KHxxxx sinh trong thu tuc).
 *  - SUA ten / ngon ngu / trinh do / so buoi / trang thai qua entity (trigger TRG_KHOAHOC_NgungTuyenSinh,
 *    TRG_KHOAHOC_KhoaNgonNgu tu kiem tra khi UPDATE).
 *  - HocPhi: updatable = false. Cot HocPhi bi DENY UPDATE (ke ca role_QuanTri) nen Hibernate KHONG duoc dua
 *    HocPhi vao cau UPDATE; doi hoc phi bat buoc qua SP_CapNhatHocPhiKhoa (cap nhat ca hoa don chua thanh toan).
 *  - MaNN luu dang chuoi (khong khai bao quan he @ManyToOne) giong cach entity cua B, de don gian va khong
 *    phu thuoc entity khac.
 */
@Entity
@Table(name = "KHOAHOC")
public class KhoaHoc {
    @Id
    @Column(name = "MaKH", nullable = false, length = 6)
    private String maKH;

    @Column(name = "TenKhoa", nullable = false, length = 50)
    private String tenKhoa;

    @Column(name = "MaNN", nullable = false, length = 3, columnDefinition = "CHAR(3)")
    private String maNN;

    @Column(name = "TrinhDo", nullable = false, length = 10)
    private String trinhDo;

    @Column(name = "SoBuoi", nullable = false, columnDefinition = "TINYINT")
    private Integer soBuoi;

    @Column(name = "HocPhi", nullable = false, precision = 19, scale = 4, columnDefinition = "MONEY",
            insertable = false, updatable = false)
    private BigDecimal hocPhi;

    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai;

    protected KhoaHoc() {
        // JPA yeu cau constructor khong tham so
    }

    public String getMaKH() { return maKH == null ? null : maKH.trim(); }
    public String getTenKhoa() { return tenKhoa; }
    public String getMaNN() { return maNN == null ? null : maNN.trim(); }
    public String getTrinhDo() { return trinhDo; }
    public Integer getSoBuoi() { return soBuoi; }
    public BigDecimal getHocPhi() { return hocPhi; }
    public String getTrangThai() { return trangThai; }

    public void setTenKhoa(String tenKhoa) { this.tenKhoa = tenKhoa; }
    public void setMaNN(String maNN) { this.maNN = maNN; }
    public void setTrinhDo(String trinhDo) { this.trinhDo = trinhDo; }
    public void setSoBuoi(Integer soBuoi) { this.soBuoi = soBuoi; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
}
