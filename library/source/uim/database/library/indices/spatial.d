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
