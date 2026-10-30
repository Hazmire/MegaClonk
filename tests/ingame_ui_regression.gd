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
 await notifications()
 await boss_bars()
 await pause_screen()
 await level_up()
 await shop_screen()
 await shrine_screen()
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
 q.push("gem:fire");q.push("gem:fire");q.start_next()
 check(q.current.key=="gem:fire" and q.current.count==2,"Same-element pickups merge into one toast (×2)")
 q.push("gem:fire");check(q.current.count==3,"A pickup of the toast being shown merges into it")
 for i in 20:q.push("gem:k%d"%i)
 check(q.waiting.size()<=ToastQueue.CAP,"The waiting line is hard-capped")
 check(q.tick(ToastQueue.MIN_SHOW-0.1).is_empty() and q.current.key=="gem:fire","A toast stays at least 1.2 s while others wait")
 var done=q.tick(0.2);check(done.key=="gem:fire" and done.count==3 and q.current.is_empty() and q.start_next() and q.current.key!="gem:fire","...then finishes (still ×3) and makes way for the next one")
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
func notifications() -> void:
 var fe=game.frontend;var h=fe.run_hud;var tq=h.toasts;var q=tq.queue
 q.clear();tq.phase="idle";tq.card.visible=false
 game.mode="run"
 game.gems.reset();game.gems.add("fire");game.gem_discovered("fire")
 check(q.waiting.size()==1 and q.waiting[0].data.new and q.waiting[0].data.name=="Fire Gem","First gem of an element queues a toast marked as a new element")
 game.gems.add("fire");game.gem_discovered("fire")
 check(q.waiting.size()==1 and q.waiting[0].count==2,"A second gem of the same element merges into the same toast (×2)")
 var steps=0
 while tq.phase!="show" and steps<400:tq._process(0.02);steps+=1
 check(tq.phase=="show" and tq.card.visible and tq.stamp.text=="NEW ELEMENT" and tq.count_label.text=="×2","The card shows 'NEW ELEMENT' and the merged ×2 after burst and fly")
 check(tq.title.text=="Fire Gem" and tq.detail.text==Elements.summary("fire") and tq.hint.text.contains("Imbue Station"),"Toast text comes from the element data (name, summary, hint)")
 check(game.mode=="run","A toast never pauses the game or changes the mode")
 game.gems.add("fire");game.gem_discovered("fire");tq._process(0.02)
 check(tq.count_label.text=="×3","A pickup during the toast merges into the card being shown")
 steps=0
 while tq.phase!="idle" and steps<600:tq._process(0.02);steps+=1
 check(tq.phase=="idle" and not tq.card.visible,"The card collects itself and the toast ends")
 game.gem_discovered("fire")
 steps=0
 while tq.phase!="show" and steps<400:tq._process(0.02);steps+=1
 check(tq.stamp.text.begins_with("OWNED ×"),"A later gem shows 'OWNED ×n' instead of the new-element stamp")
 q.clear();tq.phase="idle"
 for i in 12:
  game.gem_discovered(Elements.IDS[i%4]);game.grant_item(Catalog.ITEM_IDS[i],false)
 check(q.waiting.size()<=ToastQueue.CAP,"Many pickups never grow the waiting line past the cap")
 q.clear();tq.phase="idle"
 game.amulets=0;game.grant_item("imbued_amulet",false)
 var amulet=q.waiting.filter(func(w):return w.data.kind=="amulet")
 check(amulet.size()==1 and amulet[0].data.tier==FogPalette.Rarity.LEGENDARY and game.amulets==1,"An Imbued Amulet uses the Legendary toast variant")
 check(h.slot_for({"data":amulet[0].data})==h.gems_row.get_child(Elements.IDS.size()),"The Amulet toast flies to the Amulet slot beside the gem row")
 q.clear();tq.phase="idle";game.grant_item(Catalog.ITEM_IDS[3],false)
 check(q.waiting.size()==1 and q.waiting[0].data.kind=="item" and q.waiting[0].data.name==Catalog.item_name(Catalog.ITEM_IDS[3]),"An item pickup raises an item toast with the item's name")
 q.clear();tq.phase="idle"
 # elite / mob / miniboss warnings are the game's own announce() events, shown in the HUD banner
 game.announce("ELITE ENCOUNTER • Obsidian Sentinels");game.frontend.event_label.text=game.announcement;fe.update_hud()
 check(h.banner.visible and h.event_label.text.begins_with("ELITE ENCOUNTER"),"The warning banner shows the game's real announcement (elite / miniboss / rush)")
 check(not game.notice.text.begins_with("ELITE ENCOUNTER"),"An announcement is not also shown as a second bottom toast")
 game.announcement_time=0.0;game.frontend.event_label.text="";fe.update_hud()
 check(not h.banner.visible,"The banner leaves when the announcement ends")
