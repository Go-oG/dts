import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/scaled_noder.dart';
import 'package:dts/src/jts/noding/snapround/snap_rounding_noder.dart';

import 'buffer_builder.dart';
import 'buffer_parameters.dart';

class BufferOp {
  static const int kCapRound = BufferParameters.kCapRound;

  static const int kCapButt = BufferParameters.kCapFlat;

  static const int kCapFlat = BufferParameters.kCapFlat;

  static const int kCapSquare = BufferParameters.kCapSquare;

  static final int _kMaxPrecisionDigits = 12;

  static double precisionScaleFactor(Geometry g, double distance, int maxPrecisionDigits) {
    Envelope env = g.getEnvelopeInternal();
    double envMax = MathUtil.max2(
      Math.abs(env.maxX),
      Math.abs(env.maxY),
      Math.abs(env.minX),
      Math.abs(env.minY),
    );
    double expandByDistance = (distance > 0.0) ? distance : 0.0;
    double bufEnvMax = envMax + (2 * expandByDistance);
    int bufEnvPrecisionDigits = ((Math.log(bufEnvMax) / Math.log(10)) + 1.0).toInt();
    int minUnitLog10 = maxPrecisionDigits - bufEnvPrecisionDigits;
    double scaleFactor = Math.pow(10.0, minUnitLog10);
    return scaleFactor;
  }

  static Geometry bufferOp(Geometry g, double distance) {
    BufferOp gBuf = BufferOp(g);
    Geometry geomBuf = gBuf.getResultGeometry(distance);
    return geomBuf;
  }

  static Geometry bufferOp3(Geometry g, double distance, BufferParameters? params) {
    BufferOp bufOp = BufferOp(g, params);
    Geometry geomBuf = bufOp.getResultGeometry(distance);
    return geomBuf;
  }

  static Geometry bufferOp2(Geometry g, double distance, int quadrantSegments) {
    BufferOp bufOp = BufferOp(g);
    bufOp.setQuadrantSegments(quadrantSegments);
    Geometry geomBuf = bufOp.getResultGeometry(distance);
    return geomBuf;
  }

  static Geometry bufferOp4(Geometry g, double distance, int quadrantSegments, int endCapStyle) {
    BufferOp bufOp = BufferOp(g);
    bufOp.setQuadrantSegments(quadrantSegments);
    bufOp.setEndCapStyle(endCapStyle);
    Geometry geomBuf = bufOp.getResultGeometry(distance);
    return geomBuf;
  }

  static Geometry? bufferByZero(Geometry geom, bool isBothOrientations) {
    Geometry buf0 = geom.buffer(0);
    if (!isBothOrientations) {
      return buf0;
    }

    BufferOp op = BufferOp(geom);
    op.isInvertOrientation = true;
    Geometry buf0Inv = op.getResultGeometry(0);
    return combine(buf0, buf0Inv);
  }

  static Geometry combine(Geometry poly0, Geometry poly1) {
    if (poly1.isEmpty()) {
      return poly0;
    }

    if (poly0.isEmpty()) {
      return poly1;
    }

    List<Polygon> polys = [];
    extractPolygons(poly0, polys);
    extractPolygons(poly1, polys);
    if (polys.size == 1) {
      return polys.get(0);
    }

    return poly0.factory.createMultiPolygon(GeometryFactory.toPolygonArray(polys));
  }

  static void extractPolygons(Geometry poly0, List<Polygon> polys) {
    for (int i = 0; i < poly0.getNumGeometries(); i++) {
      polys.add((poly0.getGeometryN(i) as Polygon));
    }
  }

  final Geometry _argGeom;

  double distance = 0;

  BufferParameters _bufParams = BufferParameters.empty();

  Geometry? _resultGeometry;

  dynamic _saveException;

  bool isInvertOrientation = false;

  BufferOp(this._argGeom, [BufferParameters? bufParams]) {
    if (bufParams != null) {
      _bufParams = bufParams;
    }
  }

  void setEndCapStyle(int endCapStyle) {
    _bufParams.setEndCapStyle(endCapStyle);
  }

  void setQuadrantSegments(int quadrantSegments) {
    _bufParams.setQuadrantSegments(quadrantSegments);
  }

  Geometry getResultGeometry(double distance) {
    this.distance = distance;
    computeGeometry();
    return _resultGeometry!;
  }

  void computeGeometry() {
    bufferOriginalPrecision();
    if (_resultGeometry != null) {
      return;
    }

    PrecisionModel argPM = _argGeom.factory.getPrecisionModel();
    if (argPM.getType() == PrecisionModel.FIXED) {
      bufferFixedPrecision(argPM);
    } else {
      bufferReducedPrecision();
    }
  }

  void bufferReducedPrecision() {
    for (int precDigits = _kMaxPrecisionDigits; precDigits >= 0; precDigits--) {
      try {
        bufferReducedPrecision2(precDigits);
      } catch (ex) {
        _saveException = ex;
      }
      if (_resultGeometry != null) {
        return;
      }
    }
    throw _saveException;
  }

  void bufferReducedPrecision2(int precisionDigits) {
    double sizeBasedScaleFactor = precisionScaleFactor(_argGeom, distance, precisionDigits);
    PrecisionModel fixedPM = PrecisionModel.fixed(sizeBasedScaleFactor);
    bufferFixedPrecision(fixedPM);
  }

  void bufferOriginalPrecision() {
    try {
      final bufBuilder = createBufferBullder();
      _resultGeometry = bufBuilder.buffer(_argGeom, distance);
    } catch (ex) {
      _saveException = ex;
    }
  }

  BufferBuilder createBufferBullder() {
    BufferBuilder bufBuilder = BufferBuilder(_bufParams);
    bufBuilder.setInvertOrientation(isInvertOrientation);
    return bufBuilder;
  }

  void bufferFixedPrecision(PrecisionModel fixedPM) {
    Noder snapNoder = SnapRoundingNoder(PrecisionModel.fixed(1.0));
    Noder noder = ScaledNoder(snapNoder, fixedPM.getScale());
    BufferBuilder bufBuilder = createBufferBullder();
    bufBuilder.setWorkingPrecisionModel(fixedPM);
    bufBuilder.setNoder(noder);
    _resultGeometry = bufBuilder.buffer(_argGeom, distance);
  }
}
