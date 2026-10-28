# Dusk music, tomes and menu update15

The playlist now contains exactly one looping main-menu track and one looping in-game track, using the clearly named files uploaded by the project owner. MP3 bytes are unchanged; the game track continues across stages without restarting. Existing volume sliders and context crossfades remain. Earlier music files are retained as historical source, not played by the current playlist. Raw root copies are excluded from exports to avoid shipping duplicates.

Shrine progress remains visible after leaving while charge decays. It disappears at0%, on completion, during paused screens or death. The charge rate, decay rate and rewards are unchanged. In-progress quest tracking is removed from the gameplay HUD; quest recording, the Quests page and main-menu closest-goal cards remain.

Unlocks now has a Tomes tab with ten original, generated grimdark/dusk icons. Names in the UI describe their effects; stable internal IDs preserve old saves. Only these ten enter new tome offers:

| Tome | Effect per level | Unlock |
| --- | --- | --- |
| Crit | +6 percentage points critical chance | Available |
| Damage | +15% damage | Available |
| Projectile | +1 weapon projectile |100 lifetime kills +100 silver |
| Size | +15% attack size |150 kills +100 silver |
| Attack Speed | +12% attack speed | Available |
| Movement Speed | +10% movement speed | Available |
| Max HP | +20 maximum HP | Available |
| Lifesteal | +1% lifesteal |250 kills +150 silver |
| XP | +15% XP gain | Available |
| Gold | +20% gold gain |60 kills +75 silver |

Unlocked tomes can be enabled or disabled for new acquisitions, and those choices persist. Locked details show only the name and unlock requirements. Already-equipped tomes retain their effects/upgrades, including archived tomes in older runs; archived tomes no longer enter new offers. Existing two-to-four equipment-slot progression remains.

The menu uses the native shop visual in the map's protected spawn clearing, with the actual idle player in front. A bounded slow camera arc keeps them framed, rather than orbiting the map origin or moving through cliffs. Play uses a closer framing. The preview merchant is visual only and is removed with the menu world when a run begins.

Validation includes purchase gates, toggle persistence, disabled/stale offer rejection, all ten actual stat effects and distinct atlas regions, music-loop state and stage continuity, shrine decay labels, hidden quest HUD and camera bounds. Native Windows/audio-device playtesting is not certified; publication evidence is recorded separately in releases/BUILD_INFO.md. Versioned release files are preserved after publication; later branch builds still upload Actions artifacts.