func boss_bars() -> void:
 var fe=game.frontend;var bb=fe.run_hud.bosses
 game.enemies.clear();game.mode="run"
 var spawn=func(kind,i):
  var e=game.spawn_enemy(kind,game.player.position+Vector3(10+i*3,0,5));e.speed=0.0;return e
 var stage_a=spawn.call(8,0);var stage_b=spawn.call(8,1);var stage_c=spawn.call(8,2)
 var mini_a=spawn.call(9,3);var mini_b=spawn.call(10,4);var mini_c=spawn.call(9,5)
 bb.refresh_now()
 var lit_stage=bb.stage_bars.filter(func(b):return b.lit).size();var lit_mini=bb.mini_bars.filter(func(b):return b.lit).size()
 check(lit_stage==2 and lit_mini==2,"Three stage bosses and three minibosses show at most 2+2 bars (%d+%d)"%[lit_stage,lit_mini])
 check(bb.more_label.visible and bb.more_label.text=="+2 MORE BOSSES","The rest are summarised as '+n more' (%s)"%bb.more_label.text)
 check(bb.stage_bars[0].size.x==920 and bb.mini_bars[0].size.x==440,"Stage bars are 920px and minibosses 440px wide")
 check(bb.stage_bars[0].boss_name==stage_a.variant.name,"The bar carries the boss's real name from its variant")
 fe.run_hud.update(0.016)
 check(bb.occupied_height()>200.0 and fe.run_hud.toasts.card_y>=RunBossBars.TOP+bb.occupied_height(),"Gem/item toasts move below the boss bars")
 # damage trail, hit flash, enraged, slain
 var bar: BossBar=bb.stage_bars[0]
 stage_a.hp=stage_a.max_hp*0.6;bb.update(0.016,RunBossBars.TOP)
 check(bar.fraction<0.61 and bar.trail>bar.fraction and bar.flash_left>0.0,"A hit drops the fill at once, leaves a damage trail and flashes the bar")
 for i in 10:bb.update(0.1,RunBossBars.TOP)
 check(absf(bar.trail-bar.fraction)<0.001 and bar.flash_left==0.0,"The trail drains after its delay and the flash ends")
 check(not bar.low(),"A healthy boss is not enraged")
 stage_a.hp=stage_a.max_hp*0.2;bb.update(0.016,RunBossBars.TOP);check(bar.low(),"At 25% HP or below a stage boss is enraged")
 stage_a.hp=0.0;bb.update(0.016,RunBossBars.TOP)
 check(bar.slain_t>=0.0 and bar.lit,"A dead boss gets the SLAIN stamp and keeps its bar")
 for i in 20:bb.update(0.1,RunBossBars.TOP)
 check(bar.slain_t<0.0 and not is_same(bar.target,stage_a),"The SLAIN bar leaves after about 1.5 s and its slot is freed (a waiting boss may take it)")
 bb.refresh_now()
 check(bb.stage_bars.filter(func(b):return b.lit).size()==2,"A waiting stage boss takes the freed slot")
 # statuses show in their element colours
 stage_b.fx={"cd":{},"fire":{"t":3.0}}
 var shown=bb.stage_bars.filter(func(b):return b.lit and is_same(b.target,stage_b))[0];bb.update(0.016,RunBossBars.TOP)
 check(shown.statuses==["fire"],"The status row lists the boss's active elements")
 # off-screen pointer
 check(RunBossBars.pointer_for(Vector2(960,540),false).is_empty(),"No pointer while the boss is on screen")
 var left=RunBossBars.pointer_for(Vector2(-400,500),false);var behind=RunBossBars.pointer_for(Vector2(960,540),true)
 check(not left.is_empty() and left.pos.x<400 and not behind.is_empty(),"A pointer appears for a boss off to the side or behind the camera")
 var map_rect=Rect2(1540,670,380,410);var hp_rect=Rect2(0,880,780,200)
 var clear=true
 for angle in range(0,360,15):
  var r=RunBossBars.pointer_for(Vector2(960,540)+Vector2.RIGHT.rotated(deg_to_rad(angle))*3000.0,false)
  if r.is_empty() or map_rect.has_point(r.pos) or hp_rect.has_point(r.pos) or r.pos.x<0 or r.pos.y<0 or r.pos.x>1920 or r.pos.y>1080:clear=false
 check(clear,"Pointers stay on screen and clear of the minimap and the health / ultimate block from every direction")
 game.enemies.clear();bb.refresh_now()
 check(bb.shown_bars().is_empty() or bb.shown_bars().all(func(b):return b.slain_t>=0.0 or not b.lit),"Bars with no boss left are released")
