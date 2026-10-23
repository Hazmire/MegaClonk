> Superseded by TODO_STAGE_LOOP.md for the new core-loop update. Jacob, Kurland and ability demo icons are now integrated; see docs/ASSET_ACCESS.md for the current audit. The following checklist records the earlier menu milestone.

# MEGACLONK menu/loadout and progression update

- [x] Preserve current game; run baseline regression suites and inspect branch changes.
- [ ] Acquire requested assets only after verifying each pack's actual licence. All nine supplied itch.io pages initially returned proxy CONNECT 403. Required domains saved to environment draft; use explicitly documented original temporary assets until accessible.
- [x] Versioned profile migration: credits, quest gold, entry unlocks/toggles, slot purchases, quest claims, personal loadout leaderboard.
- [x] Four-button main menu with map orbit and closest-four unlock progress.
- [x] Single-avatar Play screen: one starting weapon, one trait, one ultimate, one forest map and personal leaderboard.
- [x] Unlock tabs, locked-detail privacy, enabled drop pools, quest categories/claims, account slot progression 2→4.
- [x] Five real traits and three cooldown ultimates with input/HUD/save support.
- [x] Single large forest arena with cliff boundary, countdown and post-zero escalation.
- [x] HUD, minimap/fog, bottom XP, loadout/stats/items, shop and upgrade card layouts, grouped settings.
- [x] Meaningful regression tests, rendered inspection, Windows export, Git commits, PR and verified downloadable delivery.

Blocked asset work is explicitly incomplete: Jacob, exact provider icons/Kurland/audio/monster/environment packs require reachable product pages and actual licence verification. Original temporary content is disclosed in docs/ASSET_ACCESS.md. The replacement GGBotNet heading font has a verified CC0 licence.

Validation: 108 existing checks plus 55 new checks pass, including all three suites against the local Windows export's embedded PCK using Linux Godot. Ten rendered UI screens were captured and inspected. GitHub Actions run 39995928415 successfully exported and uploaded artifact 12519956438; final documentation/package refresh follows. Native Windows execution is not claimed.

Delivery complete for the functional update: PR #3, final successful Actions run 39996662829/artifact 12520336253, and a separate durable repository ZIP from clean source a2051f2. Exact provider asset integration remains the one blocked checklist item.
