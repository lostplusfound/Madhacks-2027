"""Upload a verified public subset and current training source to a UC Volume."""

import argparse
import hashlib
import io
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from databricks.sdk import WorkspaceClient
from databricks.sdk.config import Config

from public_dataset import sha256, validate_subset, write_json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--profile", default="madmaps")
    parser.add_argument("--volume-directory", required=True)
    args = parser.parse_args()
    root = Path(args.dataset).resolve()
    remote = args.volume_directory.rstrip("/")
    if not remote.startswith("/Volumes/") or ".." in remote.split("/"):
        parser.error("Use an absolute Unity Catalog Volume directory")
    report = validate_subset(root)
    manifest = json.loads((root / "manifest.json").read_text())
    source_root = Path(__file__).resolve().parents[1]
    # Include current trainer changes; no local settings, credentials or run history.
    with ZipFile(root / "madmaps-training-source.zip", "w", ZIP_DEFLATED) as archive:
        for path in [
            source_root / "pyproject.toml",
            *sorted((source_root / "madmaps_extraction").glob("*.py")),
            *sorted((source_root / "madmaps_extraction").glob("*.json")),
        ]:
            archive.write(path, path.relative_to(source_root))
    client = WorkspaceClient(config=Config(profile=args.profile))
    paths = [
        root / name
        for name in (
            "manifest.json",
            "provenance.json",
            "zenodo-record.json",
            "LICENSE-NOTICE.txt",
            "validation.json",
            "rejections.json",
            "preview.jpg",
            "converter-source.py",
            "madmaps-public-dataset.zip",
            "madmaps-training-source.zip",
        )
    ]
    paths.extend(sorted((root / "source_splits").glob("*.txt")))
    for row in manifest["examples"]:
        paths.extend(
            root / row[key]
            for key in ("image", "target", "source_annotation", "overlay")
        )
        paths.append((root / row["target"]).parent / "conversion.json")
    directories = {remote, remote + "/examples", remote + "/source_splits"}
    client.files.create_directory(remote)
    for directory in sorted(directories - {remote}):
        client.files.create_directory(directory)
    sample_directories = sorted(
        {str(path.parent.relative_to(root)) for path in paths if path.parent != root}
        - {"source_splits"}
    )
    with ThreadPoolExecutor(max_workers=8) as pool:
        list(
            pool.map(
                lambda directory: client.files.create_directory(
                    remote + "/" + directory
                ),
                sample_directories,
            )
        )

        def upload(path):
            destination = remote + "/" + path.relative_to(root).as_posix()
            with path.open("rb") as source:
                client.files.upload(destination, source, overwrite=False)
            metadata = client.files.get_metadata(destination)
            if metadata.content_length != path.stat().st_size:
                raise ValueError("Remote dataset file size mismatch")
            return path.stat().st_size

        uploaded_sizes = list(pool.map(upload, paths))
    # Verify the complete portable artifact after upload, not only its file size.
    artifact_path = remote + "/madmaps-public-dataset.zip"
    response = client.files.download(artifact_path)
    with response.contents as stream:
        remote_zip = stream.read()
    artifact_sha = sha256((root / "madmaps-public-dataset.zip").read_bytes())
    if sha256(remote_zip) != artifact_sha:
        raise ValueError("Remote dataset ZIP checksum mismatch")
    with ZipFile(io.BytesIO(remote_zip)) as archive:
        if archive.testzip() is not None:
            raise ValueError("Remote dataset ZIP member failed CRC verification")
        if archive.read("manifest.json") != (root / "manifest.json").read_bytes():
            raise ValueError(
                "Remote dataset manifest differs from the validated source"
            )
    report.update(
        volume_directory=remote,
        manifest_path=remote + "/manifest.json",
        uploaded_files=len(paths),
        uploaded_bytes=sum(uploaded_sizes),
        remote_dataset_zip_sha256=artifact_sha,
        training_source_sha256=hashlib.sha256(
            (root / "madmaps-training-source.zip").read_bytes()
        ).hexdigest(),
        remote_artifact_verified=True,
        training_started=False,
    )
    write_json(root / "upload-result.json", report)
    client.files.upload(
        remote + "/upload-result.json",
        io.BytesIO((root / "upload-result.json").read_bytes()),
        overwrite=False,
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
