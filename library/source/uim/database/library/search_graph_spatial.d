/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.search_graph_spatial;

import core.sync.mutex : Mutex;
import std.algorithm.searching : canFind;
import std.array : empty;
import std.conv : to;
import std.exception : enforce;
import std.math : sqrt;
import std.range : retro;
import std.array : array;
import uim.database.library.jsoncompat : Json;


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

    Json findPath(string start, string target) {
        synchronized (_mutex) {
            if (start == target) {
                return Json(["path": Json([Json(start)])]);
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
                return Json(["path": Json([])]);
            }

            string[] path;
            string cur = target;
            while (cur.length > 0) {
                path ~= cur;
                cur = parent[cur];
            }
            path = path.retro.array;

            Json[] resultPath;
            foreach (p; path) {
                resultPath ~= Json(p);
            }
            return Json(["path": Json(resultPath)]);
        }
    }
}

