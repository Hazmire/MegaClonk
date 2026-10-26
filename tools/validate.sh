#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
log_path=$(mktemp /tmp/bonk-validation.XXXXXX)
trap 'rm -f "$log_path"' EXIT
# Godot editor import can exit zero even if a script fails to parse.
if ! tools/godot.sh --headless --path . --editor --import --quit > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
if ! tools/godot.sh --headless --path . --script tests/integration.gd > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
if ! tools/godot.sh --headless --path . --script tests/overhaul.gd > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
if ! tools/godot.sh --headless --path . --script tests/menu_systems.gd > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
if ! tools/godot.sh --headless --path . --script tests/stage_loop.gd > "$log_path" 2>&1; then
 cat "$log_path"
 exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
if ! tools/godot.sh --headless --path . --script tests/milestones.gd > "$log_path" 2>&1; then
 cat "$log_path"
 exit 1
fi
cat "$log_path"
if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
for suite in rarity terrace_seeds forest_physics forest_traversal dynamic_seeds dynamic_gameplay polish cliff_drops vertical_gameplay reward_ui; do
 if ! tools/godot.sh --headless --path . --script "tests/$suite.gd" > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
 fi
 cat "$log_path"
 if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
done
