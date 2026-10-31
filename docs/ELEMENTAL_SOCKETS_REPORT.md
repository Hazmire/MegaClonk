# Elemental Sockets update — deliverables report

Branch `feature/elemental-sockets` (milestones committed one by one: d27fff3, 38c7879, 67d7576, 164c29c, 3bc6536, plus the final polish commit).

## What was built
| Area | Where | Notes |
|---|---|---|
| Gems, inventory, sockets | `scripts/sockets/` (`elements`, `gem_inventory`, `weapon_sockets`, `imbue_rules`) | Atomic installs with rollback; saves sanitised on load. |
| Status framework | `scripts/sockets/status_manager.gd`, `combos.gd` | Per-enemy `fx` dictionary created lazily; no per-hit allocation for unsocketed weapons; all status damage bypasses `Game.hit()` so nothing recurses. |
| Vases | `scripts/world/vases.gd`, `vase_loot.gd` | 25–40 per stage, deterministic by seed, **smashed with E** (weapons do not break them — changed on request). Weighted loot 35/25/10/10/10/10. |
| Power-ups | `world_pickups.gd`, `world_time.gd`, `ui/stopwatch_overlay.gd` | Heart +25% max HP; Magnet pulls every XP gem in staggered batches (gold/gems untouched); Stopwatch 8 s, hostile time ×0.2, refresh-not-stack, never touches `Engine.time_scale`. |
| Imbue Station | `scripts/sockets/imbue_station.gd`, `ui/socket_screens.gd`, `grimdark_objects.gd` | Exactly one per stage (extra interactable; falls back to converting a Chest). Costs 500/1000/1500 gold. Forge built from supplied PSX medieval blocks + shrine + element crystals. Minimap diamond. |
| Gem sources | `gem_rewards.gd` | Shop sells 2 gems at 250 g (not auto-installed); chests have a 12% gem chance; vases drop gems. |
| Build UI | `ui/socket_pips.gd`, `reward_screens.gd` | Grey/coloured socket diamonds on every weapon tile, gem counts, tooltips naming elements and combo. |
| Elements | `status_manager.gd` | Corrosive, Ice (with Shatter), Fire (ignite + crit bonus), Electricity (stun with diminishing returns). |
| Imbued Amulet | `gem_rewards.gd`, station screen | Found only in Epic/Legendary chest rewards (30%), max one per run, unlocks a second socket on one chosen weapon; second gem must differ. |
| Combos | `scripts/sockets/combos.gd` | Thermal Shock, Toxic Conduction, Caustic Combustion, Blightfrost, Overcharge, Cryoshock. |
| Audio | `assets/audio/sfx/sockets/`, `tools/generate_socket_audio.py` | 13 new events in `events.json` (vase.break, pickup.gold, gem.pickup, powerup.*, imbue.*, status.*). Synthesised, original. |

## Tuning: stated vs chosen
All numbers live in `Elements.TUNING` (and sibling `SETTINGS` tables), tagged `SPEC` (taken from the brief) or `GUESS` (my choice because the brief did not give a number). GUESS values: boss poison tick cap 60, shatter radius 3.5 / cap 150 / chain depth 2, every combo's damage %, cap, radius and cooldown, combo budget (24 per second), chest gem chance 12%, amulet chance 30% and one per run, vase/loot counts and spacing details.

## Testing performed
Full `tools/validate.sh` (headless Godot 4.7.2) passes with 0 failures across 31 suites, including the new ones: sockets 101, vases_powerups 45, imbue_station 29, elements 46, combos_amulet 41 checks. `tools/export.sh` builds the Windows pack and runs every smoke script from the compiled pack, including the new `export_socket_smoke.gd`.

## Performance (headless CPU simulation + weapon hits, ms per tick; lower is better)
Measured with `tools/profile_sockets.gd` on the cloud sandbox CPU; rendering excluded; run-to-run noise is roughly ±10%.

| Enemies | No sockets | Corrosive | Ice | Fire | Electricity | Fire+Ice | Corr+Elec | Ice+Corr+Stopwatch |
|---|---|---|---|---|---|---|---|---|
| 50 | 2.42 | 2.66 | 2.72 | 2.45 | 2.22 | 2.74 | 2.45 | 3.05 |
| 100 | 4.79 | 5.37 | 5.67 | 5.01 | 4.96 | 5.97 | 5.35 | 5.78 |
| 250 | 13.60 | 17.41 | 20.85 | 13.88 | 13.03 | 15.80 | 14.79 | 17.93 |
| 500 | 30.60 | 34.69 | 33.20 | 29.73 | 30.73 | 37.27 | 33.17 | 38.81 |

A repeat of the 250 case gave 14.0–14.9 (none), 14.9–16.4 (ice), 17.1–18.3 (ice+corrosive+Stopwatch), so the 20.85 above is an outlier. With every enemy carrying a status the overhead is about 0–25%. **Honest caveat:** even with no sockets this sandbox needs ~30 ms per tick at 500 enemies, and the existing 400-enemy benchmark drifted from 18.9 ms (before this work) to ~19.5–23 ms. I did not isolate how much of that is noise and how much is the new world-time/vase checks. These are not frame times on a real GPU.

## NOT verified
* **Nothing was seen on screen.** All testing is headless: the forge/vase/power-up models, Stopwatch screen tint, socket diamonds, tint colours for statuses, the Imbue Station layout and its text fit were never rendered or looked at. Expect to adjust sizes, colours and positions.
* **Windows execution:** the build is exported and its pack is exercised by Linux Godot, but it was never run on Windows.
* **Audio:** the new sounds load and are registered, but I could not listen to them; levels and character are untested by ear.
* **Gameplay feel/balance:** all GUESS values above are placeholders awaiting playtesting; frame-rate on real hardware at 250–500 enemies is unmeasured.
* The Stopwatch also slows status clocks (poison ticks, chill decay, stun) because they run on hostile time; this was a design choice, not a spec statement.

## Playtest feedback round 1
* Vase Heart / Magnet / Stopwatch now land 2.4 m from the player (towards the vase), outside the 1.5 m pickup radius, and are only collected by walking onto them. XP, gold and gems from vases fly straight to the player.
* Running gold (gold text) and XP (blue text) totals appear to the right of the player's head and clear 4 s after the last gain (`ui/pickup_tally.gd`).
* Shop gems are now ordinary slots in a shop's randomised offers (25% per slot, one purchase per seller like items) instead of a separate section.
* Socket diamonds show on the top-left HUD weapon icons, with element names in the tooltip.
* Picking up a gem raises a banner at the top of the screen coloured by element.
Tests added: `tests/pickup_ui.gd`, extra checks in `vases_powerups` and `imbue_station`. Still unverified visually: tally position and size, banner placement, the new gem icon in shop cards.

## Playtest feedback round 2
* Kill gold (and miniboss/boss gold) now drops as coins that always home in on the player, accelerating from any distance, and pay on arrival with the coin sound. Coins still in flight are paid out when a stage ends or the run finishes, so no gold is lost.
* Gold/XP head numbers: the lifespan bug was the timers being advanced once per HUD update (several per rendered frame) instead of by real time; they now use wall-clock time and stay for 4 s after the last gain (fading over the last 0.8 s), then restart from zero.
* Gold shows as `$N`, XP as `+N`; the shown number counts up quickly towards the real total, each step bounces the text (bigger totals bounce harder), font reduced from 26 to 20 with a soft shadow instead of an outline.
* Existing tests that assumed instant kill gold were updated (`stage_loop`, `polish`) to account for coins arriving in flight. Not visually verified: bounce feel, number position, coin flight speed.
