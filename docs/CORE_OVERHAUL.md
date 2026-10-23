# MEGACLONK core overhaul and combat feedback

## Run loop

Stages start at 10:00. At 08:00 and 04:00, 30-second mob rushes increase the
budgeted spawn rate. Brute Champion arrives at 07:00; Shadow Hunter at 03:00.
At 00:00 the display stays at zero and endless pressure begins. Fast glowing
revenants join the ordinary horde and gradually gain health, damage and speed
(speed capped at 10m/s). All events fire once and persist in checkpoints.

Find the purple portal, explore for equipment, then press E whenever ready to
summon the stage boss. Timer and timed encounters continue. The Forest Colossus
uses a jump-dodgeable slam, a locked-direction charge and radial thorns. The
Wraith Sovereign uses a single-hit spectral dash, three projectile waves and a
marked delayed explosion. Specials have independent cooldowns, weighted selection,
wind-up and recovery. Stage choices alternate after a seeded initial selection.

Boss death unlocks the mint exit but does not end the stage. Press E to advance.
New seeded forest layouts reset the timer/events and ready the ultimate while
preserving equipment, levels, items, stats, gold, trait and run-wide enemy variants.
The forest uses supplied instanced trees, bushes, grass, rocks and a relic landmark.
Terrain consists of broad planar slopes with accessible internal height differences
and steep boundary cliffs. F8 regenerates the next map in the practice sandbox (launch with --practice).

## Traits and ultimates

All traits and ultimates are immediately available. Select exactly one of each.

- Wall Climber: forward against a wall climbs at 60% of run speed. Wall jumps work;
  boundary cliffs are excluded. Gecko upgrades increase climbing speed.
- Momentum: +2% damage/sec moving above 1m/s, capped +40%. One-second stationary
  grace, followed by five-second full decay. Sliding/jumping count as movement.
- Unmoving Force: one stationary second of grace, then +5% damage/sec to +50%.
  Intentional movement clears it; minor damage knockback does not.
- Glider: hold Jump while descending: 30% gravity and 3m/s terminal descent.
  Thermal upgrades extend airtime; separately acquired air jumps still work.
- Cartographer: reveals terrain and objectives on each new stage, without mob dots.

Q activates the ultimate (rebindable). Cataclysm deals 8× starting weapon base damage
within 15m, followed by the ordinary damage/trait multipliers; cooldown 90s.
Berserker gives ×1.75 damage and ×0.70 incoming damage for 12s, cooldown 90s.
Armour reduction and Berserker multiply; damage remains at least one unless Ghost
Form grants full immunity. Ghost lasts 8s, doubles speed/jump height, cooldown120s.
It keeps terrain collisions throughout, avoiding invalid geometry on expiration.
Cooldowns pause with gameplay. Level-ups do not reset them. All stage starts ready
ultimates; loading a checkpoint preserves its cooldown. Ability rules are in
assets/config/abilities.tres; run-pressure rules in assets/config/run_rules.tres.

Ground movement is 8m/s, acceleration55, deceleration45, gravity34, jump impulse10.
Air Step grants extra jumps; Wind/Feather increase speed/jump height; Skater/Wax
increase practical slide speed/reduce friction. Sliding maximum scales with speed
and Skater; air steering preserves carried speed instead of creating kinetic energy.

## Weapons and build screen

Each weapon has eligible randomized attributes. All support damage, haste and
critical chance; projectiles support count/velocity, bullet/bone support ricochets,
area weapons support radius, applicable fields support duration, selected targeted
weapons support range. Revolver now fires real finite-lifetime bullets. It can
upgrade damage +15%, ricochets +1, projectiles +1, velocity +20%, haste +10%, or
crit +5 percentage points. Cards show the proposed attribute before/after. Attributes
persist in run saves; stale cards cannot apply twice. Legacy weapon ranks retain
previous damage scaling on migration.

Tab pauses and shows equipment, item stacks, stage/gold and percentage-based stats.
Hover a stat for its rule; hover a weapon for current damage/cooldown, applicable
projectile/ricochet/velocity values, attributes, measured 10-second DPS and a separately
labelled base single-target estimate. Actual DPS counts only health removed, excluding
overkill; old samples age out to zero. DOT damage retains its originating weapon.

## Economy and shops

Gold belongs to the run, automatically collected on every kill, and carries across
stages. Starting a new run resets it. Silver belongs to the account and comes from
claiming real quests exactly once. V3 profiles convert old credits + quest gold to
silver once; old fields remain for history. Run kills themselves do not mint silver.

Weapon slots:2 default, third250silver, fourth750silver. Tome slots independently use
the same prices, without account-level gating. Weapon purchases have per-entry silver
prices; disabled owned weapons remain valid starters but are excluded as new offers.
Items unlock automatically at their kill milestones; legendary items are available.
Quests include weapon kills, bosses/minibosses, stage2, endless, early exit, chests,
ultimate uses and legendary purchases. Weapon mastery quests provide a path to fund
both capacities and the full collection.

Shop tiers roll75%Common/20%Rare/5%Legendary. Common stock is common, Rare stock is
rare/epic, Legendary stock is legendary. Prices are15/40/65/150 gold by rarity.
Only a successful purchase consumes a seller: deduct gold, apply the item, show smoke,
hide the NPC and close the menu. Browsing or insufficient gold does not consume it.
Consumed state and stock survive save/load. Legendary effects: Phoenix revives once;
Thunder Covenant strikes nearby foes each second; Timekeeper recovers cooldown25%faster.

## Feedback and assets

Damage flashes red on the player, all regular variants, bosses, minibosses and ghosts.
Enemy custom instance data drives the flash without breaking batching; player overlays
restore the underlying textured/ability materials. Invulnerability/dodged hits do not
trigger a new damage flash. Flash timers pause with gameplay.

PSX FX flipbooks provide impacts, blood, muzzle flashes, smoke, fire, sparks and explosions.
Electric FX's shader drives bounded GPU lightning particles. Flipbooks reuse cached frames
and pooled billboards (24 maximum,6 in reduced mode); only3 electric emitters coexist.
VFX intensity/reduced-effect settings control decoration without suppressing damage feedback.
Supplied RPG sounds drive interface, weapon, hit, death, pickup, level and ultimate cues.

All uploaded archives remain preserved. Exact unavailable pack substitutions and testing
limits are in TODO_STAGE_LOOP.md; full attribution and modifications are in ASSET_CREDITS.md.
