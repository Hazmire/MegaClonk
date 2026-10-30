#!/usr/bin/env python3
"""Regenerates assets/audio/events.json from docs/audio_handoff/manifest.json.
Existing events emitted for the same moment keep their id (and cooldown/priority/max_voices/gain_db) but point at the
new files; every other manifest event is added under its manifest id with the manifest's suggested values.
Run: python3 tools/build_audio_events.py"""
import json,os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAN=json.load(open(os.path.join(ROOT,"docs/audio_handoff/manifest.json")))["events"]
PATH=os.path.join(ROOT,"assets/audio/events.json")
OLD=json.load(open(os.path.join(ROOT,"tools/audio_events_legacy.json")))["events"] # events.json before the Fog pack
# old id -> manifest id (same game moment)
REPOINT={
"weapon.sword.swing":"weapon.sword_swing","weapon.sword.hit":"weapon.sword_hit",
"weapon.firestaff.cast":"weapon.fireball_cast","weapon.firestaff.impact":"weapon.fireball_impact",
"weapon.lightning.strike":"weapon.lightning_strike","weapon.lightning.chain":"weapon.lightning_bounce",
"weapon.bow.fire":"weapon.bow_shot","weapon.bow.hit":"weapon.arrow_pierce",
"weapon.revolver.fire":"weapon.revolver_shot","weapon.revolver.ricochet":"weapon.revolver_ricochet","weapon.revolver.hit":"weapon.bullet_hit",
"weapon.aura.hum":"weapon.aura_loop","weapon.aura.pulse":"weapon.aura_pulse",
"weapon.scythes.throw":"weapon.scythe_throw","weapon.scythes.catch":"weapon.scythe_catch","weapon.scythes.hit":"weapon.scythe_hit",
"weapon.shotgun.fire":"weapon.shotgun_blast","weapon.shotgun.hit":"weapon.bullet_hit",
"ui.hover":"ui.menu_move","ui.confirm":"ui.menu_select","ui.open":"ui.panel_open","ui.close":"ui.panel_close","ui.purchase":"ui.shop_buy",
"gem.pickup":"ui.gem_pickup","pickup.gold":"ui.gold_pickup",
"player.slide":"movement.slide","player.footstep.grass":"movement.step_grass","player.footstep.rock":"movement.step_stone",
"reward.chest.tick":"ui.reel_tick",
}
REPOINT["player.damage"]="player.player_hurt"
# legacy events whose moment the pack fully replaces and that nothing emits any more
RETIRED={"imbue.install","imbue.interact","reward.chest.reveal","reward.chest.legendary","weapon.lightning.thunder"}
ORDERED={"world.shrine_charge_tick","ui.gold_pickup","weapon.arrow_pierce","weapon.sword_hit","weapon.sword_swing"}
DEFAULT_GAIN=-12.0
def res(p):return "res://assets/audio/fog/"+p[len("audio/"):]
by={e["event"]:e for e in MAN}
out={};used=set()
for old_id,man_id in REPOINT.items():
 o=OLD[old_id];m=by[man_id];used.add(man_id)
 c={"files":[res(p) for p in m["files"]],"bus":m["bus"],"cooldown":o["cooldown"],"priority":o["priority"],"max_voices":o["max_voices"],"gain_db":o["gain_db"],"pitch":m.get("pitch_var",0.0),"base_pitch":1.0,"manifest":man_id}
 if man_id in ORDERED:c["ordered"]=True
 if m["loop"]:c["loop"]=True
 out[old_id]=c
for old_id,o in OLD.items():
 if old_id not in out and old_id not in RETIRED:out[old_id]=o
for m in MAN:
 if m["event"] in used:continue
 c={"files":[res(p) for p in m["files"]],"bus":m["bus"],"cooldown":m.get("cooldown",0.0),"priority":m.get("priority",5 if m["bus"]=="Music" else 1),"max_voices":m.get("max_voices",1),"gain_db":m.get("gain_db",DEFAULT_GAIN),"pitch":m.get("pitch_var",0.0),"base_pitch":1.0,"manifest":m["event"]}
 if m["event"] in ORDERED:c["ordered"]=True
 if m["loop"]:c["loop"]=True
 if m["bus"]=="Music":c["music"]=True
 out[m["event"]]=c
json.dump({"events":out},open(PATH,"w"),indent=2)
print(len(out),"events;",len(used),"repointed manifest ids;",len({m['event'] for m in MAN}-used-{k for k in out if out[k].get('manifest')==k}),"x")
