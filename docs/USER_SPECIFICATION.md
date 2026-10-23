# PROJECT BONK INFINITY
## Complete Autonomous Game Development Specification

### 1. YOUR ROLE

You are the lead game developer, gameplay designer, 3D technical artist, UI designer, systems architect, performance engineer, and QA tester for a project called **BONK INFINITY**.

Your task is to independently develop a complete, polished, native Windows 3D action roguelike inspired by the gameplay of Megabonk.

The user is the creative director and playtester. They do not intend to write code, build Godot scenes, configure assets, debug scripts, or manually develop the game.

You are responsible for all technical implementation.

This is a personal, offline, non-commercial project. The game will not be distributed or sold.

The objective is to reproduce the distinctive gameplay experience of Megabonk as closely as practical, while adding five new weapons and creating an extensible foundation for future content.

The finished game must be a genuinely enjoyable, fully functional 3D game, not a collection of mockups, menus, incomplete scripts, or placeholder systems.

You must work autonomously, make sensible development decisions, and avoid unnecessary questions.

If a tool, dependency, permission, or technical capability is unavailable, identify the problem clearly and propose the simplest resolution.

Never claim to have implemented or tested functionality that has not actually been implemented or tested.

---

# 2. TECHNOLOGY STACK

Use:

- **Engine:** Latest stable Godot 4.x.
- **Primary language:** GDScript.
- **Platform:** Windows 10/11, 64-bit.
- **Rendering:** Godot's Forward+ renderer, with compatibility options if required.
- **Physics:** Godot's built-in 3D physics, supplemented by optimised custom simulation where appropriate.
- **UI:** Godot Control nodes and themes.
- **Audio:** Godot AudioStreamPlayer and audio buses.
- **Save data:** Godot's user:// directory.
- **Version control:** Git.
- **Testing:** Godot headless validation, scripted gameplay tests, and available automated integration tools.
- **Asset processing:** Blender scripting and command-line conversion tools when available.

Do not use a web-based game framework.

The finished game must export to a standalone Windows executable.

The game must function without an internet connection.

Do not require online accounts, external APIs, subscription services, or paid software.

---

# 3. AUTONOMOUS DEVELOPMENT REQUIREMENTS

You must handle:

1. Project setup and configuration.
2. Folder and file structure.
3. Godot scene creation.
4. GDScript programming.
5. Gameplay architecture.
6. Character controllers.
7. Camera systems.
8. Weapon and projectile systems.
9. Enemy AI.
10. Procedural terrain.
11. 3D asset acquisition and integration.
12. Materials, shaders, and lighting.
13. Animation setup.
14. Particle effects.
15. Audio integration.
16. User interfaces.
17. Save systems.
18. Unlocks and progression.
19. Debugging.
20. Automated testing.
21. Performance optimisation.
22. Windows executable exports.
23. Documentation.
24. Future feature integration.

Do not require the user to perform development work inside Godot.

The user should only need to launch the game, test it, and provide feedback.

---

# 4. RESEARCH THE ORIGINAL GAME

Before implementing the full game, research publicly documented Megabonk gameplay.

Reference sources:

- https://megabonk.wiki/wiki/Characters
- https://megabonk.wiki/wiki/Weapons
- https://bonkmaster.com/database
- https://survivorsdb.com/megabonk
- https://megabonk.org/guides/mechanics/

Research:

- Characters and starting weapons.
- Character passive abilities.
- Weapon attack patterns.
- Weapon upgrade effects.
- Tomes.
- Passive items.
- Character statistics.
- Movement mechanics.
- Enemy behaviour.
- Enemy scaling.
- Maps and biomes.
- Bosses.
- Shrines.
- Chests.
- Shops.
- XP and levelling.
- Unlock requirements.
- Persistent progression.
- Run structure.
- Victory and defeat conditions.

Create `RESEARCH.md` documenting the findings.

Distinguish verified mechanics from approximations.

When exact formulas are unavailable, create configurable approximations that preserve the gameplay feel.

Do not pretend that guessed formulas are verified.

