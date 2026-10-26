# Latest combat and atmosphere polish

See [current update](POLISH_UPDATE.md), [performance evidence](PERFORMANCE_POLISH.md) and [weapon audit](WEAPON_VFX_AUDIT.md). Older notes below are historical. The Mesa shutdown diagnostic and Windows/GPU verification limits are disclosed in those guides.

# Latest Dynamic Forest update

See [current gameplay/asset guide](DYNAMIC_FOREST.md). New KayKit Minion and Warrior models are integrated. The active ordinary roster is now Basic/Special/Large, with per-spawn choices; the main bosses are Big Chunkus and Rock Golem. Earlier release notes below are historical.

# Current Forest update

The supplied assets-v1 packages are now downloaded and integrated. See [Forest overhaul](FOREST_OVERHAUL.md) and [verified inventory](ASSETS_V1_INVENTORY.md) for current terrain, models, controls and limitations. Earlier release notes below are historical.

# Playtest guide — core overhaul

Extract the Windows ZIP, launch BONK_INFINITY.exe. Use Launch_Compatibility.bat if Vulkan
is unavailable. No Godot installation is needed. Native Windows execution is not verified
in the cloud; the export's packed resources are validated with Linux Godot.

Play / Unlocks / Quests / Settings. Choose one owned starting weapon, any of the five traits,
and any of the three ultimates. There is one forest biome and one player character, Jacob.

WASD movement; mouse camera; Space jump / hold to glide with Glider; Left Ctrl crouch/slide;
E interact; Q ultimate; Tab build/stat tooltips; Escape pause/save; wheel zoom; F11 fullscreen.
Gameplay controls are rebindable. Air Step grants extra jumps; Wall Climber can wall jump.

10:00 countdown. Rushes08:00/04:00. Minibosses07:00/03:00. Endless at00:00. Find the purple
portal and E to summon the seeded main boss at any time. Defeat it, explore further or E at
the mint portal to advance. Build and gold persist across generated forest stages. The
Colossus slam can be jumped; dodge its charge and thorns. The Sovereign marks explosions,
dashes along its telegraph and fires three projectile waves. Main/miniboss bars coexist.

Gold is automatically collected from kills and spent in the run. A shop offers tier-appropriate
stock; one successful purchase consumes the seller. Browsing/insufficient gold leaves it intact.
Chests start at15gold and increase by5 each. Legendary effects include a revival, periodic
lightning and faster ultimate recovery. Red flashes indicate actual damage; particle intensity
and reduced effects are configurable.

Quests persist progress when a non-practice run ends; claim silver once per quest. Silver
unlocks weapons and buys capacity:250 for slot3,750 for slot4, separately for weapons/tomes.
All traits/ultimates are always available. Disabled owned weapons remain valid starters.
Weapon upgrade cards select an eligible attribute and show the exact proposed change.
Tab tooltips distinguish recent measured DPS (no overkill) from a labelled base estimate.

Escape > Save run, then Play > Resume saved run. Profiles retain the old data location:
%APPDATA%\Godot\app_userdata\BONK INFINITY\progress.json
V3 migrates old credits + quest gold to silver once. Existing owned entries/settings/statistics
remain. Run checkpoints preserve stage/event/portal/encounter state, weapon attributes, shops,
fog and abilities; transient projectiles, damage windows and visual effects restart on loading.

[Full rules](CORE_OVERHAUL.md). Missing exact-art substitutions are documented in ASSET_STATUS.md.
