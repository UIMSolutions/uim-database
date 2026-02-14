/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uimdb.ha_security;

import core.sync.mutex : Mutex;
import std.datetime : Clock, SysTime, seconds;
import std.exception : enforce;
import uimdb.jsoncompat : JSONValue;
import vibe.http.server : HTTPServerRequest;

class ApiSecurity {
private:
    string _apiKey;

public:
    this(string apiKey) {
        _apiKey = apiKey;
    }

    void authorize(const HTTPServerRequest req) {
        auto key = req.headers.get("X-API-Key");
        enforce(key == _apiKey, "unauthorized");
    }
}

class ReplicationLog {
private:
    Mutex _mutex;
    JSONValue[] _events;

public:
    this() {
        _mutex = new Mutex;
    }

    void append(JSONValue event) {
        synchronized (_mutex) {
            _events ~= event;
        }
    }

    JSONValue status() {
        synchronized (_mutex) {
            return JSONValue([
                "mode": JSONValue("single-node-with-replication-log"),
                "replicationEvents": JSONValue(cast(long)_events.length),
                "timestamp": JSONValue(Clock.currTime().toISOExtString())
            ]);
        }
    }
}
