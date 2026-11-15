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
import 'package:madmaps_server/src/generated/building.dart' as _immk5i13;
import 'package:madmaps_server/src/generated/edge.dart' as _iyt7s8vt;
import 'package:madmaps_server/src/generated/location_category.dart'
    as _ine5rn9y;
import 'package:madmaps_server/src/generated/locations.dart' as _idkqo2s3;
import 'package:madmaps_server/src/generated/map_edge_input.dart' as _i2zbo8fc;
import 'package:madmaps_server/src/generated/map_graph.dart' as _iuy2uhz7;
import 'package:madmaps_server/src/generated/map_report.dart' as _iyphw3s3;
import 'package:madmaps_server/src/generated/node.dart' as _iccguhj3;
import 'package:madmaps_server/src/generated/search_result.dart' as _iw7f3ebs;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'building.dart' as _icdi8t76;
import 'create_graph_request.dart' as _ihh4bgnv;
import 'edge.dart' as _ilmyslsx;
import 'edge_type.dart' as _iv43g6lk;
import 'floor.dart' as _ibt68ans;
import 'floor_input.dart' as _i647gghf;
import 'graph_patch_request.dart' as _iv9rsso3;
import 'graph_read_result.dart' as _iu1utyem;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'kind.dart' as _iokugpqm;
import 'location_category.dart' as _ipivyxsl;
import 'location_input.dart' as _iaviofrw;
import 'locations.dart' as _iy2kpyso;
import 'map_api_exception.dart' as _igm7lgul;
import 'map_edge_input.dart' as _ipndifli;
import 'map_entity_status.dart' as _itjn1vsu;
import 'map_graph.dart' as _ikb2yia4;
import 'map_graph_snapshot.dart' as _iuswi8s2;
import 'map_node_input.dart' as _i3qve637;
import 'map_report.dart' as _iictijcz;
import 'map_wall.dart' as _i064s9h8;
import 'node.dart' as _i9tve71o;
import 'replace_graph_request.dart' as _iz7e8f0p;
import 'report_reason.dart' as _ijgj7dn0;
import 'report_status.dart' as _i8pcsu0p;
import 'report_target_type.dart' as _iyydfyiu;
import 'search_result.dart' as _ifcih7a1;
import 'wall_input.dart' as _icks2m2l;
import 'wall_point.dart' as _inoptxl6;
export 'building.dart';
export 'create_graph_request.dart';
export 'edge.dart';
export 'edge_type.dart';
export 'floor.dart';
export 'floor_input.dart';
export 'graph_patch_request.dart';
export 'graph_read_result.dart';
export 'greetings/greeting.dart';
export 'kind.dart';
export 'location_category.dart';
export 'location_input.dart';
export 'locations.dart';
export 'map_api_exception.dart';
export 'map_edge_input.dart';
export 'map_entity_status.dart';
export 'map_graph.dart';
export 'map_graph_snapshot.dart';
export 'map_node_input.dart';
export 'map_report.dart';
export 'map_wall.dart';
export 'node.dart';
export 'replace_graph_request.dart';
export 'report_reason.dart';
export 'report_status.dart';
export 'report_target_type.dart';
export 'search_result.dart';
export 'wall_input.dart';
export 'wall_point.dart';

