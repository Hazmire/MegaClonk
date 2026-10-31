# Megaclonk audio pack

All sound and music for Megaclonk's Fog County design. Everything is synthesised from code: original, no
third-party samples, nothing to license. Hear every sound in context on the Megaclonk soundboard artifact.

- `manifest.json` is the machine-readable list: one entry per **event**, with its files, bus, loop flag,
  positional flag, channel count, a description of when it plays, and suggested `cooldown`, `max_voices`,
  `pitch_var` and `priority` (the same fields `assets/audio/events.json` already uses).
- `audio/` holds the files to import. 186 WAV (44.1 kHz, 16-bit) + 10 OGG music loops, in 124 events.
- `reference/premixed_imbued_weapons/` holds 168 weapon sounds with a gem element already mixed in. **Reference
  only**: the game should layer `element.*` events at runtime instead (see below).

**The WAVs are finished. Don't low-pass, bit-reduce, resample or "dark pass" them.**

## Folders

| Folder | Files | Bus | Positional | What |
|---|---|---|---|---|
| `audio/ui/` | 58 (stereo) | UI | no | Menus, memos, level up, chest, shop, imbue station, panels, settings |
| `audio/weapons/` | 44 (mono) | SFX | yes | Attacks, hits, specials and loops for all 8 weapons + Cataclysm |
| `audio/movement/` | 19 (mono) | SFX | yes | Footsteps on dirt / grass / stone / wood, slides |
| `audio/player/` | 8 (mono) | SFX | no | Player hurt, heavy hurt, low-HP heartbeat loop, death |
| `audio/world/` | 19 (mixed) | SFX/UI | mostly | Gem-found popups, shrine charge/ticks/cancel/complete, stage boss death + victory, boss enrage roars |
| `audio/imbue/` | 10 (stereo) | UI | no | Element fuses (4) and combo fuses (6) at the Imbue Station |
| `audio/imbued_layers/` | 28 (mono) | SFX | yes | Gem element layers: attack ×3, hit ×3, loop, per element |
| `audio/music/` | 10 (OGG, stereo) | Music | no | Menu, level up, death, 2 tracks per stage, final boss |

## When things play (summary; full detail in `manifest.json`)

**Menus:** `ui.menu_move` on focus/hover change; `ui.menu_select` on confirm; `ui.menu_play` on Play;
`ui.menu_back` on Esc; `ui.menu_locked` on a locked entry; `ui.weapon_select` in the loadout dropdown;
`ui.run_start` on "Enter the …". Memos: `ui.memo_hover`, `ui.stamp_not_yet`, `ui.stamp_done`, `ui.quest_claim`.
Settings: `ui.toggle_on` / `ui.toggle_off`, `ui.slider_tick` per slider step. Panels: `ui.panel_open` / `ui.panel_close`.

