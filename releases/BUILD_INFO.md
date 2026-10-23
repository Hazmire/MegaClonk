# MEGACLONK core overhaul and combat feedback

- Clean source: `b7ccae74ed26b4a39e0adc76d5508d43985b42fe`, Godot4.7.2.
- Successful CI: https://github.com/Hazmire/MegaClonk/actions/runs/40023925327
- Artifact: `BONK_INFINITY-Windows-x64`, ID12532156289;59,747,426bytes;unexpired when checked.
- Artifact digest from GitHub metadata: `sha256:150db7aa66bdd7531524a508b6bf79676c5c9e74513b10fe3953c27f87edf820`.
- Repository ZIP:70,048,168bytes;19files.
- Repository ZIP SHA256: `4f534bf8abb83842c337372d48b02e8054926c5b54eaa96546dca55ff37e3086`.

The repository ZIP is independently exported from the same clean source as CI;
its container bytes differ from the Actions artifact. ZIP integrity, required
licence/guide files and its embedded Windows resources were checked. All315checks
pass against the embedded PCK under Linux Godot. Native Windows execution is not tested.

CI success, upload success, artifact size/digest/non-expiry were verified via GitHub.
The public durable ZIP URL is downloaded and compared to SHA256SUMS after pushing.
Actions archive bytes themselves are not claimed as downloaded/verified here.

Rendered imported forest/Jacob, red flashes, particle effects, both bosses, health
bars, build/shops/unlocks and1080p/1440p HUD output were inspected under Mesa OpenGL.
Hardware60FPS and sustained human balance playtests remain unverified. Exact missing
art substitutions are in docs/ASSET_ACCESS.md. Full current rules: docs/CORE_OVERHAUL.md.

Merge PR3 into Full-Release to put this update on the default branch:
https://github.com/Hazmire/MegaClonk/pull/3
