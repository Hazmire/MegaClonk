# Vertical Forest validation

Fourteen suites: 606 assertions (complete clean CI regression), 200 deterministic layouts, 200 matching decorated physics/placement worlds, 101,114 collision rays, 1,000 live interactions and 70 cliff-drop cases. No repairs/failures. Twelve seed renders and two atmosphere views inspected. Old/new saves preserve geometry and object positions; unsupported future terrain is rejected. Reports: docs/world/ and docs/VERTICAL_PERFORMANCE.md. Native Windows execution remains untested. Windows v6.1 publication and exported-game smoke checks are verified in releases/BUILD_INFO.md. Prior reports follow.

# Combat and atmosphere polish validation

Current:444 assertions,55 concrete cliff traversal scenarios and three100-seed suites pass.
The cliff cases include6m/12m, all orientations, ordinary/elite/boss agents, damage during a fall
and a ramp landing. Animation checks inspect joint offsets/lengths, physics-root immobility and
locomotion during damage. All36 weapon damage tests still pass; Chunkers counts/positions share
its authoritative orbit functions and XP/gold totals survive aggregation.

Controlled before/after profiling was repeated in a detached unchanged baseline checkout and the
updated project, sequentially without another game process.100/250-enemy death pipelines measured
314.122/314.502ms before and0.402/0.869ms after. Original exploratory traces measured392/322ms.
Raw headless and rendered mean/P95/P99/worst, nodes/memory/draw/FX counts and context are in
`docs/performance/`; full scope and limits in `docs/PERFORMANCE_POLISH.md`.

Rendered inspection covers idle/run/jump/slide/crouch, Chunkers stones/debris, impacts/digits,
soil/moss ground, sparse wind grass, dark sky/fog and high rock cliffs. The cloud uses Mesa software
OpenGL. It still emits two retained-texture diagnostics on shutdown; this is disclosed rather than
called an error-free graphics run. Native Windows/audio, driver-specific first-use stalls and target
60FPS require local playtesting. Windows publication evidence is in releases/BUILD_INFO.md.

Earlier validation history follows.

# Dynamic Forest validation

Godot4.7.2, unchanged engine. Ten suites cover **383 gameplay assertions** (the previous335 plus47
new checks),100 mathematical layouts,100 actual collision/navigation worlds, and a100-seed variety
report. CI40246730637 passed and published `dynamic-forest-v3.1`. The final follow-up also verifies100 seeds keep elite statues separate from portal interactions, and checks the actual interaction prompt. Final publication details are in `releases/BUILD_INFO.md`. Earlier results below are historical.

The new checks exercise per-spawn choices and saved RNG,75/20/5 weighting, live pursuit during
emergence, bug warning/detonation, actual cliff ascent and upper landing, boundary rejection,
elite activation/emblems/live save/load/reward-once, boss UI/duplicate protection, fixed captured
AOE/escape/damage, golem cadence/cap/cleanup, and actual fitted skeletal stance-foot height.
All36 weapon patterns still deal damage; progression, menus and stage travel retain their checks.
Legacy death explosions remain tested separately from the new proximity-only Bug.

Map distribution over seeds0–99:100 unique layouts; region counts4–15; ramps4–17 (mean10.93).
Spawns: N9,S11,E9,W9,NE16,NW13,SE21,SW12. Spawn heights:0m34,6m27,12m39.
Centre:0m34,6m28,12m31, with seven sloped centre samples. All tested graph drafts succeeded first
attempt. Physical worlds use run seeds0–99 (stage map seeds73–172), checking every unblocked flow
cell plus POIs/spawn/statue, real native spawn-to-portal paths, ramp rays and perimeter rays.
The physical suite casts5,218 rays; reports distinguish first-attempt and repaired/final results.

Ten map screenshots plus close Ranger/roster/elite/boss views were rendered and inspected under
Xvfb/Mesa compatibility OpenGL. Images are in `docs/images/dynamic/`. Full software-rendered visual
fixtures report no script/resource errors; unsupported VSync warnings are expected.

Validation corrected narrow perimeter seams, cliff-side decoration pockets, rigid Warrior attachment
baking, old centre-low combat fixtures, and native region iteration readiness. The last issue could
produce empty native maps even with synchronous map iterations: region iterations must also be
synchronous. Stages now own their maps and verify a real native path before allowing enemy spawning.

