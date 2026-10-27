# Shrine rarities, reward effects, pursuit and HUD

Active specification: user upload 27 October 2026. Baseline f56a084, Godot 4.7.2; existing v8 has 22 passing suites and a verified Windows release. Preserve vertical terrain, object counts, themes, crowd support, boss groups and saved chest queues.

Audit: XP update forcibly attracts every gem aged >25 seconds and has no explicit attraction reason/state. Quest claim calls quests() and recreates TabContainer at tab zero. No true active-only gameplay quest tracker exists (home closest-unlocks also includes completed/unclaimed quests). Ordinary AI can enter melee windup/recover despite independent contact damage. RewardCelebration stops confetti at age 3. Chest uses a horizontal strip. Minimap reads avatar.rotation.y. Shrine decay is zero and completion grants one randomly selected flat stat immediately.

- [x] Fix XP attraction lifecycle and quest state/tab/scroll behavior.
- [x] Continuous ordinary contact pursuit; preserve special abilities.
- [x] Configurable decay and saved three-choice rarity shrine rewards; seeded golden shrines.
- [x] Single-icon chest reveal and persistent bounded celebration/audio.
- [x] Horizontal owned-equipment HUD and camera-facing map marker.
- [x] Integration, rendering at three resolutions, distribution/performance audit.
- [x] Clean commits, gated Windows export and verified publication.
- [ ] Dense 500-enemy optimisation and native Windows/gaming-GPU playtesting.

No claim of native Windows execution or gaming-GPU 60FPS is permitted without actual evidence.

Final local evidence: 23 suites, 859 named checks, 95 focused v9 checks, 1,986 Golden Shrines in 100,000 seeded placements, 15 source renders and compiled-pack captures at three resolutions, clean local export with four compiled gates. Source ea6c26f is pushed; PR #4 is open. Publishing workflow 40544084785 passed all 23 suites and four export gates. Downloaded shrine-rewards-v9 ZIP matched GitHub size/digest, passed every archive CRC and identified clean source ea6c26f. That downloaded pack passed a 180-frame world run plus reward/UI, stage/swarms and v9 smoke gates without script/resource errors. Dense-swarm CPU performance remains above the 60FPS budget (v9 38.55ms mean at 500 vs same-host v8 35.02ms); no gaming-GPU or native Windows certification is claimed.
