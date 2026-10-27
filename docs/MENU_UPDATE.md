# MEGACLONK — menus, loadouts and progression

## Play flow

The main menu has exactly Play, Unlocks, Quests and Settings, with a slowly orbiting forest background. Four nearest outstanding unlock requirements appear on the left. Play offers one avatar, one starting weapon, one trait and one ultimate, followed by the single forest destination. Personal bests list their selected loadouts.

The original Scout is temporarily reused. **The requested Jacob model and exact icon/audio/environment packs remain blocked**, as documented in ASSET_ACCESS.md. No pack integration is claimed.

## Rules

- Four starting weapons are initially available; owned starting weapons can be selected even when disabled from run drops. Existing equipped weapons can still receive upgrades. Unowned or disabled new weapons never enter upgrade pools.
- Five starting items, two traits and Cataclysm begin unlocked. Other entries have explicit kill requirements and credit costs. Locked details disclose requirements only. Enabled items are the only chest/shop rewards.
- Profiles begin with two weapon and two tome slots. Third slots require account level 2 and 100 quest gold each; fourth slots require account level 4 and 200 quest gold each. Two claimed quests raise the account level by one. Capacity caps at four.
- Credits come from run rewards and quest claims. Quest gold comes from quest claims. Run gold is a separate resource for shops/chests; chest costs begin at 15 and increase by 5 per opened chest.
- Twelve quests across Hunting, Arsenal, Survival and Exploration track real kills, last-hit weapon attribution, survival, fast victory, bosses, chests and ultimate usage. Claiming is explicit and cannot be repeated. Sandbox runs do not bank metrics, currency or leaderboard records.
- The single run uses one cliff-bounded 180m forest. At 3:00 the Warden spawns; the timer becomes overtime and enemy health escalates further. Defeat the Warden and enter its portal to win. No desert/graveyard or character roster is exposed in the new flow.

## Traits

Cliffwalker enables forward wall climbing. Endless Stride ramps damage to +50% over 20s of movement and drains while stopped. Rooted Fury ramps to +60% over 6s stationary and drains while moving. Skyweaver caps held-jump descent at 3m/s. Far Sight reveals the full minimap. Exactly one trait is equipped.

## Ultimates

Press Q (rebindable). Cataclysm deals `180 + 20 × level` base damage within 28m, 90s cooldown. Berserker doubles damage and halves incoming damage for 12s, 75s cooldown. Ghost Form grants immunity, double movement speed and 2.25× jump-height scaling for 8s, 90s cooldown. Ghosts phase through the existing soft enemy simulation, preserving terrain collision. Cooldowns and active durations pause in menus and survive run saves. Their animated gold borders and active status appear in UI.

## HUD and menus

Full-width bottom XP bar; upper-right run gold/current chest cost; upper-left loadout icons, health, level and kill count; top-centre countdown/overtime; corner minimap with explored fog, enemies, Warden, portal and interactables. Tab opens equipped weapons/tomes, stacked items and live stat values. Shops show actual stock/prices/sold states. Level-up cards show current/next levels and stats, reroll, skip and banish. Display/Graphics/Audio/Gameplay settings have separate tabs.

## Persistence

Profile version 2 adds collection flags, disabled drop pools, quest claims/metrics, credits, quest gold, slot counts and up to 20 best-run loadouts. V1 profiles retain existing stats/currency/settings and get a non-overwriting `.v1.bak` backup before migration. Legacy character-unlock data is retained for compatibility but no longer presented as a selectable roster. The Godot user directory remains `BONK INFINITY` to preserve saves while the window/menu title says MEGACLONK.

Active-run version 2 retains selected loadout, cooldown/duration, exploration, chest counts and shop stock in addition to the previous enemy/weapon state. Version 1 active runs receive the default new abilities and migrate to the single forest; transient attacks/fields still restart on resume. Older executables cannot read V2 profiles; the V1 backup supports rollback.
