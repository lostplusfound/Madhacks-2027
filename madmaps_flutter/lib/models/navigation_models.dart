import 'package:material_ui/material_ui.dart';

enum Availability { open, closed, closingSoon }

@immutable
class PlaceHours {
  const PlaceHours(this.status, {this.minutesUntilClose});
  final Availability status;
  final int? minutesUntilClose;

  String get label => switch (status) {
    Availability.open => 'Open',
    Availability.closed => 'Closed',
    Availability.closingSoon =>
      'Closing soon · ${minutesUntilClose ?? 45} min left',
  };
}

@immutable
class Place {
  const Place({
    required this.name,
    required this.subtitle,
    required this.room,
    required this.floor,
    required this.icon,
    required this.color,
    required this.point,
    this.category = 'Room',
    this.hours = const PlaceHours(Availability.open),
  });

  final String name;
  final String subtitle;
  final String room;
  final int floor;
  final IconData icon;
  final Color color;
  final Offset point;
  final String category;
  final PlaceHours hours;
}

@immutable
class LocationFix {
  const LocationFix({
    required this.label,
    required this.floor,
    required this.point,
  });

  final String label;
  final int floor;
  final Offset point;
}

@immutable
class RouteOption {
  const RouteOption({
    required this.name,
    required this.minutes,
    required this.distanceFeet,
    required this.stepFree,
    required this.points,
    required this.steps,
    required this.floorSegments,
  });

  final String name;
  final int minutes;
  final int distanceFeet;
  final bool stepFree;
  final List<Offset> points;
  final List<NavigationStep> steps;
  final Map<int, List<Offset>> floorSegments;
}

@immutable
class NavigationStep {
  const NavigationStep(this.instruction, {this.floor, this.transitionToFloor});
  final String instruction;
  final int? floor;
  final int? transitionToFloor;
}

@immutable
class RoutePlan {
  const RoutePlan({
    required this.destination,
    required this.origin,
    required this.options,
  });

  final Place destination;
  final LocationFix origin;
  final List<RouteOption> options;

  RouteOption get quickest => options.first;
}
