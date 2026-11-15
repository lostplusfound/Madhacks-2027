/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

abstract class WallPoint
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WallPoint._({
    required this.x,
    required this.y,
  });

  factory WallPoint({
    required double x,
    required double y,
  }) = _WallPointImpl;

  factory WallPoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return WallPoint(
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
    );
  }

  double x;

  double y;

  /// Returns a shallow copy of this [WallPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WallPoint copyWith({
    double? x,
    double? y,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WallPoint',
      'x': x,
      'y': y,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WallPoint',
      'x': x,
      'y': y,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WallPointImpl extends WallPoint {
  _WallPointImpl({
    required double x,
    required double y,
  }) : super._(
         x: x,
         y: y,
       );

  /// Returns a shallow copy of this [WallPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WallPoint copyWith({
    double? x,
    double? y,
  }) {
    return WallPoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}
