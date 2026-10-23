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
