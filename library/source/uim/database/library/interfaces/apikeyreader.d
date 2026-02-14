/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.interfaces.apikeyreader;

import core.sync.mutex : Mutex;
import std.datetime : Clock;
import std.exception : enforce;
import uim.database.library.jsoncompat : JSONValue;

interface ApiKeyReader {
  string readApiKey();
}
