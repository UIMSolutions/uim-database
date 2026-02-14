/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uimdb.storages.storage;

import core.sync.mutex : Mutex;
import std.algorithm : countUntil;
import std.conv : to;
import std.exception : enforce;
import std.array : appender;
import std.typecons : Nullable;
import uimdb.jsoncompat : JSONValue;
import uimdb.types;

struct Column {
    DataType dataType;
    CellValue[] data;
}

struct Table {
    string name;
    string[] order;
    Column[string] columns;

    size_t rowCount() const {
        if (order.length == 0) {
            return 0;
        }
        return columns[order[0]].data.length;
    }
}

class ColumnStore {
private:
    Mutex _mutex;
    Table[string] _tables;

public:
    this() {
        _mutex = new Mutex;
    }

    void createTable(string name, DataType[string] schema) {
        synchronized (_mutex) {
            enforce(name.length > 0, "table name is required");
            enforce(name !in _tables, "table already exists");

            Table table;
            table.name = name;
            foreach (colName, dtype; schema) {
                table.order ~= colName;
                table.columns[colName] = Column(dtype, []);
            }
            _tables[name] = table;
        }
    }

    JSONValue describeTable(string name) {
        synchronized (_mutex) {
            enforce(name in _tables, "unknown table");
            auto table = _tables[name];
            JSONValue schema = JSONValue.init;
            foreach (col; table.order) {
                schema.object[col] = JSONValue(to!string(table.columns[col].dataType));
            }
            return JSONValue([
                "name": JSONValue(name),
                "rows": JSONValue(cast(long)table.rowCount()),
                "schema": schema
            ]);
        }
    }

    size_t insertRow(string tableName, JSONValue row) {
        synchronized (_mutex) {
            enforce(tableName in _tables, "unknown table");
            auto table = _tables[tableName];

            foreach (col; table.order) {
                enforce(col in row.object, "missing column: " ~ col);
            }

            foreach (col; table.order) {
                auto dtype = table.columns[col].dataType;
                auto value = parseValue(dtype, row.object[col]);
                table.columns[col].data ~= value;
            }

            _tables[tableName] = table;
            return table.rowCount();
        }
    }

    JSONValue[] selectRows(string tableName, string[] selectColumns, Nullable!string filterColumn = Nullable!string.init, Nullable!string filterValue = Nullable!string.init) {
        synchronized (_mutex) {
            enforce(tableName in _tables, "unknown table");
            auto table = _tables[tableName];

            auto columns = selectColumns.length ? selectColumns : table.order;
            foreach (col; columns) {
                enforce(col in table.columns, "unknown column: " ~ col);
            }

            JSONValue[] results;
            auto rows = table.rowCount();
            foreach (idx; 0 .. rows) {
                bool pass = true;
                if (!filterColumn.isNull) {
                    auto fc = filterColumn.get;
                    enforce(fc in table.columns, "unknown filter column");
                    auto actual = toJson(table.columns[fc].data[idx]);
                    pass = actual.toString() == JSONValue(filterValue.get).toString();
                }

                if (pass) {
                    JSONValue row;
                    foreach (col; columns) {
                        row.object[col] = toJson(table.columns[col].data[idx]);
                    }
                    results ~= row;
                }
            }
            return results;
        }
    }

    JSONValue aggregate(string tableName, string functionName, string columnName) {
        synchronized (_mutex) {
            enforce(tableName in _tables, "unknown table");
            auto table = _tables[tableName];
            enforce(columnName in table.columns, "unknown column");

            auto col = table.columns[columnName];
            auto rowCount = col.data.length;
            if (functionName == "count") {
                return JSONValue(cast(long)rowCount);
            }

            enforce(rowCount > 0, "no rows");

            double total = 0;
            foreach (value; col.data) {
                total += value.match!(
                    (long v) => cast(double)v,
                    (double v) => v,
                    (string v) => 0.0,
                    (bool v) => v ? 1.0 : 0.0,
                    (auto _) => 0.0
                );
            }

            if (functionName == "sum") {
                return JSONValue(total);
            }
            if (functionName == "avg") {
                return JSONValue(total / rowCount);
            }

            enforce(false, "unsupported aggregate");
            return JSONValue();
        }
    }

    JSONValue[] allRowsWithColumn(string tableName, string columnName) {
        synchronized (_mutex) {
            enforce(tableName in _tables, "unknown table");
            auto table = _tables[tableName];
            enforce(columnName in table.columns, "unknown column");

            JSONValue[] rows;
            foreach (idx; 0 .. table.rowCount()) {
                rows ~= toJson(table.columns[columnName].data[idx]);
            }
            return rows;
        }
    }
}
