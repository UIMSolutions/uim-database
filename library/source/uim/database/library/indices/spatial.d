module uim.database.library.indices.spatial;

import core.sync.mutex : Mutex;
import std.algorithm.searching : canFind;
import std.algorithm : any, all;
import std.array : empty;
import std.math : sqrt;
import uim.database.library.interfaces.spatialindex : ISpatialIndex;
import uim.database.library.jsoncompat : Json;
import uim.database.library.types : Point;

@safe:
class SpatialIndex : ISpatialIndex {
private:
  Mutex _mutex;
  Point[][string] _pointsByNamespace;

public:
  this() {
    _mutex = new Mutex;
  }

  // Adds a point to the specified namespace
  override void addPoint(string namespace, Point point) {
    synchronized (_mutex) {
      _pointsByNamespace[namespace] ~= point;
    }
  }

  // Returns all points within the specified radius from the center point in the given namespace
  override Json withinRadius(string namespace, Point center, double radius) {
    synchronized (_mutex) {
      Json[] matches;
      foreach (p; _pointsByNamespace.get(namespace, [])) {
        auto dist = distance(center, p);
        if (dist <= radius) {
          matches ~= [
            "x": Json(p.x),
            "y": Json(p.y),
            "distance": Json(dist)
          ].toJson;
        }
      }
      return [
        "namespace": Json(namespace),
        "matches": Json(matches)
      ].toJson;
    }
  }

  override bool hasNamespace(string namespace) {
    synchronized (_mutex) {
      return (namespace in _pointsByNamespace) !is null;
    }
  }

  override bool isEmpty(string namespace) {
    synchronized (_mutex) {
      return !(namespace in _pointsByNamespace) || _pointsByNamespace[namespace].empty;
    }
  }

  override bool containsPoint(string namespace, Point point) {
    synchronized (_mutex) {
      return namespace in _pointsByNamespace
        ? _pointsByNamespace[namespace].canFind!(p => p.x == point.x && p.y == point.y) : false;
    }
  }

  override bool containsAnyPoint(string namespace, Point[] points) {
    synchronized (_mutex) {
      if (namespace in _pointsByNamespace) {
        auto nsPoints = _pointsByNamespace[namespace];
        return points.any!(pt => nsPoints.canFind!(p => p.x == pt.x && p.y == pt.y));
      }
      return false;
    }
  }

  override bool containsAllPoints(string namespace, Point[] points) {
    synchronized (_mutex) {
      if (namespace in _pointsByNamespace) {
        auto nsPoints = _pointsByNamespace[namespace];
        return points.all!(pt => nsPoints.canFind!(p => p.x == pt.x && p.y == pt.y));
      }
      return false;
    }
  }

  override void add(string id, double x, double y) {
    addPoint(id, Point(x, y));
  }

  override void remove(string id) {
    synchronized (_mutex) {
      _pointsByNamespace.remove(id);
    }
  }

  override string[] findNearby(double x, double y, double radius) {
    synchronized (_mutex) {
      string[] namespaces;
      foreach (namespaceName, points; _pointsByNamespace) {
        auto hasNearby = points.any!(point => distance(Point(x, y), point) <= radius);
        if (hasNearby) {
          namespaces ~= namespaceName;
        }
      }
      return namespaces;
    }
  }

  override string findNearest(double x, double y) {
    synchronized (_mutex) {
      double bestDistance = double.infinity;
      string bestNamespace;
      foreach (namespaceName, points; _pointsByNamespace) {
        foreach (point; points) {
          auto d = distance(Point(x, y), point);
          if (d < bestDistance) {
            bestDistance = d;
            bestNamespace = namespaceName;
          }
        }
      }
      return bestNamespace;
    }
  }

private:

  double distance(Point a, Point b) {
    auto dx = a.x - b.x;
    auto dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}
///
unittest {
  auto index = new SpatialIndex;
  index.addPoint("cities", Point(0, 0));
  index.addPoint("cities", Point(1, 1));
  index.addPoint("cities", Point(2, 2));

  auto result = index.withinRadius("cities", Point(0, 0), 1.5);
  auto resultObj = result.get!(Json[string]);
  assert(resultObj["matches"].get!(Json[]).length == 2);

  result = index.withinRadius("cities", Point(0, 0), 0.5);
  resultObj = result.get!(Json[string]);
  assert(resultObj["matches"].get!(Json[]).length == 1);
}
