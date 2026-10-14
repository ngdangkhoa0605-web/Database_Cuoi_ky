package ttnn.nguoid.service;

/** Mot muc trong o chon (ma + ten hien thi). */
public record Muc(String ma, String ten) {
    @Override
    public String toString() {
        return (ten == null || ten.isBlank()) ? ma : ma + " - " + ten;
    }
}