func pause_screen() -> void:
 var fe=game.frontend;game.enemies.clear();game.mode="run";game.level=7;game.kills=123;game.gold=456;game.elapsed=754.0
 game.pause_menu();await process_frame
 var screen: RunPause
 for n in fe.menu.get_children():
  if n is RunPause:screen=n
 check(screen!=null and game.mode=="pause","Pause opens the RunPause screen and sets mode pause")
 if screen==null:return
 check(screen.inventory_panel.size==Vector2(420,870) and screen.stats_panel.size==Vector2(420,870),"Pause carries the 420x870 Inventory and Stats panels (%s, %s)"%[screen.inventory_panel.size,screen.stats_panel.size])
 check(screen.inventory_panel.position.x<screen.items["resume"].global_position.x and screen.stats_panel.position.x>screen.inventory_panel.position.x+420,"Inventory sits left of the menu, Stats right")
 check((screen.get_node("Stage/Content/Title") as Label).text=="Paused" and (screen.get_node("Stage/Content/Title") as Label).get_theme_font_size("font_size")==104,"Header reads Paused in 104px serif")
 var line=screen.get_node("Stage/Content/StageLine").text.to_lower()
 check(line.contains("stage %d"%game.stage) and line.contains(StageThemes.config(game.stage).title.to_lower()),"Stage line carries the real stage number and name (%s)"%line)
 var want=RunPause.counter_values(game)
 check(want[0][1]=="7" and want[1][1]=="12:34" and want[2][1]=="123" and want[3][1]=="456","Counter values come from the game (%s)"%str(want))
 var shown=[]
 for k in ["level","time","kills","gold"]:shown.append(screen.counters[k].text)
 check(shown==["7","12:34","123","456"],"Level, Time, Kills and Gold counters show them (%s)"%str(shown))
 var names=[]
 for k in screen.order:names.append(k.label_text if k is MenuItem else "ABANDON")
 var expected=["Resume","Map","Inspect build","Settings","Save & quit","Restart run","ABANDON"]
 if game.sandbox:expected.insert(5,"Sandbox tools")
 check(names==expected,"Menu entries in the specified order, Abandon apart at the end (%s)"%str(names))
 check(screen.items["resume"].has_focus() and screen.items["resume"].find_next_valid_focus()==screen.items["map"],"Resume is focused first and Down moves to Map")
 var last=screen.order[screen.order.size()-2];check(last.find_next_valid_focus()==screen.abandon,"Down from Restart run reaches Abandon run")
 check(screen.items["resume"].hint_text=="ESC" and screen.items["map"].hint_text=="M" and screen.items["inspect"].hint_text=="TAB","Resume / Map / Inspect carry their key chips")
 # hold-to-confirm
 var b=AbandonButton.new();root.add_child(b);var fired=[0];b.confirmed.connect(func():fired[0]+=1)
 b.step(2.0);check(fired[0]==0 and b.progress==0.0,"Abandon does nothing without a hold")
 b.holding=true;b.step(0.5);check(fired[0]==0 and absf(b.progress-0.5)<0.001,"Half a second of holding fills half and does not abandon")
 b.holding=false;b.step(0.1);check(b.progress<0.5 and fired[0]==0,"Letting go drains the fill")
 b.progress=0.0;b.holding=true;b.step(0.6);b.step(0.6);check(fired[0]==1 and b.progress>=1.0,"A full 1 s hold abandons exactly once")
 b.step(0.5);check(fired[0]==1,"Holding on does not fire again")
 b.holding=false;b.step(1.0);b.holding=true;b.step(1.1);check(fired[0]==2,"A second full hold fires again after release")
 b.queue_free()
 check(screen.abandon.confirmed.get_connections().size()==1 and screen.abandon.progress==0.0,"The screen's Abandon is wired to end the run and starts empty")
 # Esc resumes (Game's own handler)
 var elapsed=game.elapsed;await process_frame
 check(game.elapsed==elapsed,"Gameplay time does not advance while paused")
 game.resume();await process_frame
 check(game.mode=="run" and fe.pause_frame==null,"Resume returns to the run and drops the frozen frame")
