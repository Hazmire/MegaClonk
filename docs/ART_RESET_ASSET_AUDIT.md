# Supplied asset audit — art reset

Inspected uploaded files from Full-Release df625e2, merged into the existing v9 feature branch. Existing Godot version remains 4.7.2. Archive contents were read rather than inferred from filenames.

| Upload / discovered file | Type and intended use | Status / dependencies / integration approach |
| --- | --- | --- |
| assets/Fantasy Portal 3D LowPoly Model.rar → FBX/Portal_01.fbx | Static portal mesh, 160,796 bytes | Native Godot FBX import planned. Three provided texture maps: Textures/Fantasy Portal 3D LowPoly Model_Textures_01.png, _Emissive.png, _Metallic.png. Assign explicitly after import, fit to interaction footprint, preserve original geometry. BLEND and BLEND1 are source backups, not runtime dependencies. |
| assets/PSX_Daysky_HDRI.zip → PSX_Daysky_HDRI/DAYSKY.hdr | Day panorama | Godot HDR panorama import planned; natural forest stage. Preview JPG is reference only. |
| assets/PSX_Nightsky_HDRI.zip → PSX_Nightsky_HDRI/PSX_NIGHTSKY.hdr | Night panorama | Godot HDR panorama import planned; violet stage. No third/red panorama was supplied. Crimson will use a documented colour treatment of this supplied night imagery, not a claimed third source texture. |
| assets/PSX_Forest_Level_byStarkCrafts.zip → PSX_Forest_AssetCollection_byStarkCrafts.fbx | Scenery mesh collection | Native FBX import and named mesh inventory planned. Seven supplied 128px ground/grass PNG textures. Atlas/material references must be checked after import. Retain procedural terrain and use suitable actual mesh parts for scenery/cliffs. |
| assets/StatusFXFree.zip → StatusFXFree/assets/BinbunVFX_Vol2/StatusFX/ | Native Godot status/ability VFX | Supplied CC0 licence names Binbun3D. Includes aura, bubble, ice, healing, sleep, texture, noise and streak shaders, plus vfx_status_shatter.tscn and a demonstration scene. Internal res://assets/BinbunVFX_Vol2 paths require relocation. Reuse compatible shaders/effect components in bounded native emitters; demo guy/room/HDR are not gameplay dependencies. |

There are no separately labelled new weapon-attack or boss-attack packs among these five uploads. StatusFX components and the already integrated PSX/Electric FX packs will be mapped to retained weapons and boss abilities. No missing custom Unity particle system is assumed to exist. Portal, sky and forest archives contain no separate licence file; supplied-user provenance is retained, with existing user-authorized integration scope. No new external download or licence claim is introduced.

This audit precedes substantial implementation. Import results, node names, scale/orientation corrections and asset-to-system mappings will be appended after actual Godot validation.

## Import results and runtime mapping

Native Godot FBX import resolved all portal texture references and extracted fourteen embedded forest textures. Eleven named scenery meshes were baked to assets/art_reset/baked, preserving the full imported FBX transform before normalising ground alignment and height. This corrects the collection's Blender-to-Godot orientation. Alpha-bearing foliage materials use alpha scissoring; original textures and UVs are preserved.

Portal: both Portal_01 and Portal_01_Hole are instantiated, fitted to 4.4m overall height and given a restrained shader using all three supplied maps. Its nonblocking interaction behavior is preserved. Day/night HDR textures feed three cached sky resources: day/natural, night/violet and night/crimson. No third source panorama is claimed.

Scenery: PSX_Tree2/3, PSX_Treetrunk and PSX_Rock are used alongside the existing supplied Nature kit. PSX_Tree1 and the remaining small mesh bakes are retained as reusable source assets, not claimed as additional runtime placements. Outer visible boundary walls are replaced by seeded layered rock instances; the original watertight terrain collision remains separate. Ground samples the supplied earth/grass textures. Existing vertical terraces and ramps remain in place.

Effects: supplied native vfx_status_shatter.tscn supports Chunkus impacts and Golem summons; aura_particle.gdshader supports fire/arcane weapon effects; imported PSX_Rock supports debris. They use prewarmed bounded pools. Ambient and route-aware portal wind adapt the supplied CC0 noise particle shader without depth-buffer sampling. Existing PSX flipbooks, lightning shaders and sound assets remain active.

Icons: retain supplied Undead skill Sword/Fire icons (Icon15/Icon20), and use original generated pixel-art atlas regions for Lightning Staff, Chunkers, Bone, Bow, Revolver, Bananarang, Aura and Mines. The generated atlas is committed at assets/art_reset/icons/weapons.png. Source implementations/names are existing MEGACLONK equivalents; the public Megabonk weapons reference returned HTTP503 during this audit, so no exact original-game balance or naming provenance is invented.
