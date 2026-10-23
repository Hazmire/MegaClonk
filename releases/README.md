MEGACLONK — menus, loadouts and progression build

Extract the Windows ZIP and launch BONK_INFINITY.exe (the filename/user-data
folder is retained from earlier builds). If Vulkan is unavailable, use
Launch_Compatibility.bat. No engine installation, account or internet is
needed by the exported game. Windows execution still needs native playtesting.

MAIN MENU
Play / Unlocks / Quests / Settings. The forest background rotates slowly.
The upper-left panel shows the four nearest outstanding unlock requirements.

PLAY
Choose one starting weapon, one passive trait and one ultimate. There is one
playable adventurer and one forest destination. Personal bests show selected
loadouts. The current original Scout is a temporary model: the requested
Jacob and itch.io packs remain inaccessible, as detailed in ASSET_STATUS.md.

WASD move, mouse look, Space jump, Ctrl crouch or momentum slide, E interact,
Q ultimate, Escape pause, Tab build/stats/items, wheel zoom, F11 fullscreen.
All gameplay keys can be rebound in Settings. Skyweaver glides while Jump is
held during descent. Cliffwalker climbs by moving forward against a wall.

SURVIVE
Weapons attack automatically. Collect XP, select upgrades and find treasure.
The countdown lasts three minutes. At zero the Warden appears and enemies
keep getting tougher. Defeat the Warden, then enter its portal to win.
Chests begin at 15 run gold and increase by 5 each. Shops have priced stock.
The minimap reveals explored areas; Far Sight begins fully revealed.

PROGRESSION
New profiles have 2 weapon and 2 tome slots. Unlocks tabs contain collection
entries and permanent slot upgrades. Locked details show only requirements.
Disabled owned starting weapons remain selectable; disabled unowned entries
are excluded from run offers. Credits purchase entries after their milestone.
Quest gold buys slots: level 2 +100 gold for third slots, level 4 +200 gold
for fourth slots. Two claimed quests raise account level by one.

Open Quests to CLAIM completed rewards. Credits/quest gold are persistent;
run gold buys chests/shop stock. Practice/sandbox runs do not bank progression.

SAVES
Escape > Save run; return via Play > Resume saved run. Profiles stay in
%APPDATA%\Godot\app_userdata\BONK INFINITY\progress.json
V1 profiles migrate to V2 with a .v1.bak backup. Older executables cannot read
V2 profiles. Existing lifetime statistics/currency/settings are retained.
Run saves preserve loadout, cooldowns, fog, enemies and shop stock; transient
projectiles/fields restart on resume. Do not delete the user-data folder.

This build's functional UI/loadout systems are tested. Exact requested assets,
native Windows execution and real-GPU FPS remain outstanding. Read
MENU_GUIDE.md, ASSET_STATUS.md and FEATURE_STATUS.md for details.
