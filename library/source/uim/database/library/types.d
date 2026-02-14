/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.types;

import std.datetime : SysTime, Clock;
import std.variant : Algebraic;
import uim.database.library.jsoncompat : JSONValue;

struct Point {
    double x;
    double y;
}

enum DataType {
    int64,
    float64,
    text,
    boolean,
    timestamp,
    json,
    point
}

alias CellValue = Algebraic!(long, double, string, bool, SysTime, JSONValue, Point);

CellValue parseValue(DataType t, JSONValue value) {
    final switch (t) {
        case DataType.int64:
            return cast(long)value.get!long;
        case DataType.float64:
            return cast(double)value.get!double;
        case DataType.text:
            return value.get!string;
        case DataType.boolean:
            return value.get!bool;
        case DataType.timestamp:
            if (value.type == JSONValue.Type.string) {
                return Clock.currTime();
            }
            return Clock.currTime();
        case DataType.json:
            return value;
        case DataType.point:
            auto obj = value.object;
            return Point(obj["x"].get!double, obj["y"].get!double);
    }
}

JSONValue toJson(CellValue value) {
    return value.match!(
        (long v) => JSONValue(v),
        (double v) => JSONValue(v),
        (string v) => JSONValue(v),
        (bool v) => JSONValue(v),
        (SysTime v) => JSONValue(v.toISOExtString()),
        (JSONValue v) => v,
        (Point p) => JSONValue(["x": JSONValue(p.x), "y": JSONValue(p.y)])
    );
}

DataType parseDataType(string raw) {
    import std.string : toLower;
    auto v = raw.toLower();
    switch (v) {
        case "int64": return DataType.int64;
        case "float64": return DataType.float64;
        case "text": return DataType.text;
        case "boolean": return DataType.boolean;
        case "timestamp": return DataType.timestamp;
        case "json": return DataType.json;
        case "point": return DataType.point;
        default: return DataType.text;
    }
}
