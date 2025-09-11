import '../../algorithm/angle.dart';
import '../coordinate.dart';
import 'affine_transformation.dart';
import 'affine_transformation_builder.dart';

class AffineTransformationFactory {
  static AffineTransformation? createFromControlVectors3(
    Coordinate src0,
    Coordinate src1,
    Coordinate src2,
    Coordinate dest0,
    Coordinate dest1,
    Coordinate dest2,
  ) {
    final builder = AffineTransformationBuilder(src0, src1, src2, dest0, dest1, dest2);
    return builder.getTransformation();
  }

  static AffineTransformation? createFromControlVectors2(
    Coordinate src0,
    Coordinate src1,
    Coordinate dest0,
    Coordinate dest1,
  ) {
    Coordinate rotPt = Coordinate(dest1.x - dest0.x, dest1.y - dest0.y);
    double ang = Angle.angleBetweenOriented(src1, src0, rotPt);
    double srcDist = src1.distance(src0);
    double destDist = dest1.distance(dest0);
    if (srcDist == 0.0) {
      return null;
    }

    double scale = destDist / srcDist;
    AffineTransformation trans = AffineTransformation.translationInstance(-src0.x, -src0.y);
    trans.rotate(ang);
    trans.scale(scale, scale);
    trans.translate(dest0.x, dest0.y);
    return trans;
  }

  static AffineTransformation createFromControlVectors(Coordinate src0, Coordinate dest0) {
    double dx = dest0.x - src0.x;
    double dy = dest0.y - src0.y;
    return AffineTransformation.translationInstance(dx, dy);
  }

  static AffineTransformation? createFromControlVectors4(List<Coordinate> src, List<Coordinate> dest) {
    if (src.length != dest.length) {
      throw ArgumentError("Src and Dest arrays are not the same length");
    }

    if (src.isEmpty) {
      throw ArgumentError("Too few control points");
    }

    if (src.length > 3) {
      throw ArgumentError("Too many control points");
    }

    if (src.length == 1) {
      return createFromControlVectors(src[0], dest[0]);
    }

    if (src.length == 2) {
      return createFromControlVectors2(src[0], src[1], dest[0], dest[1]);
    }

    return createFromControlVectors3(src[0], src[1], src[2], dest[0], dest[1], dest[2]);
  }

  static AffineTransformation createFromBaseLines(
    Coordinate src0,
    Coordinate src1,
    Coordinate dest0,
    Coordinate dest1,
  ) {
    Coordinate rotPt = Coordinate((src0.x + dest1.x) - dest0.x, (src0.y + dest1.y) - dest0.y);
    double ang = Angle.angleBetweenOriented(src1, src0, rotPt);
    double srcDist = src1.distance(src0);
    double destDist = dest1.distance(dest0);
    if (srcDist == 0.0) {
      return AffineTransformation();
    }

    double scale = destDist / srcDist;
    AffineTransformation trans = AffineTransformation.translationInstance(-src0.x, -src0.y);
    trans.rotate(ang);
    trans.scale(scale, scale);
    trans.translate(dest0.x, dest0.y);
    return trans;
  }
}
