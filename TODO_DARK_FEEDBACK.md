# Dark feedback and HUD12

- [x] Silence enemy hit/death/self-destruct/death-blast feedback; preserve weapon impacts.
- [x] Re-curate and process darker, crunchier effects with source/attribution records.
- [x] Separate tome row under weapons without empty slots.
- [x] Numbered dark-red left HP bar and small projected player HP bar.
- [x] Focused audio/UI regression and actual rendered inspection.
- [x] Clean CI regression, compiled export, publication and downloaded ZIP verification.

No listening/native Windows or full GPU frame-rate certification is claimed.

Verified publication: dark-feedback-v12, clean sourcef203a35, downloaded ZIP digest/CRC/source checks plus180 world frames and five smoke gates. All27 source suites pass (1,086 local named checks). See releases/DARK_FEEDBACK_VALIDATION.json.

12.1: corrected Godot’s inherited minimum height; sourcec427760 passes14 focused checks,27 CI suites and all five smoke gates from the downloaded ZIP. Rendered bar height is7px. Updated publication proof is in releases/DARK_FEEDBACK_VALIDATION.json.
