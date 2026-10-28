# Grimdark PSX redesign

Baseline: verified12.1 gameplay/audio/HUD. Dedicated branch grimdark-psx-v13 preserves original assets/materials. Godot4.7.2 retained; crouch/slide retained (sprint was previously removed).

- [x] Download/audit supplied archives outside res://; identify actual mesh/texture/shader paths.
- [x] Prototype native PSX rendering and representative materials before broad conversion.
- [x] Supplied Knight, original idle/walk and compatible supplemental animation states.
- [x] New monster silhouettes with shared baked animation frames and white damage feedback.
- [x] Green → ochre/decay → entirely dead vegetation, dark scenery and natural boundaries.
- [x] Replace all interactable models while preserving original logic/placement.
- [x] Fog/light/portal wind refinement and full-resolution readable UI.
- [ ] Twenty seeds across three stages, regression,50/100/250/500 profiles, rendered screenshots and Windows delivery.

No claim of completion or native Windows/GPU performance certification until evidence exists. Existing audio and enemy-silence rules must remain intact.

Restored cloud workspace: all source survived. Dedicated20×3 seed test passed4089 checks before disconnect; full regression/export/publication still require completion. Source repair tools and actual captures are included.
