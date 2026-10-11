package ttnn.nguoid.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDate;

/**
 * Bang BUOIHOC (Nguoi D): buoi hoc thuc te cua lop. MaLop va MaGV_Day la ma chuoi (khong khai bao
 * quan he toi LOP cua Nguoi C va GIANGVIEN) de cac entity doc lap voi nhau.
 */
@Entity
@Table(name = "BUOIHOC")
public class BuoiHoc {
    @Id
    @Column(name = "MaBuoi", nullable = false, length = 8)
    private String maBuoi;

    @Column(name = "MaLop", nullable = false, length = 6)
    private String maLop;

    @Column(name = "MaGV_Day", nullable = false, length = 4, columnDefinition = "CHAR(4)")
    private String maGVDay;

    @Column(name = "NgayHocThucTe", nullable = false)
    private LocalDate ngayHocThucTe;

    /** 'Đã diễn ra' | 'Hoãn' | 'Hủy' (CHECK trong CSDL) */
    @Column(name = "TrangThaiBuoiHoc", nullable = false, length = 20)
    private String trangThaiBuoiHoc;

    protected BuoiHoc() {
    }

    public BuoiHoc(String maBuoi, String maLop, String maGVDay, LocalDate ngayHocThucTe, String trangThaiBuoiHoc) {
        this.maBuoi = maBuoi;
        this.maLop = maLop;
        this.maGVDay = maGVDay;
        this.ngayHocThucTe = ngayHocThucTe;
        this.trangThaiBuoiHoc = trangThaiBuoiHoc;
    }

    public String getMaBuoi() { return maBuoi; }
    public String getMaLop() { return maLop; }
    public String getMaGVDay() { return maGVDay == null ? null : maGVDay.trim(); }
    public LocalDate getNgayHocThucTe() { return ngayHocThucTe; }
    public String getTrangThaiBuoiHoc() { return trangThaiBuoiHoc; }

    public void setMaGVDay(String maGVDay) { this.maGVDay = maGVDay; }
    public void setNgayHocThucTe(LocalDate ngayHocThucTe) { this.ngayHocThucTe = ngayHocThucTe; }
    public void setTrangThaiBuoiHoc(String trangThaiBuoiHoc) { this.trangThaiBuoiHoc = trangThaiBuoiHoc; }
}
