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
