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
  });

  final int floor;
  final bool highContrast;
  final List<Place> places;
  final RouteOption? route;
  final LocationFix? origin;
  final Place? destination;
  final ValueChanged<Place> onPlaceTap;
  final String Function(Place) displayName;

  static String _identityName(Place place) => place.name;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _FloorPlanPainter(
              floor: floor,
              highContrast: highContrast,
              route: route,
              origin: origin,
              destination: destination,
            ),
          ),
          for (final place in places.where((place) => place.floor == floor))
            Positioned(
              left: size.width * place.point.dx - 16,
              top: size.height * place.point.dy - 16,
              child: Semantics(
                button: true,
                label:
                    '${displayName(place)}, ${place.room}, floor ${place.floor}, ${place.hours.label}',
                child: Tooltip(
                  message: '${place.name} · ${place.room}',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onPlaceTap(place),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: place.color,
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
                      child: Icon(place.icon, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter({
    required this.floor,
    required this.highContrast,
    required this.route,
    required this.origin,
    required this.destination,
  });

  final int floor;
  final bool highContrast;
  final RouteOption? route;
  final LocationFix? origin;
  final Place? destination;

  @override
  void paint(Canvas canvas, Size size) {
    final background = highContrast
        ? const Color(0xfff2f3ee)
        : const Color(0xffefeee9);
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
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
    canvas.clipPath(boundary);

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
        roomPaint,
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
    } else if (floor == 1) {
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
      canvas.drawPath(
        routePath,
        Paint()
          ..color = (highContrast ? const Color(0xffdb6d00) : routeCobalt)
              .withValues(alpha: .2)
          ..strokeWidth = size.width * .035
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        routePath,
        Paint()
          ..color = highContrast ? const Color(0xffdb6d00) : routeCobalt
          ..strokeWidth = size.width * .012
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
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
    canvas.drawPath(
      boundary,
      linePaint..strokeWidth = highContrast ? 3.4 : 2.2,
    );
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
      12,
      Paint()..color = color.withValues(alpha: .18),
    );
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 3, Paint()..color = color);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy + 9));
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.floor != floor ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.route != route ||
      oldDelegate.origin != origin ||
      oldDelegate.destination != destination;
}
