from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET


REPO_ROOT = Path(__file__).resolve().parents[2]
MOD_DESC_PATH = REPO_ROOT / "mod" / "modDesc.xml"
BOOTSTRAP_PATH = REPO_ROOT / "mod" / "scripts" / "FS25AI.lua"
XSI_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance"


def test_mod_desc_uses_fs25_descriptor_and_dependency_order() -> None:
    root = ET.parse(MOD_DESC_PATH).getroot()
    source_files = root.find("extraSourceFiles")

    assert root.attrib["descVersion"] == "107"
    assert (
        root.attrib[f"{{{XSI_NAMESPACE}}}noNamespaceSchemaLocation"]
        == "https://validation.gdn.giants-software.com/xml/fs25/modDesc.xsd"
    )
    assert source_files is not None
    assert [
        source.attrib["filename"] for source in source_files.findall("sourceFile")
    ] == [
        "scripts/Config.lua",
        "scripts/StateCollector.lua",
        "scripts/BridgeClient.lua",
        "scripts/ActionExecutor.lua",
        "scripts/DebugHud.lua",
        "scripts/FS25AI.lua",
    ]


def test_fs25_bootstrap_registers_mission_lifecycle_listener() -> None:
    bootstrap = BOOTSTRAP_PATH.read_text(encoding="utf-8")

    assert "function FS25AI:loadMap(mapFilename)" in bootstrap
    assert "function FS25AI:deleteMap()" in bootstrap
    assert "function FS25AI:update(dt)" in bootstrap
    assert "g_fs25AI = self.runtime" in bootstrap
    assert "g_fs25AI = nil" in bootstrap
    assert 'Loaded mod version %s for map' in bootstrap
    assert 'Shutdown complete for current mission' in bootstrap
    assert "addModEventListener(FS25AI)" in bootstrap
