import 'dart:convert';
import 'package:madmaps_client/madmaps_client.dart';

Future<void> main(List<String> args) async {
  final live = args.contains("--live");
  final client = Client('http://localhost:8080/');
  try {
    final capabilities = jsonDecode(await client.extractionLab.capabilities()) as Map<String, dynamic>;
    if (capabilities['worker_ready'] != true) throw StateError('Worker unavailable: $capabilities');
    final started = jsonDecode(await client.extractionLab.start(jsonEncode({'action': 'extract', 'mode': live ? 'databricks' : 'demo', 'sample_plan': live}))) as Map<String, dynamic>;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final response = jsonDecode(await client.extractionLab.getJob(started['job_id'] as String)) as Map<String, dynamic>;
      if (response['status'] == 'failed') throw StateError('$response');
      if (response['status'] == 'completed') {
        final payload = response['payload'] as Map<String, dynamic>;
        if (payload['result']['status'] == 'failed' || (!live && payload['metrics']['rooms']['f1'] != 1)) throw StateError('Unexpected demo result');
        print('Serverpod → Python → ${live ? 'live Databricks VLM' : 'recorded demo'} extraction passed. Synthetic room F1: ${payload['metrics']['rooms']['f1']}; graph nodes: ${(payload['graph']['nodes'] as List).length}');
        print('Candidate valid: ${payload['result']['validation']['candidate_valid']}; review issues: ${payload['result']['validation']['issues']}');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    throw StateError('Demo job timed out');
  } finally {
    client.close();
  }
}
