# Current work

See [Forest visual milestone](TODO_FOREST_VISUAL.md) and [implementation guide](docs/FOREST_OVERHAUL.md).
Earlier milestone history follows.

# Gameplay, movement and visual overhaul

Baseline: branch `bonk-infinity-playable`, Godot 4.7.2. Existing 30 checks pass; 400-enemy update + spatial rebuild mean 1.61 ms/tick (headless, rendering excluded).

Inspection: `controller.gd` owns CharacterBody movement/camera; `game.gd` owns spawning, eight regular kinds (melee, fast, tank, ranged, charger, flying, explosive, shielded), Warden, combat, procedural terrain and UI. Data lives in `catalog.gd`, pooling in `mesh_pool.gd`, profiles in `progress.gd`. Models are generated primitive meshes; enemies share one MultiMesh. No Actions workflow exists; export presets and scripts already build Windows x64. Preserve all 36 weapons, progression, stages and existing tests.

- [x] Movement: remove sprint input/state; rebindable Ctrl crouch; physical slide, slopes/steering/jump chaining; ceiling clearance; automated physics checks.
- [x] Player: separate original animated model and pose state machine; idle/run/turn/jump/fall/crouch/slide/hit/death.
- [x] Variants: data-driven definitions and deterministic, serializable per-run registry; two variations for all eight existing regular archetypes.
- [x] Enemy AI: shared wind-up/recovery, projectiles, charges, slams, stationary attacks and exactly-once proximity/death explosions.
- [x] Enemy art: original committed geometry, distinct silhouettes, batched animated rendering, hit/death/attack feedback.
- [x] Combat art: recognizable pooled projectiles, trails, arcs, impact/status feedback with budgets.
- [x] Environment: preserve seeded terrain; improve cohesive foliage/rocks/ruins and collision.
- [x] Testing: baseline comparison, movement/variants/AI regression suite, rendered inspection, Windows export.
- [x] Delivery: portable installer/wrapper, GitHub Actions validation/export/artifact workflow; commit/push; verify workflow publication and artifact availability or report precise permission blocker.

Research: initial attempt at megabonk.wiki/wiki/Enemies returned 503; Quaternius, Kenney and poly.pizza requests were proxy-blocked (403). No external asset or undocumented game mechanic is assumed verified. Use original generated models if access remains blocked; maintain credits and research provenance.

Milestone checks: original 30 regression checks and 78 new movement/variant/AI/save checks pass. Model generation produces committed original native Godot meshes/scenes. Rendered inspection and delivery remain in progress.

GitHub delivery: PR #1 created against `Full-Release`. The corrected workflow has already run successfully and uploaded a 37 MB Windows artifact. Final source commit `0074f48` passed CI run 39978727835, which published artifact 12511519962. The durable repository ZIP has been refreshed from a verified local export of the same clean source. No native Windows or target-GPU FPS claim is made. Further work is listed in docs/STATUS.md.
