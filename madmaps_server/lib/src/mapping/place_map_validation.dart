import 'dart:convert';
import 'dart:typed_data';

/// Validate exported image/pin maps independently of routable graph geometry.
Map<String, dynamic> validatePlaceMap(String content) {
  if (utf8.encode(content).length > 32 * 1024 * 1024) {
    throw const FormatException('Map exceeds 32 MB.');
  }
  final value = jsonDecode(content) as Map<String, dynamic>;
  if (value['profile'] != 'rooms-and-amenities-v1' ||
      value['schema_version'] != 1 ||
      value['coordinate_origin'] != 'top-left' ||
      value['coordinate_units'] != 'pixels' ||
      value['image_mime_type'] != 'image/png') {
    throw const FormatException('Choose an exported rooms-and-amenities map.');
  }
  final width = value['width'], height = value['height'];
  if (width is! num ||
      height is! num ||
      !width.isFinite ||
      !height.isFinite ||
      width <= 0 ||
      height <= 0 ||
      width > 16000 ||
      height > 16000 ||
      width * height > 80000000) {
    throw const FormatException('Invalid map dimensions.');
  }
  final bytes = base64Decode(value['image_base64'] as String);
  const signature = [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
  ];
  if (bytes.length < 33 ||
      List.generate(
        signature.length,
        (i) => bytes[i] == signature[i],
      ).contains(false) ||
      ByteData.sublistView(bytes).getUint32(16) != width ||
      ByteData.sublistView(bytes).getUint32(20) != height) {
    throw const FormatException('Map image dimensions do not match its pins.');
  }
  final places = value['places'];
  if (places is! List || places.isEmpty || places.length > 1000) {
    throw const FormatException('Keep between 1 and 1000 places.');
  }
  const categories = {
    'other',
    'bathroom',
    'elevator',
    'stairs',
    'entrance',
    'exit',
    'classroom',
    'office',
    'studySpace',
    'food',
    'auditorium',
    'accessibilityService',
    'landmark',
  };
  final ids = <String>{};
  for (final item in places) {
    if (item is! Map) throw const FormatException('Invalid place.');
    final id = item['id'], label = item['label'], x = item['x'], y = item['y'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 160 ||
        !ids.add(id) ||
        label is! String ||
        label.trim().isEmpty ||
        label.length > 120 ||
        !categories.contains(item['category']) ||
        x is! num ||
        y is! num ||
        !x.isFinite ||
        !y.isFinite ||
        x < 0 ||
        y < 0 ||
        x > width ||
        y > height) {
      throw const FormatException(
        'Invalid place label, category, or coordinates.',
      );
    }
  }
  return value;
}
