# Weapon Overhaul 2.0 — implementation report

Status: implemented and validated headless; **not yet playtested by a human, audio never heard, Windows build never run on Windows.**
Outstanding dependency: **the scythe model** (see "Outstanding").

## 1. Roster (single source: `Catalog.ACTIVE_WEAPONS` / `Catalog.WEAPONS`)

| Id | Weapon | Notes |
|---|---|---|
| 0 | Sword | white angular slash, burst count |
| 1 | Firestaff | fireball fan, knock-back + flame burst |
| 2 | Lightning Staff | bolts from above, separated targets, chain |
| 6 | Bow | dark piercing arrows, glowing white tip |
| 7 | Revolver | silver bullets, grey smoke trail, ricochet |
| 9 | Scythes | renamed from Bananarang; placeholder mesh |
| 10 | Aura | dark-green occult circle, pulse damage |
| 15 | Shotgun | 6 independent pellets, single blast |

Chunkers, Mines, Bones (and every other retired id) are gone from the catalog, pools, loadout lists, rewards, audio registry, icons and tests.
Ids are kept stable so saves remain valid; `Catalog.WEAPONS` is now a sparse Dictionary. Loading an old run drops retired weapons, refunds their gems, and equips the Sword if nothing is left. `MetaProgress.migrate()` erases retired `weapons:N` unlock entries.

## 2. Upgrade pools (`WeaponUpgrades.POOLS`, exactly the specified stats)

| Weapon | Stats offered |
|---|---|
| Sword | Projectile Count, Size, Damage, Attack Speed |
| Firestaff | Projectile Velocity, Projectile Count, Damage, Size |
| Lightning Staff | Projectile Count, Damage, Size, Projectile Bounces, Attack Speed |
| Bow | Damage, Attack Speed, Crit Chance, Crit Damage, Projectile Count, Projectile Speed, Size |
| Revolver | Damage, Attack Speed, Crit Chance, Crit Damage, Projectile Count, Projectile Speed, Projectile Bounces |
| Aura | Attack Speed, Size, Damage |
| Scythes | Attack Speed, Damage, Projectile Count, Projectile Speed, Size |
| Shotgun | Attack Speed, Size, Damage, Crit Chance, Crit Damage, Projectile Count |

Capped stats (bounces, count) stop being offered once at cap. Cards show `Weapon — Stat`, icon, level, rarity styling and `current → new` (e.g. `Projectile Count: 3 slashes per burst → 4 slashes per burst`) produced by the same `WeaponStats.resolve()` that combat uses, so the card can never disagree with the weapon. Rarity still drives the upgrade roll/metadata; it is not cosmetic-only.

## 3. Architecture

- `scripts/weapons/weapon_stats.gd` — tuning constants and `resolve()`: the single source of numbers for cards, tooltips and combat.
- `scripts/weapons/weapon_runtime.gd` (`game.wrt`) — all firing/stepping for the eight weapons. Pools: fireballs 60, arrows 120, bullets 120, scythes 40, timers 400 (drops are counted). Own RNG so seeded runs are untouched.
- `scripts/weapons/psx_fx.gd` (`game.psx`) — shared PSX VFX framework (below).
- `scripts/weapons/weapon_feel.gd` — palettes, impact/audio mapping and per-weapon effect recipes.
- `scripts/debug/weapon_lab.gd` + `tools/weapon_lab_capture.gd` — test scene / debug mode used for every screenshot.
- Removed: `weapon_vfx.gd`, `weapon_art.gd`, `launch()`, fields, orbit/summon code.

**Shared hit interface:** every weapon damage goes through `WeaponRuntime.strike()` → `Game.hit(e,damage,id,{source,dir,pos})`. `Game.hit` is the only place that calls `StatusManager.on_hit`, so all eight weapons and every hit type (slash, fireball, strike, chain, arrow, bullet, ricochet, pulse, scythe out/back, pellet) apply Elemental Sockets exactly once per hit, with no per-weapon socket code.