func level_screen() -> RunLevelUp:
 for n in game.frontend.menu.get_children():
  if n is RunLevelUp:return n
 return null
func open_level(choices: Array=[]) -> RunLevelUp:
 game.mode="run";game.frontend.upgrades(choices);await process_frame
 return level_screen()
func ready_level(s: RunLevelUp) -> void:
 s.fanfare.skip();s.clock=RunLevelUp.READY_AT+1.0;s.apply_timeline();await process_frame
func level_up() -> void:
 var fe=game.frontend;game.enemies.clear();game.pending_upgrades=0;game.rerolls=3;game.banished.clear()
 var s=await open_level()
 check(s!=null and game.mode=="upgrade" and s.cards.size()==3,"Level up opens RunLevelUp with three cards and mode upgrade")
 if s==null:return
 # fanfare and deal-in
 check(not s.fanfare.done and not s.interactive,"The fanfare plays first and the cards cannot be taken yet")
 var before=[game.weapons.duplicate(true),game.tomes.duplicate()]
 s.take(0);check(game.mode=="upgrade" and [game.weapons,game.tomes]==before,"Taking a card during the fanfare does nothing")
 s.clock=1.65;s.apply_timeline()
 check(s.cards[1].modulate.a>0.5 and s.cards[0].modulate.a==0.0,"Cards are dealt 2, 3, then 1 (card 2 is visible before card 1)")
 s.clock=0.3;s.apply_timeline();check(s.content.position!=Vector2.ZERO or s.clock<0.0,"The screen shakes during the fanfare")
 s.clock=1.0;s.apply_timeline()
 var skip_event=InputEventKey.new();skip_event.keycode=KEY_SPACE;skip_event.pressed=true;s._input(skip_event)
 check(s.fanfare.done and s.clock>=RunLevelUp.FANFARE_SKIP_TO-0.001,"Any key skips the fanfare")
 await ready_level(s)
 check(s.interactive and s.cards[0].has_focus(),"After the deal the first card has focus and the screen takes input")
 # data from the real choices
 var weapon_card=-1;var tome_card=-1
 for i in s.cards_data.size():
  if s.cards_data[i].type=="weapon" and s.cards_data[i].rows.size()>0 and not s.cards_data[i].is_new:weapon_card=i
  if s.cards_data[i].type=="tome":tome_card=i
 check(s.cards_data.all(func(c):return c.tier==RunData.tier_index(str(s.choices[s.cards_data.find(c)].get("tier","common")))),"Each card carries the tier its choice rolled")
 # a weapon upgrade: name format, LV n -> n+1, current -> new equals what WeaponStats resolves after applying it
 var wid=game.weapons.keys()[0];var st: Dictionary=game.weapons[wid]
 var proposal=WeaponUpgrades.proposal(wid,RandomNumberGenerator.new(),st,"rare");proposal["key"]="w%d"%wid;proposal["type"]="weapon";proposal["id"]=wid;proposal["tier"]="rare"
 var wc=RunData.level_card(game,proposal)
 check(wc.name==Catalog.weapon_name(wid)+" — "+WeaponUpgrades.label(wid,str(proposal.attribute)) and wc.level_from==int(st.level) and wc.level_to==int(st.level)+1,"Upgrade card reads 'Weapon — Stat' with LV n → n+1 (%s, %d → %d)"%[wc.name,wc.level_from,wc.level_to])
 var after=st.duplicate(true);WeaponUpgrades.apply(wid,after,proposal);var resolved=WeaponStats.resolve(game,wid,after)
 check(wc.rows[0].to==WeaponUpgrades.format_value(wid,str(proposal.attribute),resolved) and wc.rows[0].from==WeaponUpgrades.format_value(wid,str(proposal.attribute),WeaponStats.resolve(game,wid,st)),"The card's current → new are the numbers WeaponStats resolves before and after (%s → %s)"%[wc.rows[0].from,wc.rows[0].to])
 var nw=-1
 for id in Catalog.ACTIVE_WEAPONS:
  if not game.weapons.has(id):nw=id;break
 if nw>=0:
  var nc=RunData.level_card(game,{"type":"weapon","id":nw,"key":"w%d"%nw,"tier":"common"})
  check(nc.is_new and nc.name==Catalog.weapon_name(nw) and nc.rows.size()==3 and nc.rows[1].value=="%.0f"%float(Catalog.WEAPONS[nw][2]),"A new weapon shows its real type, base damage and cooldown")
 # tomes: preview matches the stat after applying; level caps
 var tome_id=Catalog.ACTIVE_TOMES[0];var tc=RunData.level_card(game,{"type":"tome","id":tome_id,"key":tome_id,"tier":"epic"})
 var stat=str(Catalog.TOMES[tome_id][0]);var stats_before=float(game.stats[stat])
 var applied=game.stats.duplicate();game.tomes[tome_id]=int(game.tomes.get(tome_id,0));var tomes_backup=game.tomes.duplicate();var tr_backup=game.tome_rarities.duplicate()
 game.apply_upgrade({"type":"tome","id":tome_id,"key":tome_id,"tier":"epic"})
 check(absf(float(game.stats[stat])-float(tc.preview.to))<0.0001 or absf(float(game.stats[stat])-float(tc.preview.to))<0.02,"Tome card preview (%s: %.3f → %.3f) matches the stat after taking it (%.3f)"%[stat,tc.preview.from,tc.preview.to,float(game.stats[stat])])
 game.tomes=tomes_backup;game.tome_rarities=tr_backup;game.stats=applied
 game.tomes[tome_id]=Economy.TOME_MAX_LEVEL;var capped=RunData.level_card(game,{"type":"tome","id":tome_id,"key":tome_id,"tier":"common"})
 check(capped.level_to==Economy.TOME_MAX_LEVEL and capped.max_level==80,"Tome level display is capped at the real maximum (80)")
 game.tomes=tomes_backup
 check(Economy.WEAPON_MAX_LEVEL==40,"Weapon level display is capped at the real maximum (40)")
 # selection: Take label, stats preview, number keys, focus
 s.cards[1].grab_focus();await process_frame
 check(s.primary.label_text=="Take "+str(s.cards_data[1].short_name),"The Take button names the selected card (%s)"%s.primary.label_text)
 if tome_card>=0:
  s.cards[tome_card].grab_focus();await process_frame
  check(s.stats_panel.previewing==str(s.cards_data[tome_card].preview.stat) and s.stats_panel.shown_text(s.stats_panel.previewing).contains("→"),"Focusing a tome card previews its stat change in the Stats panel")
 var key2=InputEventKey.new();key2.keycode=KEY_3;key2.pressed=true;s._input(key2)
 check(s.cards[2].has_focus(),"Number key 3 selects the third card")
 check(s.cards[0].focus_neighbor_right==s.cards[0].get_path_to(s.cards[1]) and s.cards[0].focus_neighbor_bottom==s.cards[0].get_path_to(s.primary) and s.primary.focus_neighbor_bottom==s.primary.get_path_to(s.skip_button),"Focus neighbours: cards left/right, down to Take, down to the footer row")
 # device hints
 MenuScreen.set_pad_active(true);s.refresh_hints()
 check(s.hint_bar.entries.any(func(e):return e.size()>2 and e[2]=="A"),"On a controller the hints show the pad buttons")
 MenuScreen.set_pad_active(false);s.refresh_hints()
 # take: exactly once, applies the card
 var lvl=int(game.weapons[wid].level);var picked={"type":"weapon","id":wid,"key":"w%d"%wid,"tier":"common"};var p2=WeaponUpgrades.proposal(wid,RandomNumberGenerator.new(),game.weapons[wid]);picked.merge(p2,true);picked["expected_level"]=lvl
 var s2=await open_level([picked]);await ready_level(s2)
 s2.cards[0].pressed.emit();s2.cards[0].pressed.emit()
 check(game.mode=="run" and int(game.weapons[wid].level)==lvl+1,"Taking a card applies it exactly once and returns to the run (LV %d → %d)"%[lvl,int(game.weapons[wid].level)])
 # skip, refresh, banish
 game.health=50.0;var s3=await open_level();await ready_level(s3);s3.skip_button.pressed.emit()
 check(game.mode=="run" and absf(game.health-60.0)<0.01,"Skip heals 10 and closes the screen")
 game.rerolls=2;var s4=await open_level();await ready_level(s4);s4.refresh_button.pressed.emit();await process_frame
 check(game.rerolls==1 and game.mode=="upgrade" and level_screen()!=s4,"Refresh uses one reroll and deals a new screen (1 left)")
 var s5=level_screen();check(s5.refresh_button.caption=="REFRESH · 1 LEFT","Refresh shows the real rerolls left (%s)"%s5.refresh_button.caption)
 game.rerolls=0;var s6=await open_level();check(s6.refresh_button.disabled,"Refresh is disabled with none left")
 await ready_level(s6);var key=str(s6.choices[0].key);s6.cards[0].grab_focus();s6.banish_button.pressed.emit()
 check(game.banished.has(key) and game.mode=="run","Banish removes the focused offer from the pool (existing rule: it uses up this pick)")
 game.banished.clear();game.rerolls=3
 var supply=await open_level([{"type":"supply","id":"0","key":"supply0"},{"type":"supply","id":"1","key":"supply1"},{"type":"supply","id":"2","key":"supply2"}])
 check(supply.cards_data[0].name=="Field supplies" and supply.banish_button.disabled,"With nothing left to offer the cards are Field supplies and Banish is off")
 game.resume();await process_frame
