# Verified Reference UI v7.1 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/reference-ui-v7.1/BONK_INFINITY_Windows_x64.zip). Extract and launch `BONK_INFINITY.exe`, or `Launch_Compatibility.bat` for OpenGL.

- Clean source: `0b9a6082fd16f331b14318937ac55010dbae8f1f`.
- Successful workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40401832094
- Release asset ID `679498463`; 111,612,559 bytes.
- ZIP SHA256: `08682c9d43c895c4ac0bae020d1b6ea80e33bc034cccc76a3c663e074dc01c56`.
- Actions artifact ID `12688743851`, `BONK_INFINITY-Windows-x64`; 112,516,002 bytes; not expired at verification.
- Artifact SHA256: `df8efbf4b9578524e2fd6155f03f57f22c253a5e74697780fda985042bf06856`.

The actual published ZIP was downloaded. Size and SHA256 match GitHub, every archive CRC passes, and BUILD_INFO confirms clean source. Linux Godot loaded its embedded game data for a 180-frame practice run and an explicit pause/map/reward-screen smoke without script/resource errors. The smoke also verifies that the five uploaded reference screenshots are excluded from the game pack.

All fifteen regression suites pass: 633 named assertions, including 27 focused reward/UI checks, plus seeded-world reports. The world validation retains 200 layouts, 200 decorated worlds, 101,114 collision rays, 400 enemy traversals, 1,000 live interactions and 70 detailed cliff-drop cases. Pause, map and reward screens were rendered at 720p/1080p/1440p and inspected; the local exported pack's pause/map views were also rendered and viewed.

The five references and implemented UI changes are mapped in [REFERENCE_UI.md](../docs/REFERENCE_UI.md). Press M (rebindable) in gameplay to inspect the discovered world, or use Map from pause. Existing rewards, prices, combat, progression and save compatibility are preserved.

These checks validate compiled resources and Linux rendering; **native Windows execution remains untested**. Physical controllers, audible audio and gaming-PC 60FPS remain unverified. The known Mesa sky-texture shutdown diagnostic and large XP-burst hitch limit remain documented in docs/REWARD_UI.md and docs/VERTICAL_PERFORMANCE.md.

Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge into Full-Release to update the default branch; this download works independently of merging. [Rewards and XP v7](https://github.com/Hazmire/MegaClonk/releases/tag/rewards-ui-v7) remains a fallback, with historical REWARDS_VALIDATION.json and checksum preserved. The ZIP tracked directly in this directory is an older build.
