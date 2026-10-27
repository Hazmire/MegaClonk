MEGACLONK — Vertical Forest Playtest (Milestones 2–4)

New runs explore a substantially more vertical forest: four bands at 0/12/24/36m, unequal connected landmasses, irregular cliff contours and length-adaptive straight ramps. Tall rocky perimeter walls now seal against high plateau floors. Adds a layered blue sky, soft static clouds, warm fill and gentler distance fog.

Player spawn, portal, elite statue, chests, shops and shrines use deterministic constrained placement with clear landings across elevation levels. Default reward-object counts are unchanged. Existing terrain-version-3 saves retain their original layout; new runs use version 4. Enemies can climb taller cliffs, and terrain probes no longer climb a wall behind a nearby target.

Validation: 606 assertions, 200 deterministic layouts, 200 decorated worlds, 101,114 collision rays, 1,000 live interactions, 400 per-world enemy climb/drop checks, 70 cliff-drop cases and 12 rendered seed previews. Full import/regression suites pass. Stage assembly averaged 272ms versus 258ms for the legacy generator; 250-enemy CPU work averaged 5.58ms/tick. Native Windows execution and gaming-GPU 60FPS are unverified. Mesa software OpenGL still reports retained sky texture handles on shutdown.

Extract the ZIP and launch BONK_INFINITY.exe, or Launch_Compatibility.bat for OpenGL. See VERTICAL_FOREST.md and VERTICAL_PERFORMANCE.md. The XP gemstone and level-up/chest/shop/build-screen overhaul remains pending; this release does not claim those milestones complete.

Version 6.1 fixes an export-only missing empty-array default in height sampling. Windows export now smoke-tests its embedded game data before packaging/publication and rejects script/resource errors. Version 6 was marked superseded after downloaded-build verification found that issue.