Do not copy proprietary game source code or extract copyrighted game assets.

Use independently written implementations and original or appropriately licensed assets.

---

# 5. GAMEPLAY VISION

BONK INFINITY is a fast-paced, third-person, 3D survival roguelike.

The player controls a character in a procedurally varied environment while weapons automatically attack nearby enemies.

The player must:

- Move continuously.
- Avoid enemies.
- Navigate slopes and vertical terrain.
- Collect experience.
- Level up.
- Choose weapons and tomes.
- Acquire passive items.
- Open chests.
- Activate shrines.
- Fight increasingly powerful enemy hordes.
- Defeat bosses.
- Reach stage exit portals.
- Unlock permanent progression.

Gameplay must become increasingly chaotic as the player gains power.

A successful late-game build should be capable of producing enormous damage, large attack areas, multiple projectiles, chain reactions, and spectacular visual effects.

The game must retain good performance and visual clarity as the number of enemies increases.

---

# 6. CORE GAME LOOP

Implement the following complete gameplay loop:

1. Launch the game.
2. Display the main menu.
3. Select an unlocked character.
4. Select a biome and difficulty.
5. Begin a run.
6. Spawn the player into a 3D environment.
7. Spawn enemies outside the immediate player area.
8. Automatically attack enemies using equipped weapons.
9. Collect XP and gold.
10. Level up and choose upgrades.
11. Acquire weapons, tomes, and items.
12. Explore the map for interactables.
13. Survive escalating enemy waves.
14. Fight elites and bosses.
15. Reach an exit portal or stage objective.
16. Progress to subsequent stages.
17. Win or die.
18. Display run results.
19. Award persistent progression.
20. Return to the main menu.

All steps must be functional.

---

# 7. PLAYER MOVEMENT

Movement is a critical design priority.

Implement a responsive third-person movement controller using CharacterBody3D or an appropriately optimised alternative.

Controls:

- WASD: move relative to the camera.
- Mouse: rotate camera.
- Space: jump.
- Shift: sprint or movement modifier.
- E: interact.
- Escape: pause.
- Tab: inspect current build.
- Mouse wheel: zoom.
- F11: toggle fullscreen.

Support configurable key bindings.

Movement must include:

- Smooth acceleration.
- Responsive deceleration.
- Momentum preservation.
- Gravity.
- Jumping.
- Air control.
- Sloped terrain traversal.
- Sliding on steep slopes.
- Knockback.
- Falling.
- Fall damage where applicable.
- Movement speed bonuses.
- Jump height bonuses.
- Character-specific movement abilities.

Avoid stiff, slow, or unresponsive controls.

The player should be able to move quickly through complex terrain.

---

# 8. CAMERA SYSTEM

Create a third-person camera using Camera3D and SpringArm3D where appropriate.

Requirements:

- Smooth player following.
- Camera-relative movement.
- Adjustable mouse sensitivity.
- Adjustable zoom.
- Camera collision with terrain.
- Stable camera movement.
- Minimal jitter.
- Clear view of nearby enemies.
- Configurable camera inversion.
- Optional camera shake.

The camera must remain usable on slopes, hills, cliffs, and during jumps.

---

# 9. WORLD GENERATION

Create three primary biomes.

## Forest

Include:

- Grassy hills.
- Trees.
- Bushes.
- Rocks.
- Cliffs.
- Ruins.
- Elevated terrain.
- Hidden locations.
- Forest-themed enemies.

## Desert

Include:

- Sand dunes.
- Canyons.
- Rocky plateaus.
- Sandstone ruins.
- Dust effects.
- Environmental hazards.
- Desert-themed enemies.

## Graveyard

Include:

- Tombstones.
- Mausoleums.
- Dead trees.
- Crypt structures.
- Fog.
- Dark atmospheric lighting.
- Undead enemies.

Use procedural or seeded terrain generation.

Terrain must include meaningful elevation and varied traversal.

Avoid flat rectangular arenas.

Implement safe player spawning, enemy spawning, and interactable placement.

