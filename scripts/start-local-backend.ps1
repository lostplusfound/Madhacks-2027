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
try {
    dart pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    dart run bin/local_postgres.dart
    if ($LASTEXITCODE -ne 0) { throw 'Local PostgreSQL startup failed.' }
    dart run bin/prepare_local_cli.dart
    if ($LASTEXITCODE -ne 0) { throw 'Local Serverpod CLI preparation failed.' }
    $localCli = Join-Path $workspace '.dart_tool/toolchains/serverpod_cli/bin/local_cli.dill'
    dart $localCli --no-analytics runner start --no-docker
    if ($LASTEXITCODE -ne 0) { throw 'Serverpod runner startup failed.' }
    dart run bin/seed_floor1.dart
    if ($LASTEXITCODE -ne 0) { throw 'Floor 1 seed verification failed.' }
} finally {
    Pop-Location
}
