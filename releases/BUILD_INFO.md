# Movement/variant Windows build

- Source: `0074f48f772b9a1671f01bc7bbebd3e0275f406b`, Godot 4.7.2.
- Successful GitHub Actions run: https://github.com/Hazmire/MegaClonk/actions/runs/39978727835
- Published Actions artifact: `BONK_INFINITY-Windows-x64`, ID `12511519962`, 39,134,894 bytes; upload step verified successful through the GitHub API.
- Actions archive SHA256 (GitHub metadata): `8dd68548f43c1432331c684beb97eb7955550ec9751d9b7884310b0b38e05d05`.
- Repository ZIP SHA256: `6ebae9d4f7fc291986d80d8739fa3a1b22976ce2a59f5918002d74ed744ffdf6`.

The durable repository ZIP is a local Windows export of the exact same clean source commit as the successful Actions run. Its ZIP bytes need not match GitHub's artifact container. Archive integrity, PE32+ x64 architecture and embedded resources were checked. Both test suites (30 + 78 checks) also passed against the local Windows executable's embedded PCK using the Linux Godot engine. This checks packaged resources/scripts, not native Windows execution.

The Actions artifact's publication and digest were verified through GitHub. Downloading that artifact into this cloud machine was denied at its Azure blob storage destination; no claim is made that those archive bytes were downloaded/inspected. The repository ZIP provides a separate durable download without the Actions storage route. Actual Windows device playtesting remains outstanding.