Use chunk-based loading or another suitable world-management strategy where beneficial.

Support three difficulty tiers per biome.

Support multi-stage runs and stage transitions.

---

# 10. CHARACTERS

Implement the following 21 characters.

Each character must have:

- A distinct 3D appearance.
- A starting weapon.
- Unique passive abilities.
- Individual base statistics.
- Character selection preview.
- Unlock conditions.
- Working gameplay implementation.

Character roster:

1. Fox — Firestaff.
2. Sir Oofie — Sword.
3. Calcium — Bone.
4. Megachad — Aura.
5. Ogre — Axe.
6. CL4NK — Revolver.
7. Athena — Aegis.
8. Robinette — Bow.
9. Monke — Bananarang.
10. Tony McZoom — Wireless Dagger.
11. Bush — Sniper Rifle.
12. Birdo — Tornado.
13. Noelle — Frostwalker.
14. Amog — Poison Flask.
15. Spaceman — Black Hole.
16. Bandit — Dexecutioner.
17. Ninja — Katana.
18. Vlad — Blood Magic.
19. Sir Chadwell — Corrupted Sword.
20. Dicehead — Dice.
21. Roberto — Scythe.

Research the original character passives and implement their documented behaviour.

Examples:

- Fox gains Luck through levelling.
- Sir Oofie gains Armor.
- Calcium gains bonuses through movement.
- Megachad performs periodic defensive flexes.
- Ogre gains damage.
- CL4NK gains critical chance.
- Athena gains low-health damage and Thorns.
- Robinette benefits from accumulated gold.
- Monke can climb and gains health.
- Tony McZoom gains movement-related electrical effects.
- Bush marks enemies and gains critical damage.
- Birdo has enhanced airborne movement.
- Noelle benefits from freezing enemies.
- Amog spreads poison through enemy deaths.
- Spaceman gains XP-related bonuses.
- Bandit gains attack speed.
- Ninja gains evasion and execution mechanics.
- Vlad gains lifesteal.
- Sir Chadwell has difficulty-related scaling.
- Dicehead receives random stat bonuses.
- Roberto periodically receives chest rewards.

Use researched values where available.

Initially unlock Fox and Sir Oofie.

Implement unlock conditions for the remaining characters.

Provide a sandbox mode that unlocks all characters temporarily.

---

# 11. ORIGINAL WEAPONS

Implement the following 31 weapons:

1. Sword.
2. Firestaff.
3. Lightning Staff.
4. Flamewalker.
5. Chunkers.
6. Bone.
7. Bow.
8. Revolver.
9. Aegis.
10. Bananarang.
11. Aura.
12. Axe.
13. Space Noodle.
14. Sniper Rifle.
15. Slutty Rocket.
16. Shotgun.
17. Mines.
18. Wireless Dagger.
19. Frostwalker.
20. Tornado.
21. Dexecutioner.
22. Blood Magic.
23. Black Hole.
24. Poison Flask.
25. Katana.
26. Dragon's Breath.
27. Dice.
28. Hero Sword.
29. Corrupted Sword.
30. Scythe.
31. Ice Crystal.

Verify the roster against the researched game version.

Each weapon must have distinctive behaviour.

Do not implement every weapon as a generic projectile with a different visual effect.

Implement appropriate mechanics such as:

- Melee sweeps.
- Explosive fireballs.
- Lightning strikes.
- Orbiting objects.
- Returning projectiles.
- Piercing arrows.
- Hitscan firearms.
- Homing rockets.
- Explosive mines.
- Persistent damaging areas.
- Freezing attacks.
- Poison clouds.
- Gravity effects.
- Lifesteal.
- Chain lightning.
- Critical attacks.
- Execution mechanics.

Use data-driven weapon definitions.

Support a maximum of four equipped weapons by default.

---

# 12. FIVE ADDITIONAL WEAPONS

Create five new weapons beyond the original roster.

## Chrono Slicer

A temporal melee weapon.

- Summons rotating energy blades.
- Blades orbit the player.
- Damages enemies on contact.
- Periodically emits slowing shockwaves.
- Higher levels increase blade count and radius.
- Advanced upgrades briefly freeze enemies in time.

