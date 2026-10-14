package ttnn.nguoid.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

/** Khoa chinh phuc hop (MaBuoi, MaDK) cua DIEMDANH. */
@Embeddable
public class DiemDanhId implements Serializable {
    @Column(name = "MaBuoi", nullable = false, length = 8)
    private String maBuoi;

    @Column(name = "MaDK", nullable = false, length = 8)
    private String maDK;

    protected DiemDanhId() {
    }

    public DiemDanhId(String maBuoi, String maDK) {
        this.maBuoi = maBuoi;
        this.maDK = maDK;
    }

    public String getMaBuoi() { return maBuoi; }
    public String getMaDK() { return maDK; }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof DiemDanhId other)) {
            return false;
        }
        return Objects.equals(maBuoi, other.maBuoi) && Objects.equals(maDK, other.maDK);
    }

    @Override
    public int hashCode() {
        return Objects.hash(maBuoi, maDK);
    }
}
