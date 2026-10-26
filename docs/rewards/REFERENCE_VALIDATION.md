# Uploaded-reference validation

```text
Source: 0b9a6082fd16f331b14318937ac55010dbae8f1f
Godot 4.7.2 Linux headless
Full validation exit: 0; script/resource error lines: 0

BENCHMARK 400 enemies CPU simulation mean: 8.17 ms/tick (headless; rendering excluded)
RESULT: 31 checks, 0 failures
OVERHAUL RESULT: 78 checks, 0 failures
MENU RESULT: 55 checks, 0 failures
STAGE LOOP RESULT: 39 checks, 0 failures
MILESTONE RESULT: 112 checks, 0 failures
RARITY: 143 checks, 0 failures
{"failed":[],"final_passed":200,"first_attempt_failures":[],"first_attempt_passed":200,"ms":40769,"repaired_count":0,"seeds":200,"unique_layouts":200}
{"collision_rays":101114,"enemy_traversal_checks":400,"failed":[],"final_passed":200,"first_attempt_failures":[],"first_attempt_passed":200,"interaction_checks":1000,"milliseconds":64977,"repaired_count":0,"seeds":200}
FOREST TRAVERSAL RESULT: 20 checks, 0 failures
{"center_elevations":{"0.0":21,"12.0":21,"12.7058820724487":1,"2.0":1,"22.0":1,"23.0":2,"24.0":26,"31.0":2,"36.0":25},"errors":[],"ramp_counts":["11","8","13","12","10","9"],"region_counts":["10","7","12","11","9","8"],"seeds":100,"sides":{"E":9,"N":9,"NE":15,"NSE":1,"NW":17,"NWE":1,"S":6,"SE":15,"SW":15,"W":12},"spawn_elevations":{"0.0":28,"12.0":23,"24.0":28,"36.0":21},"unique_layouts":100}
DYNAMIC BENCHMARK 400 ordinary enemies: 9.20 ms/tick, headless simulation and spatial rebuild
DYNAMIC RESULT: 48 checks, 0 failures
POLISH RESULT: 58 checks, 0 failures
CLIFF DROP RESULT: {"cases":70,"failures":[],"heights":[12,36,24],"orientations":4,"ramp_landing":true}
VERTICAL GAMEPLAY: 22 checks, 0 failures
REWARD UI: 27 checks, 0 failures
```

Final CI run 40401832094 passed all suites, world and pause/map/reward compiled-pack gates before publication. Download integrity and compiled-resource checks are recorded in releases/REFERENCE_UI_VALIDATION.json.