## Thunder Rail

An electrical precision weapon.

- Fires a powerful piercing energy beam.
- Targets distant enemies.
- Pierces multiple enemies.
- Creates chain-lightning effects.
- Critical hits trigger additional arcs.
- Higher levels increase damage, piercing, and chain count.

## Spore Cannon

A poison-based area weapon.

- Fires explosive fungal projectiles.
- Creates persistent toxic clouds.
- Poisoned enemies spread spores when killed.
- Higher levels increase cloud size and duration.
- Advanced upgrades trigger large fungal eruptions.

## Gravity Hammer

A heavy area-of-effect weapon.

- Summons a spectral hammer.
- Smashes enemy clusters.
- Pulls enemies toward impact locations.
- Produces damaging shockwaves.
- Launches enemies away.
- Higher levels increase impact radius and damage.
- Advanced upgrades create secondary ground fissures.

## Phantom Legion

A spectral summoning weapon.

- Summons ghostly warriors.
- Warriors follow the player.
- Independently attack enemies.
- Higher levels increase summon count and damage.
- Advanced upgrades periodically summon an elite spectral warrior.

All five weapons must have:

- Unique effects.
- Working damage systems.
- Upgrade levels.
- Stat scaling.
- Interactions with tomes.
- Distinct audio.
- Appropriate balance.

---

# 13. WEAPON SYSTEM ARCHITECTURE

Create a reusable weapon framework.

Every weapon should support:

- Base damage.
- Attack cooldown.
- Attack range.
- Critical chance.
- Critical damage.
- Projectile count.
- Projectile speed.
- Attack size.
- Duration.
- Knockback.
- Status effects.
- Weapon level.
- Upgrade effects.

Use custom Godot Resources or an equivalent data-driven architecture.

Weapon definitions must be separate from their runtime behaviour.

Support:

- Additive modifiers.
- Multiplicative modifiers.
- Percentage bonuses.
- Critical hits.
- On-hit effects.
- On-kill effects.
- Projectile piercing.
- Projectile bouncing.
- Area damage.
- Damage over time.
- Status interactions.

Adding a new weapon should require minimal changes to existing systems.

---

# 14. EXPERIENCE AND LEVEL-UP SYSTEM

Enemies drop XP pickups.

XP pickups must:

- Have different values.
- Be attracted to the player within pickup range.
- Be collected automatically.
- Support XP Gain bonuses.
- Remain performant during large enemy hordes.

When the player levels up:

1. Pause gameplay.
2. Display three random upgrade choices.
3. Allow the player to select one.
4. Apply the upgrade.
5. Resume gameplay.

Upgrade choices include:

- New weapons.
- Weapon upgrades.
- New tomes.
- Tome upgrades.

Implement reroll, skip, and banish mechanics where supported.

Respect weapon and tome slot limits.

---

# 15. TOMES

Research and implement the original game's documented tomes.

At minimum, support the following statistics:

- Damage.
- Attack Speed.
- Critical Chance.
- Critical Damage.
- Maximum Health.
- Health Regeneration.
- Armor.
- Evasion.
- Movement Speed.
- Jump Height.
- Pickup Range.
- XP Gain.
- Luck.
- Projectile Count.
- Projectile Speed.
- Attack Size.
- Duration.
- Knockback.
- Thorns.
- Lifesteal.
- Gold Gain.
- Difficulty modifiers.

Tomes must have upgrade levels.

Every stat must produce a real gameplay effect.

Support four tome slots by default.

---

# 16. PASSIVE ITEMS AND CHESTS

Implement a data-driven passive item system.

Research the original game's items.

Items can provide:

- Stat bonuses.
- Conditional damage.
- Defensive effects.
- Movement bonuses.
- XP bonuses.
- Gold bonuses.
- Critical-hit effects.
- On-kill effects.
- Weapon synergies.
- Status-effect interactions.

Implement item rarity.

Chests must:

