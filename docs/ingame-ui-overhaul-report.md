# In-run UI Overhaul — implementation report

Status: every in-run screen is rebuilt in the "Fog County" style on the menu foundation. `tests/ingame_ui_regression.gd` has **193 checks, 0 failures**; the full `tools/validate.sh` result is in section 5.
**Not playtested by a human. Nothing here has been seen on a real GPU, a real monitor, Windows hardware or a controller. Screenshots are software-rendered (Vulkan → llvmpipe) at 1920×1080.**

## 1. What was built
| # | Screen | Class | Notes |
|---|---|---|---|
| 1 | HUD | `RunHud` (+ `HudBar`, `HudNumber`, `RaritySlot`, `UltimateTile`) | Build rows, timer, stage line, stats, HP, ultimate, trait, paper minimap, XP; chest cost is the live `Economy` value |
| 2 | Notifications | `RunToasts` (+ `ToastQueue`, `PickupPopup`) | Pickup popups fly to their HUD slot; elite banner uses the game's own announce text |
| 3 | Boss bars | `RunBossBars` (+ `BossBar`) | Up to 2 stage + 2 miniboss bars, "+n more", damage trail, ENRAGED, SLAIN stamp, off-screen pointers |
| 4 | Pause | `RunPause` | Blurred frozen frame, Inventory/Stats panels, hold-to-confirm Abandon, Settings over the frozen frame |
| 5 | Level up | `RunLevelUp` (+ `LevelCard`, `LevelFanfare`) | Per-card tier, current → new from `WeaponStats`, Stats preview, Take / Banish / Skip / Refresh |
| 6 | Shop | `RunShop` (+ `ShopRow`, `PriceTag`) | Standard / Rare / Legendary frames, prices from `Economy`, "Need n more", Socket Gem rows |
| 7 | Shrine | `RunShrine` (+ `ShrineCard`) | The three real choices, Stats preview, Golden shrine, all-capped Continue |
| 8 | Treasure chest | `RunChest` (+ `ChestReel`, `ChestCard`, `ChestFx`) | Wobble → Open chest → jump 0.65 s → reel 6 s → land 1 s → reveal; hold Enter/click/Space skips |
| 9 | Imbue Station | `RunImbue` (+ `GemTile`, `SocketSlot`) | Pick gem → pick socket → confirm → fuse; amulet unlocks the second socket; same-element rule shown |
| 10a | Results / game over | `RunResults` | Real run figures, damage per weapon, requirements met |
| 10b | Sandbox menu | `RunSandbox` | Same callbacks as before, in the kit |
| 10c | Stage banner | `StageBanner` | Stage number + real stage title in its accent colour |
| 10d | Full map | `RunMap` | The HUD's own `RunMinimap` at full size; legend built from the map palette |
| 10e | Build inspector | `RunBuild` | Run totals + every weapon's tooltip and sockets |
| 10f | Bottom notice | `NoticeLabel` | Same `Label` API as before, drawn as a Fog plate |

Shared frame: `RunPanelScreen` (Inventory 420×870 | section 856×870 | Stats 420×870 on the 1920×1080 stage) for Level up, Shop, Shrine, Imbue, Map and Build. `RunData` is the single data layer (like `MenuData`): nothing in a screen reads game internals on its own. Prices come only from `Economy` / `ShopSystem` / `ImbueRules`.
Removed: the old stacked-offer reward screens and helpers (`RewardFrame`, `RewardCelebration`, `layout`, `offer`, `frame`, `equipment`, `statistics`, `celebration`).

## 2. Rules kept
- No gameplay or balance change. `Game.hit()` is still the only damage entry; reward results (chest item, shrine rolls) are decided before the screen opens and never re-rolled by it.
- The chest reel's filler cards use a private RNG seeded from the item and the chest count: `game.rng` is untouched (checked in tests) and the same chest always spins the same way.
- Stopwatch/Hourglass effects use hostile time, never `Engine.time_scale`. Pause screens do not touch it either.
- No per-hit allocations; effect pools are fixed (18 chest embers, the toast queue and boss-bar slots are capped).
- Stale controls cannot apply a reward twice (shrine and chest screens check the active reward before acting).

