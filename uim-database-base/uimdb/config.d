/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uimdb.config;

struct ServerConfig {
    string host = "0.0.0.0";
    ushort port = 8080;
    string apiKey = "dev-secret-key";
    bool allowExternalCodeExecution = true;
}

ServerConfig loadConfig() {
    return ServerConfig();
}