- Spawn in the world.
- Be interactable.
- Award actual items.
- Display reward information.
- Apply effects immediately.

Include suitable animations and sounds.

---

# 17. ENEMY AI

Implement multiple enemy archetypes:

- Basic melee enemies.
- Fast enemies.
- Tank enemies.
- Ranged enemies.
- Charging enemies.
- Flying enemies.
- Exploding enemies.
- Shielded enemies.
- Elite enemies.
- Biome-specific enemies.

Enemies must:

- Chase the player.
- Navigate terrain.
- Attack.
- Receive damage.
- React to knockback.
- Receive status effects.
- Die.
- Drop rewards.

Implement efficient enemy simulation.

Do not give every enemy expensive independent navigation and physics processing.

Use simplified steering, spatial partitioning, batched updates, and instanced rendering where appropriate.

---

# 18. ENEMY DIRECTOR

Create a system that controls enemy spawning and difficulty.

Difficulty should scale with:

- Elapsed time.
- Stage number.
- Map tier.
- Optional difficulty modifiers.

Scale:

- Enemy health.
- Enemy damage.
- Enemy count.
- Elite frequency.
- Spawn rate.
- Enemy composition.

Spawn enemies outside the immediate player area.

Avoid unfair spawns directly on top of the player.

Ensure difficulty increases smoothly.

---

# 19. BOSSES

Implement biome-specific bosses and minibosses.

Each boss must have:

- Unique appearance.
- Multiple attacks.
- Telegraphable attack patterns.
- Large health pool.
- Clear damage feedback.
- Reward drops.
- Victory conditions.

Include multi-phase bosses where appropriate.

Bosses must be mechanically distinct from ordinary enemies.

Implement stage exit portals and transitions.

---

# 20. SHRINES AND INTERACTABLES

Implement:

- Charge Shrines.
- Treasure chests.
- Shops.
- Healing objects.
- Stat-enhancement shrines.
- Risk/reward shrines.
- Secret objects.
- Map-specific interactables.

Every interactable must have:

- A visible 3D model.
- Interaction distance.
- UI prompt.
- Functional effect.
- Appropriate cost or cooldown.
- Visual and audio feedback.

---

# 21. PERSISTENT PROGRESSION

Save progression locally.

Include:

- Unlocked characters.
- Unlocked weapons.
- Permanent currency.
- Achievements.
- Quests.
- Map completions.
- Difficulty unlocks.
- Best runs.
- Lifetime statistics.
- Settings.

Use versioned save files.

Implement save migration where necessary.

Support importing and exporting save data.

Do not reset progression when updating the game.

---

# 22. USER INTERFACE

Create a polished native Godot UI.

## Main Menu

- Play.
- Character Select.
- Unlocks.
- Achievements.
- Statistics.
- Settings.
- Sandbox Mode.
- Quit.

## Character Selection

- Character preview.
- Starting weapon.
- Passive ability.
- Base statistics.
- Unlock status.

## Gameplay HUD

- Health.
- XP.
- Player level.
- Run timer.
- Kill count.
- Gold.
- Weapon slots.
- Tome slots.
- Boss health.
- Interaction prompts.

## Level-Up Screen

- Three upgrade choices.
- Icons.
- Descriptions.
- Current and next-level values.
- Reroll and skip controls.

## Pause Menu

- Resume.
- Settings.
- Current build.
- Restart.
- Quit to menu.

## Results Screen

- Victory or defeat.
- Survival time.
- Kills.
- Damage dealt.
- Highest damage weapon.
- Level reached.
- Currency earned.
- Unlocks achieved.

All menus must function with mouse and keyboard.

---

# 23. VISUAL ART DIRECTION

Use a cohesive stylised low-poly 3D aesthetic.

Prioritise:

- Recognisable character silhouettes.
- Distinct enemies.
- Attractive environments.
- Bright weapon effects.
- Clear hit feedback.
- Explosions.
- Trails.
- Damage numbers.
- Critical-hit indicators.
- Status effects.
- Environmental fog.
- Readable lighting.
- Smooth animations.

