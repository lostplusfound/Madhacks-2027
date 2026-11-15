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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:madmaps_client/src/protocol/ar_capture.dart' as _i1pvqriv;
import 'package:madmaps_client/src/protocol/building.dart' as _ixxicett;
import 'package:madmaps_client/src/protocol/create_graph_request.dart'
    as _ik7sj57u;
import 'package:madmaps_client/src/protocol/edge.dart' as _i71va5xw;
import 'package:madmaps_client/src/protocol/floor_connector.dart' as _ik47qssa;
import 'package:madmaps_client/src/protocol/graph_patch_request.dart'
    as _iq2332iw;
import 'package:madmaps_client/src/protocol/graph_read_result.dart'
    as _ijpyrqq0;
import 'package:madmaps_client/src/protocol/greetings/greeting.dart'
    as _igi1f61t;
import 'package:madmaps_client/src/protocol/location_category.dart'
    as _iosiyc7r;
import 'package:madmaps_client/src/protocol/location_input.dart' as _i9u1r3i1;
import 'package:madmaps_client/src/protocol/locations.dart' as _iwfkkrvw;
import 'package:madmaps_client/src/protocol/map_edge_input.dart' as _i63byxc2;
import 'package:madmaps_client/src/protocol/map_graph.dart' as _i5ydwcda;
import 'package:madmaps_client/src/protocol/map_graph_snapshot.dart'
    as _igef8xkz;
import 'package:madmaps_client/src/protocol/map_node_input.dart' as _iknlbgoc;
import 'package:madmaps_client/src/protocol/map_report.dart' as _i5b93lv5;
import 'package:madmaps_client/src/protocol/node.dart' as _i6rsjj6d;
import 'package:madmaps_client/src/protocol/replace_graph_request.dart'
    as _iwd56web;
import 'package:madmaps_client/src/protocol/report_reason.dart' as _i6ynwlr2;
import 'package:madmaps_client/src/protocol/report_target_type.dart'
    as _iws3unv8;
