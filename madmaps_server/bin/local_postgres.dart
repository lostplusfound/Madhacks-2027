import 'dart:io';
import 'dart:convert';
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
    stdout.writeln(
      'Checking PostgreSQL ${entry.key} on port ${entry.value}...',
    );
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
      stdout.writeln('Starting PostgreSQL ${entry.key}...');
      // Wait for pg_ctl itself, not EOF on pipes inherited by the server.
      final launch = await Process.start('$binaryRoot/pg_ctl.exe', [
        '-D',
        data.path,
        '-l',
        '${data.path}.postgres.log',
        '-w',
        '-t',
        '30',
        'start',
      ]);
      final output = StringBuffer();
      final outSub = launch.stdout.transform(utf8.decoder).listen(output.write);
      final errSub = launch.stderr.transform(utf8.decoder).listen(output.write);
      await launch.stdin.close();
      try {
        final code = await launch.exitCode.timeout(const Duration(seconds: 40));
        if (code != 0)
          throw StateError(
            'PostgreSQL ${entry.key} failed: $output\nSee ${data.path}.postgres.log',
          );
      } finally {
        await outSub.cancel();
        await errSub.cancel();
      }
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
