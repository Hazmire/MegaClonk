# Verified Vertical Forest v6.1 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/vertical-forest-v6.1/BONK_INFINITY_Windows_x64.zip).

- Clean source: `9ce8efb892847209ac50ea1e1b6a661605c12651`.
- Successful workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40363304658
- Release asset ID `678836256`; 111,587,935 bytes.
- ZIP SHA256: `7121675ffce1fdac3e864655611bd2d1614cc5cf91c0e247c1ba32d48133bc60`.
- Actions artifact ID `12670056636`, `BONK_INFINITY-Windows-x64`; 112,491,258 bytes; not expired at verification.
- Artifact SHA256: `bd24d19a0b431e5c25dee75551f9a3b7aa9100a54abf8d3235070d08a8243215`.

The actual published ZIP was downloaded again. Size and SHA256 match GitHub, every archive CRC passes, and BUILD_INFO confirms the clean source above. Linux Godot loaded its embedded game data for a 180-frame practice run without script/resource errors. The local export from the same source was rendered and visually inspected with Mesa OpenGL. These checks validate exported resources; **native Windows executable execution remains untested**.

CI passed all fourteen regression suites and the new exported-pack smoke gate before packaging/publication. Evidence: 606 assertions, 200 deterministic layouts, 200 decorated worlds, 101,114 collision rays, 400 completed per-world enemy climbs/drops, 1,000 live interactions and 70 detailed cliff-drop cases. Twelve seed previews and raw reports are committed in docs/images/vertical/ and docs/world/.

Version 6 was marked superseded after downloaded-build testing found a missing empty-array default in release mode. Version 6.1 handles that default safely and smoke-tests the compiled pack on every export. Use the **6.1** download above.

Stage setup and software-renderer measurements are in docs/VERTICAL_PERFORMANCE.md. Gaming-PC 60FPS and audible audio remain unverified. Mesa still reports retained sky texture handles at shutdown.

XP gemstones and the level-up/chest/shop/build-screen overhaul remain pending in TODO_RARITY_WORLD.md. Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge into Full-Release to update the default branch; the release download works independently of merging. The ZIP tracked directly in this directory is an older build.
