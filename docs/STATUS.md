# Movement and enemy-variation milestone

The initial requested overhaul milestone is implemented in the existing project. This is a playable development build, with further art/animation and game-feel work remaining.

## Implemented

- Sprint removed; configurable ground acceleration/friction, air control, slide threshold/friction/steering, slope acceleration, slide-speed cap, crouch speed and jump impulse. Rebindable Ctrl crouch/slide, low capsule, ceiling clearance, real slope response and momentum-preserving jump chaining. Monke forward wall-climb and character jump/air bonuses retained.
- Original Fox Scout model separated from physics, with a pivot rig and blended pose state machine for idle, run, turning, jumping, falling, crouching, sliding, hit and death. Victory does not trigger death animation. Playable characters currently share the rig; their stats, passives and starting weapons remain distinct.
- Eight preserved regular archetypes, each with two configurations and distinct committed models: goblin/skeleton, wolf/spider, ogre/golem, archer/cactus, knight/brute, bat/wisp, scarab/sporecap, bulwark/beetle.
- Configurable stats, reward values, resistance and shared wind-up/recovery modules. Visible ranged projectiles/fans, stationary cactus, charges, slams, proximity explosions and guarded death blasts. Death blasts warn for 0.4s before damage; one death cannot repeatedly detonate.
- Seeded, independent 50/50 per-archetype selection once per run, all eight preselected. Stage transitions and save/resume preserve the registry. Save snapshots retain enemies, HP/stats, equipped levels, XP drops, run counts, camera and interactables. Transient projectiles/fields restart on resume. Save format is currently version 1; no old active-run saves existed before this feature.
- Original arrow/rocket/fire/spore/bolt meshes; pooled trails and sparks; slash ribbons, lightning segments, burn/poison/freeze colours, critical numbers, hit reactions, budgeted death meshes and effect intensity settings. Existing 36-weapon damage suite remains passing.
- Existing terrain retained and run-seeded; procedural ground grain, grass/bushes, faceted rocks and ruins. Trees/rocks/grave markers/ruin columns have static collision. Ground enemies use local prop avoidance without individual physics/navigation nodes.
- Instanced body/limb rendering and distant merged geometry; no per-enemy scene or skeleton. GitHub Actions validates, exports Windows x64 and publishes a playable artifact. PR #1 targets the existing default `Full-Release` branch.

## Validation and limits

Read `VALIDATION.md` for measured checks and publication evidence. Native Windows execution, audible output on real devices and 60 FPS on a target PC remain unverified. The richer AI, collisions and animated transforms have increased CPU cost relative to the single-mesh baseline; measured headless timings are explicitly reported, not presented as target-PC FPS.

The supplied research sites remain unavailable from the initial research attempts. Variant behaviour and balance are original design choices, not verified Megabonk formulas. The project uses original generated native Godot assets; no third-party downloaded model or proprietary asset was imported.

## Remaining work

- Human Windows playtesting of movement, combat balance, camera comfort and long runs; real-GPU profiling and further crowd optimizations.
- Tailored models for the other 20 characters; more detailed player/monster rigs, authored attack/death animation, expressive faces and richer environment art. Current enemy animation is simplified instanced body/limb movement, attack poses, hit flash/recoil and falling/shrinking corpses.
- Enemy separation, sophisticated navigation, more distinct biome bosses and authored multi-phase combat. Existing Warden mechanics are preserved.
- Original game's verified passives/items/quests and full conditional item synergies. Persistent currency spending, comprehensive achievements, weapon unlock progression and difficulty unlock progression remain outside this milestone.
- Saved active runs currently reset transient attacks/fields rather than restoring every effect. Malformed manually edited active-run files are not a supported import format.
- Further extraction of world/UI/combat orchestration from `game.gd`; continued accessibility/controller and settings testing.
