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
import 'map_graph_snapshot.dart' as _iuswi8s2;

abstract class GraphReadResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
      unchanged: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['unchanged'],
      ),
      snapshot: jsonSerialization['snapshot'] == null
          ? null
          : _isgyuksw.Protocol().deserialize<_iuswi8s2.MapGraphSnapshot>(
              jsonSerialization['snapshot'],
            ),
    );
  }

  bool unchanged;

  _iuswi8s2.MapGraphSnapshot? snapshot;

  /// Returns a shallow copy of this [GraphReadResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    return _isc.SerializationManager.encode(this);
  }
}

class _UndefinedGraphReadResult$snapshot extends _isc.UndefinedSentinel
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
  @_isc.useResult
  @override
  GraphReadResult copyWith({
    bool? unchanged,
    _iuswi8s2.MapGraphSnapshot? snapshot =
        const _UndefinedGraphReadResult$snapshot(),
  }) {
    return GraphReadResult(
      unchanged: unchanged ?? this.unchanged,
      snapshot: snapshot is _isc.UndefinedSentinel
          ? this.snapshot?.copyWith()
          : snapshot,
    );
  }
}
