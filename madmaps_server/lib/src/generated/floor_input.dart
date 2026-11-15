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

abstract class FloorInput
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FloorInput._({
    required this.floorId,
    required this.floorNumber,
    this.name,
    required this.width,
    required this.height,
    required this.metersPerUnit,
  });

  factory FloorInput({
    required String floorId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    required double metersPerUnit,
  }) = _FloorInputImpl;

  factory FloorInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return FloorInput(
      floorId: jsonSerialization['floorId'] as String,
      floorNumber: jsonSerialization['floorNumber'] as int,
      name: jsonSerialization['name'] as String?,
      width: (jsonSerialization['width'] as num).toDouble(),
      height: (jsonSerialization['height'] as num).toDouble(),
      metersPerUnit: (jsonSerialization['metersPerUnit'] as num).toDouble(),
    );
  }

  String floorId;

  int floorNumber;

  String? name;

  double width;

  double height;

  double metersPerUnit;

  /// Returns a shallow copy of this [FloorInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FloorInput copyWith({
    String? floorId,
    int? floorNumber,
    String? name,
    double? width,
    double? height,
    double? metersPerUnit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FloorInput',
      'floorId': floorId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FloorInput',
      'floorId': floorId,
      'floorNumber': floorNumber,
      if (name != null) 'name': name,
      'width': width,
      'height': height,
      'metersPerUnit': metersPerUnit,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FloorInputImpl extends FloorInput {
  _FloorInputImpl({
    required String floorId,
    required int floorNumber,
    String? name,
    required double width,
    required double height,
    required double metersPerUnit,
  }) : super._(
         floorId: floorId,
         floorNumber: floorNumber,
         name: name,
         width: width,
         height: height,
         metersPerUnit: metersPerUnit,
       );

  /// Returns a shallow copy of this [FloorInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FloorInput copyWith({
    String? floorId,
    int? floorNumber,
    Object? name = _Undefined,
    double? width,
    double? height,
    double? metersPerUnit,
  }) {
    return FloorInput(
      floorId: floorId ?? this.floorId,
      floorNumber: floorNumber ?? this.floorNumber,
      name: name is String? ? name : this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      metersPerUnit: metersPerUnit ?? this.metersPerUnit,
    );
  }
}
