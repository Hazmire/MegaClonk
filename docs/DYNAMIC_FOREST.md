# Dynamic Forest, roster and encounters

This update supersedes the fixed nine-region layout, centre spawn, carry-walk player animation,
per-run ordinary variant choices, and the previous two main bosses. Godot4.7.2, progression,
loadouts, weapons, shops, quests, ten-minute pressure, rushes and portal travel remain.

## Maps and spawn

Each seed partitions the192m world into2–4 rows, then independently partitions each row into
2–4 differently sized regions. This produces4–16 rectangles with staggered T junctions, different
adjacency graphs and no prescribed central basin or elevated ring. Elevations0/6/12m are assigned
independently of position. A randomized spanning backbone plus optional nonintersecting loop ramps
connects all regions. Ramps remain12m wide,28m long and planar. Drafts with an incomplete backbone
are rejected deterministically before terrain is constructed; the tested100 seeds all used one draft.

A seeded peripheral region supplies the flat player spawn, before decoration. A12m spawn clearing,
protected ramps, plateau approach lanes and10m statue/portal clearings prevent blocking scenery.
The portal chooses a distant region. Nature trees/rocks also avoid cliff margins. Continuous outer
walls extend below adjacent floors so elevation seams cannot expose perimeter gaps.

Terrain planes are shared by render geometry, collision, native navigation and a horde flow field. Each stage owns its native map; both map and region
iterations synchronize before a spawn-to-portal path verifies readiness. This prevents transient
empty maps during replacement, rather than relying on a fixed number of frames.
The same seed reproduces terrain, spawn and decoration; stage travel changes the seed while keeping
build/gold/progression. Older terrain saves reposition the player safely and clear legacy ordinary
mobs; saved old main boss identities migrate to the new pair. New checkpoints preserve individual
roster choices, spawn RNG state, climb phase, boss ability timers/targets, summons and statue state.

## Ranger locomotion

The supplied UAL2 library was inspected: its carry-walk and zombie walk are unsuitable as natural
player locomotion; it contains no ordinary run. The replacement is an original in-place skeletal
cycle fitted to the Ranger's actual thigh/calf lengths with two-bone inverse kinematics. Stance feet
move backward linearly, ankles stay planted, swing feet lift, arms counter-swing, and torso remains
upright. Playback rate uses actual horizontal velocity and a calibrated3.10m/s reference stride.
Player speed/acceleration/jump/slide physics are unchanged. Existing idle, jump/air/fall/land,
crouch, slide, hit and death states retain crossfades. The numerical stance test allows2.5cm ankle
height error; rendered phases were inspected. Foot locking is approximate on slopes and sharp turns.

## Ordinary enemies

Only three categories enter the ordinary spawn table, using a dedicated seeded RNG:

| Category | Weight | Per-spawn choice | Base HP | Speed | Damage |
|---|---:|---|---:|---:|---:|
| Basic |75%|50% Goblin /50% KayKit Skeleton|30|2.5|8|
| Special |20%|50% Exploding Bug|20|3.2|20 explosion|
| Special |within the same20%|50% Speedy Monster|25|4.5|10|
| Large |5%|Forest Behemoth|250|1.8|20|

Health/damage retain stage/tier/time scaling. Basic variants have identical stats; choices are made
for each entity, independently of the legacy run registry. Large enemies use2× visual scale and an
expanded hit/obstacle radius. Configuration is in `assets/config/ordinary.tres` and OrdinaryRoster.
Legacy archetype definitions remain for checkpoint/tool compatibility, not ordinary weighted spawning.
Timed minibosses and endless revenants remain separate stage encounters.

Every enemy rises from below ground over0.55s while its gameplay entity already pursues the player.
Pooled smoke flipbooks have a24-effect budget. Existing red hit flashes and combat effects remain.
Bug activation uses a0.6s warning, accurate3m ring and an exactly-once explosion; the Bug has no
extra death explosion. The legacy death-explosion behaviour remains regression-tested separately.

Grounded enemies prefer direct compatible-surface pursuit, route around blocking props using the
shared flow field, and probe actual cliff collision when an upper surface blocks pursuit. A climb
requires an interior wall hit, flat free landing samples across the agent radius, and clear overhead.
The visual/entity rises on the lower side until its feet clear the upper surface, then crosses onto
the landing and resumes pursuit. Invalid landings use navigation; outer walls cannot be climbed.
A timeout recovers from interrupted climbs. Climbing and its phase persist in new run saves.

