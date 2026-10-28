# Visual/playtest corrections —14

- Solid terrain previously defined ALPHA_OPAQUE, but the supplied include only recognizes ALPHA_DISABLED. That left alpha writes in the terrain shader. Solid meshes now use an explicitly opaque, two-sided PSX shader; alpha cutouts are restricted to foliage. The texture-alpha assignment is explicit, and snapping guards view-depth division near zero. Transparent spell/portal effects remain intentional.
- Shrine progress appears only inside the active charging radius during gameplay. It hides outside the radius, on completion, during pause/screens and after death. Charge/decay/reward rules are unchanged.
- Basic and fast standard enemies now use the supplied Autopsy Zombie. Its90-bone rig has only an imported A-pose, so an original articulated skeletal walking/idle cycle was authored and baked. Small exploding enemies use bitkiln's crab with its supplied Walk/Idle clips; the hidden helper sphere is excluded. Retained masked/hooded elite models have repaired skeletal limb animation and facing, rather than moving an unposed mesh. All frames remain shared/batched; AI/stats, explosion telegraphs and enemy silence are preserved.
- The Knight's procedural slide/crouch offsets were applied repeatedly to already-modified bones. Each update now restores the last authored animation pose before applying one procedural layer, preventing accumulated rotations/translation and restoring standing on release.

Focused checks hold slides/crouches for thousands of updates, freeze animation time to detect accumulated pose offsets, check walking mesh deformation and exercise shrine label visibility. A rendered regression checks that solid terrain/objects block a red background from both sides even when a supplied texture has zero alpha. Broader validation and Windows publication status are recorded separately in releases/BUILD_INFO.md. Native Windows execution remains untested.

Asset source: user uploads AutopsyZombie.zip and PSX_SEA_HORROR_MONSTERS_Free_Sampler.zip, committed upstream on the current branch. Crab licence/credit retained under assets/enemies_corrected/crab/LICENSE.txt; original zombie FBX and normal texture retained behind a source-only import ignore, with the corrected rig/texture/frame assets in the project. Rebuild with Blender4.3.2 tools/prepare_corrected_enemies.py, then Godot tools/bake_corrected_enemies.gd. The older frame-bake scripts are historical and do not overwrite these new named frame sets.

## Rendered checks

[Animated roster](images/visual-corrections/animated_roster.png) · [player poses](images/visual-corrections/player_poses.png) · [opaque front faces](images/visual-corrections/opaque_front.png) · [opaque back faces](images/visual-corrections/opaque_back.png). These are actual Mesa-rendered captures. The occlusion test uses red behind the panels; panel centres must block it, including with zero texture alpha.

## Verified Windows delivery

[Download14 ZIP](https://github.com/Hazmire/MegaClonk/releases/download/grimdark-fixes-v14/BONK_INFINITY_Windows_x64.zip). Clean source, downloaded digest/CRC,180 frames, seven smoke gates and rendered occlusion checks pass. Native Windows execution remains untested. [Full proof](../releases/BUILD_INFO.md).

Actual downloaded-pack captures: [outside shrine](images/visual-corrections/published_outside.png), [actively charging](images/visual-corrections/published_charging.png), [long-held slide and new enemies](images/visual-corrections/published_slide.png). The glowing shrine orb is an intentionally transparent effect; solid terrain and object meshes are opaque.
