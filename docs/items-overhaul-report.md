# Item Overhaul — implementation report

Status: all 60 items implemented and validated headless (full `tools/validate.sh` exit 0, including the two new item suites).
**Not playtested by a human, no item screen seen on a real display, audio unchanged and unheard, Windows build never run on Windows.**

## 1. Roster (single source: `data/items.json` → `Catalog.ITEMS`)

| Item | Id | Tier | Kind | Short effect |
|---|---|---|---|---|
| Whetstone | whetstone | Common | stacks | +10% damage |
| Pilgrim's Sandals | pilgrims_sandals | Common | stacks | +8% movement speed |
| Gambler's Knucklebone | knucklebone | Common | stacks | +5% crit chance |
| Salted Pork | salted_pork | Common | stacks | +20 max HP |
| Tallow Candle | tallow_candle | Common | stacks | +2 HP regen per second |
| Flagellant's Cord | flagellants_cord | Common | stacks | +10% attack speed |
| Tithe Purse | tithe_purse | Common | stacks | +15% gold from kills |
| Bone Reliquary | bone_reliquary | Common | stacks | +8% XP gain |
| Crowsfoot Charm | crowsfoot_charm | Common | stacks | +12% evasion (diminishing) |
| Executioner's Hood | executioners_hood | Common | stacks | +20% damage to enemies above 90% HP |
| Bounty Writ | bounty_writ | Common | stacks | +15% damage to elites and bosses |
| Rusted Key | rusted_key | Common | stacks | 10% chance to open a chest for free |
| Hermit's Ember | hermits_ember | Common | stacks | Stand still 1 s: heal 3% max HP/s |
| Mourner's Veil | mourners_veil | Common | stacks | +5% move speed; +25% for 2 s after a hit |
| Gravedigger's Spade | gravediggers_spade | Common | stacks | Vases: 15% chance of an extra pickup |
| Cracked Hourglass | cracked_hourglass | Common | stacks | Stopwatch lasts +2 s |
| Tinder Pouch | tinder_pouch | Uncommon | stacks · needs FIRE GEM | Burning enemies take +15% damage |
| Rime Shard | rime_shard | Uncommon | stacks · needs ICE GEM | Chill +50% duration; Shatter radius +1 m |
| Leper's Bell | lepers_bell | Uncommon | stacks · needs CORROSIVE GEM | Corrosion stacks deal +20% damage |
| Lodestone | lodestone | Uncommon | stacks · needs ELECTRICITY GEM | Stunned enemies take +25% damage |
| Plague Doctor's Mask | plague_mask | Uncommon | stacks | +20% damage to enemies with any status |
| Brute's Gauntlet | brutes_gauntlet | Uncommon | stacks | +20% damage at close range |
| Tax Collector's Ledger | tax_ledger | Uncommon | stacks | +2.5% damage per chest opened (run) |
| Skin of Bitter Wine | bitter_wine | Uncommon | stacks | +20% damage, −10% max HP |
| Hangman's Noose | hangmans_noose | Uncommon | stacks | Curses one enemy: 25% max HP/s |
| Pyre Ashes | pyre_ashes | Uncommon | stacks | Kills: 3% chance of roast meat (15% HP) |
| Thunderstruck Nail | thunderstruck_nail | Uncommon | stacks | Taking damage stuns nearby enemies |
| Restless Bones | restless_bones | Uncommon | stacks | Chest or vase summons 2 wraiths for 8 s |
| Forgemaster's Tongs | forgemasters_tongs | Uncommon | stacks | Imbue Station costs 20% less |
| Leaden Heart | leaden_heart | Uncommon | stacks | Heart power-up: +10% damage for 15 s |
| Pilgrim's Pack | pilgrims_pack | Rare | stacks | +1 projectile for all weapons |
| Saint's Finger | saints_finger | Rare | Unique | Every on-hit effect rolls one extra time |
| Butcher's Hook | butchers_hook | Rare | stacks | Crits: 15% chance of a Brutal Crit (×2) |
| Blood Chalice | blood_chalice | Rare | stacks | Crits: 20% chance to heal 2% max HP |
| Shade Cloak | shade_cloak | Rare | stacks | After evading: next hit ×2, speed for 3 s |
| Soul Lantern | soul_lantern | Rare | stacks | Kills: 12% chance of an extra XP gem |
| Mire Flask | mire_flask | Rare | stacks · needs CORROSIVE GEM | Hits on Corroded: 15% chance of a puddle |
| Grave Hound Whistle | hound_whistle | Rare | stacks | Every 15 m, a skeletal hound charges |
| Gem Cutter's Loupe | gem_loupe | Rare | stacks | Gem statuses +30% duration and damage |
| Alchemist's Retort | alchemist_retort | Rare | stacks | Combos +30% radius, −25% cooldown |
| Cartographer's Candle | cartographers_candle | Rare | stacks | Vases, chests and Imbue on the minimap |
| Witch-Hunter's Brand | witch_hunters_brand | Epic | stacks | Armour + lifesteal per burning enemy |
| Martyr's Shroud | martyrs_shroud | Epic | stacks | Damage rises as HP falls, up to +60% |
| Shattered Codex | shattered_codex | Epic | stacks | XP gems slice enemies as they fly to you |
| Reaper's Sickle | reapers_sickle | Epic | stacks | Kills release 2 homing souls |
| Powder Keg Heart | powder_keg_heart | Epic | stacks | Hits: 25% chance to explode for 65% |
| Heretic's Prism | heretics_prism | Epic | stacks | Combos +50% damage and heal 1 HP each |
| Headsman's Oath | headsmans_oath | Legendary | Unique | 1% execute on hit; each adds +1% damage |
| Hourglass of the Damned | hourglass_damned | Legendary | Unique | First lethal hit: freeze time 5 s, heal to 50% |
| Anvil of the First Forge | anvil_first_forge | Legendary | Unique | Every upgrade and Imbue gains +1 stat |
| Rosary of Teeth | rosary_teeth | Common | stacks | +5% crit chance, +10% crit damage |
| Grave Salt | grave_salt | Common | stacks | +15 max HP, +5% armour |
| Hex Penny | hex_penny | Common | stacks | +20% gold from smashed vases |
| Ouija Planchette | ouija_planchette | Uncommon | stacks | 3% chance a hit deals 10× damage |
| Black Candle | black_candle | Uncommon | stacks | Enemies within 3 m take 5 damage/s |
| Bloodletting Knife | bloodletting_knife | Uncommon | stacks | +25% damage, −15 max HP |
| Witch Bottle | witch_bottle | Rare | stacks | 20% chance to ignore incoming damage |
| Goat Skull | goat_skull | Rare | stacks | Burning kill: 10% to Ignite all within 3 m |
| Coven Sigil | coven_sigil | Epic | stacks | +15% damage per status on the enemy (max +60%) |
| Devil's Bargain | devils_bargain | Legendary | Unique | Each level-up: −5 max HP, +4% damage |

