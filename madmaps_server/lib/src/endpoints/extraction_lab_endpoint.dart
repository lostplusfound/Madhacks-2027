import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:serverpod/serverpod.dart';

/// Development-only bridge. The application backend remains Serverpod;
/// Python is an isolated worker and never exposes an HTTP service.
class ExtractionLabEndpoint extends Endpoint {
  static final _jobs = <String, _LabJob>{};
  static final _random = Random.secure();

  Directory get _root => Directory(
    Platform.environment['MADMAPS_EXTRACTION_ROOT'] ?? '../map_extraction/src',
  ).absolute;

  String get _python =>
      Platform.environment['MADMAPS_PYTHON'] ??
      '${_root.path}/.venv/${Platform.isWindows ? 'Scripts/python.exe' : 'bin/python'}';

  String? _setting(String name, String environment) {
    final fromEnvironment = Platform.environment[environment];
    if (fromEnvironment != null && fromEnvironment.isNotEmpty)
      return fromEnvironment;
    final file = File('${_root.path}/lab.local.json');
    if (!file.existsSync()) return null;
    final local = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return local[name] as String?;
  }

  void _guard(Session session) {
    if (session.serverpod.runMode != ServerpodRunMode.development) {
      throw StateError('The extraction lab is available in development only.');
    }
  }

  Future<String> capabilities(Session session) async {
    final enabled = session.serverpod.runMode == ServerpodRunMode.development;
    return jsonEncode({
      'enabled': enabled,
      'worker_ready':
          enabled &&
          File(_python).existsSync() &&
          File('${_root.path}/examples/plan.png').existsSync(),
      'live_ready':
          enabled &&
          (_setting('endpoint', 'MADMAPS_VLM_ENDPOINT')?.isNotEmpty ?? false),
      'training_ready':
          enabled &&
          (_setting('training_job_id', 'MADMAPS_TRAINING_JOB_ID')?.isNotEmpty ??
              false),
      'endpoint': enabled ? _setting('endpoint', 'MADMAPS_VLM_ENDPOINT') : null,
    });
  }

  Future<String> start(Session session, String requestJson) async {
    _guard(session);
    if (utf8.encode(requestJson).length > 12 * 1024 * 1024) {
      throw ArgumentError(
        'Request exceeds 12 MB. Upload an image of at most 8 MB.',
      );
    }
    final request = jsonDecode(requestJson) as Map<String, dynamic>;
    final action = request['action'] ?? 'extract';
    if (!{
      'extract',
      'benchmark',
      'review',
      'export',
      'train',
    }.contains(action)) {
      throw ArgumentError('Unknown lab action.');
    }
    if (_jobs.values.any((j) => !j.done)) {
      throw StateError('A lab job is already running. Wait for it to finish.');
    }
    if (_jobs.length >= 64) {
      final expired = _jobs.entries.where((e) => e.value.done).firstOrNull;
      if (expired != null) _jobs.remove(expired.key);
    }
    // Never pass browser-supplied paths or environment overrides to the worker.
    request.remove('previous_result');
    if (action == 'review') {
      final previous = _jobs[request.remove('source_job_id')];
      if (previous == null || !previous.done) {
        throw ArgumentError('Run an extraction before saving a correction.');
      }
      request['previous_result'] = '${previous.directory.path}/payload.json';
    }
    final id = List.generate(
      24,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final directory = Directory('${_root.path}/runs/workbench/$id');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/request.json',
    ).writeAsString(jsonEncode(request));
    final process = await Process.start(
      _python,
      [
        '-m',
        'madmaps_extraction.workbench',
        '--request',
        '${directory.path}/request.json',
      ],
      workingDirectory: _root.path,
      runInShell: false,
    );
    final job = _LabJob(directory);
    _jobs[id] = job;
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    unawaited(_monitor(process, job));
    return jsonEncode({'job_id': id});
  }

  static Future<void> _monitor(Process process, _LabJob job) async {
    try {
      final exit = await process.exitCode.timeout(const Duration(minutes: 20));
      if (exit != 0 ||
          !File('${job.directory.path}/response.json').existsSync()) {
        job.error =
            'Worker exited without a result. Check the Python environment.';
      }
    } on TimeoutException {
      process.kill();
      job.error = 'Worker timed out after 20 minutes.';
    } finally {
      job.done = true;
    }
  }

  Future<String> getJob(Session session, String jobId) async {
    _guard(session);
    final job = _jobs[jobId];
    if (job == null) throw ArgumentError('Unknown or expired job.');
    if (!job.done) return jsonEncode({'status': 'running'});
    if (job.error != null)
      return jsonEncode({'status': 'failed', 'error': job.error});
    final response =
        jsonDecode(
              await File('${job.directory.path}/response.json').readAsString(),
            )
            as Map<String, dynamic>;
    if (response['payload'] != null) {
      await File(
        '${job.directory.path}/payload.json',
      ).writeAsString(jsonEncode(response['payload']));
    }
    return jsonEncode(response);
  }
}

class _LabJob {
  _LabJob(this.directory);
  final Directory directory;
  bool done = false;
  String? error;
}
