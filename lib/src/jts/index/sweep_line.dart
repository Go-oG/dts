abstract interface class SweepLineOverlapAction {
  void overlap(SweepLineInterval s0, SweepLineInterval s1);
}

class SweepLineInterval<T> {
  late double min;
  late double max;

  T? item;

  SweepLineInterval(double min, double max, [this.item]) {
    this.min = (min < max) ? min : max;
    this.max = (max > min) ? max : min;
  }

  double getMin() {
    return min;
  }

  double getMax() {
    return max;
  }
}

class SweepLineEvent implements Comparable<SweepLineEvent> {
  static const int _insert = 1;
  static const int _delete = 2;

  double xValue;

  late int eventType;

  final SweepLineEvent? insertEvent;

  int deleteEventIndex = 0;

  SweepLineInterval sweepInt;

  SweepLineEvent(this.xValue, this.insertEvent, this.sweepInt) {
    eventType = _insert;
    if (insertEvent != null) {
      eventType = _delete;
    }
  }

  bool isInsert() {
    return insertEvent == null;
  }

  bool isDelete() {
    return insertEvent != null;
  }

  SweepLineInterval getInterval() {
    return sweepInt;
  }

  @override
  int compareTo(SweepLineEvent pe) {
    if (xValue < pe.xValue) {
      return -1;
    }

    if (xValue > pe.xValue) {
      return 1;
    }

    if (eventType < pe.eventType) {
      return -1;
    }

    if (eventType > pe.eventType) {
      return 1;
    }

    return 0;
  }
}

class SweepLineIndex {
  List<SweepLineEvent> events = [];

  bool _indexBuilt = false;

  int _nOverlaps = 0;

  void add(SweepLineInterval sweepInt) {
    final insertEvent = SweepLineEvent(sweepInt.getMin(), null, sweepInt);
    events.add(insertEvent);
    events.add(SweepLineEvent(sweepInt.getMax(), insertEvent, sweepInt));
  }

  void buildIndex() {
    if (_indexBuilt) {
      return;
    }
    events.sort();

    for (int i = 0; i < events.length; i++) {
      SweepLineEvent ev = events[i];
      if (ev.isDelete()) {
        ev.insertEvent!.deleteEventIndex = i;
      }
    }
    _indexBuilt = true;
  }

  void computeOverlaps(SweepLineOverlapAction action) {
    _nOverlaps = 0;
    buildIndex();
    for (int i = 0; i < events.length; i++) {
      SweepLineEvent ev = events[i];
      if (ev.isInsert()) {
        processOverlaps(i, ev.deleteEventIndex, ev.getInterval(), action);
      }
    }
  }

  void processOverlaps(
      int start, int end, SweepLineInterval s0, SweepLineOverlapAction action) {
    for (int i = start; i < end; i++) {
      SweepLineEvent ev = events[i];
      if (ev.isInsert()) {
        SweepLineInterval s1 = ev.getInterval();
        action.overlap(s0, s1);
        _nOverlaps++;
      }
    }
  }
}
