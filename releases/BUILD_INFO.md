# Dynamic Forest playtest publication

[Download the Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/dynamic-forest-v3.1/BONK_INFINITY_Windows_x64.zip).

- Release: https://github.com/Hazmire/MegaClonk/releases/tag/dynamic-forest-v3.1
- Clean source: `d5be3a4ad32ea4d1b43a6a3dbaf56b9a6bb4edf3`, `megaclonk-menu-loadouts`.
- Successful Actions run: https://github.com/Hazmire/MegaClonk/actions/runs/40246730637
- Release asset: `676461991`, **111,201,896 bytes**.
- Release ZIP SHA256: `f28073c27fe79eaaebbd18dcae8b08128043f4d93c10c98d4ddfca5db06b64df`.
- Actions artifact: `BONK_INFINITY-Windows-x64`, `12618179949`, **112,102,438 bytes**, not expired at verification.
- Artifact SHA256: `9d71ec544c82604b784535298b03469efe290bb47eb03cc4cc64b9ba6985fc0a`.

CI imported the committed runtime assets, passed all ten suites, exported Windows x86-64 and
published both downloads. Release and artifact sizes/digests were verified through GitHub's API.
The Actions artifact wraps the exported directory; its bytes differ from the release ZIP.

The published ZIP was downloaded again: byte count and SHA256 match GitHub, all ZIP CRCs pass,
and BUILD_INFO confirms clean source d5be3a4. The KayKit licence is present alongside all four
Quaternius notices. Its executable is PE32+ Windows x86-64 with embedded game data. Linux Godot
loaded that downloaded data for a180-frame headless practice run and a120-frame rendered compatibility
practice run without script/resource errors. Driver VSync/shader-cache warnings are expected on
software OpenGL. This validates exported resources; **native Windows execution remains untested**.

Validation:383 gameplay assertions,100 layouts,100 actual collision/native-navigation worlds,
100 distribution samples,5,218 collision rays, zero repairs/failures. New-roster400-enemy simulation
averaged8.74ms/tick, rendering excluded. See `DYNAMIC_VALIDATION.json` and `VALIDATION.md`.

Source PR: https://github.com/Hazmire/MegaClonk/pull/3 . Merge into `Full-Release` to update the default
branch. The release download is available independently of merging. The ZIP tracked directly in
this directory is an older release; use the URL above. The previous Forest playtest remains at
release `forest-playtest-v2`; its checksum is in `FOREST_SHA256SUMS`.

Version3.1 keeps the elite statue in a separate region from the portal/player spawn. All100 variety seeds verify interaction-zone separation, and the gameplay suite checks the actual E prompt.
