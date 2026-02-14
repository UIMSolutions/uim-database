module uim.database.library.interfaces.spatialindex;

import uim.database.library.jsoncompat : Json;
import uim.database.library.types : Point;

interface ISpatialIndex {
    // Adds a spatial object to the index with the given identifier
    void add(string id, double x, double y);

    // Removes a spatial object from the index by its identifier
    void remove(string id);

    // Finds all spatial objects within a certain radius of a point
    string[] findNearby(double x, double y, double radius);

    // Finds the nearest spatial object to a given point
    string findNearest(double x, double y);

    // Adds a point to the specified namespace
    void addPoint(string namespace, Point point);

    // Returns all points within the specified radius from the center point in the given namespace
    Json withinRadius(string namespace, Point center, double radius);

    bool hasNamespace(string namespace);

    bool isEmpty(string namespace);

    bool containsPoint(string namespace, Point point);

    bool containsAnyPoint(string namespace, Point[] points);

    bool containsAllPoints(string namespace, Point[] points);
}
