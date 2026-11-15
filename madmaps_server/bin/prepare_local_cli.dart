import 'dart:convert';
import 'dart:io';

/// Copies the installed CLI into ignored project tooling and applies one
/// Windows-only VM-service workaround. Never changes Pub cache or Flutter SDK.
Future<void> main() async {
  final cache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['LOCALAPPDATA']}/Pub/Cache';
  final configFile = File(
    '$cache/global_packages/serverpod_cli/.dart_tool/package_config.json',
  );
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final packages = config['packages'] as List;
  final cli = packages.cast<Map<String, dynamic>>().singleWhere(
    (p) => p['name'] == 'serverpod_cli',
  );
  final source = Directory.fromUri(
    configFile.uri.resolve(cli['rootUri'] as String),
  );
  final target = Directory('../.dart_tool/toolchains/serverpod_cli').absolute;
  if (!target.existsSync()) {
    await target.create(recursive: true);
    for (final entry in source.listSync(recursive: true)) {
      final relative = entry.path
          .substring(source.path.length)
          .replaceFirst(RegExp(r'^[/\\]'), '');
      final destination = '${target.path}/$relative';
      if (entry is Directory)
        await Directory(destination).create(recursive: true);
      if (entry is File) {
        await File(destination).parent.create(recursive: true);
        await entry.copy(destination);
      }
    }
  }
  final processFile = File(
    '${target.path}/lib/src/commands/start/server_process.dart',
  );
  final sourceCode = await processFile.readAsString();
  const original = 'final args = <String>[];';
  const patched =
      "final args = <String>[if (Platform.isWindows) '--disable-experimental-vm-service'];";
  if (!sourceCode.contains(original) && !sourceCode.contains(patched))
    throw StateError('CLI changed; review the VM-service workaround.');
  await processFile.writeAsString(sourceCode.replaceFirst(original, patched));
  for (final package in packages.cast<Map<String, dynamic>>()) {
    package['rootUri'] = package['name'] == 'serverpod_cli'
        ? target.uri.toString()
        : configFile.uri.resolve(package['rootUri'] as String).toString();
  }
  final localConfig = File('${target.path}/.dart_tool/package_config.json');
  await localConfig.parent.create(recursive: true);
  await localConfig.writeAsString(jsonEncode(config));
  final kernel = File('${target.path}/bin/local_cli.dill');
  if (!kernel.existsSync() || sourceCode.contains(original)) {
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      '--packages=${localConfig.path}',
      '${target.path}/bin/serverpod_cli.dart',
      '-o',
      kernel.path,
    ]);
    if (result.exitCode != 0)
      throw StateError('${result.stdout}\n${result.stderr}');
  }
  stdout.writeln(
    'Project-local Serverpod CLI prepared (legacy Windows VM service).',
  );
}