## Elite statue

One optional statue is placed in a protected flat clearing (`elite_statues`:0 or1). Press E nearby
to activate it once. It creates three350HP,2.8speed,15damage Obsidian Sentinels using the newly
imported KayKit Skeleton Warrior, with gold diamond emblems and common pursuit/climbing. Defeating
the final elite grants90 gold in addition to ordinary kill rewards. Used/completed/active state and
live elites survive save/load; no extra currency is introduced. Count/reward are configurable.

## Main bosses

Exactly one seeded choice is made for the stage and activated through the existing portal. An
active-boss guard prevents duplicate summons. The UI shows its name and health bar.

- **Big Chunkus:** oversized Puglin,5000HP,1.8speed,25contact damage. Every10s it captures the
  player's current ground position and marks a5m area for1.5s. The target stays fixed. Detonation
  deals40 base damage on the marked floor; stage/tier/difficulty scaling follows boss damage.
- **Rock Golem:** assembled from supplied Nature rock geometry,5000HP,1.7speed,25contact damage.
  Every12s it summons up to three lesser golems, capped at twelve living owned summons. Lesser
  golems have60HP,3.8speed,8damage and smaller geometry. Boss death stops abilities, defeats its
  remaining summons, and unlocks the existing exit portal.

Both use common cliff traversal and preserve existing stage progression. Telegraphs are simple
circles aligned to ground height; they are not stencil-clipped across vertical cliff discontinuities.
Boss AOE damage checks horizontal radius and the marked floor's vertical tolerance.

## Assets and limitations

New runtime imports: KayKit Skeleton_Minion and Skeleton_Warrior, shared skeleton texture,
MovementBasic and General animation libraries (23-bone compatible rigs; walking/idle baked into
shared instanced frames). Creator Kay Lousberg; CC0 licence included. The Standout7 skeleton pack
was inspected but not selected because KayKit supplies matching animation clips. The Wrapper
upload is not required for this roster and is not integrated. No missing skeleton download remains.

Goblin is the project's original pointy-eared model with new articulated leg frames; Bug/Speedy/
Large/Chunkus use existing supplied Bestiary creatures. Rock Golem geometry comes from Nature
MegaKit, with original assembly/animation. The Basic Goblin remains simpler than the imported art.
No fictional additional Bestiary species are claimed.

`tests/dynamic_visual.gd` renders ten representative map seeds and close locomotion/roster/boss
views. See `docs/images/dynamic/` and `docs/validation/dynamic-seeds.json`. F6/F7/F8 and seed entry
remain available in practice mode. `tools/bake_skeleton.gd` and `tools/bake_original_encounters.gd`
reproduce committed animation frames. Tests/README describe Windows delivery and current evidence.

Native Windows execution, audible speaker output, long-session balance and stable60FPS on a gaming
GPU require local playtesting. Headless CPU timings exclude rendering and full late-game combat.

## Main changed files

- `scripts/stages/forest_map.gd`, `forest_world.gd`, `forest_navigation.gd`: partitions, spawn/POIs, placement and native map lifecycle.
- `scripts/art/ranger_stride.gd`, `rig_clips.gd`, `ranger_visual.gd`: fitted stride and velocity playback.
- `scripts/enemies/ordinary_roster.gd`, `ordinary_settings.gd`, `enemy_traversal.gd`: weighted roster and collision-checked pursuit/climbing.
- `scripts/enemies/enemy_simulation.gd`, `enemy_view.gd`, `encounters.gd`: behaviours, emergence, emblems and bosses.
- `scripts/core/game.gd`, `scripts/ui/minimap.gd`: stage hooks, interaction, rewards, hit radii and checkpoints.
- `tests/dynamic_seeds.gd`, `dynamic_gameplay.gd`, `dynamic_visual.gd`: new validation and captures; existing suites use an explicit flat combat fixture.
- `assets/kaykit/skeletons/`, `assets/quaternius/baked/`, `tools/bake_skeleton.gd`, `tools/bake_original_encounters.gd`: selected source assets and reproducible frames.
- Windows workflow/export scripts, README, credits and validation evidence.
