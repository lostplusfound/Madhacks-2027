import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'map_graph_service.dart';

class MapReportEndpoint extends Endpoint {
  static const _service = MapGraphService();

  Future<MapReport> reportEntity(
    Session session,
    ReportTargetType targetType,
    String targetId,
    ReportReason reason,
    String? notes,
  ) => _service.reportEntity(
    session,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    notes: notes,
  );

  Future<List<MapReport>> listMyReports(
    Session session,
    int limit,
    int offset,
  ) => _service.listMyReports(session, limit: limit, offset: offset);

  Future<MapReport> withdrawReport(Session session, String reportId) =>
      _service.withdrawReport(session, reportId);
}