func shop_screen() -> void:
 var fe=game.frontend;game.enemies.clear();game.mode="run";game.gold=20;game.stage=1
 game.gems.reset();game.items.clear();game.irt.reset();game.stats=Catalog.base_stats();game.stats.damage=float(game.stats.damage)
 var code=GemRewards.offer_code("fire")
 var obj={"tier":"Rare","offers":["whetstone","pilgrims_sandals",code],"sold":[],"used":false}
 fe.shop(obj);await process_frame
 var s: RunShop
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 check(s!=null and game.mode=="shop" and s.rows.size()==3,"Shop opens RunShop with a row per offer (including the Socket Gem)")
 if s==null:return
 check(s.get_node("Stage/Content/Header/Title").text=="Rare shop","Title names the shop type (%s)"%s.get_node("Stage/Content/Header/Title").text)
 var std={"tier":"Common","offers":["whetstone"],"sold":[],"used":false};fe.shop(std);await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 check(s.get_node("Stage/Content/Header/Title").text=="Standard shop","A Common seller is titled Standard shop")
 fe.shop(obj);await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 var item_row=s.rows[0];var gem_row=s.rows[2]
 check(item_row.data.price==ShopSystem.price("whetstone",1) and item_row.data.price==Economy.item_price(Catalog.item_tier("whetstone"),1),"Item price is the Economy price (%d)"%item_row.data.price)
 check(gem_row.data.kind=="gem" and gem_row.data.price==Economy.gem_price(1) and gem_row.data.kind_label=="Socket gem" and gem_row.data.tier_name=="Rare","Socket gem rows use the Economy gem price and the Rare tier")
 check(item_row.data.owned==0 and item_row.data.owned_after==1 and gem_row.data.owned==0 and gem_row.data.owned_after==1,"Owned ×a → ×b shows the real count and +1")
 check(item_row.data.preview.size()>0 and item_row.data.preview[0].stat=="damage" and item_row.data.preview[0].to>item_row.data.preview[0].from,"The Whetstone row carries a real damage preview")
 var before=game.stats.duplicate()
 check(is_equal_approx(float(game.stats.damage),float(before.damage)),"Computing a preview does not change the stats")
 s.rows[0].grab_focus();await process_frame
 check(s.stats_panel.has_preview() and s.stats_panel.shown_text("damage").contains("→"),"Focusing a row previews its stat change in the Stats panel (%s)"%s.stats_panel.shown_text("damage"))
 s.rows[2].grab_focus();await process_frame
 check(not s.stats_panel.has_preview(),"A row with no stat effect (Socket Gem) clears the preview")
 # affordability
 check(item_row.data.affordable==(game.gold>=item_row.data.price) and (item_row.data.price<=20 or item_row.button_text()=="NEED %d MORE"%(item_row.data.price-20)),"Button reads Need n more with the exact shortfall (%s)"%item_row.button_text())
 check(gem_row.button_text()=="NEED %d MORE"%(Economy.gem_price(1)-20) and not gem_row.can_buy(),"The gem row is unaffordable at 20 gold and says so (%s)"%gem_row.button_text())
 check(s.get_node("Stage/Content/Header/YourGold").get_child(1).text=="20","Your gold shows the real gold")
 # denied purchase changes nothing
 var gold=game.gold;var denied=[0];gem_row.denied.connect(func():denied[0]+=1);s.rows[2].grab_focus()
 var enter=InputEventAction.new();enter.action="ui_accept";enter.pressed=true;gem_row._gui_input(enter)
 check(denied[0]==1 and game.gold==gold and game.mode=="shop","Enter on an unaffordable row is refused and changes nothing")
 # buy the item
 game.gold=1000;fe.shop(obj);await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 var price=s.rows[0].data.price;s.rows[0].buy_requested.emit()
 check(game.gold==1000-price and game.item_stacks("whetstone")==1 and obj.used and game.mode=="run","Buying takes exactly the price, grants the item, uses up the seller and returns to the run")
 # reopened: used seller
 fe.shop(obj);await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 check(s.rows[0].button_text()=="SOLD" and s.rows[1].button_text()=="CLOSED" and not s.rows[1].can_buy(),"A used seller shows SOLD on the bought row and CLOSED on the rest")
 check(s.rows[0].data.owned==1 and s.rows[0].data.owned_after==2,"Owned reads ×1 → ×2 after buying one")
 # gem purchase
 var gobj={"tier":"Rare","offers":[code],"sold":[],"used":false};game.gold=1000;fe.shop(gobj);await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 var gp=s.rows[0].data.price;s.rows[0].buy_requested.emit()
 check(game.gold==1000-gp and game.gems.count("fire")==1 and game.mode=="run","Buying a Socket Gem takes the gem price and adds the gem")
 # navigation
 fe.shop({"tier":"Common","offers":["whetstone","pilgrims_sandals"],"sold":[],"used":false});await process_frame
 for n in fe.menu.get_children():
  if n is RunShop:s=n
 check(s.rows[0].focus_neighbor_bottom==s.rows[0].get_path_to(s.rows[1]) and s.rows[1].focus_neighbor_bottom==s.rows[1].get_path_to(s.leave_button),"Focus moves down the offers and on to Leave shop")
 game.resume();await process_frame