Tier counts: 19 Common, 17 Uncommon, 13 Rare, 7 Epic, 4 Legendary. Uniques (held once, never stack): Saint's Finger and the four Legendaries. Item art is the supplied 32×32 set in `assets/icons/items/`, shown at whole-number scales with nearest filtering.

## 2. Architecture

- `data/items.json` is the only place names, tiers and effect text live. `Catalog.ITEMS`, `ITEM_IDS`, `item_name/tier/unique/description` read it. Cards, tooltips, shop rows and chest results use it (short text on the card, full text plus "Needs a Fire socket gem" in the tooltip).
- `scripts/items/item_stats.gd` (`ItemStats`): every number, tagged SPEC or GUESS like `Elements.TUNING`.
- `scripts/items/item_runtime.gd` (`game.irt`): all effects. Inventory is `game.items = [{id, stacks}]`, mirrored in `irt.stacks`. Stat effects are folded into `game.stats` as deltas and recomputed only when something changes (acquire, level-up, buff start/end).
- `scripts/items/item_drops.gd`: tier-first drops (50/28/15/5/2 with the existing luck boost) using the seeded game RNG before any animation; vases give Common/Uncommon only; shops sell every tier except Legendary; owned Uniques and items disabled in Unlocks are skipped.
- `scripts/items/item_migration.gd`: old-run migration.
- Unlocks: `items:<id>` entries with enabled toggles in `MetaProgress`; everything starts unlocked and enabled. `MetaProgress.migrate()` erases entries for retired items.
- Item RNG is a separate stream (`run_seed + offset`, serialised), so weapon and gem rolls consume exactly the same `game.rng` values as before for runs without proc items.

