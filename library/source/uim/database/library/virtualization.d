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
import uim.database.library.jsoncompat : Json;

class DataVirtualization {
public:
    Json queryCsv(string path, size_t limit = 100) {
        enforce(exists(path), "CSV file not found");

        auto file = File(path, "r");
        auto reader = csvReader(file);

        bool headerCaptured = false;
        string[] header;
        Json[] rows;

        foreach (record; reader) {
            if (!headerCaptured) {
                header = record.dup;
                headerCaptured = true;
                continue;
            }

            Json row;
                auto rowObj = row.get!(Json[string]);
            foreach (idx, value; record) {
                if (idx < header.length) {
                    rowObj[header[idx]] = Json(value);
                }
            }
            rows ~= row;
            if (rows.length >= limit) {
                break;
            }
        }

        return Json([
            "source": Json(path),
            "rows": Json(rows)
        ]);
    }
}
