# Grimdark performance verification

Measured in isolation on the restored cloud host using tools/art_reset_profile.gd, Godot4.7.2. CPU timings cover AI/contact/crowd/grid, FX, HUD and portal wind. Rendered timings include Mesa llvmpipe software rendering, not a gaming GPU or native Windows.

| Enemies | Previous recorded CPU mean (ms) | New CPU mean / p95 (ms) | Software-rendered frame mean (ms) |
| --- | ---: | ---: | ---: |
| 50 | 3.25 | 3.53 / 4.64 | 112.35 |
| 100 | 7.08 | 7.27 / 9.24 | 157.66 |
| 250 | 21.65 | 19.14 / 22.68 | 304.45 |
| 500 | 37.15 | 36.88 / 42.27 | 496.39 |

CPU cost at500 enemies is essentially unchanged within host variability, and still exceeds the16.7ms60FPS budget. The previous measurement is a recorded baseline, not a simultaneous controlled hardware test. No stable60FPS or native Windows certification is claimed.

Stage setup: [515.6, 481.8, 393.4]ms for stages1/2/3. Four-weapon update mean: 5.08ms. Multi-boss case: 8 bosses, 15 lesser golems, 1.61ms mean CPU.

Preserved: shared animated MultiMeshes, distance animation detail, spatial/crowd simulation, pooled projectiles/FX/corpses, shared materials, instanced props, distance-culled ground cover and shadow-free boundaries. World renders once at retro resolution with full-resolution HUD. Shared precision uniforms avoid the instance-buffer overflow found during development.

Known rendered-host limitation: several small5460-byte texture-leak diagnostics appear during process shutdown under Mesa/Godot after repeated stage rebuilds. Rendered runs finish and exit successfully, with no shader compilation or instance-buffer errors. These shutdown diagnostics remain unresolved and have not been verified on Windows. They are not hidden or treated as native-platform certification. Headless validation and compiled export checks contain no error markers.
