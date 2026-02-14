/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.virtualization;

import std.csv : csvReader;
import std.exception : enforce;
import std.file : exists;
import std.stdio : File;
import uim.database.library.jsoncompat : JSONValue;

class DataVirtualization {
public:
    JSONValue queryCsv(string path, size_t limit = 100) {
        enforce(exists(path), "CSV file not found");

        auto file = File(path, "r");
        auto reader = csvReader(file);

        bool headerCaptured = false;
        string[] header;
        JSONValue[] rows;

        foreach (record; reader) {
            if (!headerCaptured) {
                header = record.dup;
                headerCaptured = true;
                continue;
            }

            JSONValue row;
                auto rowObj = row.get!(JSONValue[string]);
            foreach (idx, value; record) {
                if (idx < header.length) {
                    rowObj[header[idx]] = JSONValue(value);
                }
            }
            rows ~= row;
            if (rows.length >= limit) {
                break;
            }
        }

        return JSONValue([
            "source": JSONValue(path),
            "rows": JSONValue(rows)
        ]);
    }
}