import 'package:madmaps_client/src/protocol/search_result.dart' as _i56rwuj1;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// {@category Endpoint}
class EndpointBuilding extends _isc.EndpointRef {
  EndpointBuilding(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'building';

  _ida.Future<_ixxicett.Building> createBuilding(
    String buildingId,
    String name,
    String? address,
  ) => caller.callServerEndpoint<_ixxicett.Building>(
    'building',
    'createBuilding',
    {
      'buildingId': buildingId,
      'name': name,
      'address': address,
    },
  );

  _ida.Future<_ixxicett.Building?> getBuilding(String buildingId) =>
      caller.callServerEndpoint<_ixxicett.Building?>(
        'building',
        'getBuilding',
        {'buildingId': buildingId},
      );

  _ida.Future<List<_ixxicett.Building>> listBuildings(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_ixxicett.Building>>(
    'building',
    'listBuildings',
    {
      'limit': limit,
      'offset': offset,
    },
  );
}

/// {@category Endpoint}
class EndpointBuildingMap extends _isc.EndpointRef {
  EndpointBuildingMap(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'buildingMap';

  _ida.Future<List<_ik47qssa.FloorConnector>> listConnectors(
    String buildingId,
  ) => caller.callServerEndpoint<List<_ik47qssa.FloorConnector>>(
    'buildingMap',
    'listConnectors',
    {'buildingId': buildingId},
  );

  _ida.Future<List<_i1pvqriv.ArCapture>> listCaptures(
    String graphId,
    int graphVersion,
  ) => caller.callServerEndpoint<List<_i1pvqriv.ArCapture>>(
    'buildingMap',
    'listCaptures',
    {
      'graphId': graphId,
      'graphVersion': graphVersion,
    },
  );

  /// Prototype contributions are public immediately; no graph-edit rights granted.
  _ida.Future<_i1pvqriv.ArCapture> publishCapture(
    _i1pvqriv.ArCapture capture,
  ) => caller.callServerEndpoint<_i1pvqriv.ArCapture>(
    'buildingMap',
    'publishCapture',
    {'capture': capture},
  );
}

/// Email sign-in endpoint supplied by Serverpod's maintained auth module.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailOtpIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Starts a passwordless login by sending a one-time password to [email].
  ///
  /// The code is sent whether or not an account is registered for the email.
  /// If none is, verifying the code lets the user create a new account.
  ///
  /// Always returns a login request ID, which must be passed to
  /// [verifyOtpLoginCode] together with the one-time password.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the email is
  ///   not valid.
  /// - [EmailAccountRequestExceptionReason.tooManyAttempts] if too many
  ///   one-time passwords have been requested for the email.
  @override
  _ida.Future<_isc.UuidValue> startOtpLogin({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startOtpLogin',
        {'email': email},
      );

  /// Verifies a one-time password and returns a token to complete the login.
  ///
  /// If [EmailAccountOtpVerificationResult.accountExists] is `true`, pass the
  /// token to [finishOtpLogin] to sign in. Otherwise, have the user accept the
  /// terms (and optionally set a password if
  /// [EmailAccountOtpVerificationResult.allowPassword] is `true`) and pass it
  /// to [finishOtpRegistration] to create the account.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the login request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts to verify the code.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists for
  ///   the given [otpLoginRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<_iaic.EmailAccountOtpVerificationResult> verifyOtpLoginCode({
    required _isc.UuidValue otpLoginRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<_iaic.EmailAccountOtpVerificationResult>(
    'emailIdp',
    'verifyOtpLoginCode',
    {
      'otpLoginRequestId': otpLoginRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a passwordless login for an existing account and returns a new
  /// session.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the login request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [otpLoginToken] is
  ///   invalid or no account exists for the email.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> finishOtpLogin({
    required String otpLoginToken,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishOtpLogin',
    {'otpLoginToken': otpLoginToken},
  );

  /// Completes a passwordless login for an email without an account, by
  /// creating a new auth user with a profile and attaching the verified email
  /// to it.
  ///
  /// Must only be called after the user accepted the terms. The [password] is
  /// optional, and may only be set if
  /// [EmailAccountOtpVerificationResult.allowPassword] was `true`.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the login request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if a password is
  ///   given but not allowed, or it does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [otpLoginToken] is
  ///   invalid or an account already exists for the email.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishOtpRegistration({
    required String otpLoginToken,
    String? password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishOtpRegistration',
    {
      'otpLoginToken': otpLoginToken,
      'password': password,
    },
  );

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// {@category Endpoint}
class EndpointLocation extends _isc.EndpointRef {
  EndpointLocation(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'location';

  _ida.Future<_iwfkkrvw.Locations> createLocation(
    String graphId,
    int expectedGraphVersion,
    _i9u1r3i1.LocationInput location,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations>(
    'location',
    'createLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'location': location,
    },
  );

  _ida.Future<_iwfkkrvw.Locations?> getLocation(
    String graphId,
    String locationId,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations?>(
    'location',
    'getLocation',
    {
      'graphId': graphId,
      'locationId': locationId,
    },
  );

  _ida.Future<List<_iwfkkrvw.Locations>> listLocations(
    String graphId,
    int? floorNumber,
    _iosiyc7r.LocationCategory? category,
  ) => caller.callServerEndpoint<List<_iwfkkrvw.Locations>>(
    'location',
    'listLocations',
    {
      'graphId': graphId,
      'floorNumber': floorNumber,
      'category': category,
    },
  );

  _ida.Future<_iwfkkrvw.Locations> updateLocation(
    String graphId,
    int expectedGraphVersion,
    _i9u1r3i1.LocationInput location,
  ) => caller.callServerEndpoint<_iwfkkrvw.Locations>(
    'location',
    'updateLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'location': location,
    },
  );

  _ida.Future<void> deleteLocation(
    String graphId,
    int expectedGraphVersion,
    String locationId,
  ) => caller.callServerEndpoint<void>(
    'location',
    'deleteLocation',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'locationId': locationId,
    },
  );
}

/// {@category Endpoint}
class EndpointLocationSearch extends _isc.EndpointRef {
  EndpointLocationSearch(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'locationSearch';

  _ida.Future<List<_i56rwuj1.SearchResult>> searchLocations(
    String graphId,
    String? query,
    _iosiyc7r.LocationCategory? category,
    int? floorNumber,
    int limit,
  ) => caller.callServerEndpoint<List<_i56rwuj1.SearchResult>>(
    'locationSearch',
    'searchLocations',
    {
      'graphId': graphId,
      'query': query,
      'category': category,
      'floorNumber': floorNumber,
      'limit': limit,
    },
  );

  _ida.Future<List<_i56rwuj1.SearchResult>> listLocationsByCategory(
    String graphId,
    _iosiyc7r.LocationCategory category,
    int? floorNumber,
    int limit,
  ) => caller.callServerEndpoint<List<_i56rwuj1.SearchResult>>(
    'locationSearch',
    'listLocationsByCategory',
    {
      'graphId': graphId,
      'category': category,
      'floorNumber': floorNumber,
      'limit': limit,
    },
  );

  _ida.Future<List<_iosiyc7r.LocationCategory>> listQuickAccessCategories(
    String graphId,
  ) => caller.callServerEndpoint<List<_iosiyc7r.LocationCategory>>(
    'locationSearch',
    'listQuickAccessCategories',
    {'graphId': graphId},
  );
}

/// {@category Endpoint}
class EndpointMapEdge extends _isc.EndpointRef {
  EndpointMapEdge(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapEdge';

  _ida.Future<_i71va5xw.Edge> createEdge(
    String graphId,
    int expectedGraphVersion,
    _i63byxc2.MapEdgeInput edge,
  ) => caller.callServerEndpoint<_i71va5xw.Edge>(
    'mapEdge',
    'createEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edge': edge,
    },
  );

  _ida.Future<_i71va5xw.Edge?> getEdge(
    String graphId,
    String edgeId,
  ) => caller.callServerEndpoint<_i71va5xw.Edge?>(
    'mapEdge',
    'getEdge',
    {
      'graphId': graphId,
      'edgeId': edgeId,
    },
  );

  _ida.Future<List<_i71va5xw.Edge>> listEdges(String graphId) =>
      caller.callServerEndpoint<List<_i71va5xw.Edge>>(
        'mapEdge',
        'listEdges',
        {'graphId': graphId},
      );

  _ida.Future<_i71va5xw.Edge> updateEdge(
    String graphId,
    int expectedGraphVersion,
    _i63byxc2.MapEdgeInput edge,
  ) => caller.callServerEndpoint<_i71va5xw.Edge>(
    'mapEdge',
    'updateEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edge': edge,
    },
  );

  _ida.Future<void> deleteEdge(
    String graphId,
    int expectedGraphVersion,
    String edgeId,
  ) => caller.callServerEndpoint<void>(
    'mapEdge',
    'deleteEdge',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'edgeId': edgeId,
    },
  );
}

/// {@category Endpoint}
class EndpointMapGraph extends _isc.EndpointRef {
  EndpointMapGraph(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapGraph';

  _ida.Future<_igef8xkz.MapGraphSnapshot> createGraph(
    _ik7sj57u.CreateGraphRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'createGraph',
    {'request': request},
  );

  _ida.Future<_ijpyrqq0.GraphReadResult> getGraph(
    String graphId,
    int? ifVersion,
  ) => caller.callServerEndpoint<_ijpyrqq0.GraphReadResult>(
    'mapGraph',
    'getGraph',
    {
      'graphId': graphId,
      'ifVersion': ifVersion,
    },
  );

  _ida.Future<List<_i5ydwcda.MapGraph>> listGraphs(
    String? buildingId,
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_i5ydwcda.MapGraph>>(
    'mapGraph',
    'listGraphs',
    {
      'buildingId': buildingId,
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<_igef8xkz.MapGraphSnapshot> patchGraph(
    _iq2332iw.GraphPatchRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'patchGraph',
    {'request': request},
  );

  _ida.Future<_igef8xkz.MapGraphSnapshot> replaceGraph(
    _iwd56web.ReplaceGraphRequest request,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapGraph',
    'replaceGraph',
    {'request': request},
  );

  _ida.Future<void> deleteGraph(
    String graphId,
    int expectedVersion,
  ) => caller.callServerEndpoint<void>(
    'mapGraph',
    'deleteGraph',
    {
      'graphId': graphId,
      'expectedVersion': expectedVersion,
    },
  );
}

/// {@category Endpoint}
class EndpointMapNode extends _isc.EndpointRef {
  EndpointMapNode(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapNode';

  _ida.Future<_i6rsjj6d.Nodes> createNode(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes>(
    'mapNode',
    'createNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
    },
  );

  /// Creates a routable contribution atomically. This is the normal creation
  /// path after a graph has been seeded because active nodes must be connected.
  _ida.Future<_igef8xkz.MapGraphSnapshot> createNodeWithConnections(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
    List<_i63byxc2.MapEdgeInput> edges,
    _i9u1r3i1.LocationInput? location,
  ) => caller.callServerEndpoint<_igef8xkz.MapGraphSnapshot>(
    'mapNode',
    'createNodeWithConnections',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
      'edges': edges,
      'location': location,
    },
  );

  _ida.Future<_i6rsjj6d.Nodes?> getNode(
    String graphId,
    String nodeId,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes?>(
    'mapNode',
    'getNode',
    {
      'graphId': graphId,
      'nodeId': nodeId,
    },
  );

  _ida.Future<List<_i6rsjj6d.Nodes>> listNodes(
    String graphId,
    int? floorNumber,
  ) => caller.callServerEndpoint<List<_i6rsjj6d.Nodes>>(
    'mapNode',
    'listNodes',
    {
      'graphId': graphId,
      'floorNumber': floorNumber,
    },
  );

  _ida.Future<_i6rsjj6d.Nodes> updateNode(
    String graphId,
    int expectedGraphVersion,
    _iknlbgoc.MapNodeInput node,
  ) => caller.callServerEndpoint<_i6rsjj6d.Nodes>(
    'mapNode',
    'updateNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'node': node,
    },
  );

  _ida.Future<void> deleteNode(
    String graphId,
    int expectedGraphVersion,
    String nodeId,
  ) => caller.callServerEndpoint<void>(
    'mapNode',
    'deleteNode',
    {
      'graphId': graphId,
      'expectedGraphVersion': expectedGraphVersion,
      'nodeId': nodeId,
    },
  );
}

/// {@category Endpoint}
class EndpointMapReport extends _isc.EndpointRef {
  EndpointMapReport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'mapReport';

  _ida.Future<_i5b93lv5.MapReport> reportEntity(
    _iws3unv8.ReportTargetType targetType,
    String targetId,
    _i6ynwlr2.ReportReason reason,
    String? notes,
  ) => caller.callServerEndpoint<_i5b93lv5.MapReport>(
    'mapReport',
    'reportEntity',
    {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'notes': notes,
    },
  );

  _ida.Future<List<_i5b93lv5.MapReport>> listMyReports(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<_i5b93lv5.MapReport>>(
    'mapReport',
    'listMyReports',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  _ida.Future<_i5b93lv5.MapReport> withdrawReport(String reportId) =>
      caller.callServerEndpoint<_i5b93lv5.MapReport>(
        'mapReport',
        'withdrawReport',
        {'reportId': reportId},
      );
}

/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  _ida.Future<_igi1f61t.Greeting> hello(String name) =>
      caller.callServerEndpoint<_igi1f61t.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    building = EndpointBuilding(this);
    buildingMap = EndpointBuildingMap(this);
    emailIdp = EndpointEmailIdp(this);
    location = EndpointLocation(this);
    locationSearch = EndpointLocationSearch(this);
    mapEdge = EndpointMapEdge(this);
    mapGraph = EndpointMapGraph(this);
    mapNode = EndpointMapNode(this);
    mapReport = EndpointMapReport(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointBuilding building;

  late final EndpointBuildingMap buildingMap;

  late final EndpointEmailIdp emailIdp;

  late final EndpointLocation location;

  late final EndpointLocationSearch locationSearch;

  late final EndpointMapEdge mapEdge;

  late final EndpointMapGraph mapGraph;

  late final EndpointMapNode mapNode;

  late final EndpointMapReport mapReport;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'building': building,
    'buildingMap': buildingMap,
    'emailIdp': emailIdp,
    'location': location,
    'locationSearch': locationSearch,
    'mapEdge': mapEdge,
    'mapGraph': mapGraph,
    'mapNode': mapNode,
    'mapReport': mapReport,
    'greeting': greeting,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
