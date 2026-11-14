/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'edge.dart' as _ilmyslsx;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'kind.dart' as _iokugpqm;
import 'locations.dart' as _iy2kpyso;
import 'node.dart' as _i9tve71o;
export 'edge.dart';
export 'greetings/greeting.dart';
export 'kind.dart';
export 'locations.dart';
export 'node.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_ilmyslsx.Edge>,
          _isc.getType<_izw8z7ou.Greeting>,
          _isc.getType<_iokugpqm.Kind>,
          _isc.getType<_iy2kpyso.Locations>,
          _isc.getType<_i9tve71o.Nodes>,
          _isc.getType<_ilmyslsx.Edge?>,
          _isc.getType<_izw8z7ou.Greeting?>,
          _isc.getType<_iokugpqm.Kind?>,
          _isc.getType<_iy2kpyso.Locations?>,
          _isc.getType<_i9tve71o.Nodes?>,
        ],
        modules: const [],
        classNames: const [
          'Edge',
          'Greeting',
          'Kind',
          'Locations',
          'Nodes',
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) =>
      _isc.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _isc.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ilmyslsx.Edge) {
      return _ilmyslsx.Edge.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _iokugpqm.Kind) {
      return _iokugpqm.Kind.fromJson(data) as T;
    }
    if (t == _iy2kpyso.Locations) {
      return _iy2kpyso.Locations.fromJson(data) as T;
    }
    if (t == _i9tve71o.Nodes) {
      return _i9tve71o.Nodes.fromJson(data) as T;
    }
    if (t == _isc.getType<_ilmyslsx.Edge?>()) {
      return (data != null ? _ilmyslsx.Edge.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iokugpqm.Kind?>()) {
      return (data != null ? _iokugpqm.Kind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iy2kpyso.Locations?>()) {
      return (data != null ? _iy2kpyso.Locations.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9tve71o.Nodes?>()) {
      return (data != null ? _i9tve71o.Nodes.fromJson(data) : null) as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ilmyslsx.Edge => 'Edge',
      _izw8z7ou.Greeting => 'Greeting',
      _iokugpqm.Kind => 'Kind',
      _iy2kpyso.Locations => 'Locations',
      _i9tve71o.Nodes => 'Nodes',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('madmaps.', '');
    }

    switch (data) {
      case _ilmyslsx.Edge():
        return 'Edge';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _iokugpqm.Kind():
        return 'Kind';
      case _iy2kpyso.Locations():
        return 'Locations';
      case _i9tve71o.Nodes():
        return 'Nodes';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Edge') {
      return deserialize<_ilmyslsx.Edge>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'Kind') {
      return deserialize<_iokugpqm.Kind>(data['data']);
    }
    if (dataClassName == 'Locations') {
      return deserialize<_iy2kpyso.Locations>(data['data']);
    }
    if (dataClassName == 'Nodes') {
      return deserialize<_i9tve71o.Nodes>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'madmaps';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
