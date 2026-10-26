# Vertical Forest performance and regression evidence

Godot 4.7.2, cloud Linux. CPU measurements are headless; rendering measurements use Mesa llvmpipe software OpenGL at 1280×720 with Dummy audio. These results do not establish gaming-GPU 60FPS or native Windows behavior.

## Stage setup

Twenty seeds per generator, executed sequentially in one process after warming shared models/materials. Each sample clears the layout cache. Deferred destruction of the previous world runs between samples; its later cleanup cost is outside synchronous assembly time. The static floor-noise texture, instancing, shared models and stage-only navigation are retained.

| Mean synchronous stage phase | Legacy v3 | Vertical v4 |
|---|---:|---:|
| Layout and eligibility generation | 59.79ms | 75.27ms |
| Terrain mesh + collision | 102.95ms | 104.42ms |
| Environmental props | 8.43ms | 7.57ms |
| Grass setup | 2.92ms | 2.69ms |
| Native navigation + flow field | 73.10ms | 73.98ms |
| Whole stage assembly | 252.17ms | 268.93ms |

Median assembly: 251.73 → 267.82ms; worst: 267.43 → 282.30ms. The mean increase is **16.76ms / 6.65% once per stage**, principally layout work, not per enemy death. No terrain/nav rebuild was added to combat. [All 40 samples](world/generation-profile.json).

## Combat

Sequential 80-tick cases using the existing manual combat profiler, with a valid flat combat patch selected separately in each terrain. Camera/origin differs because terrain differs; this is a workload comparison, not identical rendered scenes. Assets and pools retain their existing prewarm behavior. Spawned enemies are aligned to actual terrain. Damage values, upgrade scaling and death rewards remain unchanged.

| Workload | Legacy v3 | Vertical v4 |
|---|---:|---:|
| 250 enemies: mean manual tick | 5.759ms | 5.578ms |
| Four continuous weapons: mean manual tick | 2.549ms | 2.440ms |
| 100 simultaneous deaths: worst death-processing block | 0.385ms | 0.362ms |
| 250 simultaneous deaths: worst death-processing block | 0.982ms | 0.890ms |

This shows no significant regression in these sampled CPU workloads. **The entire manual tick is not always below 16.7ms**: the 100-death scenario peaked at 21.913ms legacy and 18.546ms vertical, including other hit/AI/FX/XP/UI work. Do not describe the sub-1ms death block as an end-to-end frame guarantee. No controlled cause is claimed for the remaining total-tick peak. Engine physics counters exclude the manually advanced AI.

Raw [legacy](world/combat-legacy.json) and [vertical](world/combat-vertical.json) reports include mean/p95/p99/worst values, memory, nodes, effects and XP counts. Eighty samples give coarse tail estimates. Headless process-frame rates are not rendered game FPS.

## Clouds, fog and wind grass

Frozen seed-9 scene and camera; two warmup frames, then 20 process-frame samples per case, sequentially. Small samples and software-renderer scheduling make these observations unsuitable for attributing small differences to a single effect.

| Software-rendered case | Mean frame | Worst | Peak draw calls |
|---|---:|---:|---:|
| Gradient sky, fog and grass | 286.36ms | 323.07ms | 211 |
| Cloud sky, fog and grass | 290.92ms | 312.03ms | 211 |
| Cloud sky, fog disabled | 293.48ms | 338.89ms | 211 |
| Cloud sky, wind-grass batches hidden | 290.91ms | 322.34ms | 209 |

This machine renders this view at roughly **3.4FPS**, not 60FPS. Clouds have no TIME-driven radiance update, no volumetric passes and use a 128px radiance map. Fog is ordinary distance fog. Grass remains sparse instanced cutouts with bounded visibility, not individual physics objects. The small fog/grass differences are within the observed frame variation; no speedup is inferred. P95 equals worst for 20 samples under this profiler's indexing. [Raw observations](world/atmosphere-software.json).

## Validation and inspection

Fourteen suites pass: 605 assertions, 70 ordinary/elite/boss cliff-drop cases and 200 matching seeds for deterministic geometry and decorated physics/navigation/placement. The world suite performs 9,914 collision rays and 1,000 actual interactions (shop purchase, chest opening, charge-shrine completion, elite activation, boss portal activation), with no failures or repairs. The live reward tests reset each world's economy so chest-price accumulation does not invalidate affordability.

Old combat tests use the legacy seed-9 flat patch to isolate weapon/progression behavior from terrain changes. New-world coverage includes player/enemy ramps, 24m+ climbs, 12/24/36m drops, damage while falling, ramp landings, high-plateau boss telegraphs/damage, near-target cliff probes, checkpoint object/geometry preservation and future-version rejection. Twelve actual seed renders plus two atmosphere views were inspected; overview fog is explicitly disabled only in debug captures.

XP gems, confetti, chest roulette and redesigned reward UI have not been implemented in this increment, so no new performance claim is made for them. They remain in the next milestones.

## Known limits

- Native Windows execution, audible audio and gaming-PC GPU performance need local playtesting.
- Mesa software OpenGL reports **four retained sky texture handles of 87,380 bytes each at shutdown** in these render fixtures. This replaces the prior observed two larger handles; the underlying diagnostic remains unresolved. No claim is made that there is no runtime resource leak. Gameplay rendering produced no shader/script/resource-load errors.
- Generation and collision tests validate the default settings on 200 seeds; they do not prove every possible designer configuration or every seed. Region drafting has a bounded retry budget and records attempt counts. No flattening/decoration repair occurred in the reported defaults.
- The terrain is stylized piecewise-planar geometry with cell-aligned outlines; it is not an organically sculpted high-resolution landscape. Four bands and region/route variation are measured, not a claim to reproduce Megabonk's exact geometry.
