$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$postgresRoot = Join-Path $workspace '.dart_tool/toolchains/postgres16'
$postgresBinary = Join-Path $postgresRoot 'pgsql/bin/postgres.exe'
if (-not (Test-Path -LiteralPath $postgresBinary)) {
    $archive = Join-Path $workspace '.dart_tool/toolchains/postgres.zip'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archive) | Out-Null
    Write-Host 'Downloading portable PostgreSQL 16 from EDB...'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri 'https://get.enterprisedb.com/postgresql/postgresql-16.16-1-windows-x64-binaries.zip' -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $postgresRoot -Force
}
Push-Location (Join-Path $workspace 'madmaps_server')
$localCli = Join-Path $workspace '.dart_tool/toolchains/serverpod_cli/bin/local_cli.dill'
try {
    dart pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    Write-Host 'Starting project-local PostgreSQL...'
    dart bin/local_postgres.dart
    if ($LASTEXITCODE -ne 0) { throw 'Local PostgreSQL startup failed.' }
    dart bin/prepare_local_cli.dart
    if ($LASTEXITCODE -ne 0) { throw 'Local Serverpod CLI preparation failed.' }
    dart $localCli --no-analytics runner start --no-docker --no-flutter
    if ($LASTEXITCODE -ne 0) { throw 'Serverpod runner startup failed.' }
    dart run bin/seed_all_floors.dart
    if ($LASTEXITCODE -ne 0) { throw 'Floor seed verification failed.' }
    Write-Host 'Backend ready. Streaming logs; launch Flutter separately on your phone.'
    Write-Host 'Ctrl+C stops the backend and both project-local databases.'
    # Keep log following in PowerShell so Ctrl+C reaches this script's finally.
    Get-Content -LiteralPath '.dart_tool/serverpod/runner.log' -Tail 60 -Wait
} finally {
    try {
        Write-Host 'Stopping MadMaps backend...'
        if (Test-Path -LiteralPath $localCli) {
            dart $localCli --no-analytics runner stop
        }
        $pgCtl = Join-Path $postgresRoot 'pgsql/bin/pg_ctl.exe'
        if (Test-Path -LiteralPath $pgCtl) {
            foreach ($databaseMode in @('development', 'test')) {
                $dataDirectory = Join-Path $workspace "madmaps_server/.serverpod/local-postgres/$databaseMode"
                if (Test-Path -LiteralPath (Join-Path $dataDirectory 'PG_VERSION')) {
                    & $pgCtl -D $dataDirectory status *> $null
                    if ($LASTEXITCODE -eq 0) {
                        & $pgCtl -D $dataDirectory -m fast -w stop
                    }
                }
            }
        }
    } finally {
        Pop-Location
    }
}
