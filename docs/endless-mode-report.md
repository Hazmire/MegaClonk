# Endless mode report

Branch: `feature/endless-mode`. Source of truth for every number: `assets/config/endless_rules.json` (gameplay) and `assets/config/endless_timer_style.json` (HUD). Tests: `tests/endless_mode.gd` (92 checks, in `tools/validate.sh`). `tools/validate.sh` passes.

## What it does
- **Trigger.** The stage timer is per stage and counts down. When it reaches 0:00 the same timer node becomes the endless timer and counts up `endless_time`. It happens once per run (`endless_started`, saved with Save & quit). The portal seals (`Endless.LOCK_PORTAL = true`); a boss already alive stays.
- **Spawning.** Waves, elites, minibosses and elite statues stop for good. Level-ups, chests, shops, shrines, items and gems are untouched.
- **Clock.** `endless_time` advances inside `Game._physics_process` only in `mode == "run"`, so pause and every reward/menu screen stop it. The Stopwatch/Hourglass freeze ghost spawning and flight (hostile time) but not `endless_time`.
- **Ghosts.** Four tiers, one `MultiMesh` each, one shared mesh (`GhostMesh`) and one shared material per tier. They are ordinary `Game.enemies` entries flagged `ghost`, so weapons, `Game.hit()`, statuses, saves and revives all work. They fly straight at the chest, bank into turns, ignore terrain, use a 0.5 m sphere, fade in 0.6 s and out 0.25 s. Contact goes through `Game.hurt_contact`/`Game.hurt`. Spawn: 26–34 m ring (outside the view), heights -1..12 m, never inside 18 m. Live cap 600; at the cap the count stops growing and damage/speed keep escalating.
- **End.** Death is the only ending. `best_endless_time` is saved in the profile; Results lead with the endless time in red ("SURVIVED IN ENDLESS") and the existing stamp shows NEW RECORD. A death before 0:00 shows Results exactly as before.
- **Main menu.** The only place bests are shown is the Loadout screen's PERSONAL BESTS memo, which now carries a "Best endless" line once one exists. No new screen.

## Curves (per tier: spawn/s | HP | contact damage | speed m/s)
Spawn/s is the tier's share of total rate (rate x tier weight, before the Difficulty stat). Mourner 0:00, Drowned 3:00, Wrathful 6:00, Hollow 10:00; tiers never leave the mix. Values shown for tiers before they join are what they would have.

| Tier | 0 min | 5 min | 10 min | 15 min | 20 min |
|---|---|---|---|---|---|
| Mourner | 0.80 / 60 / 12 / 4.0 | 1.83 / 116 / 54 / 6.2 | 4.19 / 222 / 241 / 8.5 | 9.58 / 428 / 1082 / 23.5 | 21.91 / 825 / 4851 / 38.5 |
| Drowned | 0.36 / 132 / 12 / 4.0 | 0.82 / 254 / 54 / 6.2 | 1.88 / 489 / 241 / 8.5 | 4.31 / 942 / 1082 / 23.5 | 9.86 / 1814 / 4851 / 38.5 |
| Wrathful | 0.24 / 84 / 19 / 5.0 | 0.55 / 162 / 86 / 7.8 | 1.26 / 311 / 386 / 10.6 | 2.87 / 600 / 1731 / 29.4 | 6.57 / 1154 / 7762 / 48.1 |
| Hollow | 0.16 / 180 / 24 / 4.4 | 0.37 / 347 / 108 / 6.9 | 0.84 / 667 / 483 / 9.4 | 1.92 / 1285 / 2164 / 25.9 | 4.38 / 2474 / 9703 / 42.4 |

Targets and what the tests assert: speed passes the player's run speed (8.0) at 10:00 (8.5), passes the stress build (16.5) by 13:00 (17.5), one contact exceeds the stress build's ~190 effective HP by 15:00 (1082). Escalation is exponential per minute with no ceiling (tested monotonic for 120 minutes).

**Stress-build survival (simulation).** The stress build (every item x5, 8 weapons) running a 40 m circle at 16.5 m/s, no god mode, dies at **endless 16:38** (`tests/endless_mode.gd`). That is later than the 15:00 I aimed for: the player is fast and ghosts are killed on contact, so early minutes are survivable. It is a scripted runner, not a person; a human who stands still or is cornered dies far earlier.