### Hooks (each called from one place, guarded by a boolean so unused hooks cost nothing)
`on_stats` (refresh_stats) · `on_hit` / `on_crit` (inside `Game.hit`, weapon hits only) · `on_kill` (`kill_enemy`) · `on_damage_taken` / `on_evade` / Witch Bottle / Hourglass (`Game.hurt`) · `on_level_up` (`on_level`) · `on_chest_opened` (paid and free chests) · `on_vase_smashed` (`Vases.break_vase`) · `on_powerup` (`WorldPickups.collect`) · `on_tick` / `on_still` / `on_move` (`irt.tick`, only while `ticking`).

### No recursion
All item damage goes through `Game.hit()` with `{"item": true, "source": "item:<id>"}`. `Game.hit` skips crit rolls, the player damage stat and lifesteal for item hits, never calls `irt.on_hit` for them, and flags the enemy `last_item`, so kills made by item damage never trigger kill procs (Soul Lantern, Pyre Ashes, Goat Skull, Reaper's Sickle). `Game.hit()` remains the only caller of `StatusManager.on_hit`. Saint's Finger adds one extra roll only to weapon-hit procs (`roll_hit`, plus the Fire/Electricity gem rolls). Tests prove each of these.

### Summons and pools (hard caps, refusals counted in `irt.dropped`)
Wraiths 12 · Hounds 8 · Souls 48 · Mire puddles 24 · Roast meat 10 · Keg explosions 20 per second. Drawn with `PsxFx` immediate squares/segments/bursts; no nodes or materials are created.

### Hourglass of the Damned
`WorldTime.freeze(5)` sets hostile scale to 0 for 5 s (the same hostile-time system as the Stopwatch, saved and restored). It never touches `Engine.time_scale`. It triggers inside `Game.hurt` on the first hit that would be lethal, heals to 50%, grants 1.5 s of invulnerability and removes itself from the inventory.

## 3. Interpretation rules and every GUESS value

Bosses are never instantly killed: Headsman's Oath skips bosses and takes 25% max HP from elites; Ouija Planchette's ×10 is capped at 3% (boss) / 10% (elite) of max HP; Hangman's Noose skips bosses and does 6%/s to elites; Thunderstruck Nail stuns bosses for 0.5 s. Evasion uses the existing 75% cap; Crowsfoot Charm stacks as 1−(1−x)ⁿ. Armour uses the existing 100/(100+5·a) formula (Grave Salt = 1 armour per stack). Witch Bottle is a separate roll after evasion, capped at 60%.

GUESS values (all in `ItemStats`):

| Item | GUESS |
|---|---|
| Drops | vase item chance 4%; shop prices 15/25/40/65/150 by tier |
| All stacking procs | independent rolls per stack, capped (Rusted Key, Spade, Soul Lantern 75%; Tongs discount 80%; Witch Bottle 60%) |
| Crowsfoot Charm | diminishing 1−(1−0.12)ⁿ |
| Grave Salt | +1 armour per stack ("+5% armour" is not an existing stat) |
| Brute's Gauntlet | close range = 4 m |
| Max HP floor | 10 (Bitter Wine, Bloodletting Knife, Devil's Bargain) |
| Mourner's Veil | "+25% more" read as +0.25 speed for 2 s |
| Gravedigger's Spade | the extra pickup is a duplicate of the vase's own reward |
| Vase item drop | granted immediately with a toast (no reveal animation) |
| Pyre Ashes | meat pool 10, lasts 30 s, pickup radius 1.4 m |
| Thunderstruck Nail | radius 6 m, stun 1.5 s, 3 s cooldown, boss stun 0.5 s |
| Restless Bones | wraith speed 9, 12 + 0.5/level damage, hit every 0.5 s, search 16 m, pool 12 |
| Leaden Heart | stacks add +10% each; timer refreshes |
| Black Candle | +4% damage per player level, 0.5 s tick, stacks add damage |
| Cartographer's Candle | also marks unbroken vases (small purple dots) and forces chest/Imbue markers visible |
| Mire Flask | puddle radius 2.2 m, 4 s, 8 dps, 0.25 s global cooldown, pool 24 |
| Leper's Bell | "corrosion stacks" read as item stacks: +20% corrosion damage each (corrosion itself does not stack) |
| Gem Cutter's Loupe | +30% duration and +30% damage per stack on poison, burn, stun, chill hold, shatter and combo damage |
| Alchemist's Retort | +30% radius / −25% cooldown per stack (cooldown floor 25%) |
| Heretic's Prism | +50% combo damage and 1 HP per combo, per stack |
| Coven Sigil | cap scales with stacks (60% per stack) |
| Witch-Hunter's Brand | 0.4 armour (cap 8) and 0.2% lifesteal (cap 4%) per burning enemy, re-counted every 0.5 s |
| Shade Cloak | +25% attack and move speed for 3 s; ×2 applies to the next weapon hit only |
| Grave Hound Whistle | speed 22, length 14 m, 20 + 1/level damage, one hound per stack fanned, direction = last movement |
| Hangman's Noose | search 14 m, stacks multiply the rate, elites 6%/s |
| Martyr's Shroud | linear in missing HP (+60% at 0 HP) per stack |
| Shattered Codex | 8 + 0.4/level damage, 1.1 m radius, 0.4 s per-enemy cooldown, 16 gems checked per frame |
| Reaper's Sickle | 2 souls per stack, 15 + 0.6/level damage, speed 14, 3 s life, pool 48 |
| Powder Keg Heart | radius 3 m, 20 explosions/s, explosion damage = 65% of the damage dealt |
| Headsman's Oath | elites lose 25% max HP |
| Anvil of the First Forge | "+1 extra stat" = one extra random stat from the weapon's own pool after each upgrade and each Imbue |
| Ouija Planchette | boss cap 3% / elite cap 10% max HP |
| Stack sanity clamp | 99 |

## 4. Tests

- Full `tools/validate.sh`: exit 0 (1731 PASS lines in the final run; every suite 0 failures).
- `tests/items_regression.gd` — **150 checks, 0 failures**: 60-item catalog equals items.json field for field; tier counts; Uniques; 60 icons exist, are 32×32 and import without mipmaps; whole-number icon scales; tier weights over 4000 seeded rolls; Unique never drops twice; vases Common/Uncommon only at the configured rate; shops never sell Legendary; disabled items never drop; every stat number against its text; each proc's rate over a seeded sample (Rusted Key, Witch Bottle, Spade, Soul Lantern, Pyre Ashes, Ouija, Mire Flask, Goat Skull, Headsman's Oath, Butcher's Hook, Blood Chalice, Saint's Finger, Powder Keg); boss/elite caps; pool caps and drop counters; no-chain tests (item kills trigger no kill procs, item hits never roll Ouija or crit procs, keg explosions are item damage); gem boosters inert without their gem (Tinder, Lodestone, Leper's Bell, Mire Flask, Goat Skull, Brand, Retort/Prism); Hourglass fires once and never changes `Engine.time_scale`; old-save and `MetaProgress` migration.
- `tests/items_smoke.gd` — **7 checks, 0 failures**: all 60 items equipped (second stack of every non-Unique), four gem-socketed weapons, 600 frames with a crowd, chest/power-up/evade/level hooks, a teleport, then save and load.
- Existing tests updated for string ids and stacking (integration, menu_systems, milestones, reward_ui, reward_drops, rewards_ai_v9, imbue_station, forest_physics, sockets, rarity). The tests for retired Phoenix Seal / Timekeeper were replaced by a check that those stats no longer exist.

## 5. Performance (headless CPU simulation only — no GPU, no mixer)

`tools/item_perf_profile.gd`, 600 frames per case, stationary 1e9-HP enemies so every hook keeps firing, four gem-socketed weapons (Sword, Firestaff, Lightning Staff, Revolver with two gems each), per-frame hostile update excluded (weapons + projectiles + `irt.tick` + PSX tick). Loadout A: Saint's Finger, Powder Keg Heart, Pilgrim's Pack ×3, Reaper's Sickle, Heretic's Prism. Loadout B: every item at 5 stacks (Uniques at 1).

| Loadout | Enemies | avg ms | p95 ms | max ms | PSX dropped (cumulative counter) | Item pool refusals |
|---|---|---|---|---|---|---|
| A | 50 | 0.29 | 0.79 | 3.68 | 0 | {"kegs": 102} |
| A | 150 | 0.40 | 1.18 | 4.81 | 0 | {"kegs": 238} |
| A | 300 | 0.57 | 1.69 | 6.39 | 0 | {"kegs": 419} |
| A | 500 | 0.79 | 2.37 | 9.57 | 111 | {"kegs": 632} |
| B | 50 | 0.67 | 1.26 | 5.31 | 111 | {"kegs": 291} |
| B | 150 | 0.88 | 1.88 | 6.14 | 111 | {"kegs": 611} |
| B | 300 | 1.12 | 2.60 | 8.87 | 120 | {"kegs": 1058} |
| B | 500 | 1.44 | 3.70 | 13.22 | 1211 | {"kegs": 1636} |

Notes: the PSX dropped counter is cumulative across the whole profile run (A@500: 111, B@500: 1091 more). Those are cosmetic particles refused at the hard cap; no weapon timers were dropped. Item pool refusals are Powder Keg explosions beyond the 20/s limit — this limit is doing its job under 5 stacks (chance ~76%) in a stationary crowd. Real frame time on target hardware is **unmeasured**.

## 6. Outstanding / unverified

- **Nothing has been seen on screen.** Pause Items grid, chest reveal, shop rows, tooltips with the "Needs a … socket gem" line, minimap markers from the Candle, and every item VFX (wraiths, hounds, souls, puddles, meat, curse line) were only exercised headless. Their look and readability are unjudged.
- Not played: balance of every GUESS value is untuned; Loadout B (every item ×5) is a stress test, not a design target.
- Full `validate.sh` ran once after all four batches. Batches 2–4 were checked with the item suites plus the affected existing suites between commits, not with a full validate after each commit as requested; the single full run covers the final state.
- Vases hand out their item instantly with a toast and no reveal animation.
- Hourglass freeze: enemies and spawns stop, but hostile projectiles already in flight are also scaled to 0; nothing was checked visually.
- Cartographer's Candle changes only minimap drawing; the pause-screen minimap copy uses the same drawing code but was not viewed.
- Docs that still mention the retired items: `docs/CORE_OVERHAUL.md`, `docs/rewards/ASSIGNMENTS.md`, `docs/audio/SOURCE_INVENTORY.json` were not rewritten.
- Debug/sandbox "add a specific item" button was not added.
- No audio events were added for items; they reuse existing sounds (pickup, hit, status).
- Windows export was built headless-compiled only; never run on Windows.