class Protocol extends _is.DatabaseSerializationManager
    implements _is.DatabaseProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _is.ProtocolDeserialization get deserializationMetadata =>
      _is.ProtocolDeserialization.cached(
        this,
        types: const [
          _is.getType<_icdi8t76.Building>,
          _is.getType<_ihh4bgnv.CreateGraphRequest>,
          _is.getType<_ilmyslsx.Edge>,
          _is.getType<_iv43g6lk.EdgeType>,
          _is.getType<_ibt68ans.Floor>,
          _is.getType<_i647gghf.FloorInput>,
          _is.getType<_iv9rsso3.GraphPatchRequest>,
          _is.getType<_iu1utyem.GraphReadResult>,
          _is.getType<_izw8z7ou.Greeting>,
          _is.getType<_iokugpqm.Kind>,
          _is.getType<_ipivyxsl.LocationCategory>,
          _is.getType<_iaviofrw.LocationInput>,
          _is.getType<_iy2kpyso.Locations>,
          _is.getType<_igm7lgul.MapApiException>,
          _is.getType<_ipndifli.MapEdgeInput>,
          _is.getType<_itjn1vsu.MapEntityStatus>,
          _is.getType<_ikb2yia4.MapGraph>,
          _is.getType<_iuswi8s2.MapGraphSnapshot>,
          _is.getType<_i3qve637.MapNodeInput>,
          _is.getType<_iictijcz.MapReport>,
          _is.getType<_i064s9h8.MapWall>,
          _is.getType<_i9tve71o.Nodes>,
          _is.getType<_iz7e8f0p.ReplaceGraphRequest>,
          _is.getType<_ijgj7dn0.ReportReason>,
          _is.getType<_i8pcsu0p.ReportStatus>,
          _is.getType<_iyydfyiu.ReportTargetType>,
          _is.getType<_ifcih7a1.SearchResult>,
          _is.getType<_icks2m2l.WallInput>,
          _is.getType<_inoptxl6.WallPoint>,
          _is.getType<_icdi8t76.Building?>,
          _is.getType<_ihh4bgnv.CreateGraphRequest?>,
          _is.getType<_ilmyslsx.Edge?>,
          _is.getType<_iv43g6lk.EdgeType?>,
          _is.getType<_ibt68ans.Floor?>,
          _is.getType<_i647gghf.FloorInput?>,
          _is.getType<_iv9rsso3.GraphPatchRequest?>,
          _is.getType<_iu1utyem.GraphReadResult?>,
          _is.getType<_izw8z7ou.Greeting?>,
          _is.getType<_iokugpqm.Kind?>,
          _is.getType<_ipivyxsl.LocationCategory?>,
          _is.getType<_iaviofrw.LocationInput?>,
          _is.getType<_iy2kpyso.Locations?>,
          _is.getType<_igm7lgul.MapApiException?>,
          _is.getType<_ipndifli.MapEdgeInput?>,
          _is.getType<_itjn1vsu.MapEntityStatus?>,
          _is.getType<_ikb2yia4.MapGraph?>,
          _is.getType<_iuswi8s2.MapGraphSnapshot?>,
          _is.getType<_i3qve637.MapNodeInput?>,
          _is.getType<_iictijcz.MapReport?>,
          _is.getType<_i064s9h8.MapWall?>,
          _is.getType<_i9tve71o.Nodes?>,
          _is.getType<_iz7e8f0p.ReplaceGraphRequest?>,
          _is.getType<_ijgj7dn0.ReportReason?>,
          _is.getType<_i8pcsu0p.ReportStatus?>,
          _is.getType<_iyydfyiu.ReportTargetType?>,
          _is.getType<_ifcih7a1.SearchResult?>,
          _is.getType<_icks2m2l.WallInput?>,
          _is.getType<_inoptxl6.WallPoint?>,
          _is.getType<List<_i647gghf.FloorInput>>,
          _is.getType<List<_i3qve637.MapNodeInput>>,
          _is.getType<List<_ipndifli.MapEdgeInput>>,
          _is.getType<List<_iaviofrw.LocationInput>>,
          _is.getType<List<_icks2m2l.WallInput>>,
          _is.getType<List<_icks2m2l.WallInput>?>,
          _is.getType<List<String>>,
          _is.getType<List<_ibt68ans.Floor>>,
          _is.getType<List<_i9tve71o.Nodes>>,
          _is.getType<List<_ilmyslsx.Edge>>,
          _is.getType<List<_iy2kpyso.Locations>>,
          _is.getType<List<_inoptxl6.WallPoint>>,
          _is.getType<List<_immk5i13.Building>>,
          _is.getType<List<_idkqo2s3.Locations>>,
          _is.getType<List<_iw7f3ebs.SearchResult>>,
          _is.getType<List<_ine5rn9y.LocationCategory>>,
          _is.getType<List<_iyt7s8vt.Edge>>,
          _is.getType<List<_iuy2uhz7.MapGraph>>,
          _is.getType<List<_i2zbo8fc.MapEdgeInput>>,
          _is.getType<List<_iccguhj3.Nodes>>,
          _is.getType<List<_iyphw3s3.MapReport>>,
        ],
        modules: const [
          _iais.Protocol.new,
          _iacs.Protocol.new,
          _isp.Protocol.new,
        ],
        classNames: const [
          'Building',
          'CreateGraphRequest',
          'Edge',
          'EdgeType',
          'Floor',
          'FloorInput',
          'GraphPatchRequest',
          'GraphReadResult',
          'Greeting',
          'Kind',
          'LocationCategory',
          'LocationInput',
          'Locations',
          'MapApiException',
          'MapEdgeInput',
          'MapEntityStatus',
          'MapGraph',
          'MapGraphSnapshot',
          'MapNodeInput',
          'MapReport',
          'MapWall',
          'Nodes',
          'ReplaceGraphRequest',
          'ReportReason',
          'ReportStatus',
          'ReportTargetType',
          'SearchResult',
          'WallInput',
          'WallPoint',
        ],
      );

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    ..._ownTableDefinitions,
    ..._iais.Protocol().getOwnTableDefinitions(),
    ..._iacs.Protocol().getOwnTableDefinitions(),
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static List<_isp.TableDefinition> get _ownTableDefinitions => [
    _isp.TableDefinition(
      name: 'building',
      dartName: 'Building',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'building_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'address',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'created_by',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deleted_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MapEntityStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'building__building_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'building_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'buildings_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'buildings_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'created_by',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'edge',
      dartName: 'Edge',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'edge_id',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'graph_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'from_node_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'to_node_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EdgeType',
          columnDefault: '\'walk\'',
        ),
        _isp.ColumnDefinition(
          name: 'cost_px',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'bidirectional',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MapEntityStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'created_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'updated_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deleted_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'edge_fk_0',
          columns: ['graph_id'],
          referenceTable: 'map_graph',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'edge__edge_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'edge_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'edges_graph_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'graph_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'edges_from_node_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'from_node_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'edges_to_node_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'to_node_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'edges_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'created_by',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'floor',
      dartName: 'Floor',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'floor_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'building_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'floor_number',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'width',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'height',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'meters_per_unit',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1.0',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'floor_fk_0',
          columns: ['building_id'],
          referenceTable: 'building',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'floor__building_id__floor_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'building_id',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'floor_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'floors_building_number_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'building_id',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'floor_number',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'locations',
      dartName: 'Locations',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'location_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'graph_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'floor_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'floor',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'room_number',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'category',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:LocationCategory?',
        ),
        _isp.ColumnDefinition(
          name: 'aliases',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'route_node_id',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'review_note',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MapEntityStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'created_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'updated_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deleted_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'locations_fk_0',
          columns: ['graph_id'],
          referenceTable: 'map_graph',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'locations_fk_1',
          columns: ['floor_id'],
          referenceTable: 'floor',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'locations__location_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'location_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'locations_graph_floor_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'graph_id',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'floor_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'locations_room_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'room_number',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'locations_category_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'category',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'locations_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'created_by',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'map_graph',
      dartName: 'MapGraph',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'graph_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'building_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'owner_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MapEntityStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deleted_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'map_graph_fk_0',
          columns: ['building_id'],
          referenceTable: 'building',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'map_graph__graph_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'graph_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'map_graph_building_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'building_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'map_graph_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'owner_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'map_report',
      dartName: 'MapReport',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'report_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'target_type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReportTargetType',
        ),
        _isp.ColumnDefinition(
          name: 'target_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reporter_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReportReason',
        ),
        _isp.ColumnDefinition(
          name: 'notes',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReportStatus',
          columnDefault: '\'open\'',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'map_report__report_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'report_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'reports_target_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'target_type',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'target_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'reports_reporter_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reporter_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'map_wall',
      dartName: 'MapWall',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'graph_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'wall_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'floor_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'vertices_json',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'map_wall_fk_0',
          columns: ['graph_id'],
          referenceTable: 'map_graph',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'map_wall_graph_wall_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'graph_id',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'wall_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'nodes',
      dartName: 'Nodes',
      schema: 'public',
      module: 'madmaps',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'node_id',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'graph_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'floor_id',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'floor',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'x',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'y',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'location_id',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Kind',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MapEntityStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'created_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'updated_by',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'created_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updated_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deleted_at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'nodes_fk_0',
          columns: ['graph_id'],
          referenceTable: 'map_graph',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'nodes_fk_1',
          columns: ['floor_id'],
          referenceTable: 'floor',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'nodes__node_id__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'node_id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'nodes_graph_floor_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'graph_id',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'floor_id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'nodes_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'created_by',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
  ];

  static String? getClassNameFromObjectJson(dynamic data) =>
      _is.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _is.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _icdi8t76.Building) {
      return _icdi8t76.Building.fromJson(data) as T;
    }
    if (t == _ihh4bgnv.CreateGraphRequest) {
      return _ihh4bgnv.CreateGraphRequest.fromJson(data) as T;
    }
    if (t == _ilmyslsx.Edge) {
      return _ilmyslsx.Edge.fromJson(data) as T;
    }
    if (t == _iv43g6lk.EdgeType) {
      return _iv43g6lk.EdgeType.fromJson(data) as T;
    }
    if (t == _ibt68ans.Floor) {
      return _ibt68ans.Floor.fromJson(data) as T;
    }
    if (t == _i647gghf.FloorInput) {
      return _i647gghf.FloorInput.fromJson(data) as T;
    }
    if (t == _iv9rsso3.GraphPatchRequest) {
      return _iv9rsso3.GraphPatchRequest.fromJson(data) as T;
    }
    if (t == _iu1utyem.GraphReadResult) {
      return _iu1utyem.GraphReadResult.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _iokugpqm.Kind) {
      return _iokugpqm.Kind.fromJson(data) as T;
    }
    if (t == _ipivyxsl.LocationCategory) {
      return _ipivyxsl.LocationCategory.fromJson(data) as T;
    }
    if (t == _iaviofrw.LocationInput) {
      return _iaviofrw.LocationInput.fromJson(data) as T;
    }
    if (t == _iy2kpyso.Locations) {
      return _iy2kpyso.Locations.fromJson(data) as T;
    }
    if (t == _igm7lgul.MapApiException) {
      return _igm7lgul.MapApiException.fromJson(data) as T;
    }
    if (t == _ipndifli.MapEdgeInput) {
      return _ipndifli.MapEdgeInput.fromJson(data) as T;
    }
    if (t == _itjn1vsu.MapEntityStatus) {
      return _itjn1vsu.MapEntityStatus.fromJson(data) as T;
    }
    if (t == _ikb2yia4.MapGraph) {
      return _ikb2yia4.MapGraph.fromJson(data) as T;
    }
    if (t == _iuswi8s2.MapGraphSnapshot) {
      return _iuswi8s2.MapGraphSnapshot.fromJson(data) as T;
    }
    if (t == _i3qve637.MapNodeInput) {
      return _i3qve637.MapNodeInput.fromJson(data) as T;
    }
    if (t == _iictijcz.MapReport) {
      return _iictijcz.MapReport.fromJson(data) as T;
    }
    if (t == _i064s9h8.MapWall) {
      return _i064s9h8.MapWall.fromJson(data) as T;
    }
    if (t == _i9tve71o.Nodes) {
      return _i9tve71o.Nodes.fromJson(data) as T;
    }
    if (t == _iz7e8f0p.ReplaceGraphRequest) {
      return _iz7e8f0p.ReplaceGraphRequest.fromJson(data) as T;
    }
    if (t == _ijgj7dn0.ReportReason) {
      return _ijgj7dn0.ReportReason.fromJson(data) as T;
    }
    if (t == _i8pcsu0p.ReportStatus) {
      return _i8pcsu0p.ReportStatus.fromJson(data) as T;
    }
    if (t == _iyydfyiu.ReportTargetType) {
      return _iyydfyiu.ReportTargetType.fromJson(data) as T;
    }
    if (t == _ifcih7a1.SearchResult) {
      return _ifcih7a1.SearchResult.fromJson(data) as T;
    }
    if (t == _icks2m2l.WallInput) {
      return _icks2m2l.WallInput.fromJson(data) as T;
    }
    if (t == _inoptxl6.WallPoint) {
      return _inoptxl6.WallPoint.fromJson(data) as T;
    }
    if (t == _is.getType<_icdi8t76.Building?>()) {
      return (data != null ? _icdi8t76.Building.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihh4bgnv.CreateGraphRequest?>()) {
      return (data != null ? _ihh4bgnv.CreateGraphRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilmyslsx.Edge?>()) {
      return (data != null ? _ilmyslsx.Edge.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv43g6lk.EdgeType?>()) {
      return (data != null ? _iv43g6lk.EdgeType.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ibt68ans.Floor?>()) {
      return (data != null ? _ibt68ans.Floor.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i647gghf.FloorInput?>()) {
      return (data != null ? _i647gghf.FloorInput.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv9rsso3.GraphPatchRequest?>()) {
      return (data != null ? _iv9rsso3.GraphPatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu1utyem.GraphReadResult?>()) {
      return (data != null ? _iu1utyem.GraphReadResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iokugpqm.Kind?>()) {
      return (data != null ? _iokugpqm.Kind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipivyxsl.LocationCategory?>()) {
      return (data != null ? _ipivyxsl.LocationCategory.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaviofrw.LocationInput?>()) {
      return (data != null ? _iaviofrw.LocationInput.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iy2kpyso.Locations?>()) {
      return (data != null ? _iy2kpyso.Locations.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igm7lgul.MapApiException?>()) {
      return (data != null ? _igm7lgul.MapApiException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipndifli.MapEdgeInput?>()) {
      return (data != null ? _ipndifli.MapEdgeInput.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itjn1vsu.MapEntityStatus?>()) {
      return (data != null ? _itjn1vsu.MapEntityStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikb2yia4.MapGraph?>()) {
      return (data != null ? _ikb2yia4.MapGraph.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iuswi8s2.MapGraphSnapshot?>()) {
      return (data != null ? _iuswi8s2.MapGraphSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3qve637.MapNodeInput?>()) {
      return (data != null ? _i3qve637.MapNodeInput.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iictijcz.MapReport?>()) {
      return (data != null ? _iictijcz.MapReport.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i064s9h8.MapWall?>()) {
      return (data != null ? _i064s9h8.MapWall.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9tve71o.Nodes?>()) {
      return (data != null ? _i9tve71o.Nodes.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iz7e8f0p.ReplaceGraphRequest?>()) {
      return (data != null
              ? _iz7e8f0p.ReplaceGraphRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijgj7dn0.ReportReason?>()) {
      return (data != null ? _ijgj7dn0.ReportReason.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8pcsu0p.ReportStatus?>()) {
      return (data != null ? _i8pcsu0p.ReportStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyydfyiu.ReportTargetType?>()) {
      return (data != null ? _iyydfyiu.ReportTargetType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifcih7a1.SearchResult?>()) {
      return (data != null ? _ifcih7a1.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icks2m2l.WallInput?>()) {
      return (data != null ? _icks2m2l.WallInput.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_inoptxl6.WallPoint?>()) {
      return (data != null ? _inoptxl6.WallPoint.fromJson(data) : null) as T;
    }
    if (t == List<_i647gghf.FloorInput>) {
      return (data as List)
              .map((e) => deserialize<_i647gghf.FloorInput>(e))
              .toList()
          as T;
    }
    if (t == List<_i3qve637.MapNodeInput>) {
      return (data as List)
              .map((e) => deserialize<_i3qve637.MapNodeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_ipndifli.MapEdgeInput>) {
      return (data as List)
              .map((e) => deserialize<_ipndifli.MapEdgeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_iaviofrw.LocationInput>) {
      return (data as List)
              .map((e) => deserialize<_iaviofrw.LocationInput>(e))
              .toList()
          as T;
    }
    if (t == List<_icks2m2l.WallInput>) {
      return (data as List)
              .map((e) => deserialize<_icks2m2l.WallInput>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_icks2m2l.WallInput>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_icks2m2l.WallInput>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ibt68ans.Floor>) {
      return (data as List).map((e) => deserialize<_ibt68ans.Floor>(e)).toList()
          as T;
    }
    if (t == List<_i9tve71o.Nodes>) {
      return (data as List).map((e) => deserialize<_i9tve71o.Nodes>(e)).toList()
          as T;
    }
    if (t == List<_ilmyslsx.Edge>) {
      return (data as List).map((e) => deserialize<_ilmyslsx.Edge>(e)).toList()
          as T;
    }
    if (t == List<_iy2kpyso.Locations>) {
      return (data as List)
              .map((e) => deserialize<_iy2kpyso.Locations>(e))
              .toList()
          as T;
    }
    if (t == List<_inoptxl6.WallPoint>) {
      return (data as List)
              .map((e) => deserialize<_inoptxl6.WallPoint>(e))
              .toList()
          as T;
    }
    if (t == List<_immk5i13.Building>) {
      return (data as List)
              .map((e) => deserialize<_immk5i13.Building>(e))
              .toList()
          as T;
    }
    if (t == List<_idkqo2s3.Locations>) {
      return (data as List)
              .map((e) => deserialize<_idkqo2s3.Locations>(e))
              .toList()
          as T;
    }
    if (t == List<_iw7f3ebs.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_iw7f3ebs.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_ine5rn9y.LocationCategory>) {
      return (data as List)
              .map((e) => deserialize<_ine5rn9y.LocationCategory>(e))
              .toList()
          as T;
    }
    if (t == List<_iyt7s8vt.Edge>) {
      return (data as List).map((e) => deserialize<_iyt7s8vt.Edge>(e)).toList()
          as T;
    }
    if (t == List<_iuy2uhz7.MapGraph>) {
      return (data as List)
              .map((e) => deserialize<_iuy2uhz7.MapGraph>(e))
              .toList()
          as T;
    }
    if (t == List<_i2zbo8fc.MapEdgeInput>) {
      return (data as List)
              .map((e) => deserialize<_i2zbo8fc.MapEdgeInput>(e))
              .toList()
          as T;
    }
    if (t == List<_iccguhj3.Nodes>) {
      return (data as List).map((e) => deserialize<_iccguhj3.Nodes>(e)).toList()
          as T;
    }
    if (t == List<_iyphw3s3.MapReport>) {
      return (data as List)
              .map((e) => deserialize<_iyphw3s3.MapReport>(e))
              .toList()
          as T;
    }
    final modules = deserializationMetadata.modulesForDeserialization(
      t,
      className: rawDataClassName,
    );
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _is.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _icdi8t76.Building => 'Building',
      _ihh4bgnv.CreateGraphRequest => 'CreateGraphRequest',
      _ilmyslsx.Edge => 'Edge',
      _iv43g6lk.EdgeType => 'EdgeType',
      _ibt68ans.Floor => 'Floor',
      _i647gghf.FloorInput => 'FloorInput',
      _iv9rsso3.GraphPatchRequest => 'GraphPatchRequest',
      _iu1utyem.GraphReadResult => 'GraphReadResult',
      _izw8z7ou.Greeting => 'Greeting',
      _iokugpqm.Kind => 'Kind',
      _ipivyxsl.LocationCategory => 'LocationCategory',
      _iaviofrw.LocationInput => 'LocationInput',
      _iy2kpyso.Locations => 'Locations',
      _igm7lgul.MapApiException => 'MapApiException',
      _ipndifli.MapEdgeInput => 'MapEdgeInput',
      _itjn1vsu.MapEntityStatus => 'MapEntityStatus',
      _ikb2yia4.MapGraph => 'MapGraph',
      _iuswi8s2.MapGraphSnapshot => 'MapGraphSnapshot',
      _i3qve637.MapNodeInput => 'MapNodeInput',
      _iictijcz.MapReport => 'MapReport',
      _i064s9h8.MapWall => 'MapWall',
      _i9tve71o.Nodes => 'Nodes',
      _iz7e8f0p.ReplaceGraphRequest => 'ReplaceGraphRequest',
      _ijgj7dn0.ReportReason => 'ReportReason',
      _i8pcsu0p.ReportStatus => 'ReportStatus',
      _iyydfyiu.ReportTargetType => 'ReportTargetType',
      _ifcih7a1.SearchResult => 'SearchResult',
      _icks2m2l.WallInput => 'WallInput',
      _inoptxl6.WallPoint => 'WallPoint',
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
      case _icdi8t76.Building():
        return 'Building';
      case _ihh4bgnv.CreateGraphRequest():
        return 'CreateGraphRequest';
      case _ilmyslsx.Edge():
        return 'Edge';
      case _iv43g6lk.EdgeType():
        return 'EdgeType';
      case _ibt68ans.Floor():
        return 'Floor';
      case _i647gghf.FloorInput():
        return 'FloorInput';
      case _iv9rsso3.GraphPatchRequest():
        return 'GraphPatchRequest';
      case _iu1utyem.GraphReadResult():
        return 'GraphReadResult';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _iokugpqm.Kind():
        return 'Kind';
      case _ipivyxsl.LocationCategory():
        return 'LocationCategory';
      case _iaviofrw.LocationInput():
        return 'LocationInput';
      case _iy2kpyso.Locations():
        return 'Locations';
      case _igm7lgul.MapApiException():
        return 'MapApiException';
      case _ipndifli.MapEdgeInput():
        return 'MapEdgeInput';
      case _itjn1vsu.MapEntityStatus():
        return 'MapEntityStatus';
      case _ikb2yia4.MapGraph():
        return 'MapGraph';
      case _iuswi8s2.MapGraphSnapshot():
        return 'MapGraphSnapshot';
      case _i3qve637.MapNodeInput():
        return 'MapNodeInput';
      case _iictijcz.MapReport():
        return 'MapReport';
      case _i064s9h8.MapWall():
        return 'MapWall';
      case _i9tve71o.Nodes():
        return 'Nodes';
      case _iz7e8f0p.ReplaceGraphRequest():
        return 'ReplaceGraphRequest';
      case _ijgj7dn0.ReportReason():
        return 'ReportReason';
      case _i8pcsu0p.ReportStatus():
        return 'ReportStatus';
      case _iyydfyiu.ReportTargetType():
        return 'ReportTargetType';
      case _ifcih7a1.SearchResult():
        return 'SearchResult';
      case _icks2m2l.WallInput():
        return 'WallInput';
      case _inoptxl6.WallPoint():
        return 'WallPoint';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Building') {
      return deserialize<_icdi8t76.Building>(data['data']);
    }
    if (dataClassName == 'CreateGraphRequest') {
      return deserialize<_ihh4bgnv.CreateGraphRequest>(data['data']);
    }
    if (dataClassName == 'Edge') {
      return deserialize<_ilmyslsx.Edge>(data['data']);
    }
    if (dataClassName == 'EdgeType') {
      return deserialize<_iv43g6lk.EdgeType>(data['data']);
    }
    if (dataClassName == 'Floor') {
      return deserialize<_ibt68ans.Floor>(data['data']);
    }
    if (dataClassName == 'FloorInput') {
      return deserialize<_i647gghf.FloorInput>(data['data']);
    }
    if (dataClassName == 'GraphPatchRequest') {
      return deserialize<_iv9rsso3.GraphPatchRequest>(data['data']);
    }
    if (dataClassName == 'GraphReadResult') {
      return deserialize<_iu1utyem.GraphReadResult>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'Kind') {
      return deserialize<_iokugpqm.Kind>(data['data']);
    }
    if (dataClassName == 'LocationCategory') {
      return deserialize<_ipivyxsl.LocationCategory>(data['data']);
    }
    if (dataClassName == 'LocationInput') {
      return deserialize<_iaviofrw.LocationInput>(data['data']);
    }
    if (dataClassName == 'Locations') {
      return deserialize<_iy2kpyso.Locations>(data['data']);
    }
    if (dataClassName == 'MapApiException') {
      return deserialize<_igm7lgul.MapApiException>(data['data']);
    }
    if (dataClassName == 'MapEdgeInput') {
      return deserialize<_ipndifli.MapEdgeInput>(data['data']);
    }
    if (dataClassName == 'MapEntityStatus') {
      return deserialize<_itjn1vsu.MapEntityStatus>(data['data']);
    }
    if (dataClassName == 'MapGraph') {
      return deserialize<_ikb2yia4.MapGraph>(data['data']);
    }
    if (dataClassName == 'MapGraphSnapshot') {
      return deserialize<_iuswi8s2.MapGraphSnapshot>(data['data']);
    }
    if (dataClassName == 'MapNodeInput') {
      return deserialize<_i3qve637.MapNodeInput>(data['data']);
    }
    if (dataClassName == 'MapReport') {
      return deserialize<_iictijcz.MapReport>(data['data']);
    }
    if (dataClassName == 'MapWall') {
      return deserialize<_i064s9h8.MapWall>(data['data']);
    }
    if (dataClassName == 'Nodes') {
      return deserialize<_i9tve71o.Nodes>(data['data']);
    }
    if (dataClassName == 'ReplaceGraphRequest') {
      return deserialize<_iz7e8f0p.ReplaceGraphRequest>(data['data']);
    }
    if (dataClassName == 'ReportReason') {
      return deserialize<_ijgj7dn0.ReportReason>(data['data']);
    }
    if (dataClassName == 'ReportStatus') {
      return deserialize<_i8pcsu0p.ReportStatus>(data['data']);
    }
    if (dataClassName == 'ReportTargetType') {
      return deserialize<_iyydfyiu.ReportTargetType>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_ifcih7a1.SearchResult>(data['data']);
    }
    if (dataClassName == 'WallInput') {
      return deserialize<_icks2m2l.WallInput>(data['data']);
    }
    if (dataClassName == 'WallPoint') {
      return deserialize<_inoptxl6.WallPoint>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      return _iais.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(19),
      });
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      return _iacs.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(20),
      });
    }
    if (dataClassName.startsWith('serverpod.')) {
      return _isp.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(10),
      });
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('madmaps', this);
    _iacs.Protocol().registerHostProtocol('madmaps', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _icdi8t76.Building:
        return _icdi8t76.Building.t;
      case _ilmyslsx.Edge:
        return _ilmyslsx.Edge.t;
      case _ibt68ans.Floor:
        return _ibt68ans.Floor.t;
      case _iy2kpyso.Locations:
        return _iy2kpyso.Locations.t;
      case _ikb2yia4.MapGraph:
        return _ikb2yia4.MapGraph.t;
      case _iictijcz.MapReport:
        return _iictijcz.MapReport.t;
      case _i064s9h8.MapWall:
        return _i064s9h8.MapWall.t;
      case _i9tve71o.Nodes:
        return _i9tve71o.Nodes.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  List<_isp.TableDefinition> getOwnTableDefinitions() => _ownTableDefinitions;

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
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
