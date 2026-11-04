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
# Feedback pass 1 (playtest: "cannot hear enemies taking damage", quiet pickups / chest reel / gem): new absolute gains in dB.
# Hits land at the enemy, 10-15 m from the camera, so the 3D falloff costs another ~8 dB on top of their old quiet mix.
GAIN_OVERRIDE={
"weapon.sword.hit":-4,"weapon.firestaff.impact":-3,"weapon.bow.hit":-5,"weapon.revolver.hit":-5,"weapon.scythes.hit":-4,"weapon.shotgun.hit":-6,"weapon.lightning.chain":-8,
"weapon.sword.crit":-7,"weapon.firestaff.crit":-7,"weapon.lightning.crit":-7,"weapon.bow.crit":-8,"weapon.revolver.crit":-7,"weapon.scythes.crit":-7,"weapon.shotgun.crit":-8,"weapon.aura.crit":-11,
"pickup.gold":-21,"ui.socket_hover":6,"world.gem_found_corrosive":-5,"world.gem_found_electric":-5,"world.gem_found_fire":-5,"world.gem_found_ice":-5,"pickup.xp":-8,"gem.pickup":-7,"reward.chest.tick":-6,
}
for k,g in GAIN_OVERRIDE.items():out[k]["gain_db"]=g
# Fix pass 2: menu hover sounds must retrigger as fast as the pointer moves (they used to wait for the previous 0.6 s clip to finish).
# The socket_hover sample peaks 15 dB under the other UI clips, hence its positive gain above.
for k,(cd,mv) in {"ui.hover":(0.03,8),"ui.card_hover":(0.02,6)}.items():out[k]["cooldown"]=cd;out[k]["max_voices"]=mv
# The socket-hover swell is held as a charge: a gapless body of the sample (frames, zero-slope matched) loops while the pointer is on a slot.
out["ui.socket_hover"]["charge_loop"]=[13740,25558]
# Endless mode: the banshee at the 0:00 switch. Measured (RMS/peak dBFS, raw file): banshee -18.0/-1.9 vs boss_enrage_* mean -16.0/-1.0,
# so +2 dB over their -12 dB gain puts it level (-10). Priority above boss_enrage (5) so it is never stolen; one voice, plays once per run.
out["world.endless_begins_banshee"]={"files":["res://assets/audio/fog/world/endless_begins_banshee.wav"],"bus":"SFX","cooldown":0.0,"priority":8,"max_voices":1,"gain_db":-10.0,"pitch":0.0,"base_pitch":1.0,"manifest":"world.endless_begins_banshee","length_s":3.0}

# Stopwatch / Fusions / ultimates pack (docs/stopwatch_fusions/manifest_additions.json). Every WAV is the sound zip's file, imported untouched
# (no resample, no gain, no trim); the event gain is the same -12 dB convention as every other manifest event, so the layers are not re-gained.
ADD=json.load(open(os.path.join(ROOT,"docs/stopwatch_fusions/manifest_additions.json")))["events"]
DIRS={"stopwatch/":"powers/","fusion/":"fusion/","imbue_combo/":"imbue/","ultimates/":"ultimates/"}
def pack_res(p):
 for a,b in DIRS.items():
  if p.startswith(a):return "res://assets/audio/fog/"+b+p[len(a):]
 raise KeyError(p)
for eid,m in ADD.items():
 files=[pack_res(p) for p in m["files"]]
 if eid=="ult.cataclysm":files=["res://assets/audio/fog/weapons/ult_cataclysm.wav"] # replaces the file behind weapon.ult_cataclysm in place
 c={"files":files,"bus":m["bus"],"cooldown":m.get("cooldown",0.0),"priority":m.get("priority",1),"max_voices":m.get("max_voices",1),"gain_db":-12.0,"pitch":0.04 if eid.startswith("fusion.") else 0.0,"base_pitch":1.0,"manifest":eid}
 if m.get("loop"):c["loop"]=True
 if "fuse_moment_s" in m:c["fuse_moment_s"]=m["fuse_moment_s"]
 if eid.startswith("imbue.") and eid in out:c["gain_db"]=out[eid]["gain_db"];c["priority"]=out[eid]["priority"];c["bus"]=out[eid]["bus"] # the Imbue Station keeps its UI bus
 out[eid]=c
# The ids the game already emits keep their ids and point at the new files: powerup.stopwatch -> activate, weapon.ult_cataclysm -> the new cataclysm.
out["powerup.stopwatch"]=dict(out["powerup.stopwatch_activate"],manifest="powerup.stopwatch")
out["weapon.ult_cataclysm"]=dict(out["ult.cataclysm"],manifest="weapon.ult_cataclysm")
# Magnet: the new activate sound (the pack's magnet_rush is deliberately not used).
out["powerup.magnet_activate"]={"files":["res://assets/audio/fog/powers/magnet_activate.wav"],"bus":"SFX","cooldown":0.0,"priority":9,"max_voices":1,"gain_db":-12.0,"pitch":0.0,"base_pitch":1.0,"manifest":"powerup.magnet_activate"}
out["powerup.magnet"]=dict(out["powerup.magnet_activate"],manifest="powerup.magnet")
json.dump({"events":out},open(PATH,"w"),indent=2)
print(len(out),"events;",len(used),"repointed manifest ids;",len({m['event'] for m in MAN}-used-{k for k in out if out[k].get('manifest')==k}),"x")
