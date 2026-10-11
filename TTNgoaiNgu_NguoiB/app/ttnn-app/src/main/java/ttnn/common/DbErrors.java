package ttnn.common;

import java.sql.SQLException;

/**
 * Doi loi tu SQL Server / Hibernate thanh thong bao tieng Viet de hien thi cho nguoi dung.
 * - Loi THROW cua thu tuc/trigger (so loi >= 50000) -> hien nguyen van thong bao nghiep vu.
 * - Loi he thong thuong gap (trung khoa, rang buoc, deadlock, mat ket noi, thieu quyen) -> dien giai.
 */
public final class DbErrors {
    private DbErrors() {
    }

    /** Tim SQLException goc trong chuoi nguyen nhan (PersistenceException -> HibernateException -> SQLException). */
    public static SQLException findSql(Throwable t) {
        Throwable c = t;
        int guard = 0;
        while (c != null && guard++ < 20) {
            if (c instanceof SQLException se) {
                return se;
            }
            if (c.getCause() == c) {
                break;
            }
            c = c.getCause();
        }
        return null;
    }

    /** Co SQLException goc co so loi = code khong (vi du 2627 trung khoa, 52029 het cho). */
    public static boolean hasSqlError(Throwable t, int code) {
        SQLException se = findSql(t);
        return se != null && se.getErrorCode() == code;
    }

    /** Thong bao loi co chua ten rang buoc/doi tuong nay khong. */
    public static boolean mentions(Throwable t, String text) {
        Throwable c = t;
        int guard = 0;
        while (c != null && guard++ < 20) {
            String m = c.getMessage();
            if (m != null && m.contains(text)) {
                return true;
            }
            if (c.getCause() == c) {
                break;
            }
            c = c.getCause();
        }
        return false;
    }

    public static String message(Throwable t) {
        if (t instanceof IllegalArgumentException || t instanceof IllegalStateException) {
            return t.getMessage();
        }
        SQLException se = findSql(t);
        if (se == null) {
            String m = t.getMessage();
            return (m == null || m.isBlank()) ? t.getClass().getSimpleName() : m;
        }
        int code = se.getErrorCode();
        String msg = clean(se.getMessage());
        if (code >= 50000) {
            return msg; // thong bao nghiep vu do THROW tao ra
        }
        switch (code) {
            case 2627:
            case 2601:
                if (msg.contains("UQ_HOCVIEN_SDT")) {
                    return "Số điện thoại đã được học viên khác sử dụng.";
                }
                if (msg.contains("UQ_HOCVIEN_EMAIL")) {
                    return "Email đã được học viên khác sử dụng.";
                }
                if (msg.contains("PK_HOCVIEN")) {
                    return "Mã học viên đã tồn tại.";
                }
                if (msg.contains("UQ_DANGKY_HOCVIEN_LOP")) {
                    return "Học viên đã đăng ký lớp này rồi.";
                }
                if (msg.contains("UQ_HOADON_MADK")) {
                    return "Đăng ký này đã có hóa đơn.";
                }
                // ----- Kien: NGONNGU, KHOAHOC -----
                if (msg.contains("UQ_NGONNGU_TENNN")) {
                    return "Tên ngôn ngữ đã tồn tại.";
                }
                if (msg.contains("PK_NGONNGU")) {
                    return "Mã ngôn ngữ đã tồn tại.";
                }
                if (msg.contains("PK_KHOAHOC")) {
                    return "Mã khóa học đã tồn tại.";
                }
                return "Dữ liệu bị trùng với bản ghi đã có (vi phạm ràng buộc duy nhất).";
            case 547:
                // ----- Kien: xoa danh muc dang duoc tham chieu / CHECK cua KHOAHOC -----
                if (msg.contains("FK_KHOAHOC_NGONNGU")) {
                    return "Không thể xóa ngôn ngữ vì vẫn còn khóa học thuộc ngôn ngữ này.";
                }
                if (msg.contains("FK_GIANGVIEN_NGONNGU")) {
                    return "Không thể xóa ngôn ngữ vì vẫn còn giảng viên dạy ngôn ngữ này.";
                }
                if (msg.contains("FK_LOP_KHOAHOC")) {
                    return "Không thể xóa khóa học vì đã có lớp học mở theo khóa này.";
                }
                if (msg.contains("CK_KHOAHOC_SOBUOI")) {
                    return "Số buổi của khóa học phải lớn hơn 0.";
                }
                if (msg.contains("CK_KHOAHOC_HOCPHI")) {
                    return "Học phí không được âm.";
                }
                if (msg.contains("CK_KHOAHOC_TRANGTHAI")) {
                    return "Trạng thái khóa học không hợp lệ (Đang giảng dạy / Ngừng tuyển sinh).";
                }
                if (msg.contains("DELETE")) {
                    return "Không thể xóa vì dữ liệu đang được sử dụng ở bảng khác.";
                }
                return "Dữ liệu vi phạm ràng buộc của CSDL: " + msg;
            case 1205:
                return "Hệ thống đang bận (xung đột khóa - deadlock). Vui lòng thử lại.";
            case 1222:
                return "Dữ liệu đang bị phiên khác khóa, vui lòng thử lại sau ít giây.";
            case 18456:
                return "Sai tên đăng nhập hoặc mật khẩu SQL Server.";
            case 4060:
                return "Tài khoản không mở được CSDL hoặc CSDL chưa được tạo.";
            case 229:
            case 230:
            case 297:
                // Kien: cot KHOAHOC.HocPhi bi DENY UPDATE (ke ca quan tri) -> phai doi qua SP_CapNhatHocPhiKhoa
                if (code == 230 && msg.contains("HocPhi")) {
                    return "Không được sửa trực tiếp học phí. Hãy dùng chức năng \"Đổi học phí\" "
                            + "(cập nhật cả các hóa đơn chưa thanh toán).";
                }
                return "Tài khoản hiện tại không có quyền thực hiện thao tác này.";
            case 8152:
                return "Dữ liệu nhập quá dài so với độ dài cột cho phép.";
            default:
                break;
        }
        String state = se.getSQLState();
        if ((state != null && state.startsWith("08")) || msg.contains("connection") || msg.contains("TCP/IP")) {
            return "Mất kết nối tới SQL Server. Kiểm tra dịch vụ SQL Server, TCP/IP và cấu hình db.properties. (" + msg + ")";
        }
        return "Lỗi CSDL (" + code + "): " + msg;
    }

    private static String clean(String m) {
        if (m == null) {
            return "";
        }
        return m.replace('\r', ' ').replace('\n', ' ').trim();
    }
}
