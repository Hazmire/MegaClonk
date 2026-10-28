# Verified Grimdark PSX13.1 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/grimdark-psx-v13.1/BONK_INFINITY_Windows_x64.zip). Extract everything and launch BONK_INFINITY.exe, or Launch_Compatibility.bat.

- Clean game source: `c2209e6ea108119bd65f637d43155b75ffbd3c22`.
- Successful28-suite publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40670792426
- Successful PR validation: https://github.com/Hazmire/MegaClonk/actions/runs/40670800363
- Release asset ID `684613057`; 134,927,445bytes.
- ZIP SHA256: `659ed35dbecbb256bbd68e32537f41d31183d0532c17798c94cb19b6ded59a74`.
- Actions artifact ID `12808403283`; verified not expired.

Downloaded size/digest and every CRC match. BUILD_INFO confirms the expected commit and no uncommitted files. Linux Godot ran180 world frames and all six compiled smoke gates. The downloaded pack was rendered and viewed at1280×720 with640×360 internal world and sharp UI. Native Windows execution remains untested. Simplified supplemental animation,500-enemy CPU cost and Mesa shutdown diagnostics remain documented limitations.

[Guide](../docs/GRIMDARK.md) · [Performance](../docs/GRIMDARK_PERFORMANCE.md) · [Published screenshot](../docs/images/grimdark/published_13_1.png) · [Raw proof](GRIMDARK_VALIDATION.json) · [PR#6](https://github.com/Hazmire/MegaClonk/pull/6).

13.1 commits a generated Godot smoke-script UID missing in13; the earlier build's dirty-worktree flag is not presented as clean. Use13.1. Source updates are on the PR branch until merged into Full-Release; the download works independently.

# Verified Dark Feedback v12.1 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/dark-feedback-v12.1/BONK_INFINITY_Windows_x64.zip). Extract everything and launch BONK_INFINITY.exe, or Launch_Compatibility.bat.

- Clean source: `c427760d249708809bcd288ee74aac89e024508f`.
- Successful27-suite publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40595447540
- Release asset ID `683094848`; 123,874,900bytes.
- ZIP SHA256: `0f5c0bc4175df620313f9a8a63ce4329e99f4ef37882782fd4cbc0254a542952`.
- Actions artifact ID `12777370563`; not expired at verification.

Downloaded size/digest, every archive CRC and clean expected source pass. Linux Godot ran180 world frames and all five compiled smoke gates, including bar height after theme layout. The pre-hotfix full local run passed1,086 named checks; the final size correction passes14 focused checks, and clean CI passes all27 suites. Source and exported renders confirm a7px character bar. Native Windows execution and sound auditioning remain unverified.

[Guide/screenshot](../docs/DARK_FEEDBACK.md) · [Raw proof](DARK_FEEDBACK_VALIDATION.json) · [PR #5](https://github.com/Hazmire/MegaClonk/pull/5). Enemy hit/death/self-destruct sounds are silent, weapon feedback remains, effects are darker, tomes have a separate row, and matching dark-red health bars include numbered HP on the left. Existing dense-horde performance limits remain. Use this release ZIP; binaries tracked elsewhere in Git are older.

# Historical Dark Feedback v12 publication

Superseded by12.1: Godot retained a27px character-bar height despite the requested7px size;12.1 applies the thin size after theme layout and verifies rendered pixels.

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/dark-feedback-v12/BONK_INFINITY_Windows_x64.zip). Extract the entire ZIP and launch BONK_INFINITY.exe, or Launch_Compatibility.bat.

- Clean source: `f203a3503f45958b5a4c5eea912c7534fc83f254`.
- Successful publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40593680375
- Successful PR validation: https://github.com/Hazmire/MegaClonk/actions/runs/40593690314
- Release asset ID `683067158`; 123,869,365bytes.
- ZIP SHA256: `502a905476776fb6c316353b09a49c944eb54833d1df936c24970199b8ba6800`.
- Actions artifact ID `12775711951`; 124,864,984bytes; not expired at verification.

Downloaded ZIP size/digest and every archive CRC match. BUILD_INFO confirms the expected clean source. Linux Godot ran the published embedded pack for180 frames and all five compiled smoke gates, including silent enemy event registry, tome row and HP checks. All27 suites passed locally (1,086 named checks) and in clean GitHub CI. Source and compiled HUD renders were viewed.

Enemy hit/death/self-destruct feedback is silent, weapons retain their audio, effects use a darker source/filter/pitch pass, tomes have a separate row, and both health bars are dark red with current/max numbers inside the left bar. [Guide and screenshot](../docs/DARK_FEEDBACK.md) · [Raw verification](DARK_FEEDBACK_VALIDATION.json) · [PR #5](https://github.com/Hazmire/MegaClonk/pull/5). The tracked ZIP elsewhere in Git is older; use this release download. Merge PR #5 into Full-Release after review; this download works independently.

Files were not auditioned; native Windows/audio-device testing and existing dense-horde/GPU limitations remain. Earlier publications follow.

# Verified Retro Audio v11 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/retro-audio-v11/BONK_INFINITY_Windows_x64.zip). Extract the entire ZIP and launch BONK_INFINITY.exe, or Launch_Compatibility.bat. The ZIP tracked directly in this repository is an older build; use this release download.

- Clean source: `7ab7312f390474e35e5d00afff23c14e42c33224`.
- Successful publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40588840574
- Successful PR validation: https://github.com/Hazmire/MegaClonk/actions/runs/40588875421
- Release asset ID `682980577`; 123,951,986bytes.
- ZIP SHA256: `bae772210404e0208cf00afd4cd64230e8d137e019cb2177b01735bf426df6cd`.
- Actions artifact ID `12772834404`, BONK_INFINITY-Windows-x64; 124,945,156bytes; not expired at verification; expires26 November2026.
- Actions artifact digest: `sha256:2e4391beee657dc8dc4a2a58ffe609c6b685394d700f2c7f513d6a4fbab68d1f`. The durable release ZIP was downloaded separately and verified.

All26 suites passed locally (1,076 named checks) and in clean GitHub CI, alongside the existing200-seed world/physics/placement audits. CI success was read from the Actions job/step API; the signed full-log host returns403, so no independently counted CI transcript is claimed. The downloaded ZIP matches GitHub size/digest and every archive CRC, with clean expected BUILD_INFO. Linux Godot ran its embedded pack for180 frames plus all five UI/stage/v9/art/audio smoke gates. Source, compiled and published white-flash/settings renders were viewed. This validates exported resources, not native Windows execution.

Four supplied original tracks and106 selected Pixel Combat clips (3,190,904bytes) are integrated. Six existing legacy ambience/death recordings and an original project clap bed remain. The complete2.04GB library stays outside the project and export. Attribution and curation offsets are shipped.

[Full inventory, mappings and evidence](../docs/RETRO_AUDIO.md) · [Raw verification](RETRO_AUDIO_VALIDATION.json) · [PR #5](https://github.com/Hazmire/MegaClonk/pull/5). Merge PR #5 into Full-Release after review; the download works independently.

**Open playtest gates:** files were not auditioned. Native Windows/device/spatial mix, subjective timbres, loop joins and live crossfade timing require listening. ALSA-null capture is unclocked and only establishes decoded signal. Dense dispatch cost0.51ms mean at500 synthetic impact-requesting enemies; this does not solve the existing horde/GPU frame budget.

Earlier verified publications follow.

# Verified shrine rewards and pursuit v9 publication

[Download Windows ZIP](https://github.com/Hazmire/MegaClonk/releases/download/shrine-rewards-v9/BONK_INFINITY_Windows_x64.zip). Extract and run BONK_INFINITY.exe, or Launch_Compatibility.bat.

- Clean source: `ea6c26f0609035b61c683f2818ea6398165048a2`.
- Successful publishing workflow: https://github.com/Hazmire/MegaClonk/actions/runs/40544084785
- Release asset ID `682241148`; 111,701,124 bytes.
- ZIP SHA256: `ebb8a404460edbc21b40eaa4658d5f80356ffb7ac24fab70c9493845b43e28b2`.
- Actions artifact ID `12752198576`, BONK_INFINITY-Windows-x64; 112,603,909 bytes; not expired at verification; expires 26 November 2026.
- GitHub-reported artifact digest: `b5063634674aa557679ec70990fb022f46174d0da9677e25dc35def894384dd9`. The durable release ZIP, rather than the separate Actions artifact archive, was downloaded and inspected.

The published ZIP was downloaded; GitHub size/digest and every archive CRC match. BUILD_INFO confirms clean expected source. Linux Godot loaded its embedded game resources for a 180-frame world run plus explicit reward/UI, stage/swarms and v9 smoke checks, without script/resource errors. These validate compiled resources, not native Windows machine-code execution.

All 23 source suites pass locally and in the release workflow. The final local run recorded 859 assertions, including 95 focused v9 checks, plus 200 layout/decoration/object seeds. Golden Shrine sampling produced 1,986/100,000 placements (1.986%). Original and compiled reward screens/HUD were rendered and viewed at 720p/1080p/1440p. Existing crowd support, traversal, contact intervals, boss abilities, multipliers and chest/save queues remain covered.

**Performance remains open:** the final cloud CPU means at 50/100/250/500 enemies were 3.20/8.00/19.86/38.55ms; same-host v8 baseline was 2.86/5.84/17.26/35.02ms. The 500-enemy v9 worst was 48.31ms. These are shared-host samples, not gaming-PC FPS; both versions exceed a 16.67ms CPU budget. A 25-chest collection/reveal burst measured 33.62ms. Known Mesa sky-texture shutdown diagnostics remain. Native Windows execution, audible audio and gaming-GPU 60FPS are unverified.

[Rules, stat table, root causes and screenshots](../docs/REWARDS_AI_V9.md) · [Raw verification](REWARDS_V9_VALIDATION.json) · [PR #4](https://github.com/Hazmire/MegaClonk/pull/4). PR #3 was merged as 00ed498; merge PR #4 into Full-Release for this update. The new download works independently. The ZIP tracked directly in this directory is an older build.

Earlier verified publications follow.

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
