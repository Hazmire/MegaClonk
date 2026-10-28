# Grimdark PSX integration — v13

Runtime player: supplied full-armour Knight, native idle/walk, original supplemental jump/fall/crouch/slide/landing/death poses, no root motion. Original half-mesh GLB repaired by applying its supplied Blender Mirror modifier while preserving the14-bone Armature. Armour emission-only texture converted to lit diffuse. Supplemental states remain simplified compared with fully authored clips.

Enemies: supplied horror figures replace old runtime geometry through stable logical model IDs. Shared baked idle/walk frames preserve MultiMesh batching, distance animation detail and custom-data white damage flashes. Wrapper uses supplied native idle/walk clips evaluated in Blender; static figures use lightweight original procedural animation. Existing AI/stats/rewards/crowd logic remain. The Knight's red flash uses a cached PSX overlay; enemies retain silent damage/death events.

Stages cycle through Blighted Forest (living green), Withering Forest (ochre and dead trees), Deadlands (dead trees only, no healthy shrubs/grass). New Retro Tree / Stark Crafts scenery, textured medieval coffers, market stalls, altars, effigies, skulls, obelisks and stone portal arch replace previous visible placeholders. Procedural terrain, navigation and terrain-aware red portal guidance remain. Very high rocky boundaries use the supplied cliff mesh; fog obscures distance.

World renders once through a shared-world SubViewport, default640×360 at1280×720, with nearest upscaling and five-bit Bayer dithering. Root 3D is disabled; root UI stays full-resolution. Camera projection and positional audio remain rooted in the original camera; retro viewport adds no audio listener. Supplied shader math adds vertex snapping, affine textures, vertex lighting and vertex fog. Shared material precision uniforms avoid per-instance buffer exhaustion. Graphics settings expose retro scale, warping, snapping and dithering.

Original source assets remain for rollback and historical credits. New selected/derived assets are committed in assets/grimdark. Asset provenance and import repairs: GRIMDARK_ASSET_AUDIT.md and GRIMDARK_SELECTED.json. User confirmed personal-project permission for supplied assets; the Knight texture's CC0 credit applies specifically to its photograph, not a blanket geometry licence claim.

Actual rendered captures: docs/images/grimdark. The dedicated test builds20 seeds across all3 stages and checks objective access, supplied scenery, dead vegetation and portal guidance. Performance and delivery verification are reported separately; no native Windows or gaming-GPU certification is implied.

Asset rebuild: extract source archives outside res://, set MEGACLONK_PSX_SOURCE, run Blender4.3.2 with tools/prepare_grimdark_rigs.py, then tools/bake_grimdark.gd and tools/bake_wrapper_frames.gd through Godot. Bake tools default to the documented /tmp/megaclonk-psx-source and /tmp/grimdark-wrapper-frames directories. Ordinary source builds need no Blender because generated GLB/RES files are committed.

## Actual rendered gallery

- [Blighted Forest](images/grimdark/stage_1.png), [Withering Forest](images/grimdark/stage_2.png), [Deadlands](images/grimdark/stage_3.png).
- [Supplied interactables](images/grimdark/interactables.png), [enemy roster](images/grimdark/enemy_roster.png), [Knight armour repair](images/grimdark/knight_import_repair.png).
- [Red player damage](images/grimdark/knight_damage_red.png), [sharp HUD over retro world](images/grimdark/hud.png).

All screenshots were rendered and viewed under Mesa llvmpipe. Shutdown texture diagnostics and native-platform limits are disclosed in GRIMDARK_PERFORMANCE.md.
