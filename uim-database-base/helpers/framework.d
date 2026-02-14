module uim.framework;

import std.datetime : Clock, SysTime;

struct RequestContext {
    string requestId;
    SysTime receivedAt;
}

RequestContext newContext(string requestId) {
    return RequestContext(requestId, Clock.currTime());
}

struct ServiceResult(T) {
    bool ok;
    string message;
    T payload;
}

ServiceResult!T success(T)(T payload, string msg = "ok") {
    return ServiceResult!T(true, msg, payload);
}

ServiceResult!T failure(T)(string msg) {
    return ServiceResult!T(false, msg, T.init);
}
