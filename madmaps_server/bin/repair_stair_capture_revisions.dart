import 'dart:convert';
import 'dart:io';
import 'package:madmaps_server/src/generated/serverpod.dart';
import 'package:madmaps_server/src/generated/protocol.dart';

/// Repair only the known graph-only stair revisions; never alter anchor data.
Future<void> main(List<String> args) async {
  final pod = Serverpod(args);
  final s = await pod.createSession(enableLogging: false);
  try {
    final captures = await ArCapture.db.find(s);
    final backup = File(
      '.serverpod/capture-backups/before-stair-revision-repair-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await backup.parent.create(recursive: true);
    await backup.writeAsString(
      jsonEncode(captures.map((c) => c.toJson()).toList()),
    );
    await s.db.transaction((tx) async {
      for (final entry in {
        'morgridge-floor0': 3,
        'morgridge-floor1': 4,
      }.entries) {
        final g = await MapGraph.db.findFirstRow(
          s,
          where: (t) => t.graphId.equals(entry.key),
          transaction: tx,
        );
        if (g == null || g.version != entry.value + 1)
          throw StateError(
            'Unexpected graph revision for ${entry.key}; no repair applied.',
          );
        for (final c in captures.where(
          (c) => c.graphId == entry.key && c.graphVersion == entry.value,
        )) {
          await ArCapture.db.updateRow(
            s,
            c.copyWith(graphVersion: g.version),
            transaction: tx,
          );
          print(
            'Restored capture compatibility on floor ${c.floorNumber}; anchors and expiry unchanged.',
          );
        }
      }
    });
  } finally {
    await s.close();
    await pod.shutdown(exitProcess: false);
  }
}
