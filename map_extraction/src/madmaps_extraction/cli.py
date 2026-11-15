import argparse
import json
from pathlib import Path

from .benchmark import benchmark
from .contract import load_json
from .pipeline import run
from .storage import persist


def main():
    parser = argparse.ArgumentParser(description="MadMaps extraction and benchmarks")
    sub = parser.add_subparsers(dest="command", required=True)
    extraction = sub.add_parser("run")
    extraction.add_argument("--config", required=True)
    evaluation = sub.add_parser("benchmark")
    evaluation.add_argument("--manifest", required=True)
    evaluation.add_argument("--output", required=True)
    evaluation.add_argument("--repeats", type=int, default=1)
    for command in (extraction, evaluation):
        command.add_argument(
            "--endpoint",
            help="Override adapter with Databricks custom serving endpoint",
        )
        command.add_argument(
            "--model-revision",
            help="Declared immutable served-model version for provenance",
        )
        command.add_argument("--api-format", choices=["custom", "chat"])
        command.add_argument("--profile", help="Databricks CLI authentication profile")
        command.add_argument("--host", help="Databricks workspace API URL")
        command.add_argument(
            "--delta-table",
            help="Optional catalog.schema.table for append-only history",
        )
    args = parser.parse_args()
    override = (
        {"adapter": "databricks", "endpoint": args.endpoint} if args.endpoint else {}
    )
    if args.model_revision:
        override["model_revision"] = args.model_revision
    for key in ("api_format", "profile", "host"):
        if getattr(args, key) is not None:
            override[key] = getattr(args, key)
    if args.command == "run":
        path = Path(args.config).resolve()
        config = load_json(path)
        for key in ("input", "recorded_output", "output_dir"):
            if key in config:
                config[key] = str((path.parent / config[key]).resolve())
        config.update(override)
        result = run(config)
        # Delta receives the source/normalized artifacts as well as run metadata.
        payload = {"result": result}
        for name in (
            "metadata",
            "raw_response",
            "extraction",
            "graph_candidate",
            "validation",
        ):
            artifact = Path(result["artifact_dir"]) / f"{name}.json"
            if artifact.exists():
                payload[name] = load_json(artifact)
        if args.delta_table:
            persist(payload, args.delta_table, record_type="extraction")
        print(json.dumps(result, indent=2))
        if result["status"] == "failed":
            raise SystemExit(1)
    else:
        report = benchmark(
            args.manifest, args.output, repeats=args.repeats, overrides=override
        )
        if args.delta_table:
            persist(report, args.delta_table, record_type="benchmark")
        print(json.dumps(report["summary"], indent=2))
        if report["summary"]["failures"]:
            raise SystemExit(1)


if __name__ == "__main__":
    main()
