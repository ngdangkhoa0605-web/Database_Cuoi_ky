package ttnn.common;

/**
 * 4 vai tro cua ung dung, moi vai tro ung voi mot ROLE trong CSDL (tao trong sql/nguoi_A/Security_Roles.sql).
 * Sau khi dang nhap, JpaUtil.connect(...) hoi IS_ROLEMEMBER de biet tai khoan thuoc vai tro nao;
 * tai khoan khong thuoc vai tro nao trong 4 vai tro nay bi tu choi dang nhap.
 *
 * Thu tu khai bao = thu tu uu tien: neu mot login lo thuoc nhieu role thi lay role dung truoc.
 * (Chinh sach cua nhom: moi login chi thuoc DUNG MOT role.)
 *
 * Cach dung trong man hinh:  if (JpaUtil.coVaiTro(VaiTro.QUAN_TRI)) { ... hien nut Them/Sua/Xoa ... }
 */
public enum VaiTro {
    QUAN_TRI("role_QuanTri", "Quản trị viên"),
    GIAO_VU("role_GiaoVu", "Giáo vụ"),
    KE_TOAN("role_KeToan", "Kế toán"),
    GIANG_VIEN("role_GiangVien", "Giảng viên");

    private final String roleSql;
    private final String tenHienThi;

    VaiTro(String roleSql, String tenHienThi) {
        this.roleSql = roleSql;
        this.tenHienThi = tenHienThi;
    }

    /** Ten ROLE trong SQL Server, vi du role_QuanTri. */
    public String getRoleSql() {
        return roleSql;
    }

    /** Ten hien thi tren giao dien, vi du "Quản trị viên". */
    public String getTenHienThi() {
        return tenHienThi;
    }

    /** Tim vai tro theo ten ROLE trong SQL Server; khong khop -> null. */
    public static VaiTro tuRoleSql(String roleSql) {
        if (roleSql == null) {
            return null;
        }
        for (VaiTro v : values()) {
            if (v.roleSql.equalsIgnoreCase(roleSql.trim())) {
                return v;
            }
        }
        return null;
    }

    @Override
    public String toString() {
        return tenHienThi;
    }
}

