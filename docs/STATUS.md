# Implementation status

This repository now builds a playable native 3D development version. It is **not a completed implementation of the entire supplied specification**. No claim is made that it matches Megabonk balance, contains production-quality animation, or has been playtested for enjoyment.

## Working foundation

- Godot 4.7.2, GDScript, native Windows x64 export with embedded resources; Forward+ default and OpenGL compatibility launch option.
- Menu → character/biome/tier selection → automatic-combat run → paused upgrades → Warden → exit portal → three-stage victory or death → results → menu.
- Camera-relative accelerated movement, sprint, jump, gravity, fall damage, spring-arm camera collision, mouse orbit and wheel zoom. Monke wall-climb and extra jump, Birdo triple jump and stronger air control.
- Seeded non-flat terrain for forest, desert and graveyard with original instanced props and fog. Finite 180×180 metre world; boundary excursions return the player to spawn with damage.
- 21 reference-named characters with distinct generated colour/headgear combinations, starting weapons and approximate passives. Fox and Sir Oofie initially unlocked; other characters use kill milestones. No claim of faithful character likenesses.
- 36 weapon definitions, levels 1–10, four slots, shared combat modifiers and multiple runtime patterns: sweeps, auras, returning/piercing/bouncing/homing projectiles, hitscan lines, chains, trails/mines, poison fields, pull fields, freezing, lifesteal and executions.
- Additional weapons: visible Chrono orbit blades and slowing/time-stop; Thunder Rail piercing line and arcs; Spore Cannon projectile/cloud/spreading tagged kills; Gravity Hammer smash/pull/fissure effects; persistent Phantom allies that chase and strike, with a stronger lead ally at high rank.
- 22 independently balanced tomes with real stat modifiers, four slots, three-choice level-up selection, three rerolls/run, skip-heal and banish.
- Ten original stat items with rarity labels, luck-influenced rarity rolls, gold-cost chests/shops, healing objects, charge/stat/risk shrines.
- Eight regular enemy archetypes and a Warden with warning, radial fire, summons and targeted slam; desert adds extra projectiles and graveyard adds a short-range drain. Damage, poison, slowing/freezing, knockback and rewards.
- Version-1 atomic profile save/load, currency, lifetime stats, unlocks, biome completions, best time, settings and explicit profile export/import. Sandbox results leave normal progression untouched.
- Procedural score and sound effects, independent volume sliders, key rebinding, sensitivity/inversion, fullscreen shortcut, resolution, render scale, quality/shadows/MSAA, reduced effects, damage-number/shake/FPS toggles and pause on focus loss.
- MultiMesh enemy rendering and scenery batches; spatial damage queries; bounded projectiles/fields/effects; reusable XP/projectile meshes and materials.

## Validation actually performed

See `VALIDATION.md` for command results. Tests validate specific behaviours rather than every permutation. In particular, damage from all weapon patterns does not establish their balance, exact reference behaviour or high-level synergies. Headless CPU timing excludes rendering and is not a 60-FPS claim.

## Substantial remaining work

- Research sites are blocked by runtime network policy. Exact passives, original items/tomes, roster version, formulas and unlock quests remain unverified. All current balance is original approximation.
- Windows executable runtime, target-PC performance, offline Windows launch, controller feel and human enjoyment require native Windows playtesting. Only export and PE architecture are verified here.
- Characters use original procedural forms rather than tailored rigged models. Animation is procedural bob/limb movement; full idle/jump/hit/death/attack blending, tailored weapon poses and richer enemy silhouettes remain art work.
- World scenery is simple. Complex ruins, hidden traversal, obstacle navigation, canyons/crypt interiors, environmental hazards and secret/map-specific content are not complete. Trees are visual props, not blocking obstacles.
- Bosses share one body/attack framework with biome variations; fully distinct biome bosses, dedicated minibosses, robust navigation and authored phase choreography remain.
- Original reference items, conditional item synergies, comprehensive on-hit/on-kill interactions and all exact advanced weapon behaviours are not complete. Many weapons share pattern code; for example Firestaff/Rocket/lob weapons share the projectile engine. Phantom allies have simple steering rather than navigation/rigged combat.
- Persistent currency is awarded but has no spending economy yet. Achievements/quests are milestone text and derived profile stats, not a full independent quest/achievement database. Difficulty tiers are selectable; tier unlocking and weapon-unlock progression are not implemented.
- UI is functional themed Godot controls, with scrollable panels and generated character preview. Custom icon art, polished responsive layouts, detailed before/after upgrade descriptions, accessibility/controller testing and full settings coverage remain.
- Performance budgets prevent unbounded transient effects, but dynamic frame-rate adaptation, production profiling on a GPU, large-horde stress runs with all weapon combinations, complete pooling, and enemy separation need further work.
- Script orchestration remains concentrated in `game.gd`; data, player, persistence and pooling are separate. Further extraction into world/UI/director/combat modules is recommended before major expansion.

The project is useful for an initial playable test and continued implementation. These gaps should not be relabelled as completed features.