func shrine_screen() -> void:
 var fe=game.frontend;game.enemies.clear();game.mode="run";game.stats=Catalog.base_stats();game.stage=1
 var rng=RandomNumberGenerator.new();rng.seed=77
 var reward={"choices":ShrineRewards.generate(game.stats,rng,false),"golden":false}
 game.active_shrine_reward=reward;RewardScreens.shrine(fe,reward);await process_frame
 var s: RunShrine
 for n in fe.menu.get_children():
  if n is RunShrine:s=n
 check(s!=null and game.mode=="shrine" and s.cards.size()==3,"Shrine opens RunShrine with the three real choices")
 if s==null:return
 var c0=reward.choices[0]
 check(s.get_node("Stage/Content/Header/Title").text=="Choose one stat","Title is Choose one stat")
 check(s.cards[0].data.bonus==ShrineRewards.bonus_text(c0) and s.cards[0].data.stat_name==ShrineRewards.stat_name(c0.stat),"Card 1 shows the real bonus and stat name (%s %s)"%[s.cards[0].data.bonus,s.cards[0].data.stat_name])
 check(s.accept.label_text=="Accept: %s %s"%[s.cards[0].data.stat_name,s.cards[0].data.bonus],"Accept button names the focused choice (%s)"%s.accept.label_text)
 s.cards[1].grab_focus();await process_frame
 check(s.accept.label_text.begins_with("Accept: "+s.cards[1].data.stat_name),"Focusing card 2 retargets Accept")
 check(s.cards[1].focus_neighbor_bottom==s.cards[1].get_path_to(s.cards[2]) and s.cards[2].focus_neighbor_bottom==s.cards[2].get_path_to(s.accept),"Focus runs down the cards and on to Accept")
 var key=InputEventKey.new();key.keycode=KEY_3;key.pressed=true;s._unhandled_input(key);await process_frame
 check(s.cards[2].has_focus(),"Key 3 focuses card 3")
 var before=game.stats.duplicate();var ch=reward.choices[2];s.accept.chosen.emit();await process_frame
 check(is_equal_approx(game.stats[ch.stat]-before[ch.stat],ch.amount) and game.active_shrine_reward.is_empty() and game.mode=="run","Accept grants exactly the displayed amount, clears the shrine and returns to the run")
 # golden shrine: all legendary
 var g={"choices":ShrineRewards.generate(game.stats,rng,true),"golden":true};game.active_shrine_reward=g;RewardScreens.shrine(fe,g);await process_frame
 for n in fe.menu.get_children():
  if n is RunShrine:s=n
 check(s.cards.size()==3 and s.cards.all(func(c):return c.data.tier==FogPalette.Rarity.LEGENDARY),"Golden shrine cards are all Legendary")
 game.active_shrine_reward={};game.resume();await process_frame
 # capped: nothing to offer
 var empty={"choices":[],"golden":false};game.mode="run";game.active_shrine_reward=empty;RewardScreens.shrine(fe,empty);await process_frame
 for n in fe.menu.get_children():
  if n is RunShrine:s=n
 check(s.cards.is_empty() and s.accept.label_text=="Continue","With every stat capped the screen offers Continue only")
 s.accept.chosen.emit();await process_frame
 check(game.active_shrine_reward.is_empty() and game.mode=="run","Continue closes the empty shrine")
