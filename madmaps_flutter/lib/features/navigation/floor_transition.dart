/// Debounces proximity to the planned connector independently of route progress.
class FloorTransitionTrigger {
  static const radiusMeters = 4.0;
  static const dwell = Duration(milliseconds: 500);
  String? _connector;
  DateTime? _nearSince;

  void reset() {
    _connector = null;
    _nearSince = null;
  }

  bool update(String? connector, double? distanceMeters, DateTime now) {
    if (connector == null ||
        distanceMeters == null ||
        !distanceMeters.isFinite ||
        distanceMeters > radiusMeters) {
      reset();
      return false;
    }
    if (_connector != connector) {
      _connector = connector;
      _nearSince = now;
    }
    return now.difference(_nearSince!) >= dwell;
  }
}
