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
for suite in rarity economy_regression terrace_seeds forest_physics forest_traversal dynamic_seeds dynamic_gameplay polish cliff_drops vertical_gameplay reward_ui stage_themes enemy_contact crowd_physics reward_drops shrine_charging world_objects boss_multiplier rewards_ai_v9 art_reset_gameplay art_reset_world retro_audio audio_regression dark_feedback grimdark visual_corrections dusk_update sockets vases_powerups imbue_station elements combos_amulet pickup_ui weapons_smoke weapons_regression items_regression items_smoke menus_regression ingame_ui_regression; do
 if ! tools/godot.sh --headless --path . --script "tests/$suite.gd" > "$log_path" 2>&1; then
  cat "$log_path"
  exit 1
 fi
 cat "$log_path"
 if grep -Eq 'SCRIPT ERROR|^ERROR:' "$log_path"; then exit 1; fi
done
