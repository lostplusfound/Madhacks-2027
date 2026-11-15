import 'dart:io';
import 'package:yaml/yaml.dart';

/// Starts project-local PostgreSQL on Windows, including ARM64 via x64 emulation.
/// Run from madmaps_server after scripts/start-local-backend.ps1 downloads it.
Future<void> main() async {
  final binaryRoot = Directory(
    '../.dart_tool/toolchains/postgres16/pgsql/bin',
  ).absolute.path;
  final passwords =
      loadYaml(await File('config/passwords.yaml').readAsString()) as YamlMap;
  for (final entry in {'development': 8090, 'test': 9090}.entries) {
    final password = passwords[entry.key]?['database'] as String?;
    if (password == null || password.isEmpty)
      throw StateError(
        'Missing ${entry.key}.database password in config/passwords.yaml.',
      );
    final data = Directory('.serverpod/local-postgres/${entry.key}').absolute;
    await data.create(recursive: true);
    Future<ProcessResult> run(String program, List<String> arguments) =>
        Process.run('$binaryRoot/$program.exe', arguments);
    void requireSuccess(ProcessResult result) {
      if (result.exitCode != 0)
        throw StateError('${result.stdout}\n${result.stderr}');
    }

    if (!File('${data.path}/PG_VERSION').existsSync()) {
      final passwordFile = File('${data.path}.init-password.tmp');
      try {
        await passwordFile.writeAsString(password);
        requireSuccess(
          await run('initdb', [
            '-D',
            data.path,
            '-U',
            'postgres',
            '--encoding=UTF8',
            '--locale=C',
            '--auth=scram-sha-256',
            '--pwfile=${passwordFile.path}',
          ]),
        );
      } finally {
        if (passwordFile.existsSync()) await passwordFile.delete();
      }
      await File('${data.path}/postgresql.conf').writeAsString(
        "\nlisten_addresses = '127.0.0.1'\nport = ${entry.value}\n",
        mode: FileMode.append,
      );
    }
    if ((await run('pg_ctl', ['-D', data.path, 'status'])).exitCode != 0) {
      // Detach fully: PostgreSQL otherwise inherits Dart's process pipes on Windows.
      String psQuote(String text) => "'${text.replaceAll("'", "''")}'";
      final start = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        'Start-Process -FilePath ${psQuote('$binaryRoot/pg_ctl.exe')} -ArgumentList ${psQuote('-D "${data.path}" -l "${data.path}.postgres.log" -w start')} -WindowStyle Hidden -RedirectStandardOutput ${psQuote('${data.path}.startup.stdout.log')} -RedirectStandardError ${psQuote('${data.path}.startup.stderr.log')}',
      ]);
      requireSuccess(start);
      var ready = false;
      for (var attempt = 0; attempt < 100; attempt++) {
        if ((await run('pg_isready', [
              '-h',
              '127.0.0.1',
              '-p',
              '${entry.value}',
            ])).exitCode ==
            0) {
          ready = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (!ready)
        throw StateError(
          'PostgreSQL did not start. Check ${data.path}.postgres.log.',
        );
    }
    final environment = {...Platform.environment, 'PGPASSWORD': password};
    Future<ProcessResult> sql(String statement) =>
        Process.run('$binaryRoot/psql.exe', [
          '-h',
          '127.0.0.1',
          '-p',
          '${entry.value}',
          '-U',
          'postgres',
          '-d',
          'postgres',
          '-v',
          'ON_ERROR_STOP=1',
          '-tAc',
          statement,
        ], environment: environment);
    final databaseName = entry.key == 'test' ? 'madmaps_test' : 'madmaps';
    final exists = await sql(
      "SELECT 1 FROM pg_database WHERE datname = '$databaseName'",
    );
    requireSuccess(exists);
    if (exists.stdout.toString().trim() != '1')
      requireSuccess(await sql('CREATE DATABASE $databaseName'));
    stdout.writeln(
      'PostgreSQL ${entry.key}: 127.0.0.1:${entry.value}/$databaseName ready',
    );
  }
}
