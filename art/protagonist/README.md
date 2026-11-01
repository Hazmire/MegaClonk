# The Investigator

Original male protagonist for a 1990s Appalachian horror game: a dark brown duster
coat, a dark broad-brimmed felt hat, and a completely featureless shadowed face.
This revision uses dense, smoothly shaded surfaces, rounded garment edges, and
continuous sleeves and trouser legs. The hat sits 7.5 cm lower, with the front
brim curved downward to conceal more of the face and deepen the shadow beneath it.
The coat, boots, gloves, analog belt radio, and small document pouch keep the
design practical and understated. There are no eyes, nose, mouth, ears, face
textures, visible insignia, futuristic equipment, or modeled weapons.

The restrained palette and anonymous silhouette suit an investigator arriving
after the emergency broadcasts, crossing farmland, and entering the compromised
underground research facility. The model does not assign him a specific agency
or reveal his identity.

The exported character has **196,248 triangles, 28 bones, eight material surfaces,
and one skinned mesh**. These counts exclude the studio and presentation text.

## Included

- `Investigator.blend`: editable character, skeleton, materials, UVs, ten actions,
  camera, and presentation lighting. Blender 4.3 or newer.
- `Investigator_Turnaround.blend`: front, three-quarter, and rear presentation.
- `../../assets/characters/investigator/Investigator.glb`: self-contained skinned
  export containing the character and ten animation clips.
- `../../assets/characters/investigator/manifest.json`: geometry counts, scale,
  bounds, orientation, and animation durations.
- `../../assets/characters/investigator/*validation.json`: successful GLB binary,
  skin-weight, animation-loop, and Godot 4.7.2 import/playback checks.
- `../../docs/images/protagonist/`: portrait, turnaround, and animation previews.
- `../../docs/images/protagonist/animations/Investigator_Animations.mp4` and
  `.gif`: labeled playback of the six requested motions. The pose sheet is
  `Investigator_Animation_Poses.png` in the same directory.
- `generate_investigator.py`: standalone procedural source; no downloads,
  external images, models, or add-ons are required.

## Rig and animation

The rig has a root, hips, spine, chest, neck, head, clavicles, arms, hands, thighs,
shins, feet, and eight coat-tail bones. The coat panels use blended weights and
hand-keyed movement; they do not require cloth simulation. Gloves have modeled
fingers bound to the hands, without individual finger controls. The face has no
facial rig because it is intentionally featureless.

| Clip | Duration | Use |
| --- | --- | --- |
| Idle | 3 seconds | Subtle breathing and coat movement; loop |
| Walk | 1⅓ seconds | Planted stance feet and alternating steps; loop |
| Jump | 1½ seconds | Anticipation, takeoff, airborne tuck, landing and recovery |
| Crouch | 2 seconds | Held crouch with breathing; loop |
| CrouchEnter | ½ second | Stand to crouch |
| CrouchExit | ½ second | Crouch to stand |
| Slide | 1¼ seconds | Low slide pose with one leg extended; returns to crouch |
| CriticalWalk | 2 seconds | Slow uneven limp, hunched torso, lowered head, hand bracing abdomen; loop |
| Run | 1 second | In-place running; loop, retained from the earlier pack |
| Interact | 1⅔ seconds | Right-hand reach and recovery; play once |

All clips are keyed at 24 fps. Configure looping for Idle, Walk, Run, Crouch, and
CriticalWalk in your engine; glTF does not standardize looping flags. The other
clips play once. The feet use baked two-bone solves, so no runtime IK or
constraints are required. Coat panels follow the solved legs to reduce clipping
in the bent poses. The supplied clips are simple starting animations, without
weapon handling or combat actions.

All clips keep the root bone stationary. Apply walking and sliding travel through
your game controller. Suggested starting speeds at the supplied scale are
0.85 m/s for Walk, 0.35 m/s for CriticalWalk, and 1.8 m/s for Run; tune these to
your controller and blend settings. Switch/blend into CriticalWalk using your
game's low-health condition; the asset does not impose an HP threshold.

Jump includes a **0.42 m local hip arc**, while the root remains stationary.
Anticipation runs to about 0.36 s, the airborne portion ends around 1.11 s, and
landing/recovery completes at 1.5 s. Match the controller to this timing, or edit
the Jump hip-translation channel when a physics controller supplies the height.

The crouch sequence is `CrouchEnter → Crouch (loop) → CrouchExit`.
For sliding, play `CrouchEnter → Slide → Crouch`; release crouch with CrouchExit.
The transition endpoints match, including the coat and feet. Animation previews
show the clips in place, so Slide demonstrates the pose rather than world travel.

In Blender, choose a clip in the Action Editor and use its action frame range
for playback: all clips start at frame 1, and the final frame is
`duration × 24 + 1` (Walk: 33, Jump: 37, Crouch/CriticalWalk: 49, Slide: 31).

The Blender mesh retains `PART | ...` vertex groups so you can select individual
garment elements after joining. The eight standard material slots cover the coat,
weathered cloth edges, lining, felt, shirt/trousers, leather, face shadow, and
hardware. Materials use exportable colors; no texture files are required. UVs
are included for later texturing. The studio collection is excluded from the GLB.

## Import

One Blender unit equals one metre. The origin is on the ground between the feet.
Blender uses Z up / -Y forward; the GLB uses Y up / +Z forward. The hat brings the
total height to approximately 2.02 metres; scale the root if your game uses a
different character height.

Import the base GLB in Godot, Unity, Unreal, or another glTF-compatible tool.
The game now uses a separate `Investigator_Gameplay.glb` export with fitted low
poses and physics-driven jump height. See `../../docs/INVESTIGATOR_PLAYER.md` for
the live controller mapping and validation. Rebuild that runtime variant with:

```sh
blender --background --threads 8 --python-exit-code 1 --python art/protagonist/build_gameplay_asset.py
```

## Rebuild

From the repository root:

```sh
blender --background --threads 8 --python art/protagonist/generate_investigator.py
```

To refresh just the animations and export without rebuilding the model:

```sh
blender --background --threads 8 --python art/protagonist/animate_investigator.py
```

`animation_clips.py` contains the motion definitions. Run
`validate_animation_motion.py` in Blender to verify loop seams, planted feet,
floor clearance, matching crouch/slide transition endpoints, and the requested
lowered/airborne poses. `preview_animations.py` renders the six requested clips.
`python art/protagonist/encode_previews.py` builds the labeled video, GIF, and
pose sheet from those frames; this optional preview step uses Pillow and ffmpeg.

This overwrites the generated Blender files, GLB, manifest, and previews. Copy
hand-edited files elsewhere before rebuilding.
