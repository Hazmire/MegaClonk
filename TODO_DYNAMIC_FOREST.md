# Dynamic Forest update

Work on `megaclonk-menu-loadouts`; retain Godot4.7.2 and existing progression/combat.
Baseline: previous clean Forest release passed335 assertions and two100-seed suites. New remote
commits only add three source asset archives; no runtime code changed.

- [x] 1. Varied region geometry/graphs, peripheral spawn, 100-seed distribution and ten rendered seeds.
- [x] 2. Inspect/fix Ranger stride, arm motion and velocity synchronization without changing physics.
- [x] 3. Inspect new skeleton packs; Basic75%, Special20%, Large5%, per-spawn visual/behaviour selection.
- [x] 4. Independent emergence effects, immediate pursuit, collision-checked cliff climbing with fallback.
- [x] 5. One-use elite statues, three marked melee elites, persistent state and exactly-once gold reward.
- [x] 6. Big Chunkus captured delayed AOE; Rock Golem capped summons; preserve portal/stage rules.
- [x] 7. Regression, rendered inspection, profiling, committed source and verified Windows publication.

New specification supersedes the earlier eight-archetype active pool and per-run ordinary variants.
Legacy configurations/save migration remain where useful; elites/bosses never enter ordinary selection.

Delivered source6e80a8e; successful CI40246044493; release `dynamic-forest-v3`.
382 gameplay assertions and three100-seed suites pass. Rendered examples and CPU results are in VALIDATION.md.

Final follow-up: keep elite statue in a separate region from portal/spawn and test the actual prompt.

Final corrected delivery: source d5be3a4, CI40246730637, release `dynamic-forest-v3.1`;383 gameplay assertions and all100-seed checks pass.
