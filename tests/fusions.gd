extends SceneTree
# Fusions: gem pairs -> Fusion, audio layers replace (never add to) the element layers, form damage goes through Game.hit(), DPS table,
# pool caps at 500 enemies, deterministic runs, weapon models, forge timing/skip/muted, manifest sounds, ultimate sounds.
var failures: Array[String]=[]
var count=0
var game: Node
func check(value: bool, label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func fresh(seed_value: int=611) -> void:
 if game==null:
  game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://fusions-profile.json"
 game.next_run_seed=seed_value;game.map_seed_override=9;game.begin_run();game.resume();game.set_physics_process(false);game.spawn_clock=999.0
 game.sandbox=true;game.settings.invincible=true;game.enemies.clear();game.projectiles.clear();game.world_time.reset()
func step(seconds: float,dt: float=0.05) -> void:
 var n=maxi(1,int(round(seconds/dt)))
 for i in n:
  if game.mode!="run":game.mode="run"
  game.spawn_clock=999.0
  game._physics_process(seconds/n)
func give(wid: int,gems: Array) -> void:
 game.weapons.clear();game.equip(wid);game.selected_weapon=wid
 game.weapons[wid]["sockets"]={"unlocked":maxi(1,gems.size()),"gems":gems}
func dummies(n: int,radius: float) -> Array:
 var out=[];var rng=RandomNumberGenerator.new();rng.seed=5
 for i in n:
  var a=rng.randf()*TAU;var d=3.0+rng.randf()*radius
  var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*d,0,sin(a)*d))
  if e.is_empty():continue
  e.hp=1.0e9;e.max_hp=1.0e9;out.append(e)
 return out
func total_hp(list: Array) -> float:
 var t=0.0
 for e in list:t+=1.0e9-float(e.hp)
 return t
func run():
 MenuScreen.set_instant(true)
 data_checks()
 await audio_layers()
 await damage_paths()
 await dps_table()
 await pools()
 await determinism()
 forge_checks()
 await sounds_and_ultimates()
 print("fusions: %d checks, %d failures"%[count,failures.size()])
 if failures.is_empty():print("ALL PASS");quit(0)
 else:
  for f in failures:print("FAILED: "+f)
  quit(1)
func data_checks() -> void:
 var pairs={"fire+ice":"steamforged","electricity+fire":"plasma","electricity+ice":"aurora","corrosive+electricity":"livewire","corrosive+fire":"pyrebile","corrosive+ice":"rimerot"}
 for k in pairs:
  var g=k.split("+")
  check(Fusions.of_gems(g[0],g[1])==pairs[k] and Fusions.of_gems(g[1],g[0])==pairs[k],"%s in either order is %s"%[k,pairs[k]])
 check(Fusions.of_gems("fire","fire")=="" and Fusions.of_gems("fire","")=="" and Fusions.of_gems("","")=="","A non-combo pair (same gem, one gem, none) is not a Fusion")
 check(Fusions.IDS.size()==6 and Fusions.TABLE.size()==6,"Six Fusions in the table")
 var all_named=true
 for id in Fusions.IDS:
  var t: Dictionary=Fusions.TABLE[id]
  if str(t.name)=="" or str(t.epithet)=="" or not t.has("palette") or str(t.combo)=="":all_named=false
 check(all_named,"Every Fusion has a name, epithet, combo and palette")
 check(Fusions.weapon_name({"sockets":{"gems":["fire","ice"]}},0).begins_with("Steamforged "),"A Fusion weapon is named '<Fusion> <Weapon>'")
 check(Fusions.FORMS.size()==8 and Fusions.WEAPON_KEYS.size()==8,"Eight forms, one per Fusion-capable weapon")
 var numbers_ok=true
 for w in Fusions.FORMS:
  for k in Fusions.FORMS[w]:if not (Fusions.FORMS[w][k] is int or Fusions.FORMS[w][k] is float):numbers_ok=false
 check(numbers_ok and Fusions.DAMAGE_MULT>1.0 and Fusions.SAFETY.boss_hit_max_fraction<=0.05,"Every Fusion number lives in the Fusions table")
 var models_ok=true
 for w in Fusions.WEAPON_KEYS:
  var path="res://assets/models/weapons/%s.glb"%Fusions.WEAPON_KEYS[w]
  var scene=load(path) as PackedScene
  if scene==null:models_ok=false;continue
  var n=scene.instantiate()
  if n.get_node_or_null("grip")==null or n.get_node_or_null("tip")==null or n.get_node_or_null("head")==null or n.find_children("*","MeshInstance3D",true,false).is_empty():models_ok=false
  n.free()
 check(models_ok,"Every Fusion weapon resolves to a 3D model that loads with grip/tip/head markers")
