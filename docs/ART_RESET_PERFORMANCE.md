# Art reset 10 — performance evidence

Same cloud environment, headless Godot4.7.2. CPU microbenchmarks are not native Windows or gaming-GPU FPS. Raw v9 baseline: releases/REWARDS_V9_CPU.json. Raw art reset: releases/ART_RESET_CPU.json. Script: tools/art_reset_profile.gd. Scope is enemy AI/contact/crowd/grid, FX and HUD, with new portal wind simulation included. Source profile uses normal four-weapon capacity, not a fictional ten-equipped run.

| Enemies | v9 mean ms | v10 mean ms | v10 p95 ms | v10 worst ms |
| --- | --- | --- | --- | --- |
| 50 | 3.20 | 3.25 | 4.08 | 5.44 |
| 100 | 8.00 | 7.08 | 8.71 | 13.01 |
| 250 | 19.86 | 21.65 | 26.43 | 40.76 |
| 500 | 38.55 | 37.15 | 42.30 | 67.05 |

The 250-enemy mean increased about9%; 500 worst increased from48.31 to67.05ms. This is a material tail-latency limitation despite a similar 500 mean. A preceding v10 sample had33.40ms mean/58.70ms worst at500, illustrating host/workload variance; neither run justifies an optimization claim. Stable60FPS is **not** achieved at250–500 enemies in this CPU workload.

Eight bosses plus15 lesser Golems:1.38ms mean,2.08ms p95,3.08ms worst CPU in this short fixture. Four simultaneous fire/lightning/orbit/revolver weapons with80 targets:4.22ms mean,5.20ms p95,7.94ms worst. Stage rebuilds measured396/434/454ms versus prior361/357/314ms: extra imported scenery, portal and guidance incur transition cost. Loading banners remain; resource caches avoid repeated texture imports. These are synchronous stage setup measurements, not full live traversal frame traces.

Added FX use eight prewarmed effects and fixed particle budgets; wind uses64 local guidance instances,96 portal instances and64 GPU ambient particles. Guidance shares one portal flow field, with cheap per-particle neighbor lookups and30Hz updates. No particle collision, per-particle pathfinding, per-hit material creation or independent particle Nodes were added.

Software-rendered validation uses Mesa llvmpipe under Xvfb. It verifies actual models/materials/particles but does not establish target desktop performance. Native Windows, gaming-GPU frame pacing, audio and dense live weapon/boss encounters remain required local playtests. Full render timings, if available, are supplemental and cannot replace that gate.

Actual Mesa llvmpipe compatibility rendering measured mean viewport sample times of313/405/710/1089ms for50/100/250/500 enemies, with worst349/475/1066/1197ms. Eight bosses plus15 minions measured310ms mean/443ms worst viewport time. This software rasterizer is unsuitable for target FPS certification; results demonstrate the workload rendered and expose its cost on this host. Raw data: releases/ART_RESET_MESA.json. Four-weapon CPU fixture is measured separately between rendered samples, so its metric is CPU-only. These short deterministic fixtures do not cover every live multi-boss/weapon overlap.
