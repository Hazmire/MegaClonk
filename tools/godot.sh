#!/usr/bin/env bash
set -euo pipefail
bonk_tools_root=${BONK_TOOLS_ROOT:-/workspace/tools}
bonk_runtime_root=${BONK_RUNTIME_ROOT:-/workspace/bonk-runtime}
export XDG_DATA_HOME="$bonk_runtime_root/data"
export XDG_CONFIG_HOME="$bonk_runtime_root/config"
export XDG_CACHE_HOME="$bonk_runtime_root/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec "$bonk_tools_root/godot/Godot_v4.7.2-stable_linux.x86_64" "$@"