func audio_layers() -> void:
 await fresh();game.audio.count_emits=true
 var a: RetroAudio=game.audio
 give(0,["fire","ice"]);a.emit_counts.clear();a.last_events.clear()
 ElementAudio.attack(game,0,Vector3.ZERO);ElementAudio.hit(game,0,Vector3.ZERO)
 check(int(a.emit_counts.get("fusion.steamforged.attack",0))==1 and int(a.emit_counts.get("fusion.steamforged.hit",0))==1,"A Fusion plays its own attack and hit")
 check(int(a.emit_counts.get("element.fire.attack",0))+int(a.emit_counts.get("element.ice.attack",0))+int(a.emit_counts.get("element.fire.hit",0))+int(a.emit_counts.get("element.ice.hit",0))==0,"Fusion layers replace the element layers (attack and hit)")
 ElementAudio.loop_sync(game,0,true,Vector3.ZERO)
 check(a.loop_active(ElementAudio.fusion_loop_key(0)) and not a.loop_active(ElementAudio.loop_key(0,"fire")) and not a.loop_active(ElementAudio.loop_key(0,"ice")),"The Fusion loop replaces the element loops")
 ElementAudio.loop_sync(game,0,false,Vector3.ZERO)
 give(0,["fire"]);a.emit_counts.clear();a.last_events.clear()
 ElementAudio.attack(game,0,Vector3.ZERO);ElementAudio.hit(game,0,Vector3.ZERO)
 check(int(a.emit_counts.get("element.fire.attack",0))==1 and int(a.emit_counts.get("element.fire.hit",0))==1,"A one-gem weapon still plays its element layers")
 ElementAudio.loop_sync(game,0,true,Vector3.ZERO)
 check(a.loop_active(ElementAudio.loop_key(0,"fire")) and not a.loop_active(ElementAudio.fusion_loop_key(0)),"A one-gem weapon still plays its element loop")
 ElementAudio.loop_sync(game,0,false,Vector3.ZERO)
func damage_paths() -> void:
 for wid in Fusions.WEAPON_KEYS:
  await fresh();give(wid,["fire","ice"])
  var list=dummies(120,7.0);game.world_time.freeze(1.0e6)
  step(14.0)
  var fusion="steamforged";var recorded=float(game.damage_total);var lost=total_hp(list)
  var form=float(game.damage_by_form.get(fusion,0.0))
  check(lost>0.0 and absf(lost-recorded)<=maxf(1.0,lost*0.002),"%s: every point of damage went through Game.hit() (%.0f lost, %.0f recorded)"%[Fusions.WEAPON_KEYS[wid],lost,recorded])
  check(form>0.0,"%s: its fused form dealt damage (%.0f)"%[Fusions.WEAPON_KEYS[wid],form])
func run_dps(wid: int,gems: Array,forms_on: bool,n: int,seconds: float) -> float:
 await fresh(900+wid);give(wid,gems);FusionForms.enabled=forms_on
 var list=dummies(n,5.0 if n<100 else 28.0);game.world_time.freeze(1.0e6)
 step(seconds)
 FusionForms.enabled=true
 return total_hp(list)/seconds
func dps_table() -> void:
 var lines=[]
 for wid in Fusions.WEAPON_KEYS:
  var row={}
  row["fusion"]=await run_dps(wid,["fire","ice"],true,30,12.0)
  row["fusion_no_form"]=await run_dps(wid,["fire"+"","ice"],false,30,12.0)
  row["one_gem"]=await run_dps(wid,["fire"],true,30,12.0)
  row["no_gem"]=await run_dps(wid,[],true,30,12.0)
  row["fusion_500"]=await run_dps(wid,["fire","ice"],true,500,8.0)
  row["no_gem_500"]=await run_dps(wid,[],true,500,8.0)
  lines.append("DPS|%s|%.0f|%.0f|%.0f|%.0f|%.0f|%.0f"%[Fusions.WEAPON_KEYS[wid],row.fusion,row.fusion_no_form,row.one_gem,row.no_gem,row.fusion_500,row.no_gem_500])
  check(row.fusion>row.no_gem and row.fusion>=row.fusion_no_form*0.98,"%s: a Fusion out-damages no gem (%.0f vs %.0f) and its form does not lose damage"%[Fusions.WEAPON_KEYS[wid],row.fusion,row.no_gem])
 for l in lines:print(l)