Headless performance baseline this session:400 legacy enemies5.39ms/tick before changes. Current
mixed compatibility benchmark is about7.5ms; the new400-enemy ordinary roster is about9ms/tick.
These include simulation, instanced transforms and spatial rebuilding, exclude rendering, and are
not a60FPS or full late-game combat guarantee. Exact final timings:7.53ms compatibility mix,8.74ms ordinary roster; see `releases/DYNAMIC_VALIDATION.json`.
Native Windows execution, audible output and target-GPU FPS remain unverified.

---
Previous validation history follows.

# Forest overhaul validation — 2026-10-25

Pinned Godot 4.7.2. Final `tools/validate.sh`: **335 checks, zero failures** across integration
31, movement/variants78, menus55, stage loop39, milestones112, physical traversal/animation20.
Additionally, 100 graph/determinism layouts and 100 physical stage worlds pass on first attempt;
zero repairs, zero final failures. The physical suite uses 5,208 rays, checks decorated flow-field
reachability and Godot native paths to elevated portals. Reports: `docs/validation/`.

Player CharacterBody and enemy simulation traverse a real planar ramp uphill/downhill.
Stage rebuild disposes old collision/nav and reproduces seeded decoration. Actual baked mesh
vertices differ between walk samples for both monsters. All 36 weapon patterns retain damage.

Rendered inspection: Forest overview, grounded player idle/run/jump/fall/crouch/slide, sixteen
behaviour configurations using Imp/Puglin, navigation overlay and asset showcase, plus the existing
menu/combat visual fixtures, under Xvfb/Mesa OpenGL. Committed examples: `docs/images/forest-*`.
No script/resource errors; software-driver VSync warnings are expected.

400 enemies, steady-state update + spatial rebuild: **5.32 ms/tick**, rendering excluded.
Earlier baseline this session: 4.16 ms/tick (~28% increase). Cold animation-resource loading initially
inflated the measurement to 30 ms/tick; resources now prewarm during stage setup and the measured
loop warms explicitly. This is not a target-GPU FPS guarantee or a full late-game combat profile.
100 physical map builds/checks took 24.565 seconds total; graph timings are in the JSON report.

Validation fixed reversed terrain winding, stale asynchronous navigation iterations and the old
region remaining registered during rebuild. Native navigation now uses synchronous iteration and
explicit old-region detachment; query budgets cover the full map rather than the default4096 cells.
A detached menu-camera look_at was also corrected. Tests retain true 3D explosion proximity;
paused ground-combat fixtures now place the player on the ground.

Windows CI run40237119122 passed and published the release ZIP plus artifact.
Export/publication evidence is maintained in `releases/BUILD_INFO.md`.
Native Windows execution, audible speaker output and stable60FPS on gaming hardware remain unverified.

---
Earlier release history follows.

# Validation record — 2026-10-23

Engine: official Godot `4.7.2.stable.official.ed1daf0bf`, Linux x86_64. Engine archive and export-template archive were verified against official release SHA512 digests before use. No TLS or signature checks were disabled.

## Executed

- `tools/validate.sh`: editor import with explicit script-error detection, then **30 checks, 0 failures**. Includes mathematical damage/crit checks; XP thresholds; 21/36 roster sizes; atomic save round trip; starting unlock normalization; sandbox progression isolation; milestone unlocks; real CharacterBody3D movement/jump against terrain; damage; upgrade availability and stat/item application; all 36 runtime weapon patterns dealing damage; poison/slow; two character passives; visible Chrono/Phantom entities; pause; actual level-up screen with three choices; weapon-slot limit; director boss spawn; boss death/portal; victory and defeat states; retained 400-enemy simulation.
- 400-enemy simulation averaged about **1.7 ms/tick** in the measured headless run. This covers enemy updates and spatial-index rebuilding; it excludes rendering and full late-game combat. It is not a hardware FPS guarantee.
- `tests/visual.gd` rendered menu, forest gameplay, desert, graveyard, level-up and pause screens using Xvfb/Mesa llvmpipe with the compatibility renderer. Captures are in ignored `builds/*.png`. Images were inspected during development; rendered runs reported no script/resource errors. Mesa reports unsupported V-Sync changes, which is expected for this virtual display.
- Windows release exported successfully with embedded PCK; `file` identifies PE32+ Windows x86-64. The packaged ZIP includes launch instructions, compatibility launcher and Godot third-party licence notices.
- A Linux release export also started headlessly from embedded resources for 60 frames without script/resource errors when writable XDG directories were supplied. The first direct launch without those directories logged sandbox write errors; the corrected launch passed.

