# Rift Cultist

An original game character inspired by the supplied cultist reference: a tall
pointed hood, recessed dark eye openings with dim red eyes, ash-stained cloth,
wide bell sleeves, an old rope belt, and a weathered red ritual marking. The
face has no exposed nose, mouth, skin, or hair. The chest mark is an original
broken-gate design painted into the robe texture.

The export has **12,908 triangles, 28 bones, seven material surfaces, and two
embedded 512 × 512 textures**. The GLB and all three clips have been imported and
sampled successfully in Godot 4.7.2.

[Download the model pack](https://github.com/Hazmire/MegaClonk/raw/refs/heads/rift-cultist-model/art/cultist/RiftCultist_Model_Pack.zip)

## Included

- `RiftCultist.blend`: editable mesh, UVs, packed textures, a 28-bone skeleton,
  three actions, studio lights, and camera. Blender 4.3 or newer.
- `RiftCultist_Turnaround.blend`: front, three-quarter, and rear presentation.
- `../../assets/characters/cultist/RiftCultist.glb`: self-contained game export
  with the mesh, skin, materials, textures, and all three animation clips.
- `../../assets/characters/cultist/textures/`: two original 512 × 512 base-color
  PNGs, supplied separately for repainting. They are also packed into the native
  Blender file and embedded in the GLB.
- `../../docs/images/cultist/`: rendered portrait and turnaround previews.
- `../../assets/characters/cultist/manifest.json`: geometry counts, scale,
  texture details, and animation durations.
- `generate_cultist.py`: reproducible source, with no external art or add-ons.

The reference image is used as visual guidance only. Its pixels are not used as
a texture or included in the pack. The mesh and weathered textures are generated
from scratch. Nearest texture sampling keeps the grainy appearance of the
reference while the cloth silhouette remains smoothly shaded.

## Rig and motion

The single skinned mesh has separate material surfaces for the robe, hood,
shadow lining/leather, rope, rope fibers, eyes, and gloves. Named `PART | ...`
vertex groups allow selection of garment pieces after joining. Real holes in
the hood reveal recessed red eye surfaces and a dark interior.

The humanoid skeleton includes root, hips, spine, chest, neck, head, clavicles,
arms, hands, legs and feet, plus eight robe-skirt bones. The robe uses blended
skin weights; runtime cloth simulation is unnecessary. Gloves use hand bones
without separate finger controls. There is no facial rig.

| Clip | Duration | Use |
| --- | --- | --- |
| Idle | 3 seconds | Breathing, slight hood and cloth sway; loop |
| Walk | 1⅔ seconds | Slow, planted-foot walking and robe movement; loop |
| Attack | 1¼ seconds | Right-arm reach/lunge with recovery; play once |

Clips are keyed at 24 fps and keep the root stationary. Configure looping for
Idle and Walk in the game engine; glTF does not standardize looping flags.
Game code supplies horizontal travel. These are simple starting clips rather
than a full combat animation set.

## Import and scale

The model uses metres, with its origin on the ground. The pointed hood makes it
approximately 2.3 m tall. Scale the root to suit the enemy's desired size.
Blender uses Z up / -Y forward; the GLB uses Y up / +Z forward. The studio and
presentation text are excluded from the game export. Godot imports the GLB
directly; the native source directory is under a `.gdignore`.

This is a new character asset. The current enemy roster has not been replaced.
The existing game crowd renderer uses baked ArrayMesh animation frames; using
this character in that path requires baking its clips and registering the new
species. The GLB can also be instantiated with a normal Skeleton3D and
AnimationPlayer for an individual enemy.

## Rebuild

From the project root:

```sh
blender --background --threads 8 --python-exit-code 1 --python art/cultist/generate_cultist.py
```

This overwrites the generated character, textures, export, manifest, and previews.
Keep hand-edited versions separately before rebuilding.

Run `python art/cultist/validate_cultist.py` to audit the GLB's geometry, UVs,
normalized skin weights/normals, embedded textures, and looping clips.
`validate_cultist.gd` provides the Godot import/playback check. After validation,
run `python art/cultist/package_cultist.py` to rebuild the downloadable pack.
