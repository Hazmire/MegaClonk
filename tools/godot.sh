#!/usr/bin/env bash
set -euo pipefail
export XDG_DATA_HOME=/workspace/bonk-runtime/data
export XDG_CONFIG_HOME=/workspace/bonk-runtime/config
export XDG_CACHE_HOME=/workspace/bonk-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec /workspace/tools/godot/Godot_v4.7.2-stable_linux.x86_64 "$@"
