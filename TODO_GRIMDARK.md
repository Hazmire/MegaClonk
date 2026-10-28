# Grimdark PSX redesign

Baseline: verified12.1 gameplay/audio/HUD. Dedicated branch grimdark-psx-v13 preserves original assets/materials. Godot4.7.2 retained; crouch/slide retained (sprint was previously removed).

- [x] Download/audit supplied archives outside res://; identify actual mesh/texture/shader paths.
- [x] Prototype native PSX rendering and representative materials before broad conversion.
- [x] Supplied Knight, original idle/walk and compatible supplemental animation states.
- [x] New monster silhouettes with shared baked animation frames and white damage feedback.
- [x] Green → ochre/decay → entirely dead vegetation, dark scenery and natural boundaries.
- [x] Replace all interactable models while preserving original logic/placement.
- [x] Fog/light/portal wind refinement and full-resolution readable UI.
- [x] Twenty seeds across three stages, regression,50/100/250/500 profiles, rendered screenshots and Windows delivery.

No claim of completion or native Windows/GPU performance certification until evidence exists. Existing audio and enemy-silence rules must remain intact.

Restored cloud workspace: source survived and was committed/pushed. All28 local suites pass, including4089 dedicated20×3 checks. Clean import and six compiled export gates pass. Isolated50/100/250/500 profiles and actual rendered captures are recorded. GitHub13.1 publication is verified: clean source, checksum/CRC,180 downloaded-pack frames, six smoke gates and actual rendered inspection. See releases/BUILD_INFO.md.

Known follow-up limits: fully authored supplemental animation clips would improve the simplified poses;500-enemy CPU cost remains above a60FPS budget on this host; small Mesa shutdown texture diagnostics remain unresolved. Native Windows and gaming-GPU playtesting are not certified.
