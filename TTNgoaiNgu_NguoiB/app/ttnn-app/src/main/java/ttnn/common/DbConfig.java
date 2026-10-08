package ttnn.common;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Cau hinh ket noi SQL Server (host/port/database...). Doc tu db.properties tren classpath,
 * co the ghi de bang bien moi truong TTNN_DB_HOST / TTNN_DB_PORT / TTNN_DB_NAME
 * hoac tham so JVM -Dttnn.db.host / -Dttnn.db.port / -Dttnn.db.name.
 * User va password KHONG luu o day: nguoi dung nhap luc dang nhap.
 */
public final class DbConfig {
    private String host = "localhost";
    private String port = "1433";
    private String database = "QL_TTNgoaiNgu";
    private String encrypt = "true";
    private String trustServerCertificate = "true";

    public static DbConfig load() {
        DbConfig c = new DbConfig();
        Properties p = new Properties();
        try (InputStream in = DbConfig.class.getResourceAsStream("/db.properties")) {
            if (in != null) {
                p.load(in);
            }
        } catch (IOException ignored) {
            // dung gia tri mac dinh
        }
        c.host = pick(p, "host", "ttnn.db.host", "TTNN_DB_HOST", c.host);
        c.port = pick(p, "port", "ttnn.db.port", "TTNN_DB_PORT", c.port);
        c.database = pick(p, "database", "ttnn.db.name", "TTNN_DB_NAME", c.database);
        c.encrypt = p.getProperty("encrypt", c.encrypt).trim();
        c.trustServerCertificate = p.getProperty("trustServerCertificate", c.trustServerCertificate).trim();
        return c;
    }

    private static String pick(Properties p, String key, String sysProp, String env, String def) {
        String v = System.getProperty(sysProp);
        if (v == null || v.isBlank()) {
            v = System.getenv(env);
        }
        if (v == null || v.isBlank()) {
            v = p.getProperty(key);
        }
        return (v == null || v.isBlank()) ? def : v.trim();
    }

    /** Tao JDBC URL. Neu host co dang may\\instance thi dung instanceName va bo qua port. */
    public String url() {
        StringBuilder sb = new StringBuilder("jdbc:sqlserver://");
        int slash = host.indexOf('\\');
        if (slash > 0) {
            sb.append(host, 0, slash).append(";instanceName=").append(host.substring(slash + 1));
        } else {
            sb.append(host).append(':').append(port);
        }
        sb.append(";databaseName=").append(database)
          .append(";encrypt=").append(encrypt)
          .append(";trustServerCertificate=").append(trustServerCertificate)
          .append(";loginTimeout=10;applicationName=TTNgoaiNgu");
        return sb.toString();
    }

    public String getHost() { return host; }
    public void setHost(String host) { this.host = host.trim(); }
    public String getPort() { return port; }
    public void setPort(String port) { this.port = port.trim(); }
    public String getDatabase() { return database; }
    public void setDatabase(String database) { this.database = database.trim(); }
}
