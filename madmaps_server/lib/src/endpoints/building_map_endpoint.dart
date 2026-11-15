import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../mapping/capture_validation.dart';
import 'map_graph_service.dart';

class BuildingMapEndpoint extends Endpoint {
  /// Compare-and-swap shared metadata without changing map geometry.
  Future<ArCapture> updateCapture(
    Session session,
    ArCapture capture,
    String expectedAnchorMapJson,
  ) async {
    final graph = await const MapGraphService().getGraph(
      session,
      capture.graphId,
    );
    if (graph == null ||
        graph.graph.version != capture.graphVersion ||
        !graph.floors.any((f) => f.floorNumber == capture.floorNumber)) {
      throw MapApiException(
        code: 'revisionMismatch',
        message: 'Reload the floor map before editing this scan.',
      );
    }
    late DateTime expiry;
    try {
      expiry = validateCapture(
        capture.anchorMapJson,
        capture.captureId,
        capture.floorNumber,
        DateTime.now().toUtc(),
      );
    } catch (_) {
      throw MapApiException(
        code: 'invalidCapture',
        message: 'Keep 2 to 20 valid points and a valid calibration pair.',
      );
    }
    return session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@captureId))',
        parameters: QueryParameters.named({'captureId': capture.captureId}),
        transaction: transaction,
      );
      final existing = await ArCapture.db.findFirstRow(
        session,
        where: (t) => t.captureId.equals(capture.captureId),
        transaction: transaction,
      );
      if (existing == null ||
          !existing.expiresAt.isAfter(DateTime.now().toUtc()) ||
          existing.graphId != capture.graphId ||
          existing.graphVersion != capture.graphVersion ||
          existing.floorNumber != capture.floorNumber) {
        throw MapApiException(
          code: 'captureConflict',
          message: 'This scan changed or was removed. Refresh Community.',
        );
      }
      if (existing.anchorMapJson == capture.anchorMapJson) return existing;
      if (existing.anchorMapJson != expectedAnchorMapJson) {
        throw MapApiException(
          code: 'captureConflict',
          message:
              'Someone edited this scan. Refresh Community before editing again.',
        );
      }
      return ArCapture.db.updateRow(
        session,
        existing.copyWith(
          anchorMapJson: capture.anchorMapJson,
          expiresAt: expiry,
        ),
        transaction: transaction,
      );
    });
  }

  Future<void> deleteCapture(
    Session session,
    String captureId,
    String expectedAnchorMapJson,
  ) async {
    await session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@captureId))',
        parameters: QueryParameters.named({'captureId': captureId}),
        transaction: transaction,
      );
      final existing = await ArCapture.db.findFirstRow(
        session,
        where: (t) => t.captureId.equals(captureId),
        transaction: transaction,
      );
      if (existing == null ||
          !existing.expiresAt.isAfter(DateTime.now().toUtc()))
        return;
      if (existing.anchorMapJson != expectedAnchorMapJson) {
        throw MapApiException(
          code: 'captureConflict',
          message:
              'Someone edited this scan. Refresh Community before removing it.',
        );
      }
      // Retain the ID so an old queued initial upload cannot resurrect this scan.
      await ArCapture.db.updateRow(
        session,
        existing.copyWith(
          expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        transaction: transaction,
      );
    });
  }

  Future<List<FloorConnector>> listConnectors(
    Session session,
    String buildingId,
  ) => FloorConnector.db.find(
    session,
    where: (t) => t.buildingId.equals(buildingId) & t.active.equals(true),
  );

  Future<List<ArCapture>> listCaptures(
    Session session,
    String graphId,
    int graphVersion,
  ) async {
    final graph = await const MapGraphService().getGraph(session, graphId);
    if (graph == null || graph.graph.version != graphVersion) return [];
    return ArCapture.db.find(
      session,
      where: (t) =>
          t.graphId.equals(graphId) &
          t.graphVersion.equals(graphVersion) &
          (t.expiresAt > DateTime.now().toUtc()),
      limit: 200,
    );
  }

  /// Prototype contributions are public immediately; no graph-edit rights granted.
  Future<ArCapture> publishCapture(Session session, ArCapture capture) async {
    final graph = await const MapGraphService().getGraph(
      session,
      capture.graphId,
    );
    if (graph == null ||
        graph.graph.version != capture.graphVersion ||
        !graph.floors.any((f) => f.floorNumber == capture.floorNumber)) {
      throw MapApiException(
        code: 'revisionMismatch',
        message: 'Reload the floor map before publishing this scan.',
      );
    }
    late DateTime expiry;
    try {
      expiry = validateCapture(
        capture.anchorMapJson,
        capture.captureId,
        capture.floorNumber,
        DateTime.now().toUtc(),
      );
    } catch (_) {
      throw MapApiException(
        code: 'invalidCapture',
        message: 'Invalid anchors, calibration, expiry or floor metadata.',
      );
    }
    // Serialize retries of a capture ID, including simultaneous requests.
    return session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@captureId))',
        parameters: QueryParameters.named({'captureId': capture.captureId}),
        transaction: transaction,
      );
      final existing = await ArCapture.db.findFirstRow(
        session,
        where: (t) => t.captureId.equals(capture.captureId),
        transaction: transaction,
      );
      if (existing != null) {
        if (!existing.expiresAt.isAfter(DateTime.now().toUtc()) ||
            existing.graphId != capture.graphId ||
            existing.graphVersion != capture.graphVersion ||
            existing.floorNumber != capture.floorNumber ||
            jsonEncode(jsonDecode(existing.anchorMapJson)) !=
                jsonEncode(jsonDecode(capture.anchorMapJson))) {
          throw MapApiException(
            code: 'captureConflict',
            message: 'This capture ID already has different data.',
          );
        }
        return existing;
      }
      return ArCapture.db.insertRow(
        session,
        ArCapture(
          captureId: capture.captureId,
          graphId: capture.graphId,
          graphVersion: capture.graphVersion,
          floorNumber: capture.floorNumber,
          anchorMapJson: capture.anchorMapJson,
          expiresAt: expiry,
        ),
        transaction: transaction,
      );
    });
  }
}
