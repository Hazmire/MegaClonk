# Terraced Forest playtest

Godot 4.7.2; existing combat, movement, eight regular archetypes, sixteen variant configurations,
loadouts, progression and ten-minute stage loop are retained. This guide supersedes earlier
rolling-terrain/Jacob/asset-download status descriptions.

## World generation

A stage is 192 × 192 metres. Nine broad flat regions occupy three elevations (0, 6, 12m).
A seeded spanning tree connects the region graph, with additional connections creating loops.
Connections are straight, constant-slope 28m ramps, 12–16m wide, at most 28 degrees.
Vertical cliff faces close exposed region edges; continuous perimeter walls prevent walking out.
There is no noise displacement on walkable ground. Most ground remains flat.

The seed determines regions, elevations, ramp positions, objectives and decoration transforms.
The default stage seed is run seed + stage × 73. Stage travel changes the map, preserving the
existing build, variant choices, levels and gold. Legacy saves safely reposition on the new terrain.

Terrain collision and navigation share the same tile planes. A shared reverse breadth-first flow
field directs hordes around cliffs and collider obstacles, avoiding per-enemy path searches.
A matching NavigationRegion3D supports independent native path verification. Synchronous map
updates prevent stale navigation after stage rebuilds. Trees and rocks have simple colliders;
small foliage does not. Protected ramp margins, corridors, spawn and POI clearings remain open.
Disconnected layouts or decoration repairs are explicitly recorded rather than silently passed.

## Art and animation

Player: Male_Ranger clothing and 65-bone skeleton. The supplied outfit has no head; only the
head geometry from the supplied UAL2 mannequin is attached and rebound to the ranger skeleton.
No unavailable Universal Base Character download is required. The face is a simple skin material.

UAL2 animation tracks are retargeted using both source and target bone rest transforms.
States: idle, velocity-scaled movement/turning, jump start, airborne, falling/gliding, landing,
crouch movement, slide, damage and death. Crouch is an original skeletal pose with stepping;
UAL2 has no dedicated crouch or ordinary running clip. Movement adapts Walk_Carry with lowered
arms. Slides and ninja jump phases use supplied clips. Death reverses the supplied lay transition.
The visual skeleton is separate from player physics/camera; no sprint state is introduced.

Enemies use the only two supplied Bestiary models: Imp and Puglin. Existing sixteen behaviour
variants retain their stats and modules, with related tints/scales. Bosses and minibosses use
these meshes at encounter scale. This pack cannot provide sixteen unique monster species.
UAL2 idle/walk are retargeted to the 55-bone rigs and baked into shared textured mesh frames.
MultiMesh batches share frames across variants; distant locomotion uses fewer frames. Wind-up,
charge tilt, explosion swell, red damage flashes and existing attack/death effects remain.
Full original PBR monsters are available in the showcase; horde shaders prioritize albedo/readability.

Nature: CommonTree_1/3/5, Bush_Common, Bush_Common_Flowers, Grass_Common_Short, Fern_1,
Flower_3_Group and Rock_Medium_1. Clustered instancing creates forest patches and open lanes.
The supplied Standard edition contains no log model or ready-made engine shader project.

Projectiles raycast against terrain/props, including vertical cliffs; persistent fields align with
ramps. Existing weapon stats, rewards and progression are unchanged.

## Debug and reproduction

Normal play hides generation debug UI. Start with `--practice --map-seed=626` for a sandbox:
F6 toggles regions/ramps/navigation/POIs, F7 regenerates the same seed, F8 changes the seed.
The sandbox panel also accepts an explicit seed. Run with `--showcase` for isolated asset and
animation inspection (Escape returns to the menu).

Generation configuration: `assets/config/forest.tres`. Runtime source asset selection:
`tools/import_release_assets.py`; repeatable enemy animation baking: `tools/bake_bestiary.gd`.
The source archives remain outside Git; required glTF/GLB, textures, baked frames and licences
are committed. See ASSETS_V1_INVENTORY.md for verified package details.

## Validation limits

Headless checks cover existing systems, 100 seeded graph layouts, 100 actual collision/native
navigation worlds, and player/enemy ramp traversal and animation states. Report files distinguish
first-attempt failures from repaired and final results. Rendered screenshots are inspected under
Mesa software OpenGL; they establish appearance, not gaming GPU performance. Native Windows
execution and stable 60 FPS on target hardware require local playtesting.
