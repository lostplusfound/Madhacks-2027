import 'package:material_ui/material_ui.dart';

import '../models/navigation_models.dart';

const brandCrimson = Color(0xffc5050c);
const routeCobalt = Color(0xff1769aa);
const deepInk = Color(0xff20313b);
const alabaster = Color(0xfff6f4f0);
const mutedTeal = Color(0xff4f9a9b);
const amber = Color(0xffc88a2e);
const loungeSlate = Color(0xff69758a);
const mapTeal = Color(0xff2186a0);

const morgridgePlaces = <Place>[
  Place(
    name: 'Room 2584',
    subtitle: 'Classroom · Floor 2',
    room: '2584',
    floor: 2,
    icon: Icons.meeting_room_outlined,
    color: mutedTeal,
    point: Offset(.35, .16),
    category: 'Classroom',
  ),
  Place(
    name: 'Room 2532',
    subtitle: 'Classroom · Floor 2',
    room: '2532',
    floor: 2,
    icon: Icons.meeting_room_outlined,
    color: mapTeal,
    point: Offset(.25, .9),
    category: 'Classroom',
    hours: PlaceHours(Availability.closed),
  ),
  Place(
    name: 'Learning Center',
    subtitle: 'Study space · Floor 2',
    room: '2580',
    floor: 2,
    icon: Icons.menu_book_rounded,
    color: amber,
    point: Offset(.47, .16),
    category: 'Study',
    hours: PlaceHours(Availability.closingSoon, minutesUntilClose: 45),
  ),
  Place(
    name: 'Student Org',
    subtitle: 'Student organizations',
    room: '2556',
    floor: 2,
    icon: Icons.groups_rounded,
    color: loungeSlate,
    point: Offset(.17, .41),
    category: 'Commons',
  ),
  Place(
    name: 'Undergrad Lounge',
    subtitle: 'Quiet seating · Floor 2',
    room: '2610A',
    floor: 2,
    icon: Icons.weekend_rounded,
    color: loungeSlate,
    point: Offset(.79, .3),
    category: 'Lounge',
  ),
  Place(
    name: 'Library',
    subtitle: 'Quiet study · 24 seats',
    room: '2540',
    floor: 2,
    icon: Icons.local_library_rounded,
    color: amber,
    point: Offset(.2, .57),
    category: 'Study',
  ),
  Place(
    name: 'Accessible restroom',
    subtitle: 'All-gender · Step-free',
    room: '2F East',
    floor: 2,
    icon: Icons.wc_rounded,
    color: Color(0xff31846c),
    point: Offset(.56, .52),
    category: 'Amenity',
  ),
  Place(
    name: 'Hello World Auditorium',
    subtitle: 'Lecture hall · 286 seats',
    room: '1570',
    floor: 1,
    icon: Icons.account_balance_rounded,
    color: mutedTeal,
    point: Offset(.28, .19),
    category: 'Classroom',
  ),
  Place(
    name: 'Morgridge Hall Heart',
    subtitle: 'Commons · Main level',
    room: '1st Floor',
    floor: 1,
    icon: Icons.groups_2_rounded,
    color: loungeSlate,
    point: Offset(.55, .43),
    category: 'Commons',
  ),
  Place(
    name: 'Cafe',
    subtitle: 'Food and seating · Floor 1',
    room: '1F Cafe',
    floor: 1,
    icon: Icons.local_cafe_rounded,
    color: amber,
    point: Offset(.72, .32),
    category: 'Food',
  ),
  Place(
    name: 'Main entrance',
    subtitle: 'Johnson Street · Step-free',
    room: 'Entrance',
    floor: 1,
    icon: Icons.door_front_door_rounded,
    color: Color(0xff31846c),
    point: Offset(.25, .88),
    category: 'Exit',
  ),
];

const seededSavedPlaces = ['Room 2584', 'Learning Center'];
const seededRecentPlaces = ['Learning Center', 'Room 2584'];
const seededVisitHistory = ['Learning Center', 'Learning Center', 'Room 2584'];

List<RouteOption> buildMockRoutes({
  required bool stepFree,
  required int originFloor,
  required int destinationFloor,
  required Offset originPoint,
  required Offset destinationPoint,
}) {
  final crossesFloor = originFloor != destinationFloor;
  // These frontend connector points match the visible stair/elevator hubs on
  // the two plans. Physical calibration can replace them later without
  // changing the navigation UI.
  RouteOption makeRoute(bool useElevator) {
    final sourceConnector = useElevator
        ? const Offset(.55, .53)
        : const Offset(.48, .63);
    final destinationConnector = sourceConnector;
    final transferName = useElevator ? 'elevator' : 'main stairs';
    final startSegment = crossesFloor
        ? [originPoint, sourceConnector]
        : [
            originPoint,
            const Offset(.43, .53),
            const Offset(.55, .43),
            destinationPoint,
          ];
    final endSegment = crossesFloor
        ? [destinationConnector, const Offset(.55, .43), destinationPoint]
        : <Offset>[];
    final steps = crossesFloor
        ? <NavigationStep>[
            NavigationStep(
              'Follow the corridor to the $transferName',
              floor: originFloor,
            ),
            NavigationStep(
              'Take the $transferName to floor $destinationFloor',
              floor: originFloor,
              transitionToFloor: destinationFloor,
            ),
            const NavigationStep('Follow the corridor to your destination'),
            const NavigationStep('You have arrived'),
          ]
        : const <NavigationStep>[
            NavigationStep('Head along the main corridor'),
            NavigationStep('Turn at the open study area'),
            NavigationStep('Continue to your destination'),
            NavigationStep('You have arrived'),
          ];
    return RouteOption(
      name: useElevator ? 'Step-free' : 'Quickest',
      minutes: (destinationFloor == 2 ? 2 : 3) + (useElevator ? 1 : 0),
      distanceFeet: (destinationFloor == 2 ? 256 : 344) + (useElevator ? 59 : 0),
      stepFree: useElevator,
      points: startSegment,
      floorSegments: crossesFloor
          ? {originFloor: startSegment, destinationFloor: endSegment}
          : {originFloor: startSegment},
      steps: steps,
    );
  }

  final stairs = makeRoute(false);
  final elevator = makeRoute(true);
  return stepFree ? [elevator] : [stairs, elevator];
}
