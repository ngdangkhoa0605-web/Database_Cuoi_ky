package ttnn.common;

import javax.swing.table.AbstractTableModel;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** TableModel chi doc: hien thi tien theo dinh dang 1.500.000, ngay theo dd/MM/yyyy, null thanh rong. */
public class SimpleTableModel extends AbstractTableModel {
    private final String[] columns;
    private final List<Object[]> rows = new ArrayList<>();

    public SimpleTableModel(String... columns) {
        this.columns = columns;
    }

    public void setRows(List<Object[]> data) {
        rows.clear();
        rows.addAll(data);
        fireTableDataChanged();
    }

    /** Gia tri goc (chua dinh dang) cua o (row, col) theo chi so MODEL. */
    public Object raw(int row, int col) {
        return rows.get(row)[col];
    }

    @Override
    public int getRowCount() {
        return rows.size();
    }

    @Override
    public int getColumnCount() {
        return columns.length;
    }

    @Override
    public String getColumnName(int column) {
        return columns[column];
    }

    @Override
    public Object getValueAt(int rowIndex, int columnIndex) {
        Object v = rows.get(rowIndex)[columnIndex];
        if (v == null) {
            return "";
        }
        if (v instanceof BigDecimal b) {
            return UiUtil.formatNumber(b);
        }
        if (v instanceof LocalDate d) {
            return UiUtil.formatDate(d);
        }
        return v.toString();
    }

    @Override
    public boolean isCellEditable(int rowIndex, int columnIndex) {
        return false;
    }
}
