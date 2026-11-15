"""Install the staged Flutter/Serverpod source files into the existing workspace.

These sibling directories are outside Codex's writable root, so this installer
must run through an approved escalated command. No generated files are edited.
"""

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
FLUTTER = REPO / "madmaps_flutter"
SERVER = REPO / "madmaps_server"


def main():
    main_path = FLUTTER / "lib/main.dart"
    text = main_path.read_text()
    if "import 'screens/extraction_lab_screen.dart';" not in text:
        expected = "home: const MyHomePage(title: 'MadMaps — connection check'),"
        if expected not in text:
            raise RuntimeError(
                "main.dart changed; integrate the screen manually before installing"
            )
        text = text.replace(
            "import 'screens/greetings_screen.dart';",
            "import 'screens/greetings_screen.dart';\nimport 'screens/extraction_lab_screen.dart';",
        )
        text = text.replace(
            expected,
            """home: Builder(builder: (context) => ExtractionLabScreen(
        onConnectionCheck: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const MyHomePage(title: 'MadMaps — connection check'),
        )),
      )),""",
        )
        main_path.write_text(text)
    pubspec = FLUTTER / "pubspec.yaml"
    text = pubspec.read_text()
    if "\n  file_selector:" not in text:
        text = text.replace(
            "  cupertino_icons: ^1.0.5",
            "  file_selector: ^1.1.0\n  cupertino_icons: ^1.0.5",
        )
        pubspec.write_text(text)
    config = SERVER / "config/development.yaml"
    text = config.read_text()
    import re

    text = re.sub(
        r"maxRequestSize: (\d+)",
        lambda m: f"maxRequestSize: {max(int(m[1]), 16 * 1024 * 1024)}",
        text,
    )
    config.write_text(text)
    for source in (ROOT / "frontend_staging/flutter").glob("*.dart.template"):
        shutil.copyfile(
            source, FLUTTER / "lib/screens" / source.name.removesuffix(".template")
        )
    shutil.copyfile(
        ROOT / "frontend_staging/server/extraction_lab_endpoint.dart.template",
        SERVER / "lib/src/endpoints/extraction_lab_endpoint.dart",
    )
    for source in (ROOT / "frontend_staging/tests").glob("*.dart.template"):
        shutil.copyfile(
            source, FLUTTER / "test" / source.name.removesuffix(".template")
        )
    fixtures = FLUTTER / "test/fixtures"
    fixtures.mkdir(exist_ok=True)
    shutil.copyfile(ROOT / "examples/plan.png", fixtures / "lab_plan.png")
    shutil.copyfile(ROOT / "examples/recorded.json", fixtures / "lab_extraction.json")
    print(
        "Installed extraction lab sources, tests, and fixtures. Generate the Serverpod client next."
    )


if __name__ == "__main__":
    main()