func pools() -> void:
 await fresh(77)
 game.weapons.clear()
 for wid in [0,1,2,6]:
  game.equip(wid);game.weapons[wid]["sockets"]={"unlocked":2,"gems":["fire","ice"]}
 var list=dummies(500,28.0);game.world_time.freeze(1.0e6)
 var rt=game.wrt;var peak={"crescents":0,"tethers":0,"lines":0,"arrows":0,"bullets":0,"scythes":0,"fireballs":0,"timers":0}
 var budget_ok=true
 for i in 200:
  step(0.05,0.05)
  var f: FusionForms=rt.forms
  peak.crescents=maxi(peak.crescents,f.crescents.size());peak.tethers=maxi(peak.tethers,f.tethers.size());peak.lines=maxi(peak.lines,f.lines.size())
  peak.arrows=maxi(peak.arrows,rt.arrows.size());peak.bullets=maxi(peak.bullets,rt.bullets.size());peak.scythes=maxi(peak.scythes,rt.scythes.size());peak.fireballs=maxi(peak.fireballs,rt.fireballs.size());peak.timers=maxi(peak.timers,rt.timers.size())
  if rt.fusion_budget>24.0+0.001:budget_ok=false
 check(peak.crescents<=FusionForms.MAX_CRESCENTS and peak.tethers<=FusionForms.MAX_TETHERS and peak.lines<=FusionForms.MAX_LINES,"Form pools stay within caps at 500 enemies (%s)"%str(peak))
 check(peak.arrows<=WeaponRuntime.MAX_ARROWS and peak.bullets<=WeaponRuntime.MAX_BULLETS and peak.scythes<=WeaponRuntime.MAX_SCYTHES and peak.fireballs<=WeaponRuntime.MAX_FIREBALLS and peak.timers<=WeaponRuntime.MAX_TIMERS,"Weapon pools stay within caps at 500 enemies")
 check(budget_ok,"Fusion impacts never exceed the 24/s combo budget")
 check(rt.forms.stats.hits>0,"Forms ran at 500 enemies (%d form hits, %d dropped by the cap)"%[rt.forms.stats.hits,rt.forms.stats.dropped])
func fingerprint() -> String:
 var h=0.0
 for e in game.enemies:h+=float(e.hp)+e.pos.x*3.0+e.pos.z
 return "%.3f|%d|%d"%[h,game.enemies.size(),game.rng.randi()]
func one_run(muted: bool) -> String:
 await fresh(4242);game.audio.muted=muted;game.sandbox=false;game.settings.invincible=true
 give(0,["fire","ice"]);game.spawn_clock=0.0
 for i in 200:
  if game.mode!="run":game.mode="run"
  game._physics_process(0.05)
 var out=fingerprint();game.audio.muted=false;return out
func determinism() -> void:
 var a=await one_run(false);var b=await one_run(true);var c=await one_run(false)
 check(a==c,"A seeded run repeats exactly (%s)"%a)
 check(a==b,"A seeded run is identical with audio on or off")
func forge_checks() -> void:
 # collision lands within one frame of 0.85 s: normal frames, uneven frames, and a 200 ms hitch on the first frame
 for pattern in [[0.016],[0.016,0.033,0.016,0.05,0.016],[0.2,0.016,0.03]]:
  var clock=[0.0]
  var f=ForgeScene.new().setup("steamforged",["fire","ice"],"sword","Steamforged Sword");f.time_source=func():return clock[0]
  root.add_child(f)
  var prev=0.0;var at=-1.0;var step_dt=0.0;var i=0
  while clock[0]<2.0:
   step_dt=pattern[i%pattern.size()];i+=1;prev=clock[0];clock[0]+=step_dt;f._process(step_dt)
   if at<0.0 and f.collided:at=clock[0];break
  check(at>=ForgeScene.COLLIDE and at-ForgeScene.COLLIDE<=step_dt+0.0001 and prev<ForgeScene.COLLIDE,"Collision lands on the first frame at or after 0.85 s (frame %.3f, pattern %s)"%[at,str(pattern)])
  while clock[0]<2.0:clock[0]+=0.016;f._process(0.016)
  check(f.collide_calls==1 and f.reformed and f.carded,"Collision, re-form and card each happen exactly once")
  f.end();f.free()
 # skip: picture and timeline jump together, second skip closes
 var clock2=[0.3]
 var g=ForgeScene.new().setup("plasma",["electricity","fire"],"bow","Plasma Bow");g.time_source=func():return clock2[0]
 root.add_child(g);g._process(0.016)
 var done=[false];g.finished.connect(func():done[0]=true)
 g.skip()
 check(is_equal_approx(g.t,ForgeScene.CARD) and is_equal_approx(g.clock,ForgeScene.CARD) and g.collided and g.reformed and g.collide_calls==1,"Skip jumps the picture and the clock to the name card, with collision/re-form not skipped")
 clock2[0]=0.4;g._process(0.016)
 check(g.t>=ForgeScene.CARD,"After a skip the timeline never rewinds")
 g.skip();check(done[0],"A second skip closes the forge")
 # muted/no sound: the clock carries it to the end
 var m=ForgeScene.new().setup("aurora",["electricity","ice"],"scythe","Aurora Scythe");root.add_child(m)
 var finished=[false];m.finished.connect(func():finished[0]=true)
 var guard=0
 while not finished[0] and guard<400:
  m._process(0.016);guard+=1
 check(finished[0] and m.collided and m.reformed,"With the sound muted the forge still plays and ends")
 # pause holds both
 var p=ForgeScene.new().setup("livewire",["corrosive","electricity"],"shotgun","Livewire Shotgun");root.add_child(p)
 p._process(0.1);var t0=p.t;p.set_paused(true);for i in 10:p._process(0.1)
 check(is_equal_approx(p.t,t0),"Pausing holds the timeline");p.end();p.free()
