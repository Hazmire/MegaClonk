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
cp assets/fonts/LICENSE-Kurland-OFL.txt builds/windows/FONT_LICENSE_KURLAND.txt
cp assets/vendor/jacob/License.txt builds/windows/JACOB_LICENSE.txt
cp "assets/vendor/abilities/READ ME.txt" builds/windows/ABILITY_ICONS_LICENSE.txt
cp docs/ASSET_ACCESS.md builds/windows/ASSET_STATUS.md
cp docs/CORE_OVERHAUL.md builds/windows/MENU_GUIDE.md
cp docs/STAGE_FOUNDATION.md builds/windows/STAGE_FOUNDATION.md
cp docs/CORE_OVERHAUL.md builds/windows/CORE_OVERHAUL.md
cp assets/vendor/psx_fx/LICENSE.txt builds/windows/PSX_FX_LICENSE.txt
cp assets/vendor/electric/license.txt builds/windows/ELECTRIC_FX_LICENSE.txt
cp docs/licenses/PUBLISHER_VERIFICATION.md builds/windows/ASSET_TERMS.md
cp docs/FOREST_OVERHAUL.md docs/ASSETS_V1_INVENTORY.md builds/windows/
for pack in ranger animations bestiary nature; do
 cp "assets/quaternius/$pack/LICENSE.txt" "builds/windows/QUATERNIUS_${pack}_LICENSE.txt"
done
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
Path('builds/windows/BUILD_INFO.txt').write_text('MEGACLONK terraced Forest and character overhaul\nGodot 4.7.2\nSource commit: '+commit+'\nUncommitted source at build time: '+str(dirty)+'\nWindows execution requires native playtesting.\n')
with ZipFile('builds/BONK_INFINITY_Windows_x64.zip','w',ZIP_DEFLATED) as z:
 for p in sorted(Path('builds/windows').iterdir()):
  if p.is_file(): z.write(p,p.name)
print('Packaged builds/BONK_INFINITY_Windows_x64.zip')
PY
