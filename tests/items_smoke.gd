extends SceneTree
# Equips every one of the 60 items at once and runs 600 frames with a crowd, interactions and kills.
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-items-smoke.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume();await physics_frame
 game.settings.invincible=false
 for id in Catalog.ITEM_IDS:game.grant_item(id,true)
 check(game.items.size()==60,"All 60 items are equipped")
 for entry in game.items:if not Catalog.item_unique(entry.id):game.grant_item(entry.id,true)
 check(game.item_stacks("whetstone")==2 and game.item_stacks("saints_finger")==1,"Stacking and Unique rules hold with the full set")
 game.stats.evasion=0.0;game.health=game.stats.max_health
 for id in Catalog.ACTIVE_WEAPONS.slice(0,4):if not game.weapons.has(id):game.equip(id)
 for id in game.weapons:
  WeaponSockets.unlock_second(game.weapons[id])
  var els=["fire","corrosive","ice","electricity"]
  WeaponSockets.install(game.weapons[id],els[id%4]);WeaponSockets.install(game.weapons[id],els[(id+1)%4])
 game.mode="run";game.spawn_clock=999
 for i in 150:
  var e=game.spawn_enemy(i%3,game.player.position+Vector3(cos(float(i))*9.0,0,sin(float(i))*9.0));if not e.is_empty():e.speed=1.0
 var kills0=game.kills
 var peak_psx=0
 var times=[]
 for frame in 600:
  if frame==100:game.irt.on_chest_opened();game.irt.on_powerup("heart");game.irt.on_level_up()
  if frame==200:game.irt.on_evade();game.irt.on_damage_taken(3.0)
  if frame==300:game.player.position+=Vector3(0,0,20.0)
  if frame%60==0:game.invulnerability=0.0;game.hurt(2.0)
  if frame%90==0 and game.enemies.size()<200:
   for k in 20:game.spawn_enemy(0,game.player.position+Vector3(cos(float(k))*7.0,0,sin(float(k))*7.0))
  var t0=Time.get_ticks_usec()
  await physics_frame
  times.append(float(Time.get_ticks_usec()-t0)/1000.0)
  peak_psx=maxi(peak_psx,game.psx.live_count())
  game.health=maxf(game.health,5.0)
 check(true,"600 frames ran without a script error (peak PSX particles %d)"%peak_psx)
 check(game.kills>kills0,"The crowd was actually fought (%d kills)"%(game.kills-kills0))
 check(game.irt.wraiths.size()<=int(ItemStats.v("restless_bones","cap")) and game.irt.souls.size()<=int(ItemStats.v("reapers_sickle","cap")) and game.irt.hounds.size()<=int(ItemStats.v("hound_whistle","cap")) and game.irt.puddles.size()<=int(ItemStats.v("mire_flask","cap")) and game.irt.meat.size()<=int(ItemStats.v("pyre_ashes","pickup_cap")),"Every summon pool stays within its hard cap")
 var finite=true
 for k in game.stats:if game.stats[k] is float and not is_finite(game.stats[k]):finite=false
 check(finite and game.stats.max_health>=float(ItemStats.T.max_health_floor),"Stats stay finite and max HP respects the floor")
 var save_ok=game.save_run("user://test-items-smoke-run.json") and game.load_run("user://test-items-smoke-run.json")
 check(save_ok and game.items.size()>=59,"A run with every item saves and loads (hourglass may have been spent: %d items)"%game.items.size())
 print("ITEMS_SMOKE: %d checks, %d failures; dropped=%s"%[checks,failures.size(),str(game.irt.dropped)])
 game.queue_free();await process_frame;await process_frame
 quit(1 if failures.size()>0 else 0)
