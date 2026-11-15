"""Compare existing hosted vision models; preserve every response and failure."""
import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from madmaps_extraction.benchmark import benchmark
from madmaps_extraction.settings import load_settings

ROOT = Path(__file__).resolve().parents[1]
# The Databricks Qwen3.5 endpoint currently accepts text only.
MODELS = ['databricks-llama-4-maverick', 'databricks-gemma-3-12b']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    settings = load_settings(ROOT)
    manifests = [ROOT / 'examples/manifest.json', ROOT / 'examples/amenities-manifest.json']
    rows = []
    for model in MODELS:
        for manifest in manifests:
            print(f'Testing {model}: {manifest.name}', flush=True)
            overrides = {key: settings[key] for key in ('host', 'profile') if settings.get(key)}
            overrides.update(adapter='databricks', endpoint=model, api_format='chat', max_attempts=1, timeout_s=60)
            report = benchmark(manifest, output / model / manifest.stem, overrides=overrides)
            rows.append({'model': model, 'dataset': manifest.stem, 'summary': report['summary'],
                         'failures': [r['run'].get('error') for r in report['results'] if r['run'].get('error')]})
            (output / 'comparison.json').write_text(json.dumps({
                'created_at': datetime.now(timezone.utc).isoformat(),
                'scope': 'Synthetic fixtures only; no real-world winner established',
                'repeats': 1, 'results': rows}, indent=2))
            print(json.dumps(rows[-1]), flush=True)


if __name__ == '__main__':
    main()
