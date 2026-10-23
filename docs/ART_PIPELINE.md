# Original low-poly asset pipeline

No external model editor is required to run or build the project. Committed native Godot `.res` meshes and `fox_scout.tscn` are included in exports. Original geometry is generated from the source in `scripts/art/model_builder.gd` and `tools/generate_models.gd`:

```sh
tools/godot.sh --headless --path . --editor --import --quit
tools/godot.sh --headless --path . --script tools/generate_models.gd
tools/validate.sh
```

The Fox Scout is a separate pivot rig with hips, torso, head/scarf/tail, arms and legs. `ScoutVisual.animate` is a blended pose state machine driven by the controller's actual grounded state, horizontal velocity, posture, turning, damage and death. Physics capsules and camera are not part of the model. The current model is reused by the playable roster; individually tailored art for the other 20 characters remains future work.

Enemy body geometry uses baked vertex colours and shared materials. `EnemyCatalog` separates configuration from behaviour; `EnemySimulation` combines modules; `RunEnemyVariants` owns per-run selection; `EnemyView` renders shared MultiMeshes, procedural poses and distant merged meshes. No per-enemy Skeleton3D, NavigationAgent or CharacterBody is created. Deaths briefly retain a budgeted mesh with fall/shrink animation.

To add a variant, add its data and independent geometry to the generator and regenerate/commit the assets. A new character scene can reuse the pivot names or implement the same `animate(state, speed, delta)` interface. Godot import and Windows export require only committed resources; the generator is a development tool, not a runtime dependency.

These are stylized original models with simplified procedural animation. Detailed skeletal animation, authored multi-part enemy attacks, individual playable-character art, and further modelling polish remain beyond this milestone.
