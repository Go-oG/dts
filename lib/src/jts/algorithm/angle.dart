import 'dart:math';

import 'package:dts/src/jts/geom/coordinate.dart';

import 'orientation.dart';

class Angle {
  Angle._();

  static const double piTimes2 = 2.0 * pi;

  static const double piOver2 = pi / 2.0;

  static const double piOver4 = pi / 4.0;

  static const int counterClockwise = Orientation.counterClockwise;

  static const int clockwise = Orientation.clockwise;

  static const int none = Orientation.collinear;

  static double toDegrees(double radians) {
    return (radians * 180) / pi;
  }

  static double toRadians(double angleDegrees) {
    return (angleDegrees * pi) / 180.0;
  }

  static double angle2(Coordinate p0, Coordinate p1) {
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    return atan2(dy, dx);
  }

  static double angle(Coordinate p) {
    return atan2(p.y, p.x);
  }

  static bool isAcute(Coordinate p0, Coordinate p1, Coordinate p2) {
    double dx0 = p0.x - p1.x;
    double dy0 = p0.y - p1.y;
    double dx1 = p2.x - p1.x;
    double dy1 = p2.y - p1.y;
    double dotprod = (dx0 * dx1) + (dy0 * dy1);
    return dotprod > 0;
  }

  static bool isObtuse(Coordinate p0, Coordinate p1, Coordinate p2) {
    double dx0 = p0.x - p1.x;
    double dy0 = p0.y - p1.y;
    double dx1 = p2.x - p1.x;
    double dy1 = p2.y - p1.y;
    double dotprod = (dx0 * dx1) + (dy0 * dy1);
    return dotprod < 0;
  }

  static double angleBetween(
      Coordinate tip1, Coordinate tail, Coordinate tip2) {
    double a1 = angle2(tail, tip1);
    double a2 = angle2(tail, tip2);
    return diff(a1, a2);
  }

  static double angleBetweenOriented(
      Coordinate tip1, Coordinate tail, Coordinate tip2) {
    double a1 = angle2(tail, tip1);
    double a2 = angle2(tail, tip2);
    double angDel = a2 - a1;
    if (angDel <= (-pi)) {
      return angDel + piTimes2;
    }

    if (angDel > pi) {
      return angDel - piTimes2;
    }

    return angDel;
  }

  static double bisector(Coordinate tip1, Coordinate tail, Coordinate tip2) {
    double angDel = angleBetweenOriented(tip1, tail, tip2);
    double angBi = angle2(tail, tip1) + (angDel / 2);
    return normalize(angBi);
  }

  static double interiorAngle(Coordinate p0, Coordinate p1, Coordinate p2) {
    double anglePrev = Angle.angle2(p1, p0);
    double angleNext = Angle.angle2(p1, p2);
    return normalizePositive(angleNext - anglePrev);
  }

  static int getTurn(double ang1, double ang2) {
    double crossproduct = sin(ang2 - ang1);
    if (crossproduct > 0) {
      return counterClockwise;
    }
    if (crossproduct < 0) {
      return clockwise;
    }
    return none;
  }

  static double normalize(double angle) {
    while (angle > pi) {
      angle -= piTimes2;
    }

    while (angle <= (-pi)) {
      angle += piTimes2;
    }

    return angle;
  }

  static double normalizePositive(double angle) {
    if (angle < 0.0) {
      while (angle < 0.0) {
        angle += piTimes2;
      }

      if (angle >= piTimes2) {
        angle = 0.0;
      }
    } else {
      while (angle >= piTimes2) {
        angle -= piTimes2;
      }

      if (angle < 0.0) {
        angle = 0.0;
      }
    }
    return angle;
  }

  static double diff(double ang1, double ang2) {
    double delAngle;
    if (ang1 < ang2) {
      delAngle = ang2 - ang1;
    } else {
      delAngle = ang1 - ang2;
    }
    if (delAngle > pi) {
      delAngle = piTimes2 - delAngle;
    }
    return delAngle;
  }

  static double sinSnap(double ang) {
    double res = sin(ang);
    if (res.abs() < 5.0E-16) {
      return 0.0;
    }

    return res;
  }

  static double cosSnap(double ang) {
    double res = cos(ang);
    if (res.abs() < 5.0E-16) {
      return 0.0;
    }

    return res;
  }

  static Coordinate project(Coordinate p, double angle, double dist) {
    double x = p.x + (dist * Angle.cosSnap(angle));
    double y = p.x + (dist * Angle.sinSnap(angle));
    return Coordinate(x, y);
  }
}
