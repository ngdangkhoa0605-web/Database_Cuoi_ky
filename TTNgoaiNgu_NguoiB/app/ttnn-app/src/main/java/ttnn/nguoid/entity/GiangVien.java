package ttnn.nguoid.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Bang GIANGVIEN (Nguoi D). Khoa chinh la ma chuoi do ung dung sinh (GV01...), khong dung IDENTITY.
 * Chi anh xa cot (MaNN la chuoi) - KHONG khai bao quan he toi NGONNGU de khong phu thuoc entity cua Kien.
 * Khong tu doi trang thai sang Tam nghi / Da nghi viec o day: dung SP_BanGiaoLop_KhiGVNghi
 * (neu doi truc tiep ma giang vien con lop dang hoat dong thi TRG_GIANGVIEN_NghiViec tu choi).
 */
@Entity
@Table(name = "GIANGVIEN")
public class GiangVien {
    @Id
    @Column(name = "MaGV", nullable = false, length = 4, columnDefinition = "CHAR(4)")
    private String maGV;

    @Column(name = "HoTen", nullable = false, length = 40)
    private String hoTen;

    @Column(name = "MaNN", nullable = false, length = 3, columnDefinition = "CHAR(3)")
    private String maNN;

    @Column(name = "SDT", nullable = false, length = 15)
    private String sdt;

    @Column(name = "Email", nullable = false, length = 50)
    private String email;

    /** 'Đang công tác' | 'Tạm nghỉ' | 'Đã nghỉ việc' (CHECK trong CSDL) */
    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai = "Đang công tác";

    protected GiangVien() {
    }

    public GiangVien(String maGV, String hoTen, String maNN, String sdt, String email, String trangThai) {
        this.maGV = maGV;
        this.hoTen = hoTen;
        this.maNN = maNN;
        this.sdt = sdt;
        this.email = email;
        this.trangThai = trangThai;
    }

    public String getMaGV() { return maGV == null ? null : maGV.trim(); }
    public String getHoTen() { return hoTen; }
    public String getMaNN() { return maNN == null ? null : maNN.trim(); }
    public String getSdt() { return sdt; }
    public String getEmail() { return email; }
    public String getTrangThai() { return trangThai; }

    public void setHoTen(String hoTen) { this.hoTen = hoTen; }
    public void setMaNN(String maNN) { this.maNN = maNN; }
    public void setSdt(String sdt) { this.sdt = sdt; }
    public void setEmail(String email) { this.email = email; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
}
