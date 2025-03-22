abstract interface class BoundaryNodeRule {
  const BoundaryNodeRule();

  static const mod2BR = Mod2BoundaryNodeRule();

  static const endpointBR = EndPointBoundaryNodeRule();

  static const multiValentEndpoint = MultiValentEndPointBoundaryNodeRule();

  static const monoValentEndpointBR = MonoValentEndPointBoundaryNodeRule();

  static const ogcSfsBR = mod2BR;

  bool isInBoundary(int boundaryCount);
}

class Mod2BoundaryNodeRule implements BoundaryNodeRule {
  const Mod2BoundaryNodeRule();

  @override
  bool isInBoundary(int boundaryCount) {
    return (boundaryCount % 2) == 1;
  }

  @override
  String toString() {
    return "Mod2 Boundary Node Rule";
  }
}

class EndPointBoundaryNodeRule implements BoundaryNodeRule {
  const EndPointBoundaryNodeRule();

  @override
  bool isInBoundary(int boundaryCount) {
    return boundaryCount > 0;
  }

  @override
  String toString() {
    return "EndPoint Boundary Node Rule";
  }
}

class MultiValentEndPointBoundaryNodeRule implements BoundaryNodeRule {
  const MultiValentEndPointBoundaryNodeRule();

  @override
  bool isInBoundary(int boundaryCount) {
    return boundaryCount > 1;
  }

  @override
  String toString() {
    return "MultiValent EndPoint Boundary Node Rule";
  }
}

class MonoValentEndPointBoundaryNodeRule implements BoundaryNodeRule {
  const MonoValentEndPointBoundaryNodeRule();

  @override
  bool isInBoundary(int boundaryCount) {
    return boundaryCount == 1;
  }

  @override
  String toString() {
    return "MonoValent EndPoint Boundary Node Rule";
  }
}
