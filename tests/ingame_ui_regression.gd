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
 await hud()
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
 check(pops.live_count()<=PickupPopups.CAP and pops.slots.size()==PickupPopups.CAP,"Pickup popups never exceed the pool cap")
 pops.free()
func labels(node: Node) -> Array:
 var out=[]
 if node is Label:out.append(node)
 for c in node.get_children():out.append_array(labels(c))
 return out
func hud() -> void:
 var fe=game.frontend;var h=fe.run_hud
 await process_frame
 game.mode="run";game.chests_opened=3;game.gold=1234;game.kills=77;game.level=4;game.xp=5.0;game.health=61.0;game.stats.max_health=100.0
 fe.update_hud()
 check(h.gold_value.text=="1234" and h.kills_value.text=="77","HUD gold and kills equal game state")
 check(h.chest_value.text==str(Economy.chest_cost(3)) and h.chest_value.text==str(game.chest_cost()),"HUD chest cost comes from Economy (live, exponential)")
 check(h.health_text.text=="61 / 100" and int(game.health_bar.value)==61 and int(game.health_bar.max_value)==100,"HUD health text and bar equal game state")
 check(h.level_label.text=="Level 4" and h.xp_label.text.begins_with("5 / %d"%int(Catalog.threshold(4))),"HUD level and XP equal game state")
 check(h.stage_label.text.begins_with("STAGE %d"%game.stage),"HUD stage line is built from the real stage and theme title")
 var texts=labels(h).map(func(l):return l.text)
 check(not texts.any(func(t):return t.contains("KILLS ") or t.contains("HP ") and t.contains("LV ")) and not labels(fe.hud_root).any(func(l):return l.visible and l.text.contains("HP ") and l.text.contains("LV ")),"The old HP / LV / KILLS text line is gone")
 game.settings.fps=false;fe.update_hud();check(not h.fps_label.visible,"FPS text is hidden unless the debug setting is on")
 game.settings.fps=true;h.fps_clock=1.0;fe.update_hud();check(h.fps_label.visible and h.fps_label.text.ends_with("FPS"),"FPS text is a debug toggle (Settings > Graphics)")
 game.settings.fps=false
 # socket gems row and Amulet slot follow the counts
 game.gems.reset();game.amulets=0;fe.update_hud()
 var gem_slots=h.gems_row.get_children()
 check(gem_slots.size()==5 and gem_slots.all(func(c):return c.modulate.a<0.5),"Socket gem row has four elements plus the Amulet and all are dimmed when empty")
 game.gems.add("ice",3);game.amulets=2;fe.update_hud()
 check(h.gems_row.get_child(1).modulate.a>0.9 and h.gems_row.get_child(4).modulate.a>0.9 and h.gems_row.get_child(4).tooltip_text.contains("×2"),"Socket gem row shows the Ice count and the Imbued Amulet count")
 # per-section updates: an item pickup rebuilds items only
 var tomes_before=h.tomes_row.get_child(0) if h.tomes_row.get_child_count()>0 else null
 game.grant_item(Catalog.ITEM_IDS[0],true);fe.update_hud();await process_frame
 check(tomes_before==null or h.tomes_row.get_child(0)==tomes_before,"An item pickup does not rebuild the weapon or tome rows")
 var visible_items=h.item_pool.filter(func(e):return e.wrap.visible).size()
 check(visible_items==game.items.size(),"Item tiles show every item up to the pool cap (%d)"%visible_items)
 check(h.item_pool.size()==RunHud.ITEM_POOL,"The item tile pool is fixed in size")
 for id in Catalog.ITEM_IDS:game.grant_item(id,true)
 fe.update_hud();await process_frame
 var shown=h.item_pool.filter(func(e):return e.wrap.visible).size()
 check(shown<=RunHud.ITEM_POOL and h.item_pool[RunHud.ITEM_POOL-1].more>0 or game.items.size()<=RunHud.ITEM_POOL,"More items than the cap collapse into a '+n' tile")
 # ultimate tile state
 game.loadout_runtime.cooldown=0.0;game.loadout_runtime.remaining=0.0;fe.update_hud();check(h.ult_tile.state=="ready","Ultimate tile reads READY when off cooldown")
 game.loadout_runtime.cooldown=20.0;fe.update_hud();check(h.ult_tile.state=="cooling" and h.ult_tile.seconds==20,"Ultimate tile shows the cooldown in seconds")
 game.loadout_runtime.cooldown=0.0
 # popups from gold/xp gains
 var total=func():return h.popups.slots.filter(func(x):return x.live).reduce(func(a,x):return a+x.amount,0.0)
 var before=total.call();game.gold+=9;fe.update_hud();check(total.call()>=before+9.0 and h.popups.live_count()>=1,"A gold pickup raises (or merges into) a world popup")
 # HUD lives on the design stage and uses the shared theme
 check(h.get_parent()==fe.run_stage.stage and fe.run_stage.theme==MenuStyle.theme(),"HUD is laid out on the 1920x1080 stage with the shared theme")
