#!/usr/bin/env python3
"""Install the pinned official engine/templates without modifying project source."""
import hashlib
from pathlib import Path
import urllib.request
import zipfile
import os

VERSION = "4.7.2-stable"
ROOT = Path(os.environ.get("BONK_TOOLS_ROOT", "/workspace/tools")) / "godot"
DATA = Path(os.environ.get("BONK_RUNTIME_ROOT", "/workspace/bonk-runtime")) / "data/godot/export_templates/4.7.2.stable"
ARTIFACTS = {
    "Godot_v4.7.2-stable_linux.x86_64.zip": "9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65",
    "Godot_v4.7.2-stable_export_templates.tpz": "ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079",
}
ROOT.mkdir(parents=True, exist_ok=True)
DATA.mkdir(parents=True, exist_ok=True)
for name, digest in ARTIFACTS.items():
    targets = [ROOT / "Godot_v4.7.2-stable_linux.x86_64"] if name.endswith("zip") else [DATA / item for item in ["windows_release_x86_64.exe", "windows_debug_x86_64.exe", "linux_release.x86_64"]]
    if all(p.is_file() for p in targets):
        print("Retaining installed:", name)
        continue
    archive = ROOT.parent / name
    if not archive.exists() or hashlib.sha512(archive.read_bytes()).hexdigest() != digest:
        url = f"https://github.com/godotengine/godot/releases/download/{VERSION}/{name}"
        print("Downloading", name)
        urllib.request.urlretrieve(url, str(archive) + ".tmp")
        Path(str(archive) + ".tmp").replace(archive)
    if hashlib.sha512(archive.read_bytes()).hexdigest() != digest:
        raise SystemExit("SHA512 verification failed: " + name)
    with zipfile.ZipFile(archive) as source:
        for target in targets:
            entry = target.name if name.endswith("zip") else "templates/" + target.name
            target.write_bytes(source.read(entry))
            if name.endswith("zip"):
                target.chmod(0o755)
    archive.unlink()
print("Godot and export templates available")
