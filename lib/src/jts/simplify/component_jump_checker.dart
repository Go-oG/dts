import 'package:dts/src/jts/algorithm/ray_crossing_counter.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import 'tagged_line_string.dart';

class ComponentJumpChecker {
  final List<TaggedLineString> _components;

  ComponentJumpChecker(this._components);

  bool hasJump(TaggedLineString line, int start, int end, LineSegment seg) {
    Envelope sectionEnv = computeEnvelope2(line, start, end);
    for (TaggedLineString comp in _components) {
      if (comp == line) {
        continue;
      }

      Coordinate compPt = comp.getComponentPoint();
            if (sectionEnv.intersects(compPt)) {
                if (hasJumpAtComponent2(compPt, line, start, end, seg)) {
                    return true;
                }
            }
        }
        return false;
    }

    bool hasJump2(TaggedLineString line, LineSegment seg1, LineSegment seg2, LineSegment seg) {
        Envelope sectionEnv = computeEnvelope(seg1, seg2);
    for (TaggedLineString comp in _components) {
      if (comp == line) continue;

            Coordinate compPt = comp.getComponentPoint();
            if (sectionEnv.intersects(compPt)) {
                if (hasJumpAtComponent(compPt, seg1, seg2, seg)) {
                    return true;
                }
            }
        }
        return false;
    }

     static bool hasJumpAtComponent2(Coordinate compPt, TaggedLineString line, int start, int end, LineSegment seg) {
        int sectionCount = crossingCount3(compPt, line, start, end);
        int segCount = crossingCount(compPt, seg);
        bool hasJump = (sectionCount % 2) != (segCount % 2);
        return hasJump;
    }

     static bool hasJumpAtComponent(Coordinate compPt, LineSegment seg1, LineSegment seg2, LineSegment seg) {
        int sectionCount = crossingCount2(compPt, seg1, seg2);
        int segCount = crossingCount(compPt, seg);
        bool hasJump = (sectionCount % 2) != (segCount % 2);
        return hasJump;
    }

     static int crossingCount(Coordinate compPt, LineSegment seg) {
        RayCrossingCounter rcc = RayCrossingCounter(compPt);
        rcc.countSegment(seg.p0, seg.p1);
        return rcc.getCount();
    }

     static int crossingCount2(Coordinate compPt, LineSegment seg1, LineSegment seg2) {
        RayCrossingCounter rcc = RayCrossingCounter(compPt);
        rcc.countSegment(seg1.p0, seg1.p1);
        rcc.countSegment(seg2.p0, seg2.p1);
        return rcc.getCount();
    }

     static int crossingCount3(Coordinate compPt, TaggedLineString line, int start, int end) {
        RayCrossingCounter rcc = RayCrossingCounter(compPt);
        for (int i = start; i < end; i++) {
            rcc.countSegment(line.getCoordinate(i), line.getCoordinate(i + 1));
        }
        return rcc.getCount();
    }

     static Envelope computeEnvelope(LineSegment seg1, LineSegment seg2) {
        Envelope env = Envelope();
        env.expandToInclude(seg1.p0);
        env.expandToInclude(seg1.p1);
        env.expandToInclude(seg2.p0);
        env.expandToInclude(seg2.p1);
        return env;
    }

     static Envelope computeEnvelope2(TaggedLineString line, int start, int end) {
        Envelope env = Envelope();
        for (int i = start; i <= end; i++) {
            env.expandToInclude(line.getCoordinate(i));
        }
        return env;
    }
}
