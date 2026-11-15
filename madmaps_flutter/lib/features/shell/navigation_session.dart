import 'package:flutter/foundation.dart';
import '../navigation/floor_data.dart';
import '../navigation/routing.dart';

/// Presentation bridge. The native session remains owned by MapSessionScreen.
/// Both the shell and the session can be tested without creating a platform view.
class NavigationSession extends ChangeNotifier {
  FloorLocation? destination;
  bool attached = false;
  String instruction = 'Find your location to start navigation';
  double? remainingMeters;
  bool _arrivalRecorded = false;
  bool _closed = false;
  int revision = 0;
  VoidCallback? onCancel;
  void choose(FloorLocation place) {
    destination = place;
    revision++;
    _arrivalRecorded = false;
    instruction = 'Find your location to start navigation';
    remainingMeters = null;
    notifyListeners();
  }

  void cancel() {
    destination = null;
    revision++;
    remainingMeters = null;
    _arrivalRecorded = false;
    onCancel?.call();
    notifyListeners();
  }

  /// Returns true once per trip, even if tracking is lost after arrival.
  bool update(GuidanceState guidance, {required bool tracking}) {
    final previousInstruction = instruction;
    final previousDistance = remainingMeters;
    remainingMeters = tracking ? guidance.remainingMeters : null;
    instruction = !tracking
        ? 'Tracking paused - scan surroundings to resume'
        : guidance.arrived
        ? 'You have arrived near the entrance'
        : guidance.remainingMeters == null
        ? guidance.status
        : guidance.maneuver;
    final arrival =
        tracking &&
        guidance.arrived &&
        !_arrivalRecorded &&
        destination != null;
    if (arrival) _arrivalRecorded = true;
    if (!_closed &&
        (arrival ||
            previousInstruction != instruction ||
            previousDistance != remainingMeters)) {
      notifyListeners();
    }
    return arrival;
  }

  void detach() {
    attached = false;
    onCancel = null;
    if (!_closed) cancel();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
