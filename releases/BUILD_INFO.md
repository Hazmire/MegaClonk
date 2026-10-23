# MEGACLONK stage-loop foundation

- Source: `1f1a76216fdace7e6b0b0f7f69e3c3ad26daa1fd` (Godot 4.7.2).
- Runtime implementation: `a14e04e72f97d3fc5ead97308e93b46a11b1e60e`; following source commit only adds the bundled stage guide.
- Successful Actions run: https://github.com/Hazmire/MegaClonk/actions/runs/40011031526
- Published artifact: `BONK_INFINITY-Windows-x64`, ID `12526556411`, 41,219,587 bytes, unexpired when verified.
- Actions archive digest from GitHub metadata: `sha256:e6f34c302fe5a0ca67baff9134cb3e3ec0d9c356bea020e885fe1b6466bc4f6f`.
- Durable repository ZIP SHA256: `2bc250da180207ba2c9ed3a682939da58a81d9af80d2f029ec5f4f48a2c36fb0`.

The repository ZIP is a separately generated Windows export from the same clean
source commit as CI. Its bytes differ from GitHub's artifact container. ZIP
integrity, 15 bundled files and required asset licences/guides were checked.
The executable is PE32+ Windows x64 with embedded PCK.

203 automated checks pass in source and against packed Windows resources under
Linux Godot. The final guide-only export also passed the 39 stage-loop checks
against its embedded PCK. Native Windows execution remains untested. Rendered
Jacob/loadout/HUD/portal/stage-transition output was inspected under Mesa OpenGL.

GitHub workflow success and artifact publication/size/digest were verified through
the API. The public repository ZIP is checked against SHA256SUMS after pushing.
No claim is made that the Actions archive bytes were downloaded and verified.

Jacob (CC BY 4.0), Kurland (OFL 1.1) and the licensed ability demo are included.
Other supplied archives are preserved; incomplete licence evidence and missing
packs are documented in docs/ASSET_ACCESS.md. This is the foundation milestone,
not the complete requested overhaul; see TODO_STAGE_LOOP.md.

PR: https://github.com/Hazmire/MegaClonk/pull/3
