# Forest playtest publication — 2026-10-25

Download: https://github.com/Hazmire/MegaClonk/releases/download/forest-playtest-v2/BONK_INFINITY_Windows_x64.zip
Release: https://github.com/Hazmire/MegaClonk/releases/tag/forest-playtest-v2

- Clean source: `5fe086c5c549273d72e890307d61be90c683ee2e`, branch `megaclonk-menu-loadouts`.
- Successful GitHub Actions run: https://github.com/Hazmire/MegaClonk/actions/runs/40237119122
- Release asset ID: `676215692`; size **107,058,902 bytes**.
- Release ZIP SHA256: `6a5ef826faa4ac07c70493beea9c371e70d9971d07d910ece861dd9ceb9beb30`.
- Actions artifact: `BONK_INFINITY-Windows-x64`, ID `12615397512`, **107,955,250 bytes**, not expired at verification.
- Artifact SHA256: `c932383c4a989d3f86dd22cc6a31884411e2ca28498592428f1e22d5099f479b`.
- Artifact ZIP wraps the exported directory; its bytes differ from the separately packaged release ZIP.

CI imported the committed assets, passed all eight suites, exported Windows x86-64, uploaded the
artifact and published the durable release ZIP. Publication IDs, sizes and digests were verified
through GitHub's API. The release ZIP was downloaded again: its byte count and SHA256 matched, all ZIP CRCs passed, and BUILD_INFO confirms clean source5fe086c plus all four Quaternius licences. The cloud workspace's direct uploads endpoint was forbidden; the authorized
manual GitHub Actions release step performed publication successfully.

A clean local export from runtime-equivalent `54c94df234fc08277b692ca8f832ca359bb98f4f` also passed
ZIP CRC checks. Its Windows executable is PE32+ x86-64. Linux Godot loaded its embedded game data
for a 180-frame practice run and a rendered 90-frame asset-showcase run, without resource/script
errors. This checks exported resources, **not execution of the Windows binary on Windows**.
The downloaded CI release executable’s embedded game data also completed a 180-frame practice run under Linux Godot without errors. Native Windows execution and gaming-GPU performance remain local playtest tasks.

Source PR: https://github.com/Hazmire/MegaClonk/pull/3 (base `Full-Release`). Merge it to put this
source on the default branch; the release download is available independently of merging.

The old tracked `releases/BONK_INFINITY_Windows_x64.zip` is an earlier build. Use the release URL
above for this update. Its old checksum remains in `SHA256SUMS`; the new published ZIP checksum
is in `FOREST_SHA256SUMS`.
