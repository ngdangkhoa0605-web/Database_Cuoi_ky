package ttnn.nguoid.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Bang DIEMDANH (Nguoi D). Man hinh diem danh ghi CA BUOI bang SP_DiemDanh_CaLop (xem DiemDanhService);
 * entity nay dung de doc/sua tung dong. Moi INSERT/UPDATE deu duoc TRG_DIEMDANH_DungLop kiem tra
 * (dung lop, buoi da dien ra).
 */
@Entity
@Table(name = "DIEMDANH")
public class DiemDanh {
    @EmbeddedId
    private DiemDanhId id;

    /** 'Có mặt' | 'Vắng có phép' | 'Vắng không phép' (CHECK trong CSDL) */
    @Column(name = "TrangThaiDiemDanh", nullable = false, length = 20)
    private String trangThaiDiemDanh;

    @Column(name = "GhiChu", length = 100)
    private String ghiChu;

    protected DiemDanh() {
    }

    public DiemDanh(DiemDanhId id, String trangThaiDiemDanh, String ghiChu) {
        this.id = id;
        this.trangThaiDiemDanh = trangThaiDiemDanh;
        this.ghiChu = ghiChu;
    }

    public DiemDanhId getId() { return id; }
    public String getTrangThaiDiemDanh() { return trangThaiDiemDanh; }
    public String getGhiChu() { return ghiChu; }

    public void setTrangThaiDiemDanh(String v) { this.trangThaiDiemDanh = v; }
    public void setGhiChu(String ghiChu) { this.ghiChu = ghiChu; }
}
