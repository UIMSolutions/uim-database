module uim.database.library.app;

import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.string : format;
import std.typecons : Nullable;
import vibe.vibe;

import uim.database.library.config;
import uim.database.library.indices.textsearch;
import uim.database.library.indices.spatial;
import uim.database.library.jsoncompat;
import uim.database.library.types;
import uim.database.library.storage;
import uim.database.library.search_graph_spatial : GraphStore;
import uim.database.library.ml;
import uim.database.library.integration;
import uim.database.library.virtualization;
import uim.database.library.ha_security;

shared static this() {
    auto cfg = loadConfig();

    auto store = new ColumnStore();
    auto textSearch = new TextSearchIndex();
    auto graph = new GraphStore();
    auto spatial = new SpatialIndex();
    auto pal = new PredictiveLibrary();
    auto bridge = new LanguageBridge();
    auto virtualization = new DataVirtualization();
    auto security = new ApiSecurity(cfg.apiKey);
    auto replication = new ReplicationLog();

    auto router = new URLRouter();

    router.get("/health", (req, res) {
        res.writeJsonBody(["status": Json("ok")].toJson);
    });

    router.post("/api/v1/tables", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto name = body["name"].get!string;
        auto bodyObj = body.get!(Json[string]);
        auto schemaObj = body["schema"].get!(Json[string]);

        DataType[string] schema;
        foreach (colName, dataTypeJson; schemaObj) {
            schema[colName] = parseDataType(dataTypeJson.get!string);
        }

        store.createTable(name, schema);
        replication.append(Json(["event": Json("create_table"), "table": Json(name)]));
        res.writeJsonBody(Json(["ok": Json(true)]));
    });

    router.post("/api/v1/rows/:table", (req, res) {
        withAuth(req, security);
        auto tableName = req.params["table"];
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);
        auto count = store.insertRow(tableName, body);

        if ("textColumn" in req.query) {
            auto col = req.query["textColumn"];
            textSearch.indexText(tableName, body[col].get!string);
        }

        if ("pointNamespace" in req.query && "x" in bodyObj && "y" in bodyObj) {
            spatial.addPoint(req.query["pointNamespace"], Point(body["x"].get!double, body["y"].get!double));
        }

        replication.append(Json(["event": Json("insert"), "table": Json(tableName)]));
        res.writeJsonBody(Json(["rows": Json(cast(long)count)]));
    });

    router.post("/api/v1/query/select", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);

        auto table = body["table"].get!string;
        string[] cols;
        if ("columns" in bodyObj) {
            foreach (c; body["columns"].get!(Json[])) {
                cols ~= c.get!string;
            }
        }

        Nullable!string filterCol;
        Nullable!string filterVal;
        if ("where" in bodyObj) {
            filterCol = body["where"]["column"].get!string;
            filterVal = body["where"]["equals"].toString();
        }

        auto rows = store.selectRows(table, cols, filterCol, filterVal);
        res.writeJsonBody(Json(["rows": Json(rows)]));
    });

    router.post("/api/v1/query/aggregate", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto result = store.aggregate(
            body["table"].get!string,
            body["function"].get!string,
            body["column"].get!string
        );
        res.writeJsonBody(Json(["result": result]));
    });

    router.post("/api/v1/text/index", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        textSearch.indexText(body["table"].get!string, body["text"].get!string);
        res.writeJsonBody(Json(["ok": Json(true)]));
    });

    router.post("/api/v1/text/search", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto result = textSearch.search(body["table"].get!string, body["term"].get!string);
        res.writeJsonBody(result);
    });

    router.post("/api/v1/graph/edge", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        graph.addEdge(body["from"].get!string, body["to"].get!string);
        res.writeJsonBody(Json(["ok": Json(true)]));
    });

    router.post("/api/v1/graph/path", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto path = graph.findPath(body["start"].get!string, body["target"].get!string);
        res.writeJsonBody(path);
    });

    router.post("/api/v1/spatial/within-radius", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto result = spatial.withinRadius(
            body["namespace"].get!string,
            Point(body["center"]["x"].get!double, body["center"]["y"].get!double),
            body["radius"].get!double
        );
        res.writeJsonBody(result);
    });

    router.post("/api/v1/ml/pal/linear/train", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);

        double[] x;
        foreach (v; body["x"].get!(Json[])) {
            x ~= v.get!double;
        }
        double[] y;
        foreach (v; body["y"].get!(Json[])) {
            y ~= v.get!double;
        }

        auto result = pal.trainLinear(body["model"].get!string, x, y);
        res.writeJsonBody(result);
    });

    router.post("/api/v1/ml/pal/linear/predict", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto result = pal.predictLinear(body["model"].get!string, body["x"].get!double);
        res.writeJsonBody(result);
    });

    router.post("/api/v1/integration/python/run", (req, res) {
        withAuth(req, security);
        enforce(cfg.allowExternalCodeExecution, "external code execution disabled");
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);
        auto payload = ("payload" in bodyObj) ? body["payload"] : Json();
        auto result = bridge.runPython(body["code"].get!string, payload);
        res.writeJsonBody(result);
    });

    router.post("/api/v1/integration/r/run", (req, res) {
        withAuth(req, security);
        enforce(cfg.allowExternalCodeExecution, "external code execution disabled");
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);
        auto payload = ("payload" in bodyObj) ? body["payload"] : Json();
        auto result = bridge.runR(body["code"].get!string, payload);
        res.writeJsonBody(result);
    });

    router.post("/api/v1/virtualization/csv/query", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        auto bodyObj = body.get!(Json[string]);
        auto path = body["path"].get!string;
        auto limitJson = ("limit" in bodyObj) ? body["limit"] : Json(100L);
        auto limit = cast(size_t)limitJson.get!long;
        auto result = virtualization.queryCsv(path, limit);
        res.writeJsonBody(result);
    });

    router.get("/api/v1/ha/status", (req, res) {
        withAuth(req, security);
        res.writeJsonBody(replication.status());
    });

    router.post("/api/v1/ha/replicate", (req, res) {
        withAuth(req, security);
        auto body = readBody(req);
        replication.append(body);
        res.writeJsonBody(Json(["ok": Json(true)]));
    });

    auto settings = new HTTPServerSettings();
    settings.port = cfg.port;
    settings.bindAddresses = [cfg.host];

    listenHTTP(settings, router);
    logInfo("UIM HANA Cloud server started at http://%s:%d", cfg.host, cfg.port);
}

void main() {
    runApplication();
}

Json readBody(HTTPServerRequest req) {
    auto txt = req.bodyReader.readAllUTF8();
    return txt.length ? parseJsonString(txt) : Json();
}

void withAuth(HTTPServerRequest req, ApiSecurity security) {
    auto key = req.headers.get("X-API-Key");
    security.authorize(key);
}
