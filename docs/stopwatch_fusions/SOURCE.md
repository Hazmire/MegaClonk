# Where these sounds come from

These sounds are all from the "Megaclonk sound effects" chat, taken from its soundboard.

| Files | Quality |
|---|---|
| The 9 loops (`stopwatch_loop`, `imbue_layer_<fusion>_loop`, `ult_berserker_loop`, `ult_ghost_loop`) | Lossless 44.1 kHz 16-bit WAV, exactly as made. |
| The one-shots (stopwatch activate and end, Fusion attack and hit layers, combo fuses, ultimates) | Decoded to WAV from the soundboard's compressed playback copies. They're the final versions but not the masters. |

The masters are the WAVs in that chat's downloads: `megaclonk_fusion_weapons.zip` and the powers pack. They have the **same file names**, so you can drop them over these at any time with no code change.

The pre-mixed Fusion weapon files from that chat are not included, because the game layers sounds at runtime.

**How the prompt uses them:** you attach your sound zip in `docs/stopwatch_fusions/sounds/`. Claude Code takes every matching WAV from the zip, and uses these copies only for anything the zip doesn't have. The report lists which source each file came from.
