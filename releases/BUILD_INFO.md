# Rarity Foundation publication — Milestone 1 only

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/rarity-foundation-v5/BONK_INFINITY_Windows_x64.zip).

- Clean source: `321f1773540fe307adefb6af0f51d6c071c76ef9`.
- Successful workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40330979929
- Release asset ID `678268840`; 111,568,396 bytes.
- ZIP SHA256: `e4ca38cb80975bce525ff0f75ad4e48a5ccdab97ac7f110d9e47c030a61d8d85`.
- Actions artifact ID `12655227268`, `BONK_INFINITY-Windows-x64`; 112,471,191 bytes; not expired at verification.
- Artifact SHA256: `00f053a049e56916ed3bf0f2d63fc6e3e4f4dd1188104ba5853c2425d1a3be9b`.

The published ZIP was downloaded again: size/SHA256 match GitHub, every archive CRC passes, BUILD_INFO confirms clean source, and the executable is PE32+ Windows x86-64. Linux Godot loaded its embedded game data for a 180-frame headless practice run without script/resource errors. Native Windows execution remains untested.

CI passed all thirteen suites before export/publication. Local evidence includes 444 existing assertions plus 143 new rarity checks, 55 cliff-drop cases and three existing 100-seed world suites. These old-world suites do not satisfy the pending new terrain's 200-seed requirement. Rarity distribution and metadata assignments are in docs/rewards/. No new terrain or UI screenshots are claimed.

The larger world, sky, placement, XP and UI overhaul remains pending in TODO_RARITY_WORLD.md. Previous performance measurements and the unresolved Mesa shutdown texture-handle diagnostic remain documented in docs/PERFORMANCE_POLISH.md; no new gaming-GPU FPS or native audio claim is made.

Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge into Full-Release to update the default branch. Release downloads work independently of merging. The ZIP tracked directly in this directory is an older build.