**Level up:** `ui.levelup_toll` when the screen opens (its three bell rings match the animation's three rings),
`ui.card_deal` per card, `ui.reveal_<tier>` by the card's rolled tier, `ui.card_hover`, `ui.card_take`,
`ui.banish`, `ui.skip_heal`, `ui.refresh_shuffle`.

**Chest:** `ui.chest_hop` while it wobbles, `ui.chest_open`, `ui.reel_tick` per item passing the marker (or
`ui.reel_spin_full` if ticks can't be timed), `ui.reel_stop` when it lands, `ui.reveal_<tier>`, `ui.item_take`.

**Shop / gold:** `ui.gold_pickup` (ordered 01→03 on streaks), `ui.shop_buy`, `ui.cant_afford` (also the
generic error).

**Imbue Station:** `ui.gem_pickup` when a gem is picked up, `ui.socket_hover`, `ui.socket_place`, then
`imbue.imbue_fuse_<element>` for a first gem, or `imbue.imbue_combo_<combo>` when a second gem forms a combo.
`ui.imbue_fuse` is the generic fallback. Combo files are named per combo; the element pairs were inferred from
the names (Thermal Shock = fire + ice, Toxic Conduction = corrosive + electric, Caustic Combustion = corrosive +
fire, Blightfrost = corrosive + ice, Overcharge = fire + electric, Cryoshock = ice + electric). Map by combo name.

**Gems found:** `world.gem_found_<element>` with the gem pickup popup (UI, not positional).

**Shrine:** `world.shrine_charge_loop` while charging (positional; raise pitch from 1.0 to ~1.25 with progress),
`world.shrine_charge_tick` 01→05 at each 20%, `world.shrine_charge_cancel` if charging is interrupted,
`world.shrine_complete` when full (before the stat screen opens).

**Bosses:** `world.boss_enrage_<type>` when a boss becomes enraged. Suggested: stage 1 `beast` (or `bellow` for
the biggest), stage 2 `shriek`, stage 3 `abyssal`, final boss `god`. Each starts with a ~0.5 s inhale, a deliberate
tell. `world.stage_boss_death` at the boss when it dies, then `world.stage_boss_victory` (UI) about 2 s later.

**Weapons** (`weapon.*`): one attack event and one hit event per weapon, plus specials:
Sword `sword_swing` (alternate) + `sword_swing_final` + `sword_hit` (01→03 per burst);
Scythes `scythe_throw`, `scythe_spin_loop` (pitch with speed), `scythe_hit`, `scythe_catch`;
Bow `bow_shot` or `bow_volley` (projectile count > 1), `arrow_pierce` (01→03 per enemy pierced);
Revolver `revolver_shot`, `bullet_hit`, `revolver_ricochet`; Shotgun `shotgun_blast`, `shotgun_knockback`,
`shotgun_pump` (during cooldown); Lightning Staff `lightning_strike`, `lightning_bounce`;
Firestaff `fireball_cast`, `fireball_flight_loop` (optional), `fireball_impact`;
Aura `aura_loop` (while equipped), `aura_pulse` (each damage tick); Cataclysm `ult_cataclysm`.
**There are no crit sounds in this pack.** Keep the game's existing crit events.

**Imbued weapons** (`element.<fire|ice|corrosive|electric>.<attack|hit|loop>`): when a weapon carries a gem,
emit the element's `attack` layer with every attack and its `hit` layer with every hit (Aura pulses count as
hits). For Aura, Scythes and in-flight fireballs, run the element's `loop` alongside the weapon loop. A weapon
with two gems (Imbued Amulet) emits both elements' layers. The layers have their own cooldowns so fast weapons
don't stack them into noise.

**Movement / player:** `movement.step_<surface>` per footstep (random, never repeat), `movement.slide` +
`movement.slide_recover`; `player.player_hurt`, `player.player_hurt_heavy` (big hits), `player.low_hp_heartbeat_loop`
(72 bpm; speed it up as HP drops), `player.player_death`.

## Music

| Event | Plays |
|---|---|
| `music.main_menu_loop` | Main menu and every out-of-run screen |
| `music.level_up_loop` | Level-up screen (fades in under `ui.levelup_toll`) |
| `music.death_loop` | Death / game-over results (after `player.player_death`) |
| `music.stage1_a_…`, `music.stage1_b_…` | Stage 1, alternating A → B → A… with ~3 s crossfades |
| `music.stage2_a_…`, `music.stage2_b_…` | Stage 2, the same way |
| `music.stage3_a_…`, `music.stage3_b_…` | Stage 3, the same way |
| `music.boss_the_god_below` | Final boss stage (loops) |

All music is in D or built around it, so stings like the level-up toll and the shrine bell sit in tune.
Every track loops seamlessly. Stage and boss tracks are mastered louder (about −14/−15 dB RMS) than the menu,
level-up and death loops (about −16/−18 dB RMS); the manifest's `gain_db` evens that out. Start the Music bus
about 6–10 dB under SFX so weapon and pickup sounds stay clear.
