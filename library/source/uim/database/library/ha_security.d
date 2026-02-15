/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.ha_security;

import core.sync.mutex : Mutex;
import std.datetime : Clock;
import std.exception : enforce;
import uim.database.library.interfaces.apikeyreader : ApiKeyReader;
import uim.database.library.jsoncompat : Json;


class ApiSecurity {
private:
    string _apiKey;

public:
    this(string apiKey) {
        _apiKey = apiKey;
    }

    void authorize(string key) {
        enforce(key == _apiKey, "unauthorized");
    }

    void authorize(ApiKeyReader reader) {
        authorize(reader.readApiKey());
    }
}

class ReplicationLog {
private:
    Mutex _mutex;
    Json[] _events;

public:
    this() {
        _mutex = new Mutex;
    }

    void append(Json event) {
        synchronized (_mutex) {
            _events ~= event;
        }
    }

    Json status() {
        synchronized (_mutex) {
            return Json([
                "mode": Json("single-node-with-replication-log"),
                "replicationEvents": Json(cast(long)_events.length),
                "timestamp": Json(Clock.currTime().toISOExtString())
            ]);
        }
    }
}
