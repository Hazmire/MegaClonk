extends SceneTree
# In-run UI Overhaul regression (grows with each step). Headless; real renders are covered by tools/ingame_capture.gd.
var count=0
var failures: Array[String]=[]
var game: Node3D
func check(ok: bool,label: String) -> void:
 count+=1
 if ok:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-ingame-ui.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 foundation()
 print("INGAME_UI: %d checks, %d failures"%[count,failures.size()])
 quit(1 if failures.size()>0 else 0)
func foundation() -> void:
 # ---- shared scenes and the theme ----
 var scenes_ok=true
 for key in ["rarity_slot","stamp","hud_number","caps_label"]:
  var packed=load(MenuStyle.SCENES[key]) as PackedScene
  if packed==null or not MenuStyle.SCENES[key].begins_with("res://ui/common/"):scenes_ok=false;continue
  packed.instantiate().free()
 check(scenes_ok,"Shared widgets live in ui/common and still load for the menus")
 check(game.frontend.root.theme==MenuStyle.theme(),"The in-run UI root uses the shared Fog theme")
 check(game.frontend.run_overlay!=null and game.frontend.run_stage!=null,"Run overlay and the 1920x1080 run stage exist")
 # ---- run overlay: always scanlines, low_hp at <=30% HP, stopwatch while hostile time is slowed ----
 var o=game.frontend.run_overlay
 check(RunOverlay.wants_low_hp(30,100) and not RunOverlay.wants_low_hp(31,100) and not RunOverlay.wants_low_hp(0,100),"low_hp turns on at exactly 30% HP and off above it")
 game.health=20.0;o.sync(game,1.0);check(o.low_hp>=0.99,"Overlay low_hp is driven by HP")
 game.health=game.stats.max_health;o.sync(game,1.0);check(o.low_hp<=0.01,"Overlay low_hp clears when healed")
 game.world_time.freeze(2.0);o.sync(game,1.0);check(o.stopwatch>=0.99,"Overlay stopwatch is driven by the Hourglass freeze")
 game.world_time.reset();o.sync(game,1.0);check(o.stopwatch<=0.01,"Overlay stopwatch clears when time resumes")
 # ---- Stats panel: rows generated from the real stats, preview matches the change ----
 var stats=StatsPanel.new().setup(game);root.add_child(stats)
 var missing=[]
 for key in game.stats:
  if not stats.rows.has(key):missing.append(key)
 check(missing.is_empty(),"Every stat the game has is a row in the Stats panel (missing: %s)"%[missing])
 check(stats.rows.has("luck"),"The Stats panel shows Luck")
 var before=stats.shown_text("damage")
 stats.preview("damage",1.0,1.06)
 check(stats.shown_text("damage")==RunData.stat_text("damage",1.0)+" → "+RunData.stat_text("damage",1.06),"Stats preview shows old → new computed by the same formatter")
 stats.clear_preview();check(stats.shown_text("damage")==before,"Clearing the preview restores the row")
 stats.free()
 # ---- Inventory panel: matches the build; signature gates rebuilds ----
 game.apply_upgrade({"type":"tome","id":Catalog.ACTIVE_TOMES[0]})
 var inv=InventoryPanel.new().setup(game);root.add_child(inv)
 var sig=inv.signature;inv.refresh();check(inv.signature==sig,"Inventory refresh without a build change does nothing")
 game.gems.add("fire",2);game.amulets=3;inv.refresh();check(inv.signature!=sig,"Inventory rebuilds when gems or amulets change")
 check(RunData.gem_counts(game)["fire"]==2 and RunData.build_signature(game).contains("a3"),"RunData reports gem and Amulet counts from game state")
 inv.free()
 # ---- toast queue: merge and cap ----
 var q=ToastQueue.new()
 q.push("gem:fire");q.push("gem:fire");q.tick(0.0)
 check(q.current.key=="gem:fire" and q.current.count==2,"Same-element pickups merge into one toast (×2)")
 q.push("gem:fire");check(q.current.count==3,"A pickup of the toast being shown merges into it")
 for i in 20:q.push("gem:k%d"%i)
 check(q.waiting.size()<=ToastQueue.CAP,"The waiting line is hard-capped")
 q.tick(ToastQueue.MIN_SHOW-0.1);check(q.current.key=="gem:fire","A toast stays at least 1.2 s while others wait")
 q.tick(0.2);check(q.current.key!="gem:fire","...then makes way for the next one")
 # ---- pickup popups: pooled, merging, capped ----
 var pops=PickupPopups.new();root.add_child(pops)
 pops.add("gold",5,Vector2(100,100));pops.add("gold",7,Vector2(110,100))
 check(pops.live_count()==1 and pops.slots[0].label.text=="+12","Close gold pickups merge into one popup (+12)")
 for i in 40:pops.add("xp",1,Vector2(i*300,0))
 check(pops.live_count()<=PickupPopups.CAP and pops.get_child_count()==PickupPopups.CAP,"Pickup popups never exceed the pool cap")
 pops.free()
