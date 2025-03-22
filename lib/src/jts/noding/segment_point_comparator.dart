import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/util/assert.dart';


 class SegmentPointComparator {
    static int compare(int octant, Coordinate p0, Coordinate p1) {
        if (p0.equals2D(p1)) {
          return 0;
        }

        int xSign = relativeSign(p0.x, p1.x);
        int ySign = relativeSign(p0.y, p1.y);
        switch (octant) {
            case 0 :
                return compareValue(xSign, ySign);
            case 1 :
                return compareValue(ySign, xSign);
            case 2 :
                return compareValue(ySign, -xSign);
            case 3 :
                return compareValue(-xSign, ySign);
            case 4 :
                return compareValue(-xSign, -ySign);
            case 5 :
                return compareValue(-ySign, -xSign);
            case 6 :
                return compareValue(-ySign, xSign);
            case 7 :
                return compareValue(xSign, -ySign);
        }
        Assert.shouldNeverReachHere2("invalid octant value");
        return 0;
    }

    static int relativeSign(double x0, double x1) {
        if (x0 < x1) {
          return -1;
        }

        if (x0 > x1) {
          return 1;
        }

        return 0;
    }

     static int compareValue(int compareSign0, int compareSign1) {
        if (compareSign0 < 0) {
          return -1;
        }

        if (compareSign0 > 0) {
          return 1;
        }

        if (compareSign1 < 0) {
          return -1;
        }

        if (compareSign1 > 0) {
          return 1;
        }

        return 0;
    }
}
