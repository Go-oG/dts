# JTS Dart Port

A Dart port of the [JTS Topology Suite](https://github.com/locationtech/jts), a Java library for creating and manipulating vector geometry.

## Features

- **Geometry Types**: Point, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon, GeometryCollection
- **Spatial Operations**: Buffer, Convex Hull, Intersection, Union, Difference, Symmetric Difference
- **Spatial Predicates**: Contains, CoveredBy, Covers, Crosses, Disjoint, Equals, Intersects, Overlaps, Touches, Within
- **Coordinate System Support**: 2D and 3D coordinates
- **Precision Models**: Fixed and Floating precision
- **IO Support**: WKT (Well-Known Text) and WKB (Well-Known Binary) formats

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dts: ^0.1.1
```

License
BSD 3-Clause License (Same as original JTS)

Acknowledgments
Original JTS authors and LocationTech
Dart community for tooling support