Avoid photorealism.

Visual clarity and performance are more important than polygon count.

---

# 24. FREE ASSET ACQUISITION

You are authorised to research, download, modify, and integrate appropriately licensed free assets.

Prioritise:

1. Quaternius — https://quaternius.com/
2. Kenney — https://kenney.nl/assets
3. Poly Haven — https://polyhaven.com/
4. Godot Asset Library — https://godotengine.org/asset-library/

Prefer CC0 assets.

Verify each asset's licence before importing it.

Do not use ripped assets from commercial games.

Maintain `ASSET_CREDITS.md` documenting:

- Asset name.
- Creator.
- Source URL.
- Licence.
- Modifications.
- Project location.

Use Blender scripting where useful for asset conversion and modification.

Do not require the user to manually configure imported assets.

---

# 25. ANIMATION

Implement:

- Idle animations.
- Running.
- Jumping.
- Falling.
- Hit reactions.
- Death animations.
- Weapon attacks.
- Boss attack animations.

Prefer reusable skeletal rigs.

Use animation blending where appropriate.

Avoid expensive individual skeletal animation updates for enormous enemy hordes.

---

# 26. AUDIO

Implement:

- Menu sounds.
- Weapon sounds.
- Enemy hit sounds.
- Enemy death sounds.
- Critical-hit sounds.
- Level-up sounds.
- Chest sounds.
- Boss warnings.
- Victory sounds.
- Defeat sounds.
- Background music.

Use original, procedural, or appropriately licensed audio.

Provide separate volume controls for music, effects, and master audio.

---

# 27. PERFORMANCE ENGINEERING

Performance is a major priority.

Target 60 FPS on a reasonable desktop gaming PC.

Implement:

- Object pooling.
- Spatial partitioning.
- Batched enemy updates.
- Efficient collision detection.
- MultiMeshInstance3D for suitable repeated geometry.
- Particle budgets.
- Projectile budgets.
- Texture optimisation.
- Material reuse.
- Draw-call reduction.
- Efficient XP pickup handling.
- Adaptive graphics settings.
- Profiling tools.

Avoid creating thousands of expensive physics nodes.

Design the enemy architecture to support large hordes from the beginning.

Do not simply disable enemies or weapon effects to hide performance problems.

---

# 28. SANDBOX MODE

Create a sandbox mode for testing.

Features:

- Select any character.
- Equip any weapon.
- Set weapon levels.
- Add tomes.
- Add items.
- Spawn enemies.
- Spawn bosses.
- Adjust game speed.
- Toggle invincibility.
- Add XP.
- Add gold.
- Teleport.
- Display statistics.
- Reset the run.

Sandbox mode must not alter normal progression.

---

# 29. SETTINGS

Implement:

- Fullscreen/windowed mode.
- Resolution.
- Render scale.
- Graphics quality.
- Camera sensitivity.
- Camera inversion.
- Audio volume.
- Key rebinding.
- Screen shake toggle.
- Damage number toggle.
- Reduced effects mode.
- FPS display.
- Pause on focus loss.

---

# 30. TESTING AND DEBUGGING

Create automated tests for:

- Player movement.
- Damage calculations.
- Critical hits.
- Weapon cooldowns.
- Projectile collisions.
- Status effects.
- Character passives.
- XP thresholds.
- Level-up choices.
- Tome modifiers.
- Item effects.
- Enemy spawning.
- Boss transitions.
- Unlocks.
- Save/load.
- Victory and defeat.

Use Godot headless validation wherever possible.

Check for:

- Parse errors.
- Missing scripts.
- Missing resources.
- Invalid scene references.
- Runtime errors.
- Broken animations.
- Invalid collision behaviour.
- Performance regressions.

Do not report a feature as complete unless it has been validated.

---

# 31. PROJECT STRUCTURE

Use a modular Godot project structure.

Suggested layout:

project.godot

scenes/
- main/
- player/
- enemies/
- bosses/
- weapons/
- projectiles/
- world/
- interactables/
- ui/

scripts/
- core/
- player/
- combat