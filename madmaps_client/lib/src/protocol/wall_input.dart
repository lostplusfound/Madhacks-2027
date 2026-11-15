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
import 'package:madmaps_client/src/protocol/protocol.dart' as _isgyuksw;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'wall_point.dart' as _inoptxl6;

abstract class WallInput
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WallInput._({
    required this.wallId,
    required this.floorId,
    required this.vertices,
  });

  factory WallInput({
    required String wallId,
    required String floorId,
    required List<_inoptxl6.WallPoint> vertices,
  }) = _WallInputImpl;

  factory WallInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return WallInput(
      wallId: jsonSerialization['wallId'] as String,
      floorId: jsonSerialization['floorId'] as String,
      vertices: _isgyuksw.Protocol().deserialize<List<_inoptxl6.WallPoint>>(
        jsonSerialization['vertices'],
      ),
    );
  }

  String wallId;

  String floorId;

  List<_inoptxl6.WallPoint> vertices;

  /// Returns a shallow copy of this [WallInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WallInput copyWith({
    String? wallId,
    String? floorId,
    List<_inoptxl6.WallPoint>? vertices,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WallInput',
      'wallId': wallId,
      'floorId': floorId,
      'vertices': vertices.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WallInput',
      'wallId': wallId,
      'floorId': floorId,
      'vertices': vertices.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WallInputImpl extends WallInput {
  _WallInputImpl({
    required String wallId,
    required String floorId,
    required List<_inoptxl6.WallPoint> vertices,
  }) : super._(
         wallId: wallId,
         floorId: floorId,
         vertices: vertices,
       );

  /// Returns a shallow copy of this [WallInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WallInput copyWith({
    String? wallId,
    String? floorId,
    List<_inoptxl6.WallPoint>? vertices,
  }) {
    return WallInput(
      wallId: wallId ?? this.wallId,
      floorId: floorId ?? this.floorId,
      vertices: vertices ?? this.vertices.map((e0) => e0.copyWith()).toList(),
    );
  }
}
