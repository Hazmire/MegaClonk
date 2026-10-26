# Performance / traversal / presentation release

Retain Godot4.7.2 and all current gameplay. Source baseline e21aaa9; uploaded SourceCode.zip adds
BinbunGrass shaders/textures. Inspect/profiling precedes production changes.

- [x] Profile idle/moving/25/100/250 enemies, weapons, repeated hits, deaths, AOE, bosses and elites; frame percentiles and work attribution.
- [x] Remove measured hit/death allocations/loading; bounded pools, aggregation and exact reward checks.
- [x] Add gravity-based cliff drops with validated landings and exclusive climb/fall states.
- [x] Evaluate uploaded grass shader, world-space forest floor and cliff material, instanced grass budget.
- [x] Inspect rig compatibility; one simple idle/move/jump/slide animator, retain physical crouch.
- [x] Audit all36 weapons; themed pooled effects, Chunkers stone/debris at damage positions.
- [x] Before/after profiling, regression/render inspection, source commits and verified Windows delivery.

Rendering tests use software OpenGL in this cloud; report its frame timings as software-rendered,
not Windows/gaming-GPU FPS. Audio Dummy cannot establish audible audio performance.

Known remaining verification: native Windows/audio and gaming-GPU60FPS. Mesa shutdown retains two texture handles; documented, not claimed fixed.

Functional work and local validation complete; Windows publication verification is the remaining delivery step.
