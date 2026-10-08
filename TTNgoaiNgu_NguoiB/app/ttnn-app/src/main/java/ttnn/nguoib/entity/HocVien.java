package ttnn.nguoib.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDate;

/**
 * Bang HOCVIEN. Khoa chinh MaHV la ma chuoi CHAR(5) (HV001...) gan boi ung dung, KHONG dung IDENTITY.
 * CHAR(5): ma luon du 5 ky tu nen khong bi dem khoang trang; van trim khi doc ket qua truy van thu cong.
 */
@Entity
@Table(name = "HOCVIEN")
public class HocVien {
    @Id
    @Column(name = "MaHV", nullable = false, length = 5, columnDefinition = "CHAR(5)")
    private String maHV;

    @Column(name = "HoTen", nullable = false, length = 40)
    private String hoTen;

    @Column(name = "NgaySinh", nullable = false)
    private LocalDate ngaySinh;

    @Column(name = "SDT", nullable = false, length = 15)
    private String sdt;

    @Column(name = "Email", nullable = false, length = 50)
    private String email;

    @Column(name = "DiaChi", nullable = false, length = 100)
    private String diaChi;

    protected HocVien() {
        // JPA yeu cau constructor khong tham so
    }

    public HocVien(String maHV, String hoTen, LocalDate ngaySinh, String sdt, String email, String diaChi) {
        this.maHV = maHV;
        this.hoTen = hoTen;
        this.ngaySinh = ngaySinh;
        this.sdt = sdt;
        this.email = email;
        this.diaChi = diaChi;
    }

    public String getMaHV() { return maHV == null ? null : maHV.trim(); }
    public String getHoTen() { return hoTen; }
    public LocalDate getNgaySinh() { return ngaySinh; }
    public String getSdt() { return sdt; }
    public String getEmail() { return email; }
    public String getDiaChi() { return diaChi; }

    public void setHoTen(String hoTen) { this.hoTen = hoTen; }
    public void setNgaySinh(LocalDate ngaySinh) { this.ngaySinh = ngaySinh; }
    public void setSdt(String sdt) { this.sdt = sdt; }
    public void setEmail(String email) { this.email = email; }
    public void setDiaChi(String diaChi) { this.diaChi = diaChi; }
}
