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
import 'locations.dart' as _iy2kpyso;
import 'node.dart' as _i9tve71o;

abstract class SearchResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SearchResult._({
    required this.location,
    this.node,
    required this.score,
  });

  factory SearchResult({
    required _iy2kpyso.Locations location,
    _i9tve71o.Nodes? node,
    required int score,
  }) = _SearchResultImpl;

  factory SearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResult(
      location: _i1t1vlhc.Protocol().deserialize<_iy2kpyso.Locations>(
        jsonSerialization['location'],
      ),
      node: jsonSerialization['node'] == null
          ? null
          : _i1t1vlhc.Protocol().deserialize<_i9tve71o.Nodes>(
              jsonSerialization['node'],
            ),
      score: jsonSerialization['score'] as int,
    );
  }

  _iy2kpyso.Locations location;

  _i9tve71o.Nodes? node;

  int score;

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SearchResult copyWith({
    _iy2kpyso.Locations? location,
    _i9tve71o.Nodes? node = const _UndefinedSearchResult$node(),
    int? score,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResult',
      'location': location.toJson(),
      if (node != null) 'node': node?.toJson(),
      'score': score,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchResult',
      'location': location.toJsonForProtocol(),
      if (node != null) 'node': node?.toJsonForProtocol(),
      'score': score,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedSearchResult$node extends _is.UndefinedSentinel
    implements _i9tve71o.Nodes {
  const _UndefinedSearchResult$node();
}

class _SearchResultImpl extends SearchResult {
  _SearchResultImpl({
    required _iy2kpyso.Locations location,
    _i9tve71o.Nodes? node,
    required int score,
  }) : super._(
         location: location,
         node: node,
         score: score,
       );

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SearchResult copyWith({
    _iy2kpyso.Locations? location,
    _i9tve71o.Nodes? node = const _UndefinedSearchResult$node(),
    int? score,
  }) {
    return SearchResult(
      location: location ?? this.location.copyWith(),
      node: node is _is.UndefinedSentinel ? this.node?.copyWith() : node,
      score: score ?? this.score,
    );
  }
}
