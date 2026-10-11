package ttnn.kien.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Bang NGONNGU (Kien). Khoa chinh MaNN la ma CHAR(3) do nguoi dung nhap (ANH, NHA...), KHONG dung IDENTITY.
 * Ma ngon ngu khong duoc sua (la khoa chinh, dang duoc KHOAHOC/GIANGVIEN tham chieu) - chi sua TenNN.
 */
@Entity
@Table(name = "NGONNGU")
public class NgonNgu {
    @Id
    @Column(name = "MaNN", nullable = false, length = 3, columnDefinition = "CHAR(3)")
    private String maNN;

    @Column(name = "TenNN", nullable = false, length = 30)
    private String tenNN;

    protected NgonNgu() {
        // JPA yeu cau constructor khong tham so
    }

    public NgonNgu(String maNN, String tenNN) {
        this.maNN = maNN;
        this.tenNN = tenNN;
    }

    public String getMaNN() { return maNN == null ? null : maNN.trim(); }
    public String getTenNN() { return tenNN; }

    public void setTenNN(String tenNN) { this.tenNN = tenNN; }
}
