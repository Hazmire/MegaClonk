BONK INFINITY — playable development build

Windows 10/11 x64. Extract the entire ZIP and open BONK_INFINITY.exe.
If Vulkan is unavailable or the window is blank, open Launch_Compatibility.bat.
No account, network connection, engine installation or setup is needed to play.
The executable is unsigned; a Windows reputation prompt is possible.

Controls
WASD: camera-relative movement. Mouse: camera. Space: jump. Left Ctrl: crouch / momentum slide.
E: interact. Escape: pause. Tab: inspect build. Wheel: zoom. F11: fullscreen.
Hold Ctrl at low speed to crouch; press it above 7 m/s to slide. Downhill
slopes accelerate a slide; uphill slopes and friction slow it. Jump during a
slide to preserve momentum. Release Ctrl to stand when overhead space allows.
Monke climbs by moving forward against a wall; no sprint input exists.

Keys can be rebound in Settings. Escape and F11 remain dedicated controls.

Play
Choose Fox or Sir Oofie, a biome and a tier, then Enter the Wild.
Attacks are automatic. Collect glowing XP, select upgrades and find chests.
Chests/shops cost 15 gold. Blue charge shrines require staying close.
A Warden arrives after three minutes. Kill it, approach its portal and press E.
Finish three stages to win. Death or abandonment displays results.
Lifetime kill milestones unlock additional characters.
Escape > Save run stores the current run. Use Resume saved run on the main
menu to continue; variant selections and enemy state are retained. Transient
projectiles/fields restart on resume.

Sandbox
Toggle Sandbox on the main menu to temporarily select any character.
Each new run chooses one of two variations for each of eight enemy archetypes.
These choices persist through all stages. Ranged attacks and explosions have
visible wind-ups; step outside warning rings before they detonate.

During a sandbox run press Escape > Sandbox tools for weapons, levels,
enemies, boss spawns, XP/gold, items, time scale and invincibility.
Sandbox runs do not award persistent currency, wins or character unlocks.

Saves
Stored in Godot's user-data directory:
%APPDATA%\Godot\app_userdata\BONK INFINITY\progress.json
The Progress menu can export/import bonk-profile-export.json in that folder.
Updates keep the existing profile. Avoid overwriting this folder manually.

Status
This is the movement/variant milestone, not the complete polished game in
the specification. Reference mechanics and numerical balance are approximate.
The source includes a detailed status report in docs/STATUS.md.
Windows export was built in Linux; native Windows execution and human game-feel
validation remain to be performed. This build is provided for personal testing.
