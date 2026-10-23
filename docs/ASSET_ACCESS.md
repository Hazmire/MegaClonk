# Requested asset integration status

All nine linked itch.io product pages returned proxy CONNECT **403 Forbidden** when requested from this cloud machine on 2026-10-23. Required domains were saved to the environment network draft. A saved draft alone does not prove runtime access. Their product licences, prices, file contents, rigs and animation names could not be inspected. No preview sheets, paid downloads, commercial assets or presumed licences were copied.

| Requested pack | Creator / supplied source | Status |
|---|---|---|
| Undead skill icons | https://free-game-assets.itch.io/free-undead-skill-pixel-art-icons | Blocked; not imported |
| Undead loot icons | https://free-game-assets.itch.io/free-undead-loot-pixel-art-icons | Blocked; not imported |
| 48 scroll icons | https://free-game-assets.itch.io/48-scroll-pixel-art-icons-pack | Blocked; licence/price unknown; not imported |
| Buffs & ability icons | https://gandalfhardcore.itch.io/buffs-and-ability-icons-pixel-art-pack | Blocked; not imported |
| Kurland font | https://ggbot.itch.io/kurland-font | Blocked; exact font not imported |
| 200 RPG sounds | https://clutch-assets.itch.io/200-free-rpg-sounds | Blocked; not imported |
| Bestiary dungeon monsters | https://quaternius.itch.io/bestiary-dungeon-monsters-kit | Blocked; not imported |
| Low-poly environment | https://k0rveen.itch.io/lowpoly-environment-pack | Blocked; not imported |
| Jacob character | https://jupifox.itch.io/jacob-game-ready-character | Blocked; **Jacob is not integrated** |

The functional update uses one existing original Scout model, existing original enemies/environment/synthesis, original temporary icon glyphs and a separately verified font. **Pixelated Elegance** by **GGBotNet** comes from the author's official `ggbotnet/fonts-cc0` repository. Its README directs users to the included root **CC0 1.0 Universal** licence, copied to `assets/fonts/LICENSE-CC0.txt`. This is a transparent temporary substitute, not Kurland.

Next integration step: review/save the network domain additions in environment settings and publish them, then retry the actual product pages and inspect each licence/download. If a pack requires payment, a licensed copy or purchase decision will be needed; no price or licence is guessed here. After access is available, map the actual individual icons, retarget Jacob's actual animations and revalidate exports. `assets/ui/manifest.json` records the current sources. UI icon lookup supports licensed per-entry images under `assets/ui/icons/<category>/<id>.png`, but no files are falsely labelled as the requested packs.
