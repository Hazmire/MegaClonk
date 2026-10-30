# Economy Rework — implementation report

Status: all ten feedback points are implemented and covered by `tests/economy_regression.gd` (38 checks) plus updated older suites. Full `tools/validate.sh` result is recorded at the bottom.
**Not playtested by a human. None of the numbers below has been tuned against real play; they are proposals.**

## 1. What changed, per request
| # | Request | Implementation |
|---|---|---|
| 1 | Amulet from chests or shops, not vases | Imbued Amulet is a Legendary item. Chests roll it like any Legendary; Standard, Rare and Legendary shops can stock it. Vases only drop Common/Uncommon, so never. |
| 2 | Every item stacks | `unique` is false for all 61 items. Former Uniques were reworked so extra stacks do something: Headsman's Oath (+damage per execution × stacks), Devil's Bargain (trades × stacks), Anvil (extra stats × stacks), Saint's Finger (extra roll per stack), Hourglass of the Damned (a lethal hit spends one stack). The Amulet is a consumable: every pickup adds one to the bag, no per-run cap. |
| 3 | Gems like Rare items | Socket gems are Rare-tier candidates in shop draws (5 gems join the 13 Rare items). No separate "gem slot chance" any more. Measured: 17% of slots in Rare shops, 3% in Standard shops. Priced like an Epic item. |
| 4 | Standard shops sell all tiers | Standard ("Common" in saves) draws from all five tiers using the tier weights; Legendary share measured 1.9%. |
| 5 | Rare shops: Rare minimum | Rare shops draw only from Rare, Epic, Legendary. |
| 6 | Legendary shops: only Legendaries | Legendary shops draw only Legendary items (6 of them, so three distinct offers always exist). No gems. |
| 7 | Price scales with tier and stage | `Economy.item_price(tier, stage)`: base 15 / 25 / 40 / 65 / 150 × 1.6^(stage−1). Stage-3 Common = 38, stage-3 Legendary = 384. |
| 8 | Exponential chest cost | `15 × 1.2^chests_opened`: 15 for the first, ~230 for the 15th, ~3,500 for the 30th. Free chests don't raise it. |
| 9 | Upgrades: any tier, tier sets size; tomes 80, weapons 40 | Every weapon/tome card can roll any tier (candidates are drawn evenly, then each card rolls its tier). Size = Common step × tier scale (1.0 / 1.35 / 1.7 / 2.0 / 2.33). Damage Tome: Common +6%, Legendary +14% (0.06 → 0.20), as in your example. Tomes cap at 80 upgrades, weapons at 40. Whole-number stats (projectile count, bounces) are never scaled. Stat shrines already worked this way (any stat, tier-sized) and now respond to luck. |
| 10 | Luck | One curve: boost = 0.6 × luck / (luck + 2) (luck 1 → +0.20, 2 → +0.30, 8 → +0.48, ceiling 0.6). It shifts weight from Common to higher tiers (higher tiers gain more) for chest items, vase items, shop stock, level-up card tiers and shrine tiers, and raises Rare/Legendary shop-type odds. |

### Shop fairness rules (point 10)
- Shop-type odds at luck 0: Standard 75%, Rare 20%, Legendary 5%; at the luck ceiling Rare 35%, Legendary 12%.
- **At most one Legendary shop per stage**, whatever the luck. At least one Standard shop per stage.
- Measured over 3,000 stages of 3 shops: a Legendary shop appeared on 14% of stages at luck 0 and 32% at enormous luck — never guaranteed.

## 2. Judgement calls and assumptions
- **"Max upgrade 80 / 40" read as level caps** (80 upgrades per tome, 40 per weapon, up from 10). If you meant a cap on the stat total, this needs changing.
- Because levels went up ×4–8, per-level steps were shrunk: weapon steps now damage 6%, attack speed 4%, crit 2%, crit damage 10%, projectile speed 8%, size 6%; tomes Damage 6%, Attack Speed 5%, Crit 2.5%, Size 6%, Movement 4%, Max HP 8, XP 6%, Gold 8%, Lifesteal 0.4%. Early-game upgrades are therefore weaker than before (average card ≈ ×1.3 of Common, so ~8% damage per level against 15% before).
- Level-up cards previously had a fixed tier per weapon/tome; now every card rolls its own tier with the Common 50 / Uncommon 28 / Rare 14 / Epic 6 / Legendary 2 weights. A weapon's first pick is always Common (it is just equipped).
- Gems cost like an Epic item (65 gold at stage 1, was 250), a guess.
- Gold income was not changed or measured, so these prices and the chest curve may be badly balanced against how much gold a run earns.
- Old saves: item stacks, tomes and weapon levels load as before; a saved shop keeps its old type. Unchanged tome stat values already in a save are not rescaled.

## 3. Files
`scripts/rewards/economy.gd` (new, single source), `scripts/meta/shop_system.gd`, `scripts/items/item_drops.gd`, `item_runtime.gd`, `item_stats.gd`, `scripts/core/game.gd`, `scripts/core/catalog.gd`, `scripts/combat/weapon_upgrades.gd`, `scripts/rewards/*`, `scripts/sockets/gem_rewards.gd`, `scripts/ui/reward_screens.gd`, `data/items.json`.

## 4. Outstanding / unverified
- Nothing seen or played; balance is unmeasured (see above).
- The level-up and shop screens were changed but not re-screenshotted.
- Windows build needs regenerating to include this.
- Inventory/HUD does not yet show how many Imbued Amulets are in the bag outside the Imbue Station.

Validated: full tools/validate.sh exit 0 (includes economy_regression, 38 checks).
