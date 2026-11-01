# Playable Investigator

The Investigator now replaces the player and menu-preview avatar. New runs,
continued saves, and stage changes all construct the new visual through the same
avatar factory. The model retains the dark brown duster, lowered dark hat,
featureless face, eight material surfaces, and 28-bone rig.

## Movement and animation

| Gameplay state | Animation behavior |
| --- | --- |
| Stopped / turning in place | Idle |
| Moving slowly | Walk, with speed-adjusted playback |
| Normal fast movement | Run |
| Moving at 25% HP or below | CriticalWalk: hunched, head lowered, hand bracing the abdomen |
| Healing to 30% HP | Normal locomotion resumes; the gap prevents threshold flicker |
| Jump / extra jump | Jump takeoff and ascent follow the actual upward velocity |
| Falling / gliding | Descending / held airborne portions of Jump |
| Landing | Short landing compression before returning to locomotion |
| Crouching | CrouchEnter, held Crouch, CrouchExit |
| Sliding | Slide enters its low pose and holds for the physical slide duration |
| Slide slows to crouch | Slide recovery connects to held Crouch |
| Low overhead clearance | Immediately uses the fitted low pose |
| Death | Held crouched pose |

All ten imported clips remain available, including Interact. Movement keys,
acceleration, momentum, jump impulse, glide rules, damage, health, and camera
controls keep their existing behavior. Low health changes the visual gait.
Damage flashes and temporary ability appearances restore the original materials
when they expire. Animations pause with the player.

## Physics-compatible asset

`assets/characters/investigator/Investigator_Gameplay.glb` is the runtime asset.
Its positive visual jump arc is removed so the CharacterBody3D supplies jump
height once. The authored anticipation and landing compression remain, and the
runtime samples ascent/descent poses according to physics rather than replaying
takeoff while falling.

The visual is uniformly scaled to 1.8 m standing height. The gameplay crouch and
slide use a deeper squat and leg/coat poses, with a measured maximum height of
approximately 0.948 m. This fits the existing 0.95 m crouched capsule without
vertically squashing the character or lowering the boots through the floor.
The artist-facing `Investigator.blend` and original `Investigator.glb` retain
their original, more relaxed animation profile.

`scripts/art/investigator_visual.gd` owns the animation mapping, per-avatar loop
settings, transitions, and damage overlay. `BonkPlayer` supplies physical motion,
clearance, and current health to this visual; animations do not translate the
physics root. Merchant Ranger visuals remain available for their existing use.

## Build and verification

The generated gameplay asset is included in the project. Rebuild it after art
edits with:

```sh
blender --background --threads 8 --python-exit-code 1 --python art/protagonist/build_gameplay_asset.py
```

The authoring source shares `animation_clips.py`, using its gameplay profile.
Measured bounds are recorded in `gameplay_profile.json` alongside the runtime GLB.

`tests/investigator_player.gd` covers actual model instantiation, all ten clips,
loop modes, HP transitions, physics jumping, landing, held slides, crouch/exit,
low clearance, damage/ability materials, pause behavior, and movement input. The
existing stage, traversal, animation, and save/load regressions also exercise the
replacement. `tools/validate.sh` includes the new suite.

Rendered gameplay views are in `docs/images/protagonist/game_*.png`.
The Windows package contains the new model and runtime animation adapter.
Native Windows execution requires Windows playtesting; Linux Godot checks the
embedded exported resource pack.

Verification completed for this update:

- All **23** suites in `tools/validate.sh` passed, including **49** targeted
  Investigator/controller checks and the seeded terrain, combat, reward, and
  save/load regressions.
- The exported Windows pack passed running-world, reward UI, stage/boss,
  Investigator instantiation, ten-clip availability, critical-health animation,
  jump-root, and save/load smoke checks under Linux Godot.
- Seven real Godot/Mesa views captured idle, running, injured movement, crouch,
  slide, jump, and the playable camera/HUD. The software-renderer run completed;
  Mesa/Godot reported two 87,380-byte texture-leak diagnostics during shutdown.
  The headless regression and export checks completed without errors.
