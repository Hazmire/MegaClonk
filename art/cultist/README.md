# Rift Bellkeeper

An original cultist character with a hooked, off-centre charcoal-green cowl,
two recessed red eyes behind separate hood openings, and an uneven ragged
shoulder mantle. A repaired,
split ash-linen robe opens over a dark inner tunic. Mismatched sleeves, ochre
stitch circles, a diagonal leather harness, and a suspended iron censer give
this revision its own silhouette and ritual-worker identity. The face stays
completely concealed.

The export has **17,162 triangles, 28 bones, nine material surfaces, and two
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

This third revision retains the Bellkeeper design, restores its two red eyes,
and refits the garment layers, arm motion, and accessories for clearance.
The mesh and weathered textures are
generated from scratch; no reference pixels or external art are included.
Nearest texture sampling retains a grainy finish while the cloth remains
smoothly shaded. Existing `RiftCultist` filenames are retained for compatibility.

## Rig and motion

The single skinned mesh has separate material surfaces for the robe, hood,
shadow lining/leather, rope, stitching, red eyes, amber embers, gloves, and iron. Named
`PART | ...` vertex groups allow selection of garment pieces after joining.
Two real openings in the cowl reveal the recessed red eyes and dark interior.
The censer follows the hips; its chain is modeled geometry without physics.

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

## Garment clearance

The outer robe is one continuous mesh through the waist, with a tapered front
split and a raised, uneven hem. The inner tunic clears the lifting boots.
The harness follows the chest surface, the censer sits forward of the moving
arm, and the mantle has open arm slits and weights that follow the shoulders.
Both Blender presentation scenes use the checked idle pose.

`clearance_validation.json` records triangle-intersection checks for 67 pairs
of separate layers in the rest pose and every half frame of the three clips:
288 poses total. It also checks the exterior cloth surfaces for self-crossings,
ground clearance, and visibility of both eyes.
Sewn armhole attachments, knots/cord crossings, embedded stitches, glove/thumb
joins, and metal assembly joints intentionally overlap at their connections.
Those construction joins are distinct from visible clipping between moving
layers. These checks cover the included clips; future retargeting needs its
own clearance review.

## Import and scale

The model uses metres, with its origin on the ground. The hooked cowl makes it
approximately 2.15 m tall. Scale the root to suit the enemy's desired size.
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

Run the Blender clearance audit with:

```sh
blender -b -t 8 --python-exit-code 1 --python art/cultist/validate_clearance.py
```

Append `-- --no-render` to the generator command when iterating on geometry.
Re-render both saved Blender scenes before packaging if using that option.
