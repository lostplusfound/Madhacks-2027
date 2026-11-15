"""Start the local rooms-and-amenities app, recovering Docker/database startup."""

import os
import re
import socket
import subprocess
import time
from pathlib import Path
from urllib.parse import urlparse

import yaml

ROOT = Path(__file__).resolve().parents[3]
SERVER = ROOT / "madmaps_server"
FLUTTER = ROOT / "madmaps_flutter"
RUNTIME = Path(__file__).resolve().parent / "datasets/runtime"


def listening(url):
    address = urlparse(url)
    try:
        with socket.create_connection((address.hostname, address.port), timeout=1):
            return True
    except OSError:
        return False


def wait_until(check, description, seconds=60):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if check():
            return
        time.sleep(1)
    raise RuntimeError(
        f"Timed out waiting for {description}; see {RUNTIME / 'startup.log'}"
    )


def docker_ready():
    return (
        subprocess.run(
            ["docker", "info"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
            check=False,
        ).returncode
        == 0
    )


def main():
    RUNTIME.mkdir(parents=True, exist_ok=True)
    status = subprocess.run(
        ["serverpod", "runner", "status"],
        cwd=SERVER,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    match = re.search(r"API:\s+(http\S+)", status)
    api = match.group(1).rstrip("/") + "/" if match else "http://localhost:8080/"
    with (RUNTIME / "startup.log").open("a") as log:
        if not listening(api):
            print("Preparing Docker and the project databases...", flush=True)
            if not docker_ready():
                subprocess.run(["open", "-a", "Docker"], check=True)
                wait_until(docker_ready, "Docker Desktop")
            # Read existing credentials directly into the child environment;
            # never print them, change them, or put them in command arguments.
            passwords = yaml.safe_load((SERVER / "config/passwords.yaml").read_text())
            environment = dict(os.environ)
            for mode, variable in (
                ("development", "MADMAPS_DATABASE_PASSWORD"),
                ("test", "MADMAPS_TEST_DATABASE_PASSWORD"),
            ):
                value = passwords.get(mode, {}).get("database")
                if not isinstance(value, str) or not value:
                    raise RuntimeError(
                        f"Missing existing database configuration for {mode}"
                    )
                environment[variable] = value
            subprocess.run(
                ["docker", "compose", "--progress", "quiet", "up", "--detach"],
                cwd=SERVER,
                env=environment,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=True,
            )
            if not status.startswith("Running"):
                subprocess.run(
                    ["serverpod", "runner", "start", "--no-docker", "--no-flutter"],
                    cwd=SERVER,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    check=True,
                )
            wait_until(lambda: listening(api), "Serverpod")
        print("Seeding/verifying the bundled floor maps...", flush=True)
        subprocess.run(
            ["dart", "run", "bin/seed_all_floors.dart"],
            cwd=SERVER,
            stdout=log,
            stderr=subprocess.STDOUT,
            check=True,
        )
        web = "http://localhost:8082/"
        if not listening(web):
            print("Launching MadMaps in Chrome...", flush=True)
            process = subprocess.Popen(
                [
                    "flutter",
                    "run",
                    "-d",
                    "chrome",
                    "--target",
                    "lib/driver.dart",
                    "--web-port",
                    "8082",
                    f"--dart-define=SERVERPOD_API_URL={api}",
                ],
                cwd=FLUTTER,
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            (RUNTIME / "flutter.pid").write_text(str(process.pid))
            wait_until(lambda: listening(web), "the Flutter app")
        else:
            subprocess.run(["open", "-a", "Google Chrome", web], check=True)
    print(f"App ready: {web}", flush=True)
    print("Open Profile > Rooms & amenities.", flush=True)


if __name__ == "__main__":
    main()
