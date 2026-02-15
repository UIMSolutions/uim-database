/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.storages.storage;

import core.sync.mutex : Mutex;
import std.algorithm : countUntil;
import std.conv : to;
import std.exception : enforce;
import std.array : appender;
import std.typecons : Nullable;
import uim.database.library.jsoncompat : Json;
import uim.database.library.types;

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


