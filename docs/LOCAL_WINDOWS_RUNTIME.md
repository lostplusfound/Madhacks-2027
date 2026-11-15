# Local Windows backend

The frontend address is the `serverUrl` getter in `madmaps_flutter/lib/client.dart`.
Edit it and hot reload to reconnect. The JSON config asset and SERVER_URL
build override are removed. See [navigation/capture](ALL_FLOOR_NAVIGATION.md).

From the repository root, start the complete local backend with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-local-backend.ps1
```

The script downloads the [EDB Windows PostgreSQL binaries](https://productsdl.enterprisedb.com/download-postgresql-binaries)
into ignored `.dart_tool/toolchains` if absent, starts project-local development
and test databases, starts the Serverpod runner with Docker disabled, and seeds
or verifies basement and floors 1?3 without overwriting edits, then streams backend logs in the same terminal. It disables
automatic Flutter launch; launch the phone app separately. Keep this terminal
open while testing. Ctrl+C stops the Serverpod runner and both project-local
databases, including on startup failure. Use Ctrl+C for a clean shutdown.
Repeated invocations reuse the databases and runner. It never installs a system
service. The x64 PostgreSQL binaries run on this Windows ARM64 laptop.

Database clusters live in `madmaps_server/.serverpod/local-postgres/`, listen only
on `127.0.0.1`, and use passwords from ignored `config/passwords.yaml`:

| Environment | Port | Database |
| --- | --- | --- |
| Development | 8090 | madmaps |
| Test | 9090 | madmaps_test |

These ports also match Docker Compose, so Docker remains an alternative. The
development/test configs use external PostgreSQL rather than `database.dataPath`,
because the embedded database is unavailable on Windows ARM64. Start the databases
before running `dart test` in `madmaps_server`.

The installed Dart 3.14.0 SDK lacks the experimental JIT VM-service snapshot.
The launcher copies the installed Serverpod CLI into ignored project tooling and
adds `--disable-experimental-vm-service` to its Windows server subprocess. It
compiles this local copy to a kernel file to avoid startup timeouts. The global
Pub cache and Flutter SDK are unchanged. This retains the runner's watch/reload
support through the legacy VM service. Use this launcher on this machine rather
than the unmodified global CLI to start a stopped runner.

Logs are already streamed by the launcher using PowerShell's
`Get-Content -Tail 60 -Wait` on `madmaps_server/.dart_tool/serverpod/runner.log`.
Do not run a separate `serverpod start` just to see logs. The launcher passes
`--no-flutter` so attaching cannot auto-launch the companion app.

To launch the phone app separately, with the phone connected over USB:

```powershell
cd madmaps_flutter
flutter run -d <phone-device-id> -t lib/driver.dart
```

The laptop IP must remain `10.138.33.209`; update the config asset or provide
`SERVER_URL` if the network assigns a different address. Phone Wi-Fi access also
requires Windows Firewall to allow TCP 8080 and the Wi-Fi network to permit
device-to-device connections. The phone never needs access to PostgreSQL ports.

## Startup progress and troubleshooting

Expected sequence: dependency resolution, `Starting project-local PostgreSQL`,
per-environment checking/starting/ready messages, local CLI preparation, runner
readiness, seed verification, then continuous log output. Package-update notices
from pub are informational. First-time PostgreSQL download and local CLI kernel
compilation can take longer than subsequent starts.

The PostgreSQL helper launches pg_ctl directly, closes its stdin, and waits for
its exit code with a bounded timeout. It does not await EOF on pipes inherited by
PostgreSQL or launch it through a detached PowerShell wrapper. Those earlier
approaches caused silent waits/failures on this machine. The launcher invokes
this helper directly with dart to avoid unrelated workspace build-hook work.

If startup fails, read the first error above the launcher's generic failure:

| Symptom | Check |
| --- | --- |
| PostgreSQL fails to start | `.serverpod/local-postgres/development.postgres.log` or `test.postgres.log` inside madmaps_server; check port conflicts on 8090/9090 |
| Password authentication fails | Existing cluster password must match config/passwords.yaml; changing the file does not change an initialized database role |
| Missing experimental VM-service snapshot | Start through this launcher, which prepares the local CLI workaround; do not alter the global SDK |
| Seed verification differs | An existing graph was edited; coordinate an explicit update rather than deleting data or forcing replacement |
| Phone cannot connect | Check laptop IP, port 8080, Wi-Fi isolation and firewall; localhost on the phone refers to the phone |
| App still shows places after shutdown | Loaded graph and successful searches are retained in memory; this is not proof that the API is running |

Credentials, database clusters, downloaded tools and runtime logs are ignored by
Git. Ctrl+C stops services without deleting database contents, saved anchors or
preferences. Use one launcher terminal at a time; it takes responsibility for
both project-local databases even if they were already running.

If a terminal is force-killed, its finally block may not execute. For manual
cleanup, from the repository root:

```powershell
cd madmaps_server
dart ../.dart_tool/toolchains/serverpod_cli/bin/local_cli.dill --no-analytics runner stop
& ../.dart_tool/toolchains/postgres16/pgsql/bin/pg_ctl.exe -D .serverpod/local-postgres/development -m fast -w stop
& ../.dart_tool/toolchains/postgres16/pgsql/bin/pg_ctl.exe -D .serverpod/local-postgres/test -m fast -w stop
```

Do not delete the data directories to fix a startup failure. A working LAN client
request was verified on the laptop; actual phone Wi-Fi access and the latest
complete Ctrl+C path remain user acceptance checks. The earlier script cleanup
was observed stopping the runner and both databases after an interrupted startup.

## Build memory and November 14 crash investigation

Android builds now use a 2 GB Gradle heap, 1 GB maximum metaspace, two workers,
and in-process Kotlin compilation. Previously Gradle allowed an 8 GB heap plus
4 GB metaspace on this 16 GB laptop. Run builds and test suites sequentially.
These limits reduce build pressure; they do not establish a Windows driver fix.

Two reboot events on November 14 recorded bugcheck 0xD1
(DRIVER_IRQL_NOT_LESS_OR_EQUAL), with dump files
`C:\Windows\Minidump\111426-12140-01.dmp` and
`C:\Windows\Minidump\111426-11578-01.dmp`. The current non-elevated session
cannot read the protected dumps. No responsible driver has been identified and
no drivers or Windows security settings were changed.

To continue diagnosis, open those dumps locally in WinDbg with administrator
access, configure Microsoft symbols, and run `!analyze -v` and `kv` on both.
Compare the faulting modules and stacks, then use the implicated driver's vendor
update or rollback path. Keep dumps local; they can contain private memory data.
Do not infer the culprit from the stop code, VPN presence, or memory use alone.

Reference: [Microsoft bugcheck 0xD1 documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/bug-check-0xd1--driver-irql-not-less-or-equal).
