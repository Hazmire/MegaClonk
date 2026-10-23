# MegaClonk

An offline native Godot 4.7.2 3D survival roguelike in development. Built from an empty repository using original procedural geometry/audio. **This is a playable foundation, not the complete requested commercial-scale game.**

Windows playtest package: `builds/BONK_INFINITY_Windows_x64.zip` (generated, ignored by Git). Extract and run `BONK_INFINITY.exe`; `Launch_Compatibility.bat` selects OpenGL for machines without suitable Vulkan support. See [playtest instructions](docs/PLAYTEST.md).

## Development

Open `project.godot` in Godot 4.7.2. The normal desktop renderer is Forward+; compatibility can be selected with `--rendering-method gl_compatibility`.

In the prepared cloud workspace:

```sh
cd /workspace/MegaClonk
python3 tools/install_engine.py
tools/godot.sh --path .                         # desktop/display required
tools/validate.sh                              # headless import + integration
tools/export.sh                                # Windows executable + ZIP
```

Engine installation and templates live outside the checkout. `tools/godot.sh` supplies writable XDG directories under `/workspace/bonk-runtime`; it does not replace `HOME`. Engine/template downloads retain TLS verification and are checked against pinned official SHA512 digests. The installed snapshot retains tools; live processes do not survive restoration.

## Layout

- `scripts/core/catalog.gd`: independent weapon/character/tome/item data and calculations.
- `scripts/core/progress.gd`: versioned, atomic profile storage and unlocks.
- `scripts/core/mesh_pool.gd`: transient mesh/material reuse.
- `scripts/core/game.gd`: world generation, run orchestration, combat, UI, audio.
- `scripts/player/controller.gd`: movement and spring-arm camera.
- `tests/integration.gd`: real headless scene and system checks.
- `tests/visual.gd`: rendered menu/gameplay/pause capture (requires X display).

[Research provenance](RESEARCH.md) · [Asset credits](ASSET_CREDITS.md) · [Implementation limits](docs/STATUS.md) · [Original supplied brief](docs/USER_SPECIFICATION.md)