func sounds_and_ultimates() -> void:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://docs/stopwatch_fusions/manifest_additions.json")).events
 var events=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/events.json"))
 var ev=events.events if events.has("events") else events
 var missing=[]
 for id in manifest:
  if not ev.has(id):missing.append(id);continue
  for f in ev[id].files:if not FileAccess.file_exists("res://assets/audio/"+str(f).trim_prefix("res://assets/audio/")) and not FileAccess.file_exists(str(f)):missing.append(str(f))
 check(missing.is_empty(),"Every sound in the manifest additions is an event with its WAV on disk (%d events, missing: %s)"%[manifest.size(),str(missing)])
 # ultimates
 for u in ["ghost","berserk","nova"]:
  await fresh(31);game.sandbox=false;game.audio.count_emits=true;game.audio.emit_counts.clear();game.audio.last_events.clear()
  var lr: LoadoutRuntime=game.loadout_runtime;lr.reset("climber",u)
  lr.cooldown=0.0;game.mode="run"
  check(lr.activate(game),"%s activates"%u)
  var c=game.audio.emit_counts
  var press={"nova":"ult.cataclysm_activate","ghost":"ult.ghost_form","berserk":"ult.berserker"}[u]
  check(int(c.get(press,0))==1,"%s plays its opening exactly once on press"%u)
  check(int(c.get("combat.explosion",0))==0,"%s never plays combat.explosion"%u)
  if u=="nova":
   check(int(c.get("weapon.ult_cataclysm",0))==1,"Cataclysm plays weapon.ult_cataclysm (the new file) on the same press")
   check(String(ev["weapon.ult_cataclysm"].files[0]).ends_with("ult_cataclysm.wav") and String(ev["weapon.ult_cataclysm"].files[0]).contains("fog/weapons"),"weapon.ult_cataclysm points at the new file")
   continue
  var loop="ult.ghost_loop" if u=="ghost" else "ult.berserker_loop"
  var end="ult.ghost_end" if u=="ghost" else "ult.berserker_end"
  check(game.audio.loop_active(LoadoutRuntime.LOOP_KEY),"%s loop is playing while it is active"%u)
  game.audio.silence_loops();check(not game.audio.loop_active(LoadoutRuntime.LOOP_KEY),"%s loop is silenced by a pause"%u)
  lr.tick(game,0.016);check(game.audio.loop_active(LoadoutRuntime.LOOP_KEY),"%s loop resumes after the pause"%u)
  check(int(c.get(end,0))==0,"No end cue while active")
  lr.tick(game,100.0);check(not game.audio.loop_active(LoadoutRuntime.LOOP_KEY) and int(c.get(end,0))==1,"%s loop stops and the end cue plays once on expiry"%u)
  lr.cooldown=0.0;lr.activate(game);check(game.audio.loop_active(LoadoutRuntime.LOOP_KEY),"%s can be used again"%u)
  lr.stop_audio(game);check(not game.audio.loop_active(LoadoutRuntime.LOOP_KEY),"%s loop stops on death/Results"%u)
 await fresh(31);game.world_time.activate()
 var lr2: LoadoutRuntime=game.loadout_runtime;lr2.reset("climber","ghost");game.mode="run"
 check(lr2.activate(game) and lr2.remaining>0.0,"Ultimates work while the Stopwatch runs (unaffected)")