## 4. Projectile rules (as implemented)

- **Sword** — white angular slash at nearest enemy; Count = sequential slashes 0.10–0.15 s apart; one hit per enemy per slash.
- **Firestaff** — flickering blocky fireball + embers; impact knocks the enemy back and bursts into flame; Count = fan; no ground fire.
- **Lightning** — bolt strikes from above; Count = initial strikes on separate targets (spacing from strike radius); Size = strike radius; bounces chain with a hard limit, claim victims immediately (no ping-pong), 0.85 falloff. Natural lightning is blue.
- **Bow** — dark shaft, white glowing tip, piercing by default, per-arrow hit set, Count = symmetric fan.
- **Revolver** — silver bullet, discrete grey smoke squares, sparks; Bounces ricochet to another enemy (cap 6).
- **Aura** — dark-green rotating circle, damage in pulses with a lighter-green flash on hit enemies and a green pixel ring; Attack Speed changes pulse rate only; a pulse budget caps per-pulse effects and the hum plays once every ~2.6 s (no per-frame / per-enemy audio).
- **Scythes** — spinning, brown dust trail; outbound → homing return to the player's *current* position; separate out/back hit sets; 6 s max life, cap 40. Never lost.
- **Shotgun** — base 6 pellets, one blast, each pellet its own hit and crit roll; Count adds pellets, Size widens the cone (short range kept); heavier, lower sound than the revolver.

## 5. PSX VFX framework (`PsxFx`)

Everything is square hard-edged billboards, low-poly shards and stepped angular line segments, drawn with three MultiMeshes and two shared PSX-shader materials (vendor PSX includes: vertex snap, fog, nearest filtering). Struct-of-arrays pools with hard caps (squares 1400, shards 260, segments 720); excess is dropped and counted, never allocated. Colour and size change in three discrete steps, palettes are limited per weapon, and no per-effect nodes or materials are created. Hit flash is a stepped overlay in the enemy instance data (no per-hit materials) that never overrides poison/chill/ignite/stun tints; Aura hits flash light green, others white; crits add a restrained accent.

## 6. Audio mapping

Source: release `audio-assets-v1` (PixelCombat set), curated by `tools/curate_weapon_audio.py` with the project's dark pass (5 kHz low-pass, soft saturation, 10-bit grain, 32 kHz mono, short fades). Provenance for all 68 new clips: `docs/audio/WEAPON_CURATION.json`. **Clips were chosen by waveform screening and never listened to.**

| Weapon | attack | hit | crit | special |
|---|---|---|---|---|
| Sword | swing (kept) | Smack / Swish Hit | Sword Critical | — |
| Firestaff | cast (kept) | Fire Hit / Small Flare | Pyro Burst | — |
| Lightning | strike (kept, renamed from zap) | — | Jacobs Ladder | thunder (Thud/Voltaic Blast, 0.14 s later), chain (Wet Electricity/Zap Clap, 0.11 s cooldown, 2 voices) |
| Bow | fire (kept) | Gore Pierce / Strong Smack | Critical Strike | — |
| Revolver | fire (kept) | Armor Piercer / Hit Rattle | Kick Critical | ricochet (Ricochet 1/2) |
| Aura | pulse (kept) | — | Weirdness | hum (Underwater, 1 voice, 2 s cooldown, −24 dB) |
| Scythes | throw (kept, was Bananarang) | Sweep Hit / Swish Clap | Homerunner | catch (Fleeting Hit) |
| Shotgun | fire (Mecha Engine Blast + Eruption, base pitch 0.72, −8 dB, 0.3 s cooldown) | Crunchy Burst / Strong Punch | Mecha Piercing Punch | — |

Every event has its own cooldown, `max_voices`, priority, gain and pitch variation in `assets/audio/events.json`. Layering is done by emitting two events (e.g. thunder 0.14 s after strike; shotgun fire + per-pellet hit), not by baked mixes. Hit sounds are emitted per hit but throttled by the per-event cooldown/voice limits; the existing 24-voice pool still bounds total voices.

