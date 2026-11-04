# The new Stopwatch and the Fusion weapons — report

Branch `feature/stopwatch-fusions`. One commit per part: Stopwatch freeze, Stopwatch look, Stopwatch sound, Fusion data and names, Fusion look and sound + fused forms (one commit, see judgement calls), weapon VFX pack/models import, Forging moment, Ultimate sounds, then tests/captures/perf.

## What was built
**Stopwatch (Part A).** Hostile time is exactly 0 for 8 s (`WorldTime.HOSTILE_SCALE=0.0`; refresh, not stack; Cracked Hourglass still lengthens it; the Hourglass of the Damned uses the same system). Enemies, bosses, ghosts, enemy projectiles, spawning, contact and projectile damage all stop; the player keeps acting, damage and status ticks still land, everything resumes from the same state. `StopwatchFX` (CanvasLayer 1, under the HUD on layer 2) ports the handoff effect: flash + zoom punch + wave, desaturation with a bubble around the player, watch with ice wedge + number, 60 edge ticks, red only in the last 1.0 s, colour flood on release, extension (new total, ticks sweep up in 0.3 s, `+n.ns` tag, no second wave), reduce-motion, weather `speed_scale` 0.05 re-applied from state every frame (survives pause and level-up), frozen tint and one-frame jolt on enemies. The old overlay/bar/flash is deleted. Sounds: `powerup.stopwatch_activate` (replaces the file behind `powerup.stopwatch`), `_loop` (stopped on release, silenced by pause/level-up, restarted), `_end`; extensions play no new cue; magnet gets `magnet_activate` (not magnet_rush).

