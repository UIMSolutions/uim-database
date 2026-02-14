module uim.database.library.indices.spatial;

import uim.database.library;

mixin(ShowModule!());

@safe:
class SpatialIndex {
private:
  Mutex _mutex;
  Point[][string] _pointsByNamespace;

public:
  this() {
    _mutex = new Mutex;
  }

  // Adds a point to the specified namespace
  void addPoint(string namespace, Point point) {
    synchronized (_mutex) {
      _pointsByNamespace[namespace] ~= point;
    }
  }

  // Returns all points within the specified radius from the center point in the given namespace
  Json withinRadius(string namespace, Point center, double radius) {
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

  bool hasNamespace(string namespace) {
    synchronized (_mutex) {
      return namespace in _pointsByNamespace;
    }
  }

  bool isEmpty(string namespace) {
    synchronized (_mutex) {
      return !(namespace in _pointsByNamespace) || _pointsByNamespace[namespace].empty;
    }
  }

  bool containsPoint(string namespace, Point point) {
    synchronized (_mutex) {
      return namespace in _pointsByNamespace
        ? _pointsByNamespace[namespace].canFind!(p => p.x == point.x && p.y == point.y) : false;
    }
  }

  bool containsAnyPoint(string namespace, Point[] points) {
    synchronized (_mutex) {
      if (namespace in _pointsByNamespace) {
        auto nsPoints = _pointsByNamespace[namespace];
        return points.any!(pt => nsPoints.canFind!(p => p.x == pt.x && p.y == pt.y));
      }
      return false;
    }
  }

  bool containsAllPoints(string namespace, Point[] points) {
    synchronized (_mutex) {
      if (namespace in _pointsByNamespace) {
        auto nsPoints = _pointsByNamespace[namespace];
        return points.all!(pt => nsPoints.canFind!(p => p.x == pt.x && p.y == pt.y));
      }
      return false;
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
  assert(result.object["matches"].array.length == 2);

  result = index.withinRadius("cities", Point(0, 0), 0.5);
  assert(result.object["matches"].array.length == 1);
}
