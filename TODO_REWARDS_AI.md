# Shrine rarities, reward effects, pursuit and HUD

Active specification: user upload 27 October 2026. Baseline f56a084, Godot 4.7.2; existing v8 has 22 passing suites and a verified Windows release. Preserve vertical terrain, object counts, themes, crowd support, boss groups and saved chest queues.

Audit: XP update forcibly attracts every gem aged >25 seconds and has no explicit attraction reason/state. Quest claim calls quests() and recreates TabContainer at tab zero. No true active-only gameplay quest tracker exists (home closest-unlocks also includes completed/unclaimed quests). Ordinary AI can enter melee windup/recover despite independent contact damage. RewardCelebration stops confetti at age 3. Chest uses a horizontal strip. Minimap reads avatar.rotation.y. Shrine decay is zero and completion grants one randomly selected flat stat immediately.

- [x] Fix XP attraction lifecycle and quest state/tab/scroll behavior.
- [x] Continuous ordinary contact pursuit; preserve special abilities.
- [x] Configurable decay and saved three-choice rarity shrine rewards; seeded golden shrines.
- [x] Single-icon chest reveal and persistent bounded celebration/audio.
- [x] Horizontal owned-equipment HUD and camera-facing map marker.
- [ ] Integration, rendering at three resolutions, distribution/performance audit.
- [ ] Clean commits, gated Windows export and verified publication.

No claim of native Windows execution or gaming-GPU 60FPS is permitted without actual evidence.
