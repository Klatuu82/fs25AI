#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ARCHIVE_PREFIX = "FS25_fs25AI"
FIXED_ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)
MOD_DESC_FILENAME = "modDesc.xml"


class PackagingError(RuntimeError):
    """Raised when the mod package cannot be built safely."""


def iter_package_files(source_dir: Path) -> list[Path]:
    files: list[Path] = []
    for path in sorted(source_dir.rglob("*")):
        relative_parts = path.relative_to(source_dir).parts
        if path.is_dir() or any(part.startswith(".") for part in relative_parts):
            continue
        files.append(path)
    return files


def load_mod_desc(mod_desc_path: Path) -> ET.Element:
    if not mod_desc_path.is_file():
        raise PackagingError(f"Missing required file: {mod_desc_path}")
    return ET.parse(mod_desc_path).getroot()


def read_version(mod_desc_root: ET.Element) -> str:
    version = (mod_desc_root.findtext("version") or "").strip()
    if not version:
        raise PackagingError("modDesc.xml is missing a <version> value")
    return version


def referenced_source_files(mod_desc_root: ET.Element) -> list[str]:
    source_files = mod_desc_root.find("extraSourceFiles")
    if source_files is None:
        return []

    referenced_files: list[str] = []
    for source_file in source_files.findall("sourceFile"):
        filename = (source_file.attrib.get("filename") or "").strip()
        if not filename:
            raise PackagingError("modDesc.xml contains a <sourceFile> without a filename")
        referenced_files.append(filename)
    return referenced_files


def required_package_entries(mod_desc_root: ET.Element) -> set[str]:
    return {MOD_DESC_FILENAME, *referenced_source_files(mod_desc_root)}


def validate_source_tree(source_dir: Path) -> tuple[str, list[Path], set[str]]:
    if not source_dir.is_dir():
        raise PackagingError(f"Missing source directory: {source_dir}")

    mod_desc_root = load_mod_desc(source_dir / MOD_DESC_FILENAME)
    version = read_version(mod_desc_root)
    files = iter_package_files(source_dir)
    archive_entries = {path.relative_to(source_dir).as_posix() for path in files}
    required_entries = required_package_entries(mod_desc_root)
    missing_entries = sorted(required_entries - archive_entries)
    if missing_entries:
        raise PackagingError(
            "Packaging validation failed. Missing required package entries: "
            + ", ".join(missing_entries)
        )

    return version, files, required_entries


def build_output_path(output_dir: Path, version: str) -> Path:
    safe_version = version.replace(".", "_")
    return output_dir / f"{ARCHIVE_PREFIX}_{safe_version}.zip"


def build_zip(source_dir: Path, output_path: Path) -> Path:
    _, files, required_entries = validate_source_tree(source_dir)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_output_path = output_path.with_suffix(f"{output_path.suffix}.tmp")

    try:
        with ZipFile(temporary_output_path, "w", compression=ZIP_DEFLATED) as archive:
            for path in files:
                archive_name = path.relative_to(source_dir).as_posix()
                archive_entry = ZipInfo(archive_name, date_time=FIXED_ZIP_TIMESTAMP)
                archive_entry.compress_type = ZIP_DEFLATED
                archive_entry.external_attr = 0o644 << 16
                archive.writestr(archive_entry, path.read_bytes())

        validate_archive(temporary_output_path, required_entries)
        temporary_output_path.replace(output_path)
        return output_path
    except Exception:
        temporary_output_path.unlink(missing_ok=True)
        raise


def validate_archive(archive_path: Path, required_entries: set[str]) -> None:
    with ZipFile(archive_path) as archive:
        archive_entries = {entry.filename for entry in archive.infolist()}

    missing_entries = sorted(required_entries - archive_entries)
    if missing_entries:
        raise PackagingError(
            "Archive validation failed. Missing required package entries: "
            + ", ".join(missing_entries)
        )


def package_mod(source_dir: Path, output_dir: Path) -> Path:
    version, _, _ = validate_source_tree(source_dir)
    output_path = build_output_path(output_dir, version)
    return build_zip(source_dir, output_path)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Build the FS25 mod zip package.")
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=repo_root / "mod",
        help="Path to the mod source directory",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=repo_root / "dist",
        help="Directory where the ZIP archive will be written",
    )
    args = parser.parse_args()

    try:
        output_path = package_mod(args.source_dir.resolve(), args.output_dir.resolve())
    except PackagingError as error:
        print(f"Packaging failed: {error}", file=sys.stderr)
        return 1

    print(f"Built {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
