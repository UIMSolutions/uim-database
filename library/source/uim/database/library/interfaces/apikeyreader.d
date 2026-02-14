/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.interfaces.apikeyreader;

import core.sync.mutex : Mutex;
import uim.database.library;

mixin(ShowModule!());

@safe:

interface ApiKeyReader {
  string readApiKey();
}
