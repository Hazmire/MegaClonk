# Combat performance evidence

Same cloud machine, pinned Godot4.7.2, same driver/scenarios. CPU:80 samples per scenario; software OpenGL:40. With these small samples, empirical P99 can equal the worst observation; this is diagnostic evidence, not a statistical FPS certification. Raw JSON includes mean/P95/P99/worst for frame, script work, hit/death and engine physics, plus FPS derived from measured frame durations, peak draw calls/nodes/memory/flipbooks/pickups/numbers.

The controlled driver manually advances combat while normal game physics is paused. `script_work` isolates that workload; it is not the entire normal game loop. The engine physics monitor excludes manually driven enemy AI. Initial physics-monitor samples can still include scene loading. The moving case moves the player in a small area with a fixed camera; it is not a traversal/streaming benchmark. Boss/elite cases cover their visible pursuit entities; ability logic is checked in gameplay tests. Audio is Dummy, so audible/WASAPI cost is not measured.

Headless frame durations include process scheduling. Software rendering is Mesa llvmpipe at1280×720 and is heavily GPU/software-bound (roughly1–3FPS); those FPS figures must not be presented as gaming-PC results. The after run includes the requested richer ground/grass/sky/fog and stone geometry.

## Controlled CPU work and death stalls

These final CPU runs were repeated sequentially with no other game/render process: a detached baseline checkout at3d4e287 and the updated project, using the same driver. The isolated death batches measured314.122/314.502ms before and0.402/0.869ms after. Initial traces (also retained) measured392/322ms before. Pooling keeps additional idle nodes/resources; the memory and node counts disclose that tradeoff.

| Scenario | Work P99 before ms | Work P99 after ms | Death worst before ms | Death worst after ms |
|---|---:|---:|---:|---:|
|aoe250|322.319|8.044|314.502|0.869|
|boss|0.108|0.130|0.002|0.002|
|continuous_weapons|4.003|4.675|0.025|0.013|
|deaths100|316.966|13.836|314.122|0.402|
|elite|0.298|0.193|0.003|0.002|
|enemies100|2.696|3.429|0.027|0.014|
|enemies25|0.838|1.053|0.004|0.006|
|enemies250|6.898|7.713|0.071|0.042|
|grass_off|0.128|0.054|0.001|0.001|
|idle|5.334|3.580|0.001|0.001|
|moving|5.168|5.110|0.001|0.001|
|repeated_hits|2.975|4.799|0.012|0.033|
## Actual software-rendered frames

These are observational cloud traces rather than a hardware qualification. Other visual/validation work may affect individual outliers. Use the isolated CPU runs for the strong death-pipeline conclusion; actual Windows frametimes remain unestablished.

| Scenario | Mean before/after ms | P95 before/after ms | P99 before/after ms | Worst before/after ms | FPS before/after |
|---|---:|---:|---:|---:|---:|
|aoe250|450.4/487.6|746.3/881.2|1159.6/924.8|1159.6/924.8|2.22/2.05|
|boss|375.9/392.3|396.4/423.0|424.0/451.7|424.0/451.7|2.66/2.55|
|continuous_weapons|504.2/488.2|562.5/525.4|581.6/551.1|581.6/551.1|1.98/2.05|
|deaths100|414.9/413.4|507.7/505.8|884.2/511.1|884.2/511.1|2.41/2.42|
|elite|376.3/392.1|421.0/423.7|463.1/427.6|463.1/427.6|2.66/2.55|
|enemies100|520.9/522.1|570.7/556.2|582.4/563.6|582.4/563.6|1.92/1.92|
|enemies25|409.3/447.1|439.3/568.4|463.0/577.3|463.0/577.3|2.44/2.24|
|enemies250|770.4/756.7|842.6/829.6|873.8/852.7|873.8/852.7|1.30/1.32|
|grass_off|308.0/318.8|345.2/346.4|380.5/351.9|380.5/351.9|3.25/3.14|
|idle|372.3/388.0|413.7/438.3|429.8/467.7|429.8/467.7|2.69/2.58|
|moving|371.3/398.2|411.3/444.8|414.1/452.5|414.1/452.5|2.69/2.51|
|repeated_hits|515.1/545.6|578.3/607.2|596.3/614.8|596.3/614.8|1.94/1.83|

## Causes and changes

- Measured synchronous corpse preparation dominates the original mass-death stall: repeated `load(variant.model)`, imported mesh/material setup and creating a material only to discard it. Cached living-frame meshes and pooled corpses remove that path.
- Common hit/crit/slash/tracer geometry was generated repeatedly; cached unit meshes now scale/rotate into place. Common projectile resources and flipbooks warm during stage setup.
- Floating Label3D creation/text shaping has been replaced by one capped instanced digit-atlas batch with spatial/time aggregation. The experimental intermediate pooled-label measurement is not used as the final number architecture.
- XP is merged spatially, preserving the total value. Gold remains immediate and unchanged. Corpses and particles are cosmetic-budgeted; dead entities and important boss/elite outcomes are handled immediately.
- No per-enemy physics node or NavigationAgent is deleted on death: enemies were already dictionary simulation/MultiMesh batches. Navigation rebuilds remain stage-only. Sound clips were already preloaded/throttled; the two hot explosion paths now use that bank instead of synchronously synthesizing thousands of WAV samples per detonation. The audio cost itself is not measured under Dummy audio. GDScript uses reference counting; no evidence identifies a tracing-GC pause.

## Remaining limits

- CPU death spikes were removed in these tests; native Windows, target-GPU FPS, driver-specific first-use pipeline compilation and long-session balance still require local playtesting. Average software-rendered frame time is not substantially improved because software rasterization dominates; some P95 values increase with the new requested presentation.
- Mesa compatibility runs report two retained texture handles (~0.67MiB total) at process shutdown after combat. This remains unresolved. Headless tests/export pass and rendered gameplay has no script/load errors, but the shutdown diagnostic must not be described as an error-free renderer run.
- Concurrent automated windows can produce an Xvfb pointer-grab diagnostic. The visual/profile driver now leaves the pointer visible to avoid competing grabs; normal single-window Windows behaviour is untested.

Reproduce with `tools/godot.sh --headless --path . --script tests/combat_profile.gd -- --out=res://builds/profile.json`; run the same script under Xvfb/OpenGL for rendered timings. `--only=repeated_hits,deaths100,aoe250` restricts scenarios. Optional live counters are in the sandbox tools.

## Isolated new-wind-grass toggle

Same fresh scene/camera, only the new `wind_grass` batches toggled (existing Nature foliage remains). Software mean frame: 364.20ms on / 376.40ms off; peak draw calls 195 / 194. This isolates the added shader geometry on the cloud software renderer; small differences may include scheduling/noise and do not establish a gaming-GPU cost. See wind-toggle.json.
