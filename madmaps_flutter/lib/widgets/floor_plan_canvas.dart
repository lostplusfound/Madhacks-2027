import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/morgridge_mock_data.dart';
import '../models/navigation_models.dart';

class FloorPlanCanvas extends StatelessWidget {
  const FloorPlanCanvas({
    super.key,
    required this.floor,
    required this.highContrast,
    required this.places,
    required this.route,
    required this.origin,
    required this.destination,
    required this.onPlaceTap,
    this.displayName = _identityName,
    this.routeStep = 0,
    this.walking = false,
  });

  final int floor;
  final bool highContrast;
  final List<Place> places;
  final RouteOption? route;
  final LocationFix? origin;
  final Place? destination;
  final ValueChanged<Place> onPlaceTap;
  final String Function(Place) displayName;
  final int routeStep;
  final bool walking;

  static String _identityName(Place place) => place.name;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final floorPlaces = places
          .where((place) => place.floor == floor)
          .toList();
      return Stack(
        fit: StackFit.expand,
        children: [
          if (floor == 1)
            const Positioned.fill(
              child: IgnorePointer(
                child: Image(
                  image: AssetImage('assets/floor1/plan.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          CustomPaint(
            painter: _FloorPlanPainter(
              floor: floor,
              highContrast: highContrast,
              route: route,
              origin: origin,
              destination: destination,
              routeStep: routeStep,
              walking: walking,
            ),
          ),
          for (final entry in floorPlaces.indexed)
            Positioned(
              left:
                  size.width *
                      _spreadPoint(entry.$2, entry.$1, floorPlaces).dx -
                  16,
              top:
                  size.height *
                      _spreadPoint(entry.$2, entry.$1, floorPlaces).dy -
                  16,
              child: Semantics(
                button: true,
                label:
                    '${displayName(entry.$2) == entry.$2.name ? entry.$2.name : '${displayName(entry.$2)} · ${entry.$2.name}'}, floor ${entry.$2.floor}, ${entry.$2.hours.label}',
                child: Tooltip(
                  message: displayName(entry.$2) == entry.$2.name
                      ? entry.$2.name
                      : '${displayName(entry.$2)} · ${entry.$2.name}',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onPlaceTap(entry.$2),
                    // Tooltip is the touch equivalent of desktop hover.
                    // A long press deliberately avoids a modal dialog.
                    onLongPress: () {},
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: entry.$2.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .14),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(entry.$2.icon, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Offset _spreadPoint(Place place, int index, List<Place> all) {
    final nearby = [
      for (var i = 0; i < all.length; i++)
        if ((all[i].point - place.point).distance < .028) i,
    ];
    if (nearby.length < 2) return place.point;
    final rank = nearby.indexOf(index);
    final angle = rank * 6.283185307 / nearby.length;
    return place.point + Offset(.018 * math.cos(angle), .018 * math.sin(angle));
  }
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter({
    required this.floor,
    required this.highContrast,
    required this.route,
    required this.origin,
    required this.destination,
    required this.routeStep,
    required this.walking,
  });

  final int floor;
  final bool highContrast;
  final RouteOption? route;
  final LocationFix? origin;
  final Place? destination;
  final int routeStep;
  final bool walking;

  @override
  void paint(Canvas canvas, Size size) {
    final background = highContrast
        ? const Color(0xfff2f3ee)
        : const Color(0xffefeee9);
    if (floor != 1) canvas.drawRect(Offset.zero & size, Paint()..color = background);
    Offset point(double x, double y) => Offset(size.width * x, size.height * y);

    final boundary = _boundary(size, point);

    final wallColor = highContrast
        ? const Color(0xff354650)
        : const Color(0xffaab5b9);
    final linePaint = Paint()
      ..color = wallColor
      ..strokeWidth = highContrast ? 2.4 : 1.5
      ..style = PaintingStyle.stroke;
    final roomPaint = Paint()..color = Colors.white;
    final openBelowPaint = Paint()
      ..color = highContrast
          ? const Color(0xffb9c7d3)
          : const Color(0xffdce5ea);
    final loungePaint = Paint()
      ..color = highContrast
          ? const Color(0xff59677c)
          : const Color(0xff738096);
    final classroomPaint = Paint()
      ..color = highContrast
          ? const Color(0xff27819a)
          : const Color(0xff78b9c2);
    final studyPaint = Paint()
      ..color = highContrast
          ? const Color(0xffa8660b)
          : const Color(0xffe2bd78);

    canvas.save();
    if (floor != 1) canvas.clipPath(boundary);

    if (floor == 2) {
      _room(
        canvas,
        [point(.13, .08), point(.78, .08), point(.78, .2), point(.16, .2)],
        loungePaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.12, .27), point(.25, .27), point(.25, .35), point(.12, .35)],
        roomPaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.13, .39), point(.25, .39), point(.25, .5), point(.13, .5)],
        loungePaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.3, .24), point(.68, .24), point(.68, .36), point(.3, .36)],
        studyPaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.7, .24), point(.85, .34), point(.7, .43), point(.66, .34)],
        loungePaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.15, .53), point(.28, .53), point(.28, .62), point(.15, .62)],
        studyPaint,
        linePaint,
      );
      _room(
        canvas,
        [
          point(.3, .41),
          point(.59, .41),
          point(.64, .51),
          point(.54, .62),
          point(.38, .59),
        ],
        openBelowPaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.16, .65), point(.4, .65), point(.4, .73), point(.16, .73)],
        loungePaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.1, .8), point(.9, .8), point(.9, .98), point(.1, .98)],
        roomPaint,
        linePaint,
      );
      for (var i = 0; i < 12; i++) {
        final x = .14 + i * .062;
        canvas.drawLine(
          point(x, .08),
          point(x, .21),
          Paint()..color = studyPaint.color,
        );
      }
      for (final x in [.15, .32, .49]) {
        _room(
          canvas,
          [
            point(x - .1, .82),
            point(x + .1, .82),
            point(x + .1, .975),
            point(x - .1, .975),
          ],
          classroomPaint,
          linePaint,
        );
      }
      _label(canvas, '2580', point(.46, .13), size.width * .06);
      _label(canvas, 'LEARNING CENTER', point(.48, .3), size.width * .017);
      _label(canvas, 'STUDENT ORG', point(.19, .44), size.width * .018);
      _label(canvas, 'LIBRARY', point(.21, .58), size.width * .018);
      _label(canvas, 'OPEN TO BELOW', point(.49, .5), size.width * .017);
      _label(canvas, 'UNDERGRAD LOUNGE', point(.78, .33), size.width * .014);
      _label(canvas, '2532', point(.24, .9), size.width * .035);
      _label(canvas, '2522', point(.32, .9), size.width * .035);
      _label(canvas, '2516', point(.49, .9), size.width * .035);
    } else if (floor == -1) {
      _room(
        canvas,
        [
          point(.13, .1),
          point(.38, .07),
          point(.52, .13),
          point(.45, .29),
          point(.28, .37),
          point(.15, .3),
        ],
        classroomPaint,
        linePaint,
      );
      _room(
        canvas,
        [
          point(.12, .38),
          point(.84, .12),
          point(.89, .3),
          point(.48, .55),
          point(.27, .48),
        ],
        roomPaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.38, .51), point(.68, .57), point(.67, .71), point(.38, .7)],
        loungePaint,
        linePaint,
      );
      _room(
        canvas,
        [point(.12, .79), point(.37, .8), point(.37, .96), point(.12, .95)],
        classroomPaint,
        linePaint,
      );
      _label(
        canvas,
        'HELLO WORLD AUDITORIUM · 1570',
        point(.3, .2),
        size.width * .022,
      );
      _label(
        canvas,
        'MORGRIDGE HALL HEART',
        point(.54, .42),
        size.width * .016,
      );
      _label(canvas, '1st Floor', point(.54, .59), size.width * .04);
      _label(canvas, '1524', point(.24, .88), size.width * .04);
      _label(canvas, 'CAFE', point(.7, .32), size.width * .02);
    }

    // The route layer is absent until a navigation route is active.
    final activeRoute = route;
    if (activeRoute != null) {
      final routePoints = activeRoute.floorSegments[floor] ?? const <Offset>[];
      if (routePoints.length < 2) {
        canvas.restore();
        canvas.drawPath(
          boundary,
          linePaint..strokeWidth = highContrast ? 3.4 : 2.2,
        );
        return;
      }
      final first = point(routePoints.first.dx, routePoints.first.dy);
      final routePath = Path()..moveTo(first.dx, first.dy);
      for (final waypoint in routePoints.skip(1)) {
        final pixel = point(waypoint.dx, waypoint.dy);
        routePath.lineTo(pixel.dx, pixel.dy);
      }
      final routeColor = highContrast ? const Color(0xffdb6d00) : routeCobalt;
      canvas.drawPath(
        routePath,
        Paint()
          ..color = walking ? routeColor.withValues(alpha: .38) : routeColor
          ..strokeWidth = size.width * .012
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      if (walking) {
        final count = routeStep.clamp(1, routePoints.length) as int;
        if (count > 1) {
          final done = Path();
          final firstDone = point(routePoints.first.dx, routePoints.first.dy);
          done.moveTo(firstDone.dx, firstDone.dy);
          for (final waypoint in routePoints.skip(1).take(count - 1)) {
            final pixel = point(waypoint.dx, waypoint.dy);
            done.lineTo(pixel.dx, pixel.dy);
          }
          canvas.drawPath(
            done,
            Paint()
              ..color = routeColor
              ..strokeWidth = size.width * .014
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
      }
      if (origin != null && origin!.floor == floor) {
        _marker(
          canvas,
          point(origin!.point.dx, origin!.point.dy),
          highContrast ? const Color(0xff006b83) : const Color(0xff25825d),
          'YOU',
        );
      }
      if (destination != null && destination!.floor == floor) {
        _marker(
          canvas,
          point(destination!.point.dx, destination!.point.dy),
          highContrast ? const Color(0xffdb6d00) : brandCrimson,
          'END',
        );
      }
    } else if (origin != null && origin!.floor == floor) {
      _marker(
        canvas,
        point(origin!.point.dx, origin!.point.dy),
        const Color(0xff25825d),
        'YOU',
      );
    }

    canvas.restore();
    if (floor != 1) {
      canvas.drawPath(
        boundary,
        linePaint..strokeWidth = highContrast ? 3.4 : 2.2,
      );
    }
  }

  Path _boundary(Size size, Offset Function(double, double) p) {
    final normalized = floor == 1
        ? const [
            Offset(.28, .02),
            Offset(.79, .02),
            Offset(.96, .21),
            Offset(.77, .38),
            Offset(.58, .51),
            Offset(.63, .69),
            Offset(.43, .77),
            Offset(.35, .94),
            Offset(.05, .93),
            Offset(.05, .68),
            Offset(.19, .51),
            Offset(.05, .41),
            Offset(.06, .13),
          ]
        : const [
            Offset(.05, .02),
            Offset(.80, .02),
            Offset(.97, .22),
            Offset(.84, .34),
            Offset(.62, .48),
            Offset(.52, .56),
            Offset(.59, .65),
            Offset(.58, .98),
            Offset(.05, .98),
            Offset(.03, .48),
            Offset(.03, .15),
          ];
    final path = Path()
      ..moveTo(
        size.width * normalized.first.dx,
        size.height * normalized.first.dy,
      );
    for (final point in normalized.skip(1)) {
      path.lineTo(size.width * point.dx, size.height * point.dy);
    }
    return path..close();
  }

  void _room(Canvas canvas, List<Offset> points, Paint fill, Paint outline) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  void _label(Canvas canvas, String text, Offset center, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: deepInk,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          fontFamily: 'sans-serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: fontSize * 10);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _marker(Canvas canvas, Offset center, Color color, String label) {
    canvas.drawCircle(
      center,
      15,
      Paint()..color = color.withValues(alpha: .16),
    );
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(
          label == 'YOU'
              ? Icons.directions_walk_rounded.codePoint
              : Icons.flag_rounded.codePoint,
        ),
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontFamily: Icons.directions_walk_rounded.fontFamily,
          package: Icons.directions_walk_rounded.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.floor != floor ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.route != route ||
      oldDelegate.origin != origin ||
      oldDelegate.destination != destination ||
      oldDelegate.routeStep != routeStep ||
      oldDelegate.walking != walking;
}