## Fixed during validation

Reversed terrain triangles caused failed floor/jump detection. Health regeneration incorrectly rescued zero-health players. JSON numeric array values caused starting characters to appear locked. The integration suite originally wrote an unlock-test profile to the normal cloud profile path; test saves now use separate paths and the test-created default profile was removed before delivery. Silent/Dummy audio runs now skip audio playback rather than retaining a dummy playback object at shutdown.

## Not established

Native Windows execution, audible output on speakers, Forward+ rendering on a real GPU, 60 FPS on a target gaming PC, long-run stability, faithful reference balance, all character-passive combinations and playtester enjoyment. Only two passives have explicit behaviour assertions; the roster is not equivalent to complete per-character integration coverage. Exact original mechanics remain unverified because all supplied research sites are proxy-blocked.

## Movement/visual overhaul — 2026-10-23

Baseline on the existing project: **30 checks pass**, 400-enemy CPU update + grid rebuild averaged **1.61 ms/tick**.

The overhaul retains those **30 checks** and adds **78 passing checks** (108 total). New coverage includes absence of a sprint action; rebindable Ctrl crouch; capsule resize and real ceiling clearance; entry threshold and momentum; steering/cap; pure slope calculations plus actual downhill/uphill inclined StaticBody traversal; slide jumping; all nine player animation states; eight archetypes/two variations each; all 16 model resources; deterministic and diverse registry choices; per-run spawn consistency; stage and actual saved-run continuity; variant stats; cactus wind-up/fan/projectile impact; proximity and delayed death explosions with repeat guards; melee recovery; normal rewards; distinct attack meshes and animated instancing.

The comparable final local headless benchmark averaged approximately **6.0 ms/tick for 400 enemies** (runs during development ranged about 5.8–8.0 ms). This is a significant increase over 1.61 ms: richer AI, obstacle queries, separate model batches and animated transforms do more work. Distant humanoids use merged meshes to reduce update cost. Timing excludes rasterization, full late-game combat and target-PC hardware; stable 60 FPS is **not established**.

Rendered inspection used Godot 4.7.2, Xvfb and Mesa llvmpipe with OpenGL compatibility rendering. Menu, all 16 enemy silhouettes in a dedicated gallery, player idle/run/crouch/slide/jump poses and a combat scene were actually captured and viewed. The ground shader compiled/rendered. These images do not establish authored skeletal animation or Windows/Vulkan performance.

A real GitHub Actions run on commit `49d00f1` completed successfully and uploaded `BONK_INFINITY-Windows-x64` (run 39976842983); the first workflow attempt had failed due to an unsupported `runner.temp` YAML context and was fixed. Final source/artifact provenance is recorded in `releases/BUILD_INFO.md`. Artifact publication is separate from native Windows execution, which remains untested.

Final source commit `0074f48` passed GitHub Actions run **39978727835**, including import, both suites, Windows export and artifact upload. Artifact ID **12511519962** is present and unexpired, with a positive size and SHA256 digest. The blob storage download route was denied from this cloud machine; actual Actions archive-byte inspection was not possible. A separate local Windows export from that exact clean source was checked as PE32+ x64 and ZIP integrity-tested. Running its embedded PCK through the Linux Godot engine passed **all 108 checks**, confirming the packed models/scripts/resources load and execute. This is not native Windows execution. Durable download provenance/checksums are in `releases/BUILD_INFO.md`.

## MEGACLONK menus/loadouts — 2026-10-23

The existing **108 checks** and **55 new checks** pass (**163 total**). New coverage includes V1→V2 profile migration, credits/quest gold, slot purchases/account levels, idempotent quest and content purchases, enabled pools, starting-weapon exceptions, complete leaderboard loadouts, exact four-button menu/four nearest progress cards, loadout selection, all five trait mechanics, three ultimate effects/cooldowns/expiry, paused timers, real glide descent, fog/reveal, shop prices/sold state, cliff edges, active-run cooldown/minimap persistence, locked-detail effect privacy, grouped screens, Escape navigation, overtime scaling and corrupt-profile fallback.

All three suites also pass against the local Windows executable's embedded PCK using the Linux engine. This verifies packed scripts/font/models/resources; it is **not native Windows execution**. The local export is PE32+ Windows x86-64 and ZIP integrity-tested.

