# Local Windows backend

The frontend defaults to `http://10.138.33.209:8080/` in its config asset.
`--dart-define=SERVER_URL=...` still overrides it. Restart Flutter after changing
the address; hot reload does not rerun client initialization.

From the repository root, start the complete local backend with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-local-backend.ps1
```

The script downloads the [EDB Windows PostgreSQL binaries](https://productsdl.enterprisedb.com/download-postgresql-binaries)
into ignored `.dart_tool/toolchains` if absent, starts project-local development
and test databases, starts the Serverpod runner with Docker disabled, and seeds
or verifies Floor 1, then streams backend logs in the same terminal. It disables
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

To attach, run `serverpod start` from `madmaps_server` if the CLI is on PATH, or
use `dart ../.dart_tool/toolchains/serverpod_cli/bin/local_cli.dill start`.

To launch the phone app separately, with the phone connected over USB:

```powershell
cd madmaps_flutter
flutter run -d <phone-device-id> -t lib/driver.dart
```

The laptop IP must remain `10.138.33.209`; update the config asset or provide
`SERVER_URL` if the network assigns a different address. Phone Wi-Fi access also
requires Windows Firewall to allow TCP 8080 and the Wi-Fi network to permit
device-to-device connections. The phone never needs access to PostgreSQL ports.
