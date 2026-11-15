"""Canonical rendering. Models must return coordinates in this rendered frame."""

import hashlib
from pathlib import Path

import pymupdf
from PIL import Image, ImageOps


def preprocess(input_path, output_dir, *, page=0, dpi=200):
    path, output = Path(input_path), Path(output_dir)
    if page < 0 or dpi <= 0:
        raise ValueError("page must be nonnegative and dpi positive")
    output.mkdir(parents=True, exist_ok=False)
    target = output / "plan.png"
    pdf_rect = None
    if path.suffix.lower() == ".pdf":
        with pymupdf.open(path) as doc:
            if page >= len(doc):
                raise ValueError(
                    f"PDF has {len(doc)} pages; requested zero-based page {page}"
                )
            selected = doc[page]
            pdf_rect = list(selected.rect)
            selected.get_pixmap(dpi=dpi, alpha=False).save(str(target))
    else:
        if page != 0:
            raise ValueError("page selection is only supported for PDFs")
        with Image.open(path) as source:
            ImageOps.exif_transpose(source).convert("RGB").save(target)
    with Image.open(target) as image:
        width, height = image.size
    return {
        "source": str(path),
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "image": str(target),
        "image_sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "width": width,
        "height": height,
        "page": page,
        "dpi": dpi,
        "pdf_page_rect_points": pdf_rect,
        "coordinate_origin": "top-left",
        "coordinate_units": "pixels",
        "frame": "EXIF-oriented image or rendered PDF page; no resize or crop",
        "model_to_canonical": {
            "scale_x": 1,
            "scale_y": 1,
            "offset_x": 0,
            "offset_y": 0,
        },
    }