Ten UI screens were captured in a rendered Mesa llvmpipe compatibility run and viewed: home, Play, Unlocks, Quests, Settings, HUD/minimap, level-up, inventory, shop and reward. Rendered inspection led to fixes for floating preview placement, clipped collection layouts and invisible progress tracks. Only the expected virtual-display V-Sync warning remained. Target-PC FPS and native Windows playtesting remain outstanding.

GitHub Actions run **39995928415** successfully imported, tested, exported Windows and uploaded artifact **12519956438** from source commit `4d77747`. Final package/source provenance is recorded in releases/BUILD_INFO.md. Requested third-party assets remain blocked and unverified; see docs/ASSET_ACCESS.md. The only new downloaded font is the author's verified CC0 Pixelated Elegance temporary substitute, not Kurland.

Final documentation/package source `a2051f2` passed Actions run **39996662829**, which uploaded unexpired artifact **12520336253** (39,187,545 bytes; upload step and digest verified through GitHub). The durable ZIP is separately exported from that same clean source, includes licence/access/menu notes, and passed ZIP integrity checks. The requested itch.io asset integration remains incomplete; no native Windows execution claim is made.

## Stage-loop foundation — October 23, 2026

Baseline on user upload commit `04a6722`: 163 passing checks. Added stage clock,
portal/travel/save tests, a changed automatic-boss regression plus explicit
portal summon check. Four-suite result: 203 passing checks (31 integration, 78 overhaul,
55 menu, 39 stage). Old suite checks intentionally retain the previous economy
and ability values; passing them does not claim the new specification is complete.

Rendered validation uses Mesa llvmpipe/OpenGL compatibility via Xvfb. Inspected
Jacob's textured loadout preview and HUD plus dormant/exit portal views. First
pass exposed missing FBX atlas references; explicitly bound the supplied images.
Shared material caching also removed GLES material-lifetime errors during repeated
menu/world teardown. Supplied Idle and additive pose state checks run headlessly.

The 400-enemy CPU-only simulation measured 16.14ms/tick on the baseline and
9.27ms/tick in the first modified run. These are single cloud-host observations
with variable contention, not a controlled speedup or desktop 60FPS certification.
Native Windows execution, hardware GPU performance and full human movement
playtesting remain outstanding.

Foundation delivery: clean source `1f1a762`, successful CI run 40011031526,
artifact 12526556411 (41,219,587 bytes). Final Windows ZIP integrity checked
with 15 files including the stage guide and supplied-asset licences. Final
export's embedded PCK also passes 39 stage-loop checks; the same runtime's
full 203-check packed-resource run passed before the guide-only packaging change.
See releases/BUILD_INFO.md for checksums and publication evidence.

## Core milestones and combat feedback — current update

Baseline:203 prior checks. Current suites:31 integration,78 overhaul,55 updated menus,
39 stage loop and112 milestone checks =315 checks. Updated menu expectations explicitly
cover the requested silver wallet/250–750 prices, initially available abilities and revised
trait/ultimate values. New tests verify source assets,30 terrain seeds, weapon pool eligibility,
overkill-free DPS, red-flash triggers, effect caps/recycling, actual boss attack damage/dodging,
three Soul Barrage waves, single-hit dash, consumed-shop save/load and legendary item behavior.

Rendered output inspected under Mesa llvmpipe OpenGL compatibility: imported forest/Jacob,
red player/enemy flashes, PSX explosions/sparks, both boss models and simultaneous bars,
build/silver/shop screens. Actual1920×1080 and2560×1440 captures were inspected and scale
with the reference layout. No shader/script errors in that inspection; the first run's shader
cache miss recompiled successfully. Automated rendering is not a claim of human playtesting.

400-enemy CPU-only observations: prior baseline16.14ms/tick; modified runs8.07ms,9.04ms and11.92ms.
Variable cloud contention means these are observations, not a controlled speedup. Animation
remains instanced/throttled; props are batched; projectiles/flipbooks pooled; visual caps24
flipbooks/3 electric emitters (reduced mode6/no electric). Desktop-GPU60FPS certification,
native Windows execution and long human balance playtests remain unverified.

Core delivery: clean source b7ccae74ed26b4a39e0adc76d5508d43985b42fe; CI run40023925327
succeeded and published artifact12532156289 (59,747,426bytes,unexpired). All315 checks also
pass against the Windows executable's embedded PCK using Linux Godot. The durable repository
ZIP is70,048,168bytes with19 files and verified ZIP integrity; source/digests are in
releases/BUILD_INFO.md. This is resource validation, not native Windows execution.
