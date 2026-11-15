import 'dart:convert';
import 'dart:math' as math;

/// Validate the portable subset of a local AR map. Never accept graph overrides.
DateTime validateCapture(
  String raw,
  String captureId,
  int floor,
  DateTime now,
) {
  if (raw.length > 131072) throw const FormatException('Capture is too large');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  if (map['id'] != captureId || captureId.isEmpty || captureId.length > 128) {
    throw const FormatException('Invalid capture ID');
  }
  final quality = (map['scanCoverage'] as List? ?? []).cast<num>();
  if (quality.any((v) => !v.isFinite || v < 0 || v > 1))
    throw const FormatException('Invalid scan coverage');
  final setup = map['floor'] as Map<String, dynamic>;
  if (setup['floorNumber'] != floor || setup['enabled'] != true) {
    throw const FormatException('Capture floor mismatch');
  }
  for (final key in ['nodes', 'locations', 'anchorNodes']) {
    if ((setup[key] as Map? ?? {}).isNotEmpty) {
      throw const FormatException(
        'Shared captures cannot override map geometry',
      );
    }
  }
  final anchors = (map['anchors'] as List).cast<Map<String, dynamic>>();
  if (anchors.length < 2 || anchors.length > 20) {
    throw const FormatException('Capture needs 2 to 20 anchors');
  }
  final byId = <String, Map<String, dynamic>>{};
  DateTime? expiry;
  for (final anchor in anchors) {
    final id = anchor['id'] as String;
    final cloudId = anchor['cloudId'] as String;
    if (id.isEmpty ||
        cloudId.isEmpty ||
        cloudId.length > 512 ||
        byId.containsKey(id)) {
      throw const FormatException('Invalid or duplicate anchor');
    }
    byId[id] = anchor;
    final pose = (anchor['pose'] as List).cast<num>();
    if (pose.length != 16 ||
        pose.any((v) => !v.isFinite) ||
        pose[3].abs() > 1e-6 ||
        pose[7].abs() > 1e-6 ||
        pose[11].abs() > 1e-6 ||
        (pose[15] - 1).abs() > 1e-6) {
      throw const FormatException('Invalid anchor transform');
    }
    // A rigid rotation must remain invertible; translation is unrestricted.
    for (var col = 0; col < 3; col++) {
      for (var other = 0; other < 3; other++) {
        var dot = 0.0;
        for (var row = 0; row < 3; row++)
          dot += pose[col * 4 + row] * pose[other * 4 + row];
        if ((dot - (col == other ? 1 : 0)).abs() > .02) {
          throw const FormatException('Anchor transform must be rigid');
        }
      }
    }
    final determinant =
        pose[0] * (pose[5] * pose[10] - pose[9] * pose[6]) -
        pose[4] * (pose[1] * pose[10] - pose[9] * pose[2]) +
        pose[8] * (pose[1] * pose[6] - pose[5] * pose[2]);
    if (determinant < .98)
      throw const FormatException('Invalid anchor rotation');
    final end = DateTime.parse(anchor['expiresAt'] as String).toUtc();
    if (!end.isAfter(now) || end.isAfter(now.add(const Duration(days: 366)))) {
      throw const FormatException('Invalid anchor expiry');
    }
    if (expiry == null || end.isBefore(expiry)) expiry = end;
  }
  final pair = (setup['calibration'] as List).cast<String>();
  final points = setup['anchors'] as Map<String, dynamic>;
  if (pair.length != 2 ||
      pair[0] == pair[1] ||
      pair.any((id) => !byId.containsKey(id))) {
    throw const FormatException('Select two different calibration anchors');
  }
  for (final entry in points.entries) {
    final p = (entry.value as List).cast<num>();
    if (!byId.containsKey(entry.key) ||
        p.length != 2 ||
        p.any((v) => !v.isFinite) ||
        p[0] < 0 ||
        p[1] < 0 ||
        p[0] > 1632 ||
        p[1] > 1056) {
      throw const FormatException('Invalid floor-plan point');
    }
  }
  final a = (byId[pair[0]]!['pose'] as List).cast<num>();
  final b = (byId[pair[1]]!['pose'] as List).cast<num>();
  final p = (points[pair[0]] as List).cast<num>();
  final q = (points[pair[1]] as List).cast<num>();
  final meters = math.sqrt(
    math.pow(a[12] - b[12], 2) + math.pow(a[14] - b[14], 2),
  );
  final pixels = math.sqrt(math.pow(p[0] - q[0], 2) + math.pow(p[1] - q[1], 2));
  if (meters < 2 ||
      pixels < 1 ||
      pixels / meters < 1 ||
      pixels / meters > 200) {
    throw const FormatException(
      'Calibration needs two points at least 2 m apart with a plausible scale',
    );
  }
  return expiry!;
}
