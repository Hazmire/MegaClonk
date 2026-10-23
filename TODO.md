# Gameplay, movement and visual overhaul

Baseline: branch `bonk-infinity-playable`, Godot 4.7.2. Existing 30 checks pass; 400-enemy update + spatial rebuild mean 1.61 ms/tick (headless, rendering excluded).

Inspection: `controller.gd` owns CharacterBody movement/camera; `game.gd` owns spawning, eight regular kinds (melee, fast, tank, ranged, charger, flying, explosive, shielded), Warden, combat, procedural terrain and UI. Data lives in `catalog.gd`, pooling in `mesh_pool.gd`, profiles in `progress.gd`. Models are generated primitive meshes; enemies share one MultiMesh. No Actions workflow exists; export presets and scripts already build Windows x64. Preserve all 36 weapons, progression, stages and existing tests.

- [x] Movement: remove sprint input/state; rebindable Ctrl crouch; physical slide, slopes/steering/jump chaining; ceiling clearance; automated physics checks.
- [x] Player: separate original animated model and pose state machine; idle/run/turn/jump/fall/crouch/slide/hit/death.
- [x] Variants: data-driven definitions and deterministic, serializable per-run registry; two variations for all eight existing regular archetypes.
- [x] Enemy AI: shared wind-up/recovery, projectiles, charges, slams, stationary attacks and exactly-once proximity/death explosions.
- [x] Enemy art: original committed geometry, distinct silhouettes, batched animated rendering, hit/death/attack feedback.
- [ ] Combat art: recognizable pooled projectiles, trails, arcs, impact/status feedback with budgets.
- [ ] Environment: preserve seeded terrain; improve cohesive foliage/rocks/ruins and collision.
- [ ] Testing: baseline comparison, movement/variants/AI regression suite, rendered inspection, Windows export.
- [ ] Delivery: portable installer/wrapper, GitHub Actions validation/export/artifact workflow; commit/push; verify workflow publication and artifact availability or report precise permission blocker.

Research: initial attempt at megabonk.wiki/wiki/Enemies returned 503; Quaternius, Kenney and poly.pizza requests were proxy-blocked (403). No external asset or undocumented game mechanic is assumed verified. Use original generated models if access remains blocked; maintain credits and research provenance.

Milestone checks: original 30 regression checks and 73 new movement/variant/AI/save checks pass. Model generation produces committed original native Godot meshes/scenes. Rendered inspection and delivery remain in progress.
