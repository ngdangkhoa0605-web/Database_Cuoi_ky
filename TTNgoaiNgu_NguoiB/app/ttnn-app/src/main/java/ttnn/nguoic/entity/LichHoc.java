package ttnn.nguoic.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalTime;

@Entity
@Table(name = "LICHHOC", schema = "dbo")
public class LichHoc {
    @Id
    @Column(name = "MaLich", length = 8, nullable = false)
    private String maLich;

    @Column(name = "MaLop", length = 6, nullable = false)
    private String maLop;

    @Column(name = "Thu", nullable = false)
    private Short thu;

    @Column(name = "GioBatDau", nullable = false)
    private LocalTime gioBatDau;

    @Column(name = "GioKetThuc", nullable = false)
    private LocalTime gioKetThuc;

    @Column(name = "PhongHoc", length = 10, nullable = false)
    private String phongHoc;

    public LichHoc() {}

    public String getMaLich() { return maLich; }
    public void setMaLich(String maLich) { this.maLich = maLich; }
    public String getMaLop() { return maLop; }
    public void setMaLop(String maLop) { this.maLop = maLop; }
    public Short getThu() { return thu; }
    public void setThu(Short thu) { this.thu = thu; }
    public LocalTime getGioBatDau() { return gioBatDau; }
    public void setGioBatDau(LocalTime gioBatDau) { this.gioBatDau = gioBatDau; }
    public LocalTime getGioKetThuc() { return gioKetThuc; }
    public void setGioKetThuc(LocalTime gioKetThuc) { this.gioKetThuc = gioKetThuc; }
    public String getPhongHoc() { return phongHoc; }
    public void setPhongHoc(String phongHoc) { this.phongHoc = phongHoc; }
}

