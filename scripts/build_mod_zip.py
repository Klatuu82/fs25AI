#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def build_zip(source_dir: Path, output_path: Path) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with ZipFile(output_path, "w", compression=ZIP_DEFLATED) as archive:
        for path in sorted(source_dir.rglob("*")):
            if path.is_dir() or any(part.startswith(".") for part in path.relative_to(source_dir).parts):
                continue
            archive.write(path, arcname=path.relative_to(source_dir))

    return output_path
def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    source_dir = repo_root / "mod"
    output_path = repo_root / "dist" / "fs25AI-mod.zip"
    build_zip(source_dir, output_path)
    print(f"Built {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