## 3. Judgement calls and deviations from the mockups
- **Data wins over mockup, look kept.** Imbue price on the screen is the real `ImbueRules.cost` (500 gold at stage 1 here); Socket Gem shop price is `Economy.gem_price` (65 at the test stage) where the mockup showed 250.
- **No "Unique" anywhere** (economy rework): chest card says "Item" plus "you now hold ×n" when you own more than one.
- **Save run → "Save & quit"** in Pause (what it actually does).
- **Banish uses up the pick** (unchanged rule); weapon cards on Level up have no Stats preview (weapons do not change stats).
- **Chest "Open chest" step** is a real extra press (as in the mockup). Hold Enter / click / Space for 0.35 s skips; reduced motion goes straight to the reveal. Common/Uncommon reveals read "You found", Rare and above "A <tier> find", Legendary "A legendary find / The bells toll".
- **Imbue**: fusing installs through `ImbueRules.install()` immediately and then plays the 0.9 s fuse animation (the mockup deducts after the animation; doing it first keeps the transaction atomic if the player quits mid-animation).
- **Icons** are drawn at whole-number scales (the mockup's non-integer sizes would blur the pixel art).
- **Key chips** on the pause menu stay keyboard glyphs while a controller is active; the bottom hint bar does switch.
- **Banner "static jitter"** from the HUD mockup was skipped.
- **Map legend** is generated from the minimap palette, so it also lists Imbue station; the old text legend is gone.
- **Results**: shows damage per weapon (top 4) in addition to the old text figures; "Sandbox: no progression written" / "Quest progress saved" kept.
- **Sandbox menu** keeps every old entry and callback; only presentation changed.
- **Missing data**: epithets and boss phases do not exist in the game, so the boss bar's epithet line is present but empty and there is no phase marker; there is no elite "event" object beyond the existing announce text.

## 4. Tests
- `tests/ingame_ui_regression.gd` — 193 checks: foundation widgets, HUD, notifications, boss bars, pause, level up, shop, shrine, chest, imbue, banner, notice, map, build inspector, results, sandbox.
- Updated for the new screens: `reward_ui`, `rewards_ai_v9`, `retro_audio`, `imbue_station`, `combos_amulet`, `art_reset_gameplay`, `tools/export_v9_smoke.gd`. Old assertions that described the removed screens (single cycling icon for 3.5 s, per-element buttons, "SKIP REVEAL" button) were rewritten for the equivalent new behaviour, not deleted.
- Verified green individually: `rewards_ai_v9` (93), `reward_ui` (27), `retro_audio` (243), `imbue_station` (31), `combos_amulet` (45), `sockets` (101), `shrine_charging` (25), `stage_themes` (27), `menu_systems` (55), `menus_regression` (67), `integration` (30), `art_reset_gameplay` (25), `forest_physics` (200 seeds).

## 5. Full validation
`tools/validate.sh` exits **0** (2033 PASS lines, no FAIL; includes `ingame_ui_regression`, 193 checks). The first full run stopped at one stale assertion in `tests/imbue_station.gd` that looked for the old build screen's socket pips; it was updated to the new build inspector and the whole script was re-run from the start. A harmless `ObjectDB instance was leaked at exit` warning appears at shutdown of the last suite.

## 6. Performance
`tools/hud_perf_profile.gd` (Loadout B stress build, every item ×5, four gem-socketed weapons), CPU only, headless:

| Enemies | avg ms/frame | p95 | max | build rebuilds | node delta |
|---|---|---|---|---|---|
| 0 | 0.295 | 0.408 | 0.541 | 0 | 0 |
| 480 | 0.371 | 0.527 | 1.476 | 0 | 0 |

Forcing a rebuild every frame costs 1.8–2.2 ms, so the "rebuild only when the build changes" path matters and holds. Paper-minimap drawing, fog shaders and the pause blur are GPU work and are **not** measured.

## 7. Screenshots
`docs/images/ingame/` (1920×1080): HUD states, toasts, boss bars, pause (+ settings, abandon hold), level up (fanfare, dealing, rare selected, tome preview, new weapon, skip focus), shop (rare, gem need-more, preview, legendary, sold), shrine (selected, Golden), chest (closed, opening, reel fast/slow, landed, legendary and common reveal), imbue (idle, held, confirm, fusing, done, poor), map, build inspector, results (death, victory), sandbox, banner, notice, and `contact-sheet.png`.
**Mockup side-by-side comparisons were not produced:** the mockups (`*.dc.html`) need a `support.js` runtime that is not in the repository, so they cannot be rendered here. I compared against the mockup markup and `SCREENS-INGAME.md` by reading them, not by pixels.

## 8. Outstanding / unverified
- Nothing has been seen on a real GPU, monitor, Windows machine or with a physical controller. Focus order and hints were tested through input events only.
- The animated parts (chest reel, level-up fanfare, boss-bar trail, fuse bar) were checked at sampled frames and by timeline tests, not watched in motion; feel and timing are unjudged.
- Mockup pixel comparison is missing (see section 7).
- The Windows build was exported with `tools/export.sh` but not launched on Windows.
- Boss epithets / phases and an elite "event" are not in the game (section 3).
- Fonts: Overpass's middle dot and serif old-style numerals are worked around (`MenuStyle.dot`, `HudNumber`); other glyph gaps in non-Latin names were not tested.
- Text at 1280×720 is readable in the shots taken at that size for the original screens; the new Fog stage is a scaled 1920×1080 layout, and only 1920×1080 captures were reviewed for the later screens (chest, imbue, map, build, results).
