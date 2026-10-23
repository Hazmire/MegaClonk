#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds/windows
log_path=$(mktemp /tmp/bonk-export.XXXXXX)
trap 'rm -f "$log_path"' EXIT
if ! tools/godot.sh --headless --path . --export-release 'Windows Desktop' > "$log_path" 2>&1; then
 cat "$log_path"
 exit 1
fi
cat "$log_path"
if rg -q 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
cp docs/PLAYTEST.md builds/windows/READ_ME_FIRST.txt
cp docs/GODOT_COPYRIGHT.txt builds/windows/GODOT_COPYRIGHT.txt
cp docs/STATUS.md builds/windows/FEATURE_STATUS.md
cp RESEARCH.md ASSET_CREDITS.md builds/windows/
cp assets/fonts/LICENSE-CC0.txt builds/windows/FONT_LICENSE_CC0.txt
cp docs/ASSET_ACCESS.md builds/windows/ASSET_STATUS.md
cp docs/MENU_UPDATE.md builds/windows/MENU_GUIDE.md
cat > builds/windows/Launch_Compatibility.bat <<'BAT'
@echo off
cd /d "%~dp0"
start "" "BONK_INFINITY.exe" --rendering-method gl_compatibility
BAT
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import subprocess
commit = subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
dirty = bool(subprocess.check_output(['git','status','--porcelain'],text=True).strip())
Path('builds/windows/BUILD_INFO.txt').write_text('MEGACLONK menus, loadouts and progression update\nGodot 4.7.2\nSource commit: '+commit+'\nUncommitted source at build time: '+str(dirty)+'\nWindows execution requires native playtesting.\n')
with ZipFile('builds/BONK_INFINITY_Windows_x64.zip','w',ZIP_DEFLATED) as z:
 for p in sorted(Path('builds/windows').iterdir()):
  if p.is_file(): z.write(p,p.name)
print('Packaged builds/BONK_INFINITY_Windows_x64.zip')
PY
