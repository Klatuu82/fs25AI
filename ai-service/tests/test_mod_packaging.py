from __future__ import annotations

import importlib.util
import os
from pathlib import Path
from zipfile import ZipFile

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
BUILD_MOD_ZIP_PATH = REPO_ROOT / "scripts" / "build_mod_zip.py"


def load_build_mod_zip_module():
    spec = importlib.util.spec_from_file_location("build_mod_zip", BUILD_MOD_ZIP_PATH)
    assert spec is not None
    assert spec.loader is not None

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_mod_tree(root: Path) -> Path:
    source_dir = root / "mod"
    (source_dir / "scripts").mkdir(parents=True)
    (source_dir / "translations").mkdir(parents=True)
    (source_dir / "modDesc.xml").write_text(
        """<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc descVersion="107">
    <version>1.2.3.4</version>
    <extraSourceFiles>
        <sourceFile filename="scripts/FS25AI.lua"/>
    </extraSourceFiles>
</modDesc>
""",
        encoding="utf-8",
    )
    (source_dir / "scripts" / "FS25AI.lua").write_text("return {}", encoding="utf-8")
    (source_dir / "translations" / "en.xml").write_text("<l10n />", encoding="utf-8")
    return source_dir


def test_package_mod_builds_a_versioned_reproducible_archive(tmp_path: Path) -> None:
    module = load_build_mod_zip_module()
    source_dir = write_mod_tree(tmp_path)
    first_output_dir = tmp_path / "dist-one"
    second_output_dir = tmp_path / "dist-two"

    first_archive = module.package_mod(source_dir, first_output_dir)
    first_bytes = first_archive.read_bytes()

    os.utime(source_dir / "modDesc.xml", (1_725_000_000, 1_725_000_000))
    os.utime(source_dir / "scripts" / "FS25AI.lua", (1_726_000_000, 1_726_000_000))

    second_archive = module.package_mod(source_dir, second_output_dir)

    assert first_archive.name == "fs25AI-mod-1.2.3.4.zip"
    assert second_archive.name == "fs25AI-mod-1.2.3.4.zip"
    assert first_bytes == second_archive.read_bytes()

    with ZipFile(second_archive) as archive:
        assert archive.namelist() == [
            "modDesc.xml",
            "scripts/FS25AI.lua",
            "translations/en.xml",
        ]
        assert archive.read("modDesc.xml").decode("utf-8").startswith("<?xml")
        assert all(entry.date_time == module.FIXED_ZIP_TIMESTAMP for entry in archive.infolist())


def test_package_mod_fails_when_mod_desc_references_a_missing_file(tmp_path: Path) -> None:
    module = load_build_mod_zip_module()
    source_dir = write_mod_tree(tmp_path)
    (source_dir / "scripts" / "FS25AI.lua").unlink()
    output_dir = tmp_path / "dist"

    with pytest.raises(module.PackagingError, match="Missing required package entries"):
        module.package_mod(source_dir, output_dir)

    assert not output_dir.exists()


def test_build_zip_skips_hidden_files(tmp_path: Path) -> None:
    module = load_build_mod_zip_module()
    source_dir = write_mod_tree(tmp_path)
    (source_dir / ".gitignore").write_text("ignored", encoding="utf-8")

    archive_path = module.package_mod(source_dir, tmp_path / "dist")

    with ZipFile(archive_path) as archive:
        assert ".gitignore" not in archive.namelist()