## 7. Elemental Socket notes

Corrosive green, ice light blue, fire orange-red, electricity purple (unchanged). Lightning Staff's *natural* bolt is blue, the electricity gem's colour is purple — they are separate. `tests/weapons_regression.gd` fits an ice gem to each weapon and checks that every hit adds at most one chill (no duplicate procs) for sword, fireball, strike, chain, arrow, bullet, pulse, scythe and pellet sources. Gems survive level-up, rarity change, stage transition and save/load; a removed weapon's gems are refunded.

## 8. Performance (headless CPU simulation only — no GPU, no mixer)

`tools/weapon_perf_profile.gd`, 600 frames, 4 weapons equipped at once, stationary enemies, per-frame `update_weapons + update_projectiles + psx.tick`:

| Loadout | Enemies | avg ms | p95 ms | max ms | PSX live peak |
|---|---|---|---|---|---|
| Sword/Fire/Lightning/Bow | 50 | 0.12 | 0.29 | 1.48 | 226 |
| | 150 | 0.21 | 0.55 | 2.59 | 371 |
| | 300 | 0.36 | 0.98 | 4.08 | 592 |
| | 500 | 0.56 | 1.59 | 7.39 | 876 |
| Revolver/Scythes/Aura/Shotgun | 50 | 0.43 | 0.68 | 3.88 | 245 |
| | 150 | 0.52 | 0.78 | 2.62 | 258 |
| | 300 | 0.69 | 1.02 | 3.38 | 297 |
| | 500 | 0.92 | 1.27 | 5.14 | 342 |

No PSX particles or timers were dropped (peaks well under caps). Real frame time on target hardware is **unmeasured**.

## 9. Visual verification

All images are real renders (Forward+/llvmpipe under xvfb, 1280×720) from the weapon lab: `docs/images/weapons/*.png` (frames) and `docs/images/weapons/sheets/*.png` (contact sheets: sword burst/arc, fireball, fireball impact, lightning, bow, revolver, aura pulse, scythes, shotgun 6/7/9/12). Shotgun 6/7/9/12 are from the same camera and setup. Known visual limits: 6 vs 7 pellets differ by one tracer and are subtle; the Aura enemy flash is a strong saturated green; GIF clips were not produced (frame strips only); no look has been judged on real GPU or at 60 fps motion.

## 10. Regression results (full `tools/validate.sh`, exit 0)

New: `tests/weapons_regression.gd` — 103 checks (roster is exactly 8, removed ids absent, pools match spec and only offer own stats, card text, max level, caps, per-weapon behaviour rules, socket procs per hit source, old-save sanitising, stage persistence); `tests/weapons_smoke.gd` — 19 checks (all weapons fire/hit/clean up). Updated for the new roster: integration, menu_systems, milestones, polish, retro_audio, art_reset_gameplay, vases_powerups, combat_profile. Every suite reports 0 failures. One earlier flaky `integration` case was not seen this time but its cause is still unknown.

## 11. Outstanding / unverified

- **Scythe model not supplied.** A clearly named placeholder (`PLACEHOLDER_ScytheMeshes`) renders now; drop the model at `res://assets/weapons/scythe.glb` (`WeaponRuntime.SCYTHE_MODEL_PATH`) and wire it in.
- Weapon icons: Sword, Firestaff and Shotgun use the vendor fallback icon; Scythes reuses the old boomerang cell. New icons needed.
- Audio has not been heard. Mix balance, shotgun weight and hum level need ears.
- No human playtest; the Windows build has not been run on Windows.
- Hit-flash vs poison/chill/ignite/stun tints: verified by design (status tint and flash are separate channels) and by `dark_feedback`, not by screenshots of each combination.
- Perf numbers are headless CPU only.
