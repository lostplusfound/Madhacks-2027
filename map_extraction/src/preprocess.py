"""Compatibility command: python preprocess.py plan.pdf [--page 0 --output DIR]."""

import argparse
import json
from pathlib import Path
from uuid import uuid4

from madmaps_extraction.preprocess import preprocess

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--page", type=int, default=0)
    parser.add_argument("--dpi", type=int, default=200)
    parser.add_argument("--output", default=f"runs/{uuid4().hex}")
    args = parser.parse_args()
    metadata = preprocess(args.input, args.output, page=args.page, dpi=args.dpi)
    Path(args.output, "metadata.json").write_text(json.dumps(metadata, indent=2))
    print(json.dumps(metadata, indent=2))
