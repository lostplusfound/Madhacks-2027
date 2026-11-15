import 'seed_floor1.dart' show seedFloors;

/// Operator-only, non-overwriting seed for the four browsable floors.
Future<void> main(List<String> args) => seedFloors(args, [1, 0, 2, 3]);
