# Verified Stage Themes and Physical Swarms v8 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/stage-swarms-v8/BONK_INFINITY_Windows_x64.zip). Extract and launch `BONK_INFINITY.exe`, or `Launch_Compatibility.bat`. Start a new run for the expanded object layout.

- Clean source: `15310003ce3bbce808a43bb44899399316c1c516`.
- Successful publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40500299914
- Successful PR validation/export: https://github.com/Hazmire/MegaClonk/actions/runs/40500308293
- Release asset ID `681489125`; 111,652,560 bytes.
- ZIP SHA256: `c5240a8a34c0f19e298c59e5514e7318d2e7eaef7354d80d80f251325b3d3bd0`.
- Actions artifact ID `12733221334`, `BONK_INFINITY-Windows-x64`; 112,555,500 bytes; not expired at verification; expires 26 November 2026.
- GitHub-reported artifact digest: `b57713b182ed1afbbb63bb01cc7094566f0751b27e3a9edcf14fa171c07e3427`. The durable release ZIP, rather than the separate artifact archive, was downloaded and inspected.

The published ZIP was downloaded; size, GitHub digest and all archive CRCs pass. BUILD_INFO confirms the expected clean commit. Linux Godot loaded its embedded game resources for a 180-frame practice run, explicit reward/UI smoke and new stage/swarms smoke, without script/resource errors. The new gate verifies actual three-theme material settings, object minimums, automatic shrine reward, two multiplied bosses, last-boss completion and queued chest save/load without duplication. Uploaded reference screenshots remain excluded from the game pack.

All 22 source suites pass locally and in CI. The local final run recorded 761 named assertions, 200 layouts, 200 decorated worlds, 104,353 collision rays, 400 enemy traversal checks, 1,000 live interactions, 73 cliff-drop cases and 200 expanded-object layouts. Actual source and local compiled-pack renders were viewed for all three palettes, supported swarm, shrine charging/completion and multiple independent boss health bars.

**Performance acceptance remains open:** comparable dense baseline/new full CPU means at 500 enemies were 10.08/23.99ms, with a new worst of 53.89ms. The cloud host does not establish gaming-PC FPS; the measured dense CPU path exceeds a 16.67ms frame budget. Software Mesa rendering is much slower still. A 25-chest collection/reel burst measured 26.22ms. The known Mesa sky-texture shutdown diagnostic remains. Native Windows execution, audible audio and gaming-GPU 60FPS are unverified.

[Gameplay guide, screenshots and performance table](../docs/STAGE_SWARMS.md) · [Raw verification](STAGE_SWARMS_VALIDATION.json) · [Source PR #3](https://github.com/Hazmire/MegaClonk/pull/3). Source is on `megaclonk-menu-loadouts`; merge PR #3 into `Full-Release` to update the default branch. The release download works independently of merging. The ZIP tracked directly in this directory is an older build.

Earlier verified publication follows.

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
