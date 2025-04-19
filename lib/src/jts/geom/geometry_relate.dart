import 'package:dts/src/jts/operation/relate/relate_op.dart';
import 'package:dts/src/jts/operation/relateng/relate_ng.dart';
import 'package:dts/src/jts/operation/relateng/relate_predicate.dart';

import 'geometry.dart';
import 'intersection_matrix.dart';

enum GeometryRelateImpl { ng, old }

class GeometryRelate {
  static GeometryRelateImpl _relateImpl = GeometryRelateImpl.ng;

  static bool get _isRelateNG {
    return _relateImpl == GeometryRelateImpl.ng;
  }

  static void setRelateImpl(GeometryRelateImpl? relateImpl) {
    if (relateImpl == null) {
      return;
    }
    _relateImpl = relateImpl;
  }

  static bool intersects(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.intersects());
    }
    if (a.isGeometryCollection() || b.isGeometryCollection()) {
      for (int i = 0; i < a.getNumGeometries(); i++) {
        for (int j = 0; j < b.getNumGeometries(); j++) {
          if (a.getGeometryN(i).intersects(b.getGeometryN(j))) {
            return true;
          }
        }
      }
      return false;
    }
    return RelateOp.relate(a, b).isIntersects();
  }

  static bool contains(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.contains());
    }
    if ((b.getDimension() == 2) && (a.getDimension() < 2)) {
      return false;
    }
    if (((b.getDimension() == 1) && (a.getDimension() < 1)) && (b.getLength() > 0.0)) {
      return false;
    }
    if (!a.getEnvelopeInternal().contains(b.getEnvelopeInternal())) return false;

    return RelateOp.relate(a, b).isContains();
  }

  static bool covers(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.covers());
    }
    if ((b.getDimension() == 2) && (a.getDimension() < 2)) {
      return false;
    }
    if (((b.getDimension() == 1) && (a.getDimension() < 1)) && (b.getLength() > 0.0)) {
      return false;
    }
    if (!a.getEnvelopeInternal().covers(b.getEnvelopeInternal())) return false;

    if (a.isRectangle()) {
      return true;
    }
    return RelateOp.relate(a, b).isCovers();
  }

  static bool coveredBy(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.coveredBy());
    }
    return covers(b, a);
  }

  static bool crosses(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.crosses());
    }
    if (!a.getEnvelopeInternal().intersects(b.getEnvelopeInternal())) return false;

    return RelateOp.relate(a, b).isCrosses(a.getDimension(), b.getDimension());
  }

  static bool disjoint(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.disjoint());
    }
    return !intersects(a, b);
  }

  static bool equalsTopo(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.equalsTopo());
    }
    if (!a.getEnvelopeInternal().equals(b.getEnvelopeInternal())) return false;

    return RelateOp.relate(a, b).isEquals(a.getDimension(), b.getDimension());
  }

  static bool overlaps(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.overlaps());
    }
    if (!a.getEnvelopeInternal().intersects(b.getEnvelopeInternal())) return false;

    return RelateOp.relate(a, b).isOverlaps(a.getDimension(), b.getDimension());
  }

  static bool touches(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.touches());
    }
    if (!a.getEnvelopeInternal().intersects(b.getEnvelopeInternal())) return false;

    return RelateOp.relate(a, b).isTouches(a.getDimension(), b.getDimension());
  }

  static bool within(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate4(a, b, RelatePredicate.within());
    }
    return contains(b, a);
  }

  static IntersectionMatrix relate(Geometry a, Geometry b) {
    if (_isRelateNG) {
      return RelateNG.relate(a, b);
    }
    Geometry.checkNotGeometryCollection(a);
    Geometry.checkNotGeometryCollection(b);
    return RelateOp.relate(a, b);
  }

  static bool relate2(Geometry a, Geometry b, String intersectionPattern) {
    if (_isRelateNG) {
      return RelateNG.relate3(a, b, intersectionPattern);
    }
    Geometry.checkNotGeometryCollection(a);
    Geometry.checkNotGeometryCollection(b);
    return RelateOp.relate(a, b).matches2(intersectionPattern);
  }
}
