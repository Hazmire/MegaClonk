# Verified Rewards and XP v7 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/rewards-ui-v7/BONK_INFINITY_Windows_x64.zip). Extract everything and launch `BONK_INFINITY.exe`, or `Launch_Compatibility.bat` for OpenGL.

- Clean source: `9b762af6659b0b0d12be99e35e62543afe6ee983`.
- Successful workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40376476581
- Release asset ID `679058946`; 111,605,506 bytes.
- ZIP SHA256: `41bebcaf7e5bad54473c66c3c12ff6ed68e351d76ad513b2d15bb7726aba5f2c`.
- Actions artifact ID `12675635685`, `BONK_INFINITY-Windows-x64`; 112,508,821 bytes; not expired at verification.
- Artifact SHA256: `4c8d069f72db5f8bbb4603ff5b09c7ef88924aa1b07632baf88b2c73f5ce4c45`.

The published ZIP was downloaded and checked against GitHub's size and SHA256. Every archive CRC passes, and BUILD_INFO confirms the clean source above. Linux Godot loaded the downloaded embedded game data for 180 practice frames and an explicit reward-screen smoke without script/resource errors. The local export's upgrade, build, shop, roulette and reveal screens were also rendered and visually inspected. This validates compiled resources; **native Windows executable execution remains untested**.

All fifteen regression suites pass, with 625 named assertions plus seeded-world reports: 200 layouts, 200 decorated worlds, 101,114 collision rays, 400 enemy traversals, 1,000 live interactions and 70 detailed cliff-drop cases. Nineteen reward checks include queued save/load, exact-level red gems, duplicate prevention, affordability and synthetic navigation. Screens were rendered at 720p, 1080p and 1440p. See [reward guide](../docs/REWARD_UI.md), [validation](REWARDS_VALIDATION.json) and [world guide](../docs/VERTICAL_FOREST.md).

CI exposed a missing `rg` executable on the runner. Validation/export guards now use standard `grep`, including the positive compiled-UI completion check, and export failures include API-readable annotations. The final clean CI run passed with these corrected guards.

CPU results and limits are in docs/REWARD_UI.md and docs/VERTICAL_PERFORMANCE.md. Physical controllers, audible audio and gaming-PC 60FPS remain unverified. Mesa software OpenGL still reports retained sky texture handles on shutdown. Creating 1,000 unmerged gems in one burst can hitch; the normal path retains merging and prewarming.

All rarity/world/XP/reward-interface milestones now have evidence and a Windows playtest build. Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge it into Full-Release to update the default branch; the release download works independently of merging. The ZIP tracked directly in this directory is an older build. [Vertical Forest v6.1](https://github.com/Hazmire/MegaClonk/releases/tag/vertical-forest-v6.1) remains a fallback; its historical verification is retained in VERTICAL_VALIDATION.json.
