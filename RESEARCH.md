# Megabonk reference research

## Evidence and limits (2026-10-23)

The five supplied public reference sites were attempted over verified HTTPS from the cloud machine:

- https://megabonk.wiki/wiki/Characters
- https://megabonk.wiki/wiki/Weapons
- https://bonkmaster.com/database
- https://survivorsdb.com/megabonk
- https://megabonk.org/guides/mechanics/

All requests returned an environment proxy `403 Forbidden` (CONNECT denied). Their page contents have **not** been read or verified. Required domains have been saved to the environment configuration draft. A draft save does not update the running policy. No source claims or exact formulas are invented here.

## Inputs from the user's brief (not independently verified)

The brief specifies 21 character/starting-weapon pairings, 31 reference weapon names, four weapon slots, four tome slots, auto-attacks, XP drops, paused three-choice level ups, escalating waves, chests, shrines, persistent unlocks and three biomes. The complete supplied text is preserved in `docs/USER_SPECIFICATION.md`; it ends mid-way through section 31 after `scripts/combat`.

Character passive descriptions in `Catalog.CHARACTERS` follow the supplied examples. All numeric character bonuses, weapon data, XP curves, enemy stats, gold rewards, items, shrines, stages, unlock conditions and difficulty scaling are independently designed approximations. The 31-name weapon roster has not been verified against any release of Megabonk. No research-backed numerical equivalence is claimed.

## Independent implementation choices

- A stage lasts three minutes before a Warden spawns. Killing it opens a portal. Three stages make a victory.
- Enemy health scales with elapsed time, stage, tier and Curse modifiers. The director never intentionally spawns within 25 horizontal metres.
- XP threshold: `10 + 7 * level + level^1.4`.
- Damage: base × weapon-level factor × damage stat × critical multiplier. Armor reduces incoming damage by `100 / (100 + armor * 5)`.
- Reference-named characters have independently implemented approximate passives, not reverse-engineered source implementations.
- Items and bosses use original names/art/balance. Character unlocks currently use lifetime kill milestones rather than documented original quests.

## Research still needed

Verify passives and progression requirements; establish the version-specific weapon/tome/item roster; investigate documented enemy/map/boss behaviours and stage timings. Replace approximations only when reliable evidence is available, preserving an explicit provenance for every exact numeric claim. Do not import commercial assets or code.
