import 'package:flutter/foundation.dart';
import 'package:madmaps_client/madmaps_client.dart' as api;
import '../navigation/floor_data.dart';
import '../navigation/building_routing.dart';
import '../navigation/routing.dart';

/// Presentation bridge. The native session remains owned by MapSessionScreen.
/// Both the shell and the session can be tested without creating a platform view.
class NavigationSession extends ChangeNotifier {
  FloorLocation? destination;
  Map<int, FloorGraph> floors = {};
  List<api.FloorConnector> connectors = [];
  void updateMaps(Map<int, FloorGraph> value, List<api.FloorConnector> links) {
    floors = value;
    connectors = links;
    revision++;
    notifyListeners();
  }

  bool attached = false;
  bool avoidStairs = false;
  FloorTravelMode travelMode = FloorTravelMode.elevator;
  void setTravelMode(FloorTravelMode value) {
    if (travelMode == value) return;
    travelMode = value;
    revision++;
    notifyListeners();
  }

  int? currentFloor;
  void setAvoidStairs(bool value) {
    if (avoidStairs == value) return;
    avoidStairs = value;
    revision++;
    notifyListeners();
  }

  String instruction = 'Find your location to start navigation';
  double? remainingMeters;
  bool _arrivalRecorded = false;
  bool get arrived => _arrivalRecorded;
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
    remainingMeters = tracking ? guidance.tripMeters : null;
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
