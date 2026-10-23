# Supplied asset audit — October 23, 2026

All eight user uploads were found on `megaclonk-menu-loadouts` commit `04a6722`
and preserved by fast-forwarding the existing work branch. No reset or asset deletion.

| Archive | Audit and integration status |
| --- | --- |
| Jacob.zip | Contained CC BY 4.0 licence by Jupifox. FBX/textures integrated; original additive movement animation over authored Idle. |
| Kurland_Font_0_46.zip | Contained SIL OFL 1.1. Unmodified regular TTF integrated with full licence. |
| GandalfHardcore Icons Demo.zip | Five PNGs and READ ME expressly permit commercial/free game use, prohibit standalone asset resale/redistribution. Integrated as game icons, with reused demo images. |
| Free-Undead-Skill-Pixel-Art-Icons.zip | Licence.txt only points to https://craftpix.net/file-licenses/; page returns 403 from environment. Archive preserved; game import deferred until actual terms can be verified. |
| free-undead-loot-pixel-art-icons.zip | Same linked CraftPix terms; not imported yet. |
| 150+ Free RPG Sounds .zip | Publisher page now verified: permits commercial/non-commercial project use, prohibits claiming authorship or reselling sounds. **Cleared for game integration**, not yet imported/wired into the build. |
| LowPoly Environment Pack.rar | 31 FBX models. Publisher metadata now verified as **CC BY 4.0**. **Cleared for integration with attribution**, not yet imported into scenes. |
| Ancient Reliques.zip | OBJ/MTL/textures/VOX and preview, no licence. Not silently treated as the missing enemy pack. Preserved; not integrated. |

The Quaternius Bestiary and 48 Scroll packs are not in any of these archives.
GitHub's current branches were enumerated; only the menu branch had the new
upload commit. Existing original enemies, terrain, audio and weapon/item/tome
icons continue to run until their replacements can be integrated correctly.

This audit supersedes the earlier blanket claim that none of the requested
assets were available. Further work can proceed on gameplay independently.

## Publisher-page recheck

The sound/environment pages became accessible on recheck. Their publisher terms
establish permission despite absent licence files inside the archives. Both
Undead product pages also load, but do not state the licence directly; their
linked CraftPix terms remain inaccessible. See [evidence and exact terms](licenses/PUBLISHER_VERIFICATION.md).

These findings update licence status; they do not retroactively add assets to
the previously published Windows build.
