# Combat, animation and atmosphere update

Godot4.7.2 retained. Existing randomized regions/peripheral spawn, weapons/upgrades, three-category
enemy roster, elite statues, Chunkus/Golem, rewards, progression and portal stages remain.

## Performance

Measured death-pipeline spikes of roughly314–392ms were replaced with cached textured corpse
frames and a bounded mesh pool. Common impact/slash/ring/tracer geometry is shared; common models,
projectiles and flipbooks are prepared at stage setup. Damage numbers aggregate spatially over120ms
and render through one billboard MultiMesh using an original digit atlas (maximum32 active numbers).
Nearby XP drops merge while retaining their complete value; gold and decisive deaths/rewards remain
immediate. Corpse budget48 and flipbook budget24 limit cosmetics without reducing actual damage.
See PERFORMANCE_POLISH.md and raw before/after reports for frame-time distributions and limitations.
Sandbox tools expose optional hits/deaths, new pooled nodes, scene creations, queued root frees,
active FX, XP entities/merges and number counts. These counters cover the instrumented combat paths,
not every allocation inside the engine.

## Enemy descent

The previous traversal explicitly routed every negative height step back to the ramp flow field,
then snapped Y to ground. Dedicated edge/fall states now override that constraint after a validated
lower-surface ray and boundary/obstacle checks. The full agent radius clears the ledge before gravity
is applied. Falling uses24m/s² gravity and terrain-height landing, resumes pursuit, and never teleports
to the player. Climb and drop are mutually exclusive; existing upward collision/landing validation
remains. The edge timeout accounts for large bosses' radius and speed. Ordinary, elite and main boss
cases pass both6m/12m drops in all orientations, including damage during falling; a ramp landing is
also tested. Naturally floating revenants retain their separate movement design.

## Environment

The uploaded SourceCode.zip contains BinbunGrass Godot spatial shaders, shape masks, a palette and
an expensive10,000-instance demonstration. The demo is not used. The shader only shades/deforms
provided geometry; it does not generate grass. Selected source/textures are under assets/BinbunGrass.
Adaptation uses opaque cutout, sensible light clamping and sparse chunked instancing: at most650
placement attempts,55m grass draw range,10m margin, no grass collision or shadows. Ramps, POIs and
spawn corridors remain clear. A baked seeded noise texture supplies soil/moss/grass variation in
world space, with distinct stone shading on cliffs. Ramps share the same coordinates, avoiding UV
stretch. The shader's archive contains no licence file; it was supplied for this personal project
and is credited without claiming CC0.

The requested atmosphere uses a dark navy procedural sky, blue distance fog (density0.013), and
continuous faceted rocky perimeter faces rising roughly68–100m. The lower wall stays inward of the
floor edge so the existing collision boundary has no gap. Top geometry and rock shading vary along
the perimeter; it is no longer a uniform-height green/brown wall. Fog obscures distant terrain while
nearby characters retain readable lighting. All100 collision/navigation worlds still pass.

## Player animation

The old system mixed carry-walk/idle arm tracks, a procedural IK walk, extra jump/land/hit states and
manual crouch bone edits. Local-rest quaternion correction alone also assumes compatible parent
axes. Those runtime player mappings are removed. A single AnimationPlayer now plays four baked
clips: Idle_A and Running_A from KayKit General/MovementBasic, Jump_Idle from KayKit MovementBasic,
and Slide from UAL2. Both sources were already supplied with the project and have CC0 licences.
The23-bone KayKit motion is mapped to the existing65-bone Ranger using global rest-space rotation
deltas, then converted through each current target parent. Unmapped bones retain their rest offsets;
only bounded pelvis Y is animated. Scene/root XZ and physics velocity are never animation-driven.

Retargeting is reproducibly baked by tools/bake_player_core.gd into assets/config/player_core.res;
no source animation scenes are instantiated during player combat. The runtime selects slide/crouch,
airborne jump, locomotion or idle with one short crossfade. Crouch holds a low slide sample while
preserving physical capsule/ceiling behaviour. Damage flashes remain, without interrupting movement
animation. Physics speeds, acceleration, air control and jumping are unchanged. The showcase offers
the four states and crouch; tests inspect actual joint positions/lengths and root immobility.
The old RangerStride script is removed. Original UAL monster-preview tools remain separate.

## Weapons

All36 entries retain their damage/cooldown/targeting and upgrade tables. WEAPON_VFX_AUDIT.md lists
every actual weapon and its old/new projectile/attack, impact and audio family. WeaponArt caches
meshes; WeaponVFX provides reusable cosmetic attack/contact/trail events. Conventional bullets have
small brass shapes/tracers/muzzle flashes; arrows retain oriented shafts/heads without oversized
trails; fire has bounded flame/smoke; electrical links are jagged and pooled. Bone, banana, axe,
dice and sword-wave projectiles have distinct silhouettes. Ground fields retain their terrain normal.
Existing allies and their gameplay remain, with pooled links/accents.

Chunkers uses the supplied Nature Rock_Medium_1 geometry, with earthy materials and individual
rotation. The shared orbit_count/orbit_position functions drive both damage samples and visible
rocks, including count/radius upgrades. Twelve subordinate stone instances swirl at the feet, without
physics bodies. Contacts emit capped dust/chips and the supplied stone-footfall sample. Aegis uses
shield/crest geometry and Chrono uses blades rather than identical coloured rectangles.

## Evidence and limits

444 assertions,55 concrete traversal scenarios and three100-seed suites pass headlessly. Rendered
captures cover all four player poses/crouch, Chunkers/debris, attacks/numbers and fog/cliffs under
Mesa software OpenGL; examples are in docs/images/polish. A minor shutdown texture diagnostic in
that renderer remains unresolved and is disclosed in PERFORMANCE_POLISH.md. Native Windows
execution, audible audio, 60FPS on target hardware and driver-specific shader stalls require local
playtesting. Generic locomotion is deliberately simple; foot contact on slopes/rapid turns is approximate.
The broader36-weapon changes share family effects; this does not claim36 entirely bespoke art sets.

Main changed files: scripts/core/game.gd and mesh_pool.gd; combat/{combat_numbers,weapon_art,
weapon_vfx,combat_fx}.gd; art/{ranger_visual,simple_ranger_clips}.gd; player/controller.gd animation
selection; enemies/{enemy_traversal,enemy_simulation,encounters}.gd; stages/{forest_map,forest_world,
forest_atmosphere}.gd; shaders/{forest_floor,combat_numbers}.gdshader; selected BinbunGrass assets;
baked player library/noise/digit atlas; profiling/traversal/visual tests; export workflow and docs.