## Judgement calls
1. **Difficulty applies to ghosts** (spawn rate, HP, damage, speed), like normal enemies.
2. **Stress run speed 16.5 m/s** is my assumption of the stress build's top speed; `endless_rules.json` holds it.
3. **Contact kills the ghost** ("spent"): no XP, no kill count. Otherwise a swarm reaching the player would also pay out.
4. **Ghost dictionaries are not pooled** (other systems may hold references); the render slots are pooled and capped, so nothing allocates per frame in drawing.
5. **The old Endless Revenant (kind 11) is no longer spawned.** Its code is left in place, unused.
6. **Timer layering:** the glow and blood-red copies are child Labels of the one HUD timer Label, so there is still exactly one timer node.
7. **Per-loadout bests:** the profile has one leaderboard (each record carries its loadout), not per-loadout best tables, so `best_endless_time` is overall only.
8. **"HUD at 09:58 (before)":** the timer counts down, so 09:58 is the start of a stage; I captured both 09:58 and 00:02 (just before the switch).
9. **Banshee level:** raw file -18.0 dB RMS / -1.9 peak vs `boss_enrage_*` mean -16.0 / -1.0, so `gain_db` is -10 (their -12 plus 2) to be level. Priority 8, `max_voices` 1, one play at the switch (verified, never on tier changes). Music dips 6 dB (no low-pass) for 3 s then restores; skipped while the level-up duck owns the bus. Imported as uncompressed PCM, no loop, like the other WAVs.
10. **Fog sea shader** (earlier pass) was written by me from the spec.

## Performance (`tools/endless_perf.gd`, software GL under xvfb at 1280x720; compare, don't trust absolutes)
| Scene | frame ms | draw calls |
|---|---|---|
| Empty stage | 230 | 367 |
| 500 normal enemies | 869 | 736 |
| 600 ghosts (cap), held in view | 857 | 739 |
| 600 ghosts live at minute 25 | 435 | 701 |

At the cap the ghost swarm costs about the same as 500 ordinary enemies on this renderer. Ghosts drawn: four MultiMesh nodes. The +370 draw calls over empty match the normal-enemy case, so I did not attribute them to ghosts; I did not profile further. Not measured on real hardware.

## Other fix found
`PsxFx` wrote past its 1400-square buffer when a heavy build fired (script error in the stress run). Immediate-mode squares are now capped at the buffer size.

## Captures (1920x1080, `docs/images/endless/`)
`01a_hud_before_0958`, `01b_hud_before_0002`, `02_glitch_frame`, `03_red_0000_settling`, `04_hud_endless_0100`, `05_hud_endless_0400`, `06_hud_endless_0700`, `07_hud_endless_1200`, `08_swarm_0min`, `09_swarm_10min`, `10_swarm_20min`, `11_pause_strip`, `12_results_new_record`, `contact_sheet`. Rendered with `tools/endless_capture.gd` (llvmpipe). The glitch and settle frames are driven by hand to a fixed time, not captured live.

## Outstanding / unverified
- **Not playtested by a human and not seen on real hardware.** Feel, readability of the swarm, the glitch timing and the banshee's actual loudness are unjudged; the loudness match is measured, not heard.
- The curves are tuned by arithmetic and one scripted survival run, not by play. Real players may die much earlier or later.
- Embers/smoke are driven from the capture, not seen animating live; the glitch is checked as frames, not motion.
- Results capture shows "RUN TIME 00:00" because the capture drives the clocks by hand; in a real run it is the whole run time.
- Old saves made mid-endless before this change derive `endless` from the stage clock; not tested against a real legacy file.
- Perf numbers are software GL only.

## Fix pass 1 (branch `fix/endless-pass-1`)
1. **Ghost waves.** The trickle spawner is gone. A wave is a ring of ghosts that appears at once, 10-15 m from the player, evenly spaced all the way round. The first wave (30) comes the instant endless starts, then one every 5 s; wave size is 30 x 1.22^minute (x Difficulty), so ~30 at 0:00, ~81 at 5:00, ~220 at 10:00, trimmed to the 600 live cap. Values: `spawn` in `assets/config/endless_rules.json` (`wave_base`, `wave_growth_per_min`, `wave_interval_s`) and `spawn_ring`.
2. **Ghost-vs-ghost collision.** A spatial hash over preallocated arrays pushes overlapping ghosts apart each frame (`Ghosts.separate`); no per-frame allocation.
3. **E / Space skip** the chest-opening cutscene (it already skipped with Space while the reel spun; now E too, and during the open and landing phases). The level-up fanfare already took both.
4. **Tab closes the build screen** (handled before the GUI's focus navigation can swallow it).
5. **Stage spawn ramp.** After 3:00 of a stage the spawn rate gets an extra multiplier of 1 + 0.35 per minute. The values are `spawn_ramp_start_s` and `spawn_ramp_per_minute` in `scripts/meta/run_rules.gd` (0 = old curve).
6. **Chest banish.** The chest reveal has a Banish button, 3 per run. Banishing takes the item back out of the bag, bans it from chests for the rest of the run, and the chest rolls a replacement (shown straight on its reveal). Saved with the run.
7. **Vases give no items** (`vase_item_chance` 0, no vase tiers); the Unlocks memo no longer lists vases as a source.
8. **XP gem gravity.** Gems fall to the ground and hover just above it; before, a gem dropped by a flying ghost stayed where it died.

Tests: `tests/endless_fix_pass_1.gd` (33 checks); endless, items, menus and audio tests updated. With waves the stress-build runner now dies at endless 13:46 (was 16:38). Unverified: feel and difficulty by hand; banish semantics (replacement roll rather than a plain skip) is my reading of the request.
