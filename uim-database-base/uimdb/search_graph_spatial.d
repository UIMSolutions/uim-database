/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uimdb.search_graph_spatial;

import core.sync.mutex : Mutex;
import std.algorithm.searching : canFind;
import std.array : empty;
import std.conv : to;
import std.exception : enforce;
import std.math : sqrt;
import std.range : retro;
import std.array : array;
import uimdb.jsoncompat : JSONValue;
import uimdb.types : Point;

class TextSearchIndex {
private:
    Mutex _mutex;
    size_t[string][string] _tokenFreqByTable;

public:
    this() {
        _mutex = new Mutex;
    }

    void indexText(string table, string text) {
        synchronized (_mutex) {
            foreach (token; tokenize(text)) {
                _tokenFreqByTable[table][token] += 1;
            }
        }
    }

    JSONValue search(string table, string term) {
        synchronized (_mutex) {
            size_t count = 0;
            if (auto tableMap = table in _tokenFreqByTable) {
                if (auto tokenCount = term in *tableMap) {
                    count = *tokenCount;
                }
            }
            return JSONValue([
                "table": JSONValue(table),
                "term": JSONValue(term),
                "hits": JSONValue(cast(long)count)
            ]);
        }
    }

private:
    string[] tokenize(string input) {
        import std.string : toLower, split;
        auto normalized = input.toLower();
        return normalized.split();
    }
}

class GraphStore {
private:
    Mutex _mutex;
    string[][string] _adj;

public:
    this() {
        _mutex = new Mutex;
    }

    void addEdge(string from, string to) {
        synchronized (_mutex) {
            _adj[from] ~= to;
        }
    }

    JSONValue findPath(string start, string target) {
        synchronized (_mutex) {
            if (start == target) {
                return JSONValue(["path": JSONValue([JSONValue(start)])]);
            }

            string[string] parent;
            string[] queue = [start];
            parent[start] = "";

            size_t index = 0;
            while (index < queue.length) {
                auto node = queue[index++];
                foreach (next; _adj.get(node, [])) {
                    if (next !in parent) {
                        parent[next] = node;
                        queue ~= next;
                    }
                    if (next == target) {
                        break;
                    }
                }
            }

            if (target !in parent) {
                return JSONValue(["path": JSONValue([])]);
            }

            string[] path;
            string cur = target;
            while (cur.length > 0) {
                path ~= cur;
                cur = parent[cur];
            }
            path = path.retro.array;

            JSONValue[] resultPath;
            foreach (p; path) {
                resultPath ~= JSONValue(p);
            }
            return JSONValue(["path": JSONValue(resultPath)]);
        }
    }
}

class SpatialIndex {
private:
    Mutex _mutex;
    Point[][string] _pointsByNamespace;

public:
    this() {
        _mutex = new Mutex;
    }

    void addPoint(string ns, Point point) {
        synchronized (_mutex) {
            _pointsByNamespace[ns] ~= point;
        }
    }

    JSONValue withinRadius(string ns, Point center, double radius) {
        synchronized (_mutex) {
            JSONValue[] matches;
            foreach (p; _pointsByNamespace.get(ns, [])) {
                auto dist = distance(center, p);
                if (dist <= radius) {
                    matches ~= JSONValue(["x": JSONValue(p.x), "y": JSONValue(p.y), "distance": JSONValue(dist)]);
                }
            }
            return JSONValue(["namespace": JSONValue(ns), "matches": JSONValue(matches)]);
        }
    }

private:
    double distance(Point a, Point b) {
        auto dx = a.x - b.x;
        auto dy = a.y - b.y;
        return sqrt(dx * dx + dy * dy);
    }
}
