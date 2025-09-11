import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/math/math.dart';

import 'affine_transformation.dart';

class AffineTransformationBuilder {
  final Coordinate _src0;
  final Coordinate _src1;
  final Coordinate _src2;
  final Coordinate _dest0;
  final Coordinate _dest1;
  final Coordinate _dest2;

  late double m00;

  late double m01;

  late double m02;

  late double m10;

  late double m11;

  late double m12;

  AffineTransformationBuilder(this._src0, this._src1, this._src2, this._dest0,
      this._dest1, this._dest2);

  AffineTransformation? getTransformation() {
    bool isSolvable = compute();
    if (isSolvable) {
      return AffineTransformation.of2(m00, m01, m02, m10, m11, m12);
    }

    return null;
  }

  bool compute() {
    Array<double> bx = [_dest0.x, _dest1.x, _dest2.x].toArray();
    Array<double>? row0 = solve(bx);
    if (row0 == null) return false;

    m00 = row0[0];
    m01 = row0[1];
    m02 = row0[2];
    Array<double> by = [_dest0.y, _dest1.y, _dest2.y].toArray();
    Array<double>? row1 = solve(by);
    if (row1 == null) return false;

    m10 = row1[0];
    m11 = row1[1];
    m12 = row1[2];
    return true;
  }

  Array<double>? solve(Array<double> b) {
    Array<Array<double>> a = Array(3);
    a[0] = [_src0.x, _src0.y, 1.0].toArray();
    a[1] = [_src1.x, _src1.y, 1.0].toArray();
    a[2] = [_src2.x, _src2.y, 1.0].toArray();
    return Matrix.solve(a, b);
  }
}
