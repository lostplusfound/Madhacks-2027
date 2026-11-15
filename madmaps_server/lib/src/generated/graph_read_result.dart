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
import 'package:madmaps_server/src/generated/protocol.dart' as _i1t1vlhc;
import 'package:serverpod/serverpod.dart' as _is;
import 'map_graph_snapshot.dart' as _iuswi8s2;

abstract class GraphReadResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GraphReadResult._({
    required this.unchanged,
    this.snapshot,
  });

  factory GraphReadResult({
    required bool unchanged,
    _iuswi8s2.MapGraphSnapshot? snapshot,
  }) = _GraphReadResultImpl;

  factory GraphReadResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return GraphReadResult(
      unchanged: _is.BoolJsonExtension.fromJson(jsonSerialization['unchanged']),
      snapshot: jsonSerialization['snapshot'] == null
          ? null
          : _i1t1vlhc.Protocol().deserialize<_iuswi8s2.MapGraphSnapshot>(
              jsonSerialization['snapshot'],
            ),
    );
  }

  bool unchanged;

  _iuswi8s2.MapGraphSnapshot? snapshot;

  /// Returns a shallow copy of this [GraphReadResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GraphReadResult copyWith({
    bool? unchanged,
    _iuswi8s2.MapGraphSnapshot? snapshot =
        const _UndefinedGraphReadResult$snapshot(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GraphReadResult',
      'unchanged': unchanged,
      if (snapshot != null) 'snapshot': snapshot?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GraphReadResult',
      'unchanged': unchanged,
      if (snapshot != null) 'snapshot': snapshot?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedGraphReadResult$snapshot extends _is.UndefinedSentinel
    implements _iuswi8s2.MapGraphSnapshot {
  const _UndefinedGraphReadResult$snapshot();
}

class _GraphReadResultImpl extends GraphReadResult {
  _GraphReadResultImpl({
    required bool unchanged,
    _iuswi8s2.MapGraphSnapshot? snapshot,
  }) : super._(
         unchanged: unchanged,
         snapshot: snapshot,
       );

  /// Returns a shallow copy of this [GraphReadResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GraphReadResult copyWith({
    bool? unchanged,
    _iuswi8s2.MapGraphSnapshot? snapshot =
        const _UndefinedGraphReadResult$snapshot(),
  }) {
    return GraphReadResult(
      unchanged: unchanged ?? this.unchanged,
      snapshot: snapshot is _is.UndefinedSentinel
          ? this.snapshot?.copyWith()
          : snapshot,
    );
  }
}
