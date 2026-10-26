# Weapon presentation audit

Registry: `scripts/core/catalog.gd`, all36 entries retained. Damage/cooldown/range/upgrade tables are unchanged.

| ID | Weapon | Attack | Before: projectile / attack | Before: impact / audio | Current presentation |
|---:|---|---|---|---|---|
|0|Sword|sweep|Generated arc/ring/line|Concrete puff / swing|Cached themed slash/aura geometry and elemental hit accents|
|1|Firestaff|fireball|Orange paired-cone fire core / point trail|Concrete puff / shot|Orange core, pooled flame/smoke trail, fire impact/explosion|
|2|Lightning Staff|chain|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|3|Flamewalker|trail|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|4|Chunkers|orbit|Paired blue/purple rectangular bars|Concrete puff / cast|Supplied irregular stone orbits;12 instanced pebbles; dust/chips and stone audio; shared visual/damage positions and count|
|5|Bone|bounce|Generic dart mesh / point trail|Concrete puff / shot|Distinct bone/banana/axe/dice/blade mesh; pooled trail/impact|
|6|Bow|pierce|Shaft and arrowhead / point trail|Concrete puff / shot|Oriented arrow with shaft/head; restrained impact; no oversized trail|
|7|Revolver|bullet|Generic dart mesh / point trail|Concrete puff / shot|Small brass projectile, thin motion tracer, restrained muzzle/impact sparks|
|8|Aegis|orbit|Paired blue/purple rectangular bars|Concrete puff / cast|Shield/crest orbit meshes at exact damage positions|
|9|Bananarang|return|Generic dart mesh / point trail|Concrete puff / shot|Distinct bone/banana/axe/dice/blade mesh; pooled trail/impact|
|10|Aura|aura|Generated arc/ring/line|Concrete puff / cast|Cached themed slash/aura geometry and elemental hit accents|
|11|Axe|lob|Generic dart mesh / point trail|Concrete puff / shot|Distinct bone/banana/axe/dice/blade mesh; pooled trail/impact|
|12|Space Noodle|chain|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|13|Sniper Rifle|beam|Box beam|Concrete puff / cast|Existing themed rocket/toxic core with pooled trails and impact/activation accents|
|14|Slutty Rocket|rocket|Finned cone rocket / point trail|Concrete puff / shot|Existing themed rocket/toxic core with pooled trails and impact/activation accents|
|15|Shotgun|scatter|Generic dart mesh / point trail|Concrete puff / shot|Small brass projectile, thin motion tracer, restrained muzzle/impact sparks|
|16|Mines|mine|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|17|Wireless Dagger|chain|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|18|Frostwalker|frost_trail|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|19|Tornado|vortex|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|20|Dexecutioner|execute|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|21|Blood Magic|drain|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|22|Black Hole|gravity|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|23|Poison Flask|poison|Green stacked-cone toxic core / point trail|Concrete puff / shot|Existing themed rocket/toxic core with pooled trails and impact/activation accents|
|24|Katana|dash_slash|Generated arc/ring/line|Concrete puff / swing|Cached themed slash/aura geometry and elemental hit accents|
|25|Dragon's Breath|cone|Generated arc/ring/line|Concrete puff / cast|Cached themed slash/aura geometry and elemental hit accents|
|26|Dice|dice|Generic dart mesh / point trail|Concrete puff / shot|Distinct bone/banana/axe/dice/blade mesh; pooled trail/impact|
|27|Hero Sword|wave|Generic dart mesh / point trail|Concrete puff / shot|Distinct bone/banana/axe/dice/blade mesh; pooled trail/impact|
|28|Corrupted Sword|corrupt|Generated arc/ring/line|Concrete puff / swing|Cached themed slash/aura geometry and elemental hit accents|
|29|Scythe|reap|Generated arc/ring/line|Concrete puff / swing|Cached themed slash/aura geometry and elemental hit accents|
|30|Ice Crystal|freeze|Generated arc/ring/line|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|31|Chrono Slicer|chrono|Paired blue/purple rectangular bars|Concrete puff / cast|Cyan blade orbits at exact damage positions|
|32|Thunder Rail|rail|Box beam|Concrete puff / cast|Jagged pooled links, short themed impact flash, bounded spark flipbooks|
|33|Spore Cannon|spore|Green stacked-cone spore core / point trail|Concrete puff / shot|Existing themed rocket/toxic core with pooled trails and impact/activation accents|
|34|Gravity Hammer|hammer|Flat cylinder field|Concrete puff / cast|Terrain-normal-aligned themed ground field; bounded activation dust/impact accents|
|35|Phantom Legion|summon|Generated arc/ring/line|Concrete puff / cast|Existing character allies and damage targeting retained; pooled spectral links/impact accents|

Reusable architecture: WeaponArt caches geometry; WeaponVFX handles cosmetic attack/contact/trails; existing Game damage paths remain authoritative. Rings, slashes, tracers and debris share meshes/materials. Chunkers and Aegis retain their existing hit cooldowns.

Audio is preloaded and throttled. Stone feedback uses the supplied stone-footfall sample, not a claimed new dedicated impact recording. Dummy-audio profiling cannot establish audible performance.