**Fusions (Part B).** Six Fusions (table in `scripts/sockets/fusions.gd`): Steamforged fire+ice, Plasma electricity+fire, Aurora electricity+ice, Livewire corrosive+electricity, Pyrebile corrosive+fire, Rimerot corrosive+ice. Names "<Fusion> <Weapon>" in the HUD tooltip, inventory, Inspect build, level-up cards, Results (epithet in tooltips). Fusion look (tint/trail/impact/status/motes) draws through the pooled `PsxFx`, impacts share the 24/s combo budget. Eight forms: lightning staff storm cloud + tethers, bow splits into 3 shards on the first pierce, revolver every 6th shot is a judgement round that leaves a line of pops, aura twin rings with every 3rd pulse erupting, scythes leave a vortex where they turn back, shotgun leaves a bile wall, sword every 3rd slash throws a crescent, firestaff comet → meteor shower. All form damage goes through `Game.hit()` tagged with the Fusion (`damage_by_fusion`, `damage_by_form`) and a boss clamp (a form hit never takes more than 2 % of a boss's max HP). Audio: `fusion.<id>.attack/.hit/.loop` replace the element layers for a Fusion (never both); one-gem weapons are unchanged.

**Forging moment (B4).** `ui/run/forge_scene.gd`: when the second gem completes a Fusion at the Imbue Station, a ~3.4 s sequence plays over the page (own SubViewport/World3D, the weapon's real model from `assets/models/weapons/`, two orbiting gems, collision at 0.85 s, shards out and back, re-form with the `fusion_overlay` shader, name card "FUSION FORGED · <COMBO> / <Fusion> <Weapon> / gems"). Every visual is a pure function of the timeline t; t is the combo sound's playback position (+mix time − output latency), with a clock fallback when the sound is muted/not playing. Skip (E / Space / Enter / Esc / click / pad) jumps picture and sound to the name card; a second skip closes. Non-Fusion second gems keep the plain fuse.

**Ultimates (Part C).** Cataclysm: `ult.cataclysm_activate` then `weapon.ult_cataclysm` (now the new file) in the same frame. Ghost Form / Berserker: opening on press, one loop while active (restarted after pause/level-up silence), end cue on expiry; loops stop on death/Results. Neither plays `combat.explosion` any more (kept for enemy blasts). `ult.ghost_dash` is not used: there is no dash in Ghost, and none was added.

## DPS (measured, `tests/fusions.gd`, headless)
Frozen dummies (1e9 HP), 12 s (30 dummies within 5 m) and 8 s (500 dummies within 28 m), same seed, player invincible. Units: damage / second summed over all dummies. "Fusion, no form" = Fusion look and ×1.25 damage but the attack form switched off.

| Weapon | Fusion (30) | Fusion, no form | One gem | No gem | Fusion (500) | No gem (500) |
|---|---|---|---|---|---|---|
| sword | 175 | 143 | 114 | 112 | 478 | 253 |
| firestaff | 322 | 23 | 18 | 18 | 590 | 18 |
| lightning staff | 248 | 21 | 17 | 17 | 655 | 90 |
| bow | 66 | 38 | 30 | 28 | 422 | 124 |
| revolver | 97 | 62 | 50 | 45 | 342 | 44 |
| scythe | 33 | 33 | 27 | 27 | 537 | 172 |
| aura | 614 | 347 | 185 | 185 | 1816 | 506 |
| shotgun | 226 | 111 | 76 | 74 | 494 | 77 |

Fusions are meant to be overpowered and are: ×1.2–3.4 over the no-gem weapon on a pack, and far more against a crowd for the area forms (firestaff/lightning staff/scythe/shotgun/aura). The firestaff and lightning staff forms carry almost all of their gain (23→322, 21→248) — if they feel too strong in play, `comet_damage_mult`, `meteor_damage_mult` and `cloud_damage_mult` are the knobs.

**Endless still ends in death (analytic check, not a playtest).** At 20:00 a ghost has 60·1.14²⁰ ≈ 825 base HP (×3.0 for the top tier ≈ 2 500), 12·1.35²⁰ ≈ 4 800 contact damage against a 150-HP build, and 600 ghosts live (`ghost_cap`) arriving in rings 10–15 m away at ~30 m/s. The best double-Fusion crowd DPS measured above (aura 1816 + firestaff 590 ≈ 2 400/s) clears a few thousand HP in the <0.5 s a ring needs to arrive; one contact is lethal. Ghosts are not boss-class so the form boss clamp does not apply; bosses can never be one-shot by a form (2 % cap per hit).

## Every GUESS number
`DAMAGE_MULT 1.25`; `SAFETY.boss_hit_max_fraction 0.02`, `form_hits_per_second 160`. Forms (all in `Fusions.FORMS`; the *every Nth* and *3 shards* are SPEC, the rest GUESS): sword crescent_dist 6.5, crescent_time 0.5, crescent_width 1.4, damage_mult 1.6; firestaff comet_scale 1.5, comet_damage_mult 1.4, meteors 4, meteor_delay 0.18, meteor_gap 0.12, meteor_damage_mult 0.9, meteor_radius 1.7, meteor_range 9; lightning staff cloud_interval 0.9, cloud_strikes 2, cloud_damage_mult 0.7, cloud_height 4.2, tether_time 1.0, tether_tick 0.25, tether_damage_mult 0.18, cloud_range 22; bow shard_fan_deg 28, shard_damage_mult 0.75, shard_range 12, shard_speed_mult 0.85; revolver judge_damage_mult 3.5, judge_speed_mult 0.55, judge_scale 2.6, line_delay 0.35, line_spacing 0.7, line_radius 1.3, line_damage_mult 0.8, line_max_pops 16; scythe vortex_time 1.6, vortex_radius 2.4, vortex_tick 0.4, vortex_damage_mult 0.55, vortex_pull 3.0, max_vortices 8; aura inner_radius_frac 0.7, inner_damage_mult 0.6, erupt_damage_mult 2.5, erupt_crystals 6; shotgun wall_time 1.7, wall_width 3.8, wall_depth 0.9, wall_dist_frac 0.55, wall_tick 0.35, wall_damage_mult 1.4, max_walls 8. Pool caps: crescents 12, tethers 24, lines 10, cloud targets 4. Forge timeline marks (0.85 collide is the sound's FUSE marker; 1.07/1.43 shard out/back, 1.6 card, 3.4 end) follow the preview; the 0.6 s overlay ramp 2.0→0.65 is a guess.

## Judgement calls
- Fusion look and the fused forms are one commit: the forms draw through the same tinted `FusionFx`.
- Combat visuals are pooled `PsxFx` draws tinted by the Fusion palette, not the pack's `FusionLayer` GPU-particle nodes (those allocate nodes and tweens per effect, against "pool everything"). The pack's layer is used only inside the forge, where it runs a handful of times.
- The scythe's forge/held model is the pack's; thrown scythes in combat still use the placeholder mesh.
- "Two unrelated gems" cannot happen: the six pairs are every pair of the four gems, so every second gem of a different element completes a Fusion.
- Fusion overlay shader is applied in the forge. The game has no held 3D weapon model, so there is nowhere else to keep it.
- No spawns while frozen: spawning now requires `hostile_delta>0` (previously a stored spawn budget could still spawn on the first frozen tick).
- A reference cycle `WeaponRuntime` ↔ `FusionForms` leaked at exit and tripped `validate.sh`'s `^ERROR` grep; broken in `Game` when a runtime is replaced and on exit.
- `tests/audio_regression.gd` previously expected fire+ice to play both element layers; it now expects the single Steamforged layer.

## Captures (1920×1080, real render, Forward+ llvmpipe under xvfb)
- Stopwatch: `docs/images/stopwatch/stage{1,2,3}_{0_before,1_pickup_wave,2_frozen,3_extension_tag,4_last_second,5_release}.png` (each stage's dressing). Tool: `tools/stopwatch_capture.gd`.
- Fusions in combat: `docs/images/fusions/sword_<fusion>.png` (six Fusions on the sword) and `form_<weapon>.png` (eight forms with Steamforged). Tool: `tools/fusion_capture.gd`.
- Forging moment: `docs/images/fusions/forge_steamforged_<weapon>_t{050,114,180}.png` for all eight weapons (t=0.5 s orbit, 1.14 s shards, 1.8 s name card). Tool: `tools/forge_capture.gd`. I did not compare them frame-for-frame with `fusions/clips/forge_<weapon>.mp4`; the timeline and beats follow the preview script.

## Performance (`tools/fusion_perf.gd`, 500 enemies, stage 1, 1280×720, software GL)
| Config | draw calls | frame ms (software GL) |
|---|---|---|
| baseline | 726 | 706 |
| Stopwatch active | 793 | 950 |
| two Fusion weapons (aura + firestaff, fire+ice) | 1065 | 831 |
| both | 858 | 959 |

Frame times under llvmpipe are only comparable run to run (and ran beside other jobs): they show no systematic cost from Fusions, but the Stopwatch full-screen pass is visibly heavier on software GL. Draw calls rise by ~70 for the Stopwatch and by up to ~340 for two Fusion weapons at 500 enemies (the count varies with how many enemies are alive in the frame). That is the number I would look at first if a real GPU shows a cost.

## Tests
`tests/stopwatch_fx.gd` (41 checks) and `tests/fusions.gd` (86 checks) are in `tools/validate.sh`. They cover the checklist: hostile time 0, nothing moves/spawns/hurts, resume; start/extend/release for 8 s, longer, refresh and Hourglass; tick fraction; red only in the last second; layer order; weather restore after pause and level-up; `Engine.time_scale`; loop stop on release and pause; gem-pair mapping both orders; non-combo pairs; Fusion audio layers replace element layers; every form's damage through `Game.hit()` (all damage dealt equals all damage recorded); DPS table; pool caps and the 24/s budget at 500 enemies; seeded run identical with audio on/off (VFX are not switchable, see below); models load with markers; forge collision within one frame including a 200 ms first-frame hitch; skip; muted forge; manifest sounds on disk; ultimates.

## Outstanding / unverified
- **Nothing was heard or played by a human.** All sound wiring is verified by counting emitted events, not by listening.
- **Nothing was seen on real hardware.** Captures are software-rendered; the Forge's audio-clock sync was tested through an injectable clock and the clock fallback, not against a running audio device (the headless driver does not play).
- Sound levels were **not measured**: events use the manifest/pack gains (`gain_db −12`, fusion events pitch ±0.04). The "measured levels" the spec asks for are not in this report.
- Sounds: every WAV came from the sound zip, imported as is (loops `loop_mode=2`, others 1). No fallback copies from the pack's `docs/` were used. `ult.ghost_dash` (and its three WAVs) are imported but unused because Ghost has no dash.
- Determinism with VFX off was not tested (there is no switch to turn VFX off); the test covers audio on/off and two identical runs. VFX use only their own cosmetic rng.
- Forge capture vs the preview clips was not compared frame for frame. The forge Esc key skips rather than opening the pause menu.
- Balance: GUESS numbers above are untested by play. Endless lethality is an analytic argument from measured DPS, not a played 20-minute run. The firestaff/lightning staff forms are probably the strongest.
- Draw-call cost of two Fusion weapons at 500 enemies (+~340) is unoptimised.
