# Combat and Atmosphere playtest publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/combat-polish-v4/BONK_INFINITY_Windows_x64.zip).

- Clean source: `1bbd9d19bfac710617d34cd6841ec8d1ab9c81e9`.
- Successful workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40327495010
- Release asset ID: `678201532`; 111,560,708 bytes.
- ZIP SHA256: `670d5674cb8416007fcd13b5143e75863d3d3ad071522f2f7cd6926efb621ed5`.
- Actions artifact ID: `12653620213`, `BONK_INFINITY-Windows-x64`; 112,464,137 bytes; not expired when checked.
- Artifact SHA256: `0767b12a1c779d53f1e6a5ce8e2af3997d3f00ffba6b97936d45f7acd84d20f2`.

The published ZIP was downloaded again. Its size and SHA256 match GitHub, all archive CRCs pass, and BUILD_INFO confirms the clean source above. Linux Godot loaded its embedded Windows game data for a 180-frame headless practice run without script/resource errors. Native Windows executable execution remains untested.

CI passed all twelve suites and exported Windows x86-64. Local validation includes 444 gameplay assertions, 55 cliff-drop cases and three 100-seed world suites. See VALIDATION.md and docs/PERFORMANCE_POLISH.md. Software OpenGL rendering was inspected; two retained texture handles are reported at shutdown and remain unresolved. Gaming-GPU 60 FPS and native audio need local playtesting.

Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge into Full-Release to update the default branch. The release download is available independently of merging. The ZIP tracked directly in this directory is an older build.
