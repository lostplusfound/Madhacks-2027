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
import 'package:madmaps_server/src/generated/ar_capture.dart' as _ifbpi8hm;
import 'package:madmaps_server/src/generated/create_graph_request.dart'
    as _ied1q2d5;
import 'package:madmaps_server/src/generated/graph_patch_request.dart'
    as _ixd1k553;
import 'package:madmaps_server/src/generated/location_category.dart'
    as _ine5rn9y;
import 'package:madmaps_server/src/generated/location_input.dart' as _ijf9g95s;
import 'package:madmaps_server/src/generated/map_edge_input.dart' as _i2zbo8fc;
import 'package:madmaps_server/src/generated/map_node_input.dart' as _iw7xgnop;
import 'package:madmaps_server/src/generated/replace_graph_request.dart'
    as _iz03jq17;
import 'package:madmaps_server/src/generated/report_reason.dart' as _i2l2jj9m;
import 'package:madmaps_server/src/generated/report_target_type.dart'
    as _ii6tswvf;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../endpoints/building_endpoint.dart' as _iirhd8cp;
import '../endpoints/building_map_endpoint.dart' as _i1x4rfk8;
import '../endpoints/email_idp_endpoint.dart' as _ilutrrxn;
import '../endpoints/location_endpoint.dart' as _iu1rtxjg;
import '../endpoints/location_search_endpoint.dart' as _ii6rip9e;
import '../endpoints/map_edge_endpoint.dart' as _itjzzzju;
import '../endpoints/map_graph_endpoint.dart' as _i00fwvij;
import '../endpoints/map_node_endpoint.dart' as _ibynlq0k;
import '../endpoints/map_report_endpoint.dart' as _idqb48bj;
import '../greetings/greeting_endpoint.dart' as _il624ik7;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    initializeOwnEndpoints(server);
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeOwnEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeOwnEndpoints(server);
  }

  @override
  void initializeOwnEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'building': _iirhd8cp.BuildingEndpoint()
        ..initialize(
          server,
          'building',
          null,
        ),
      'buildingMap': _i1x4rfk8.BuildingMapEndpoint()
        ..initialize(
          server,
          'buildingMap',
          null,
        ),
      'emailIdp': _ilutrrxn.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'location': _iu1rtxjg.LocationEndpoint()
        ..initialize(
          server,
          'location',
          null,
        ),
      'locationSearch': _ii6rip9e.LocationSearchEndpoint()
        ..initialize(
          server,
          'locationSearch',
          null,
        ),
      'mapEdge': _itjzzzju.MapEdgeEndpoint()
        ..initialize(
          server,
          'mapEdge',
          null,
        ),
      'mapGraph': _i00fwvij.MapGraphEndpoint()
        ..initialize(
          server,
          'mapGraph',
          null,
        ),
      'mapNode': _ibynlq0k.MapNodeEndpoint()
        ..initialize(
          server,
          'mapNode',
          null,
        ),
      'mapReport': _idqb48bj.MapReportEndpoint()
        ..initialize(
          server,
          'mapReport',
          null,
        ),
      'greeting': _il624ik7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['building'] = _is.EndpointConnector(
      name: 'building',
      endpoint: endpoints['building']!,
      methodConnectors: {
        'createBuilding': _is.MethodConnector(
          name: 'createBuilding',
          params: {
            'buildingId': _is.ParameterDescription(
              name: 'buildingId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'address': _is.ParameterDescription(
              name: 'address',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['building'] as _iirhd8cp.BuildingEndpoint)
                  .createBuilding(
                    session,
                    params['buildingId'],
                    params['name'],
                    params['address'],
                  ),
        ),
        'getBuilding': _is.MethodConnector(
          name: 'getBuilding',
          params: {
            'buildingId': _is.ParameterDescription(
              name: 'buildingId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['building'] as _iirhd8cp.BuildingEndpoint)
                  .getBuilding(
                    session,
                    params['buildingId'],
                  ),
        ),
        'listBuildings': _is.MethodConnector(
          name: 'listBuildings',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['building'] as _iirhd8cp.BuildingEndpoint)
                  .listBuildings(
                    session,
                    params['limit'],
                    params['offset'],
                  ),
        ),
      },
    );
    connectors['buildingMap'] = _is.EndpointConnector(
      name: 'buildingMap',
      endpoint: endpoints['buildingMap']!,
      methodConnectors: {
        'listConnectors': _is.MethodConnector(
          name: 'listConnectors',
          params: {
            'buildingId': _is.ParameterDescription(
              name: 'buildingId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['buildingMap'] as _i1x4rfk8.BuildingMapEndpoint)
                      .listConnectors(
                        session,
                        params['buildingId'],
                      ),
        ),
        'listCaptures': _is.MethodConnector(
          name: 'listCaptures',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'graphVersion': _is.ParameterDescription(
              name: 'graphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['buildingMap'] as _i1x4rfk8.BuildingMapEndpoint)
                      .listCaptures(
                        session,
                        params['graphId'],
                        params['graphVersion'],
                      ),
        ),
        'publishCapture': _is.MethodConnector(
          name: 'publishCapture',
          params: {
            'capture': _is.ParameterDescription(
              name: 'capture',
              type: _is.getType<_ifbpi8hm.ArCapture>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['buildingMap'] as _i1x4rfk8.BuildingMapEndpoint)
                      .publishCapture(
                        session,
                        params['capture'],
                      ),
        ),
      },
    );
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'startOtpLogin': _is.MethodConnector(
          name: 'startOtpLogin',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .startOtpLogin(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyOtpLoginCode': _is.MethodConnector(
          name: 'verifyOtpLoginCode',
          params: {
            'otpLoginRequestId': _is.ParameterDescription(
              name: 'otpLoginRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .verifyOtpLoginCode(
                    session,
                    otpLoginRequestId: params['otpLoginRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishOtpLogin': _is.MethodConnector(
          name: 'finishOtpLogin',
          params: {
            'otpLoginToken': _is.ParameterDescription(
              name: 'otpLoginToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .finishOtpLogin(
                    session,
                    otpLoginToken: params['otpLoginToken'],
                  ),
        ),
        'finishOtpRegistration': _is.MethodConnector(
          name: 'finishOtpRegistration',
          params: {
            'otpLoginToken': _is.ParameterDescription(
              name: 'otpLoginToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .finishOtpRegistration(
                    session,
                    otpLoginToken: params['otpLoginToken'],
                    password: params['password'],
                  ),
        ),
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _ilutrrxn.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['location'] = _is.EndpointConnector(
      name: 'location',
      endpoint: endpoints['location']!,
      methodConnectors: {
        'createLocation': _is.MethodConnector(
          name: 'createLocation',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'location': _is.ParameterDescription(
              name: 'location',
              type: _is.getType<_ijf9g95s.LocationInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['location'] as _iu1rtxjg.LocationEndpoint)
                  .createLocation(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['location'],
                  ),
        ),
        'getLocation': _is.MethodConnector(
          name: 'getLocation',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'locationId': _is.ParameterDescription(
              name: 'locationId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['location'] as _iu1rtxjg.LocationEndpoint)
                  .getLocation(
                    session,
                    params['graphId'],
                    params['locationId'],
                  ),
        ),
        'listLocations': _is.MethodConnector(
          name: 'listLocations',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'floorNumber': _is.ParameterDescription(
              name: 'floorNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<_ine5rn9y.LocationCategory?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['location'] as _iu1rtxjg.LocationEndpoint)
                  .listLocations(
                    session,
                    params['graphId'],
                    params['floorNumber'],
                    params['category'],
                  ),
        ),
        'updateLocation': _is.MethodConnector(
          name: 'updateLocation',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'location': _is.ParameterDescription(
              name: 'location',
              type: _is.getType<_ijf9g95s.LocationInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['location'] as _iu1rtxjg.LocationEndpoint)
                  .updateLocation(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['location'],
                  ),
        ),
        'deleteLocation': _is.MethodConnector(
          name: 'deleteLocation',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'locationId': _is.ParameterDescription(
              name: 'locationId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['location'] as _iu1rtxjg.LocationEndpoint)
                  .deleteLocation(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['locationId'],
                  ),
        ),
      },
    );
    connectors['locationSearch'] = _is.EndpointConnector(
      name: 'locationSearch',
      endpoint: endpoints['locationSearch']!,
      methodConnectors: {
        'searchLocations': _is.MethodConnector(
          name: 'searchLocations',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<_ine5rn9y.LocationCategory?>(),
              nullable: true,
            ),
            'floorNumber': _is.ParameterDescription(
              name: 'floorNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['locationSearch']
                          as _ii6rip9e.LocationSearchEndpoint)
                      .searchLocations(
                        session,
                        params['graphId'],
                        params['query'],
                        params['category'],
                        params['floorNumber'],
                        params['limit'],
                      ),
        ),
        'listLocationsByCategory': _is.MethodConnector(
          name: 'listLocationsByCategory',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<_ine5rn9y.LocationCategory>(),
              nullable: false,
            ),
            'floorNumber': _is.ParameterDescription(
              name: 'floorNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['locationSearch']
                          as _ii6rip9e.LocationSearchEndpoint)
                      .listLocationsByCategory(
                        session,
                        params['graphId'],
                        params['category'],
                        params['floorNumber'],
                        params['limit'],
                      ),
        ),
        'listQuickAccessCategories': _is.MethodConnector(
          name: 'listQuickAccessCategories',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['locationSearch']
                          as _ii6rip9e.LocationSearchEndpoint)
                      .listQuickAccessCategories(
                        session,
                        params['graphId'],
                      ),
        ),
      },
    );
    connectors['mapEdge'] = _is.EndpointConnector(
      name: 'mapEdge',
      endpoint: endpoints['mapEdge']!,
      methodConnectors: {
        'createEdge': _is.MethodConnector(
          name: 'createEdge',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'edge': _is.ParameterDescription(
              name: 'edge',
              type: _is.getType<_i2zbo8fc.MapEdgeInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapEdge'] as _itjzzzju.MapEdgeEndpoint)
                  .createEdge(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['edge'],
                  ),
        ),
        'getEdge': _is.MethodConnector(
          name: 'getEdge',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'edgeId': _is.ParameterDescription(
              name: 'edgeId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mapEdge'] as _itjzzzju.MapEdgeEndpoint).getEdge(
                    session,
                    params['graphId'],
                    params['edgeId'],
                  ),
        ),
        'listEdges': _is.MethodConnector(
          name: 'listEdges',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mapEdge'] as _itjzzzju.MapEdgeEndpoint).listEdges(
                    session,
                    params['graphId'],
                  ),
        ),
        'updateEdge': _is.MethodConnector(
          name: 'updateEdge',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'edge': _is.ParameterDescription(
              name: 'edge',
              type: _is.getType<_i2zbo8fc.MapEdgeInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapEdge'] as _itjzzzju.MapEdgeEndpoint)
                  .updateEdge(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['edge'],
                  ),
        ),
        'deleteEdge': _is.MethodConnector(
          name: 'deleteEdge',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'edgeId': _is.ParameterDescription(
              name: 'edgeId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapEdge'] as _itjzzzju.MapEdgeEndpoint)
                  .deleteEdge(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['edgeId'],
                  ),
        ),
      },
    );
    connectors['mapGraph'] = _is.EndpointConnector(
      name: 'mapGraph',
      endpoint: endpoints['mapGraph']!,
      methodConnectors: {
        'createGraph': _is.MethodConnector(
          name: 'createGraph',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ied1q2d5.CreateGraphRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .createGraph(
                    session,
                    params['request'],
                  ),
        ),
        'getGraph': _is.MethodConnector(
          name: 'getGraph',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'ifVersion': _is.ParameterDescription(
              name: 'ifVersion',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .getGraph(
                    session,
                    params['graphId'],
                    params['ifVersion'],
                  ),
        ),
        'listGraphs': _is.MethodConnector(
          name: 'listGraphs',
          params: {
            'buildingId': _is.ParameterDescription(
              name: 'buildingId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .listGraphs(
                    session,
                    params['buildingId'],
                    params['limit'],
                    params['offset'],
                  ),
        ),
        'patchGraph': _is.MethodConnector(
          name: 'patchGraph',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ixd1k553.GraphPatchRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .patchGraph(
                    session,
                    params['request'],
                  ),
        ),
        'replaceGraph': _is.MethodConnector(
          name: 'replaceGraph',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iz03jq17.ReplaceGraphRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .replaceGraph(
                    session,
                    params['request'],
                  ),
        ),
        'deleteGraph': _is.MethodConnector(
          name: 'deleteGraph',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapGraph'] as _i00fwvij.MapGraphEndpoint)
                  .deleteGraph(
                    session,
                    params['graphId'],
                    params['expectedVersion'],
                  ),
        ),
      },
    );
    connectors['mapNode'] = _is.EndpointConnector(
      name: 'mapNode',
      endpoint: endpoints['mapNode']!,
      methodConnectors: {
        'createNode': _is.MethodConnector(
          name: 'createNode',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'node': _is.ParameterDescription(
              name: 'node',
              type: _is.getType<_iw7xgnop.MapNodeInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint)
                  .createNode(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['node'],
                  ),
        ),
        'createNodeWithConnections': _is.MethodConnector(
          name: 'createNodeWithConnections',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'node': _is.ParameterDescription(
              name: 'node',
              type: _is.getType<_iw7xgnop.MapNodeInput>(),
              nullable: false,
            ),
            'edges': _is.ParameterDescription(
              name: 'edges',
              type: _is.getType<List<_i2zbo8fc.MapEdgeInput>>(),
              nullable: false,
            ),
            'location': _is.ParameterDescription(
              name: 'location',
              type: _is.getType<_ijf9g95s.LocationInput?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint)
                  .createNodeWithConnections(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['node'],
                    params['edges'],
                    params['location'],
                  ),
        ),
        'getNode': _is.MethodConnector(
          name: 'getNode',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'nodeId': _is.ParameterDescription(
              name: 'nodeId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint).getNode(
                    session,
                    params['graphId'],
                    params['nodeId'],
                  ),
        ),
        'listNodes': _is.MethodConnector(
          name: 'listNodes',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'floorNumber': _is.ParameterDescription(
              name: 'floorNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint).listNodes(
                    session,
                    params['graphId'],
                    params['floorNumber'],
                  ),
        ),
        'updateNode': _is.MethodConnector(
          name: 'updateNode',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'node': _is.ParameterDescription(
              name: 'node',
              type: _is.getType<_iw7xgnop.MapNodeInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint)
                  .updateNode(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['node'],
                  ),
        ),
        'deleteNode': _is.MethodConnector(
          name: 'deleteNode',
          params: {
            'graphId': _is.ParameterDescription(
              name: 'graphId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedGraphVersion': _is.ParameterDescription(
              name: 'expectedGraphVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'nodeId': _is.ParameterDescription(
              name: 'nodeId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapNode'] as _ibynlq0k.MapNodeEndpoint)
                  .deleteNode(
                    session,
                    params['graphId'],
                    params['expectedGraphVersion'],
                    params['nodeId'],
                  ),
        ),
      },
    );
    connectors['mapReport'] = _is.EndpointConnector(
      name: 'mapReport',
      endpoint: endpoints['mapReport']!,
      methodConnectors: {
        'reportEntity': _is.MethodConnector(
          name: 'reportEntity',
          params: {
            'targetType': _is.ParameterDescription(
              name: 'targetType',
              type: _is.getType<_ii6tswvf.ReportTargetType>(),
              nullable: false,
            ),
            'targetId': _is.ParameterDescription(
              name: 'targetId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<_i2l2jj9m.ReportReason>(),
              nullable: false,
            ),
            'notes': _is.ParameterDescription(
              name: 'notes',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapReport'] as _idqb48bj.MapReportEndpoint)
                  .reportEntity(
                    session,
                    params['targetType'],
                    params['targetId'],
                    params['reason'],
                    params['notes'],
                  ),
        ),
        'listMyReports': _is.MethodConnector(
          name: 'listMyReports',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapReport'] as _idqb48bj.MapReportEndpoint)
                  .listMyReports(
                    session,
                    params['limit'],
                    params['offset'],
                  ),
        ),
        'withdrawReport': _is.MethodConnector(
          name: 'withdrawReport',
          params: {
            'reportId': _is.ParameterDescription(
              name: 'reportId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['mapReport'] as _idqb48bj.MapReportEndpoint)
                  .withdrawReport(
                    session,
                    params['reportId'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _is.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['greeting'] as _il624ik7.GreetingEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
  }
}
