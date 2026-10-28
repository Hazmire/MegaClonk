# Dark Assets audit — before implementation

Release psx-assets / Dark Assets was queried directly; eight relevant archives were downloaded/extracted under /tmp/megaclonk-psx-source. Original materials and archives remain separate from derived runtime assets. Exact selected source→project paths: GRIMDARK_SELECTED.json. No entire library is bulk imported.

| Upload | Actual contents / intended integration |
| --- | --- |
| knight.zip | knight/knight.glb, knight.fbx, knightlowres.png, texture_source.txt; supplied skinned14-bone Knight with k_idle/k_walk clips. Use original character, supplement missing states without root motion. Original material is emissive-only; convert its actual texture to muted lit armour. |
| Characters_psx_1.2.zip | Characters_psx_1.2/Characters_psx_02/Models/Rig/Killer_M/Character_Monster*.fbx and matching Textures/*.png. Static rigged horror figures plus modern civilians; only monsters and appropriate killers selected, no police/firefighter/dancer models. Inspect actual silhouettes before assigning roles. |
| Retro.Tree.Pack.v1.0.zip | Retro Tree Pack/Models/Super Low Res/GLB/tree_rt_*.glb and dead_tree_rt_1/2.glb; native Godot import. Primary stage-specific living/decaying/dead vegetation. |
| PSX_Modular_Medieval.zip | Selected GLB market stall, table, barrel/coffer pieces, stone arch and door; convert materials after import. Other full modular buildings remain outside game. |
| PS1.Dark.Fantasy.Horror.Game.Assets.by.Stark.Crafts.zip | PS1_ForestAsset/PS1_NaturAssetCollection.fbx; PS1_Palast_Assets/PS1_PalastAssetCollection.fbx; skull/skeleton/sword FBX and low-resolution textures. Audit named collection parts before selecting rocks, ruins, altars/statues/chests. |
| Industrial_exterior_v1.zip | Industrial_exterior_v2/Models/IndustrialHorror_PS_like.fbx with industrial plant/road/container textures. Inspected; mostly modern machinery, lower priority for medieval fantasy. Do not force unsuitable assets into the forest. |
| TheWrapper.V2.1.zip | MonsterPSX.fbx, MonsterPSX_Diffuse.png and .blend source. A supplied horror creature, not an engine wrapper; inspect rig/scale for a heavy boss silhouette. |
| psx_visuals-7dbba0d2ac598dda82984d3d1185e12805500fd3.zip | snotbane PSX Visuals1.5.0 addon, spatial shader include, template, material converter and canvas dither shader. Godot-native source. Integrate shader math with project materials and explicit fog globals; do not run blanket/destructive converter. Full UI must remain outside low-resolution/dither layer. |

The two BONK_INFINITY archives are byte-identical (release SHA256) to previously downloaded/verified v11 and12.1 game ZIPs. Their central directories contain EXE/readme/licence game distributions, not source art. They are excluded from asset import.

Licences: no archive contains a general licence file. PSX shader Unlicense verified from snotbane/psx_visuals at the exact7dbba0d2 commit via GitHub API, preserved as assets/grimdark/psx_addon_source/LICENSE.txt. Knight texture notice credits Petr Kratochvil’s public-domain Suit Of Armor photograph and includes its source URL. Other supplied model/scenery provenance is recorded; no invented CC0 or redistribution claim. The user confirmed the texture is CC0, supplied its exact source URL, and explicitly authorized the other supplied assets for the personal game. This is recorded as user authorization, not independently verified blanket CC0. No further evidence is required for this integration.

## Import repairs and actual rendered checks

- The original Knight GLB contains half the armour: its source Blender Mirror modifier was not applied during the original export. Applied that modifier in the supplied blend, retained the Armature and native idle/walk clips, normalized to 1.8m and grounded the derived `Knight_ready.glb`. Original retained. The original black diffuse/emission-only material is converted using its actual armour texture as lit white-tinted diffuse.
- The Characters Rig directory mixes static meshes and skinned figures. Static Monster0–5 face +X and are rotated to +Z; the others require skeleton bind-pose application before frame baking. CPU skin evaluation avoids headless Dummy-renderer skin RID limitations. Contact-sheet render confirms upright figures.
- Wrapper FBX has empty animated mesh objects that break native Godot animation import. Native import animations are disabled for that source; supplied idle/walk actions are evaluated in Blender and baked to shared runtime frames.
- Shader adaptations split varying writes into actual entry points and use view-depth for affine interpolation/fog. Rendered prototype confirms real 640×360 world output and independent sharp full-resolution UI. This prototype is not yet the final world or a completed three-stage visual review.
