package ttnn.nguoic.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;

@Entity
@Table(name = "LOP", schema = "dbo")
public class Lop {
    @Id
    @Column(name = "MaLop", length = 6, nullable = false)
    private String maLop;

    @Column(name = "MaKH", length = 6, nullable = false)
    private String maKH;

    @Column(name = "MaGV_Chinh", length = 4, nullable = false)
    private String maGVChinh;

    @Column(name = "NgayKhaiGiang", nullable = false)
    private LocalDate ngayKhaiGiang;

    @Column(name = "NgayKetThuc", nullable = false)
    private LocalDate ngayKetThuc;

    @Column(name = "SiSoToiDa", nullable = false)
    private Short siSoToiDa;

    @Column(name = "TrangThai", length = 20, nullable = false)
    private String trangThai;

    public Lop() {}

    public String getMaLop() { return maLop; }
    public void setMaLop(String maLop) { this.maLop = maLop; }
    public String getMaKH() { return maKH; }
    public void setMaKH(String maKH) { this.maKH = maKH; }
    public String getMaGVChinh() { return maGVChinh; }
    public void setMaGVChinh(String maGVChinh) { this.maGVChinh = maGVChinh; }
    public LocalDate getNgayKhaiGiang() { return ngayKhaiGiang; }
    public void setNgayKhaiGiang(LocalDate ngayKhaiGiang) { this.ngayKhaiGiang = ngayKhaiGiang; }
    public LocalDate getNgayKetThuc() { return ngayKetThuc; }
    public void setNgayKetThuc(LocalDate ngayKetThuc) { this.ngayKetThuc = ngayKetThuc; }
    public Short getSiSoToiDa() { return siSoToiDa; }
    public void setSiSoToiDa(Short siSoToiDa) { this.siSoToiDa = siSoToiDa; }
    public String getTrangThai() { return trangThai; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
}
