extends SceneTree
# Milestone 3: Imbue Station placement/interaction, shop and chest gems, gem inventory UI.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-imbue-profile.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 await placement()
 await station_ui()
 shop_and_chests()
 await inventory_ui()
 save_load()
 print("IMBUE_STATION: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func rebuild(stage_number: int,seed_value: int):
 game.map_seed_override=seed_value;game.stage=stage_number;game.enemies.clear();game.build_stage();game.resume();game.spawn_clock=999
func placement():
 var all_one=true;var spaced=true;var chest_ok=true;var stations=[]
 for stage_number in [1,2,3]:
  for seed_value in [9,3,17,42,77]:
   rebuild(stage_number,seed_value)
   if ImbueStation.count(game)!=1:all_one=false
   var station=ImbueStation.find(game)
   if station.is_empty():continue
   stations.append(station.node.position)
   for obj in game.interactables:
    if obj!=station and obj.kind!="Free Chest" and obj.node.position.distance_to(station.node.position)<5.0:spaced=false
   if Vector2(station.node.position.x-game.player.position.x,station.node.position.z-game.player.position.z).length()<8.0:spaced=false
   var chests=0
   for obj in game.interactables:
    if obj.kind=="Chest":chests+=1
   if chests<14:chest_ok=false
 check(all_one,"Exactly one Imbue Station on every tested stage and seed (%d)"%stations.size())
 check(spaced,"Station keeps clear of other interactables and the spawn")
 check(chest_ok,"Chests are preserved")
 rebuild(1,9)
 var a=ImbueStation.find(game).node.position
 rebuild(1,9)
 check(a.is_equal_approx(ImbueStation.find(game).node.position),"Station placement is deterministic")
 var near_vase=false
 for v in game.vases:
  if Vector2(v.pos.x-a.x,v.pos.z-a.z).length()<3.0:near_vase=true
 check(not near_vase,"No vase overlaps the station")
 check(ForestMap.reachable(int(game.map_layout.seed),Vector2(a.x,a.z)),"Station is on reachable ground")
 # Fallback conversion keeps exactly one station and the same interactable count.
 var before=game.interactables.size()
 for i in range(game.interactables.size()-1,-1,-1):
  if game.interactables[i].kind==ImbueStation.KIND:game.interactables[i].node.queue_free();game.interactables.remove_at(i)
 var fallback_data=game.map_layout.duplicate();fallback_data.pois=fallback_data.pois.duplicate()
 var old_spacings=ImbueStation.SETTINGS.spacings
 check(ImbueStation.count(game)==0,"Station removed for the fallback test")
 var chests_before=0
 for obj in game.interactables:
  if obj.kind=="Chest":chests_before+=1
 # Force the fallback by making the free-spot search fail.
 var saved_pois=game.map_layout.pois
 var blockers=ForestPlacement.candidates(game.map_layout)
 game.map_layout.pois=blockers
 ImbueStation.setup(game)
 game.map_layout.pois=saved_pois
 var chests_after=0
 for obj in game.interactables:
  if obj.kind=="Chest":chests_after+=1
 check(ImbueStation.count(game)==1 and game.interactables.size()==before-1+1 or (ImbueStation.count(game)==1 and chests_after==chests_before-1),"Fallback guarantees one station (chests %d -> %d)"%[chests_before,chests_after])
 rebuild(1,9)

func station_ui():
 rebuild(1,9)
 var station=ImbueStation.find(game)
 game.weapons.clear();game.equip(0);game.equip(6)
 game.player.position=station.node.position+Vector3(1.5,0,0)
 game.gems.add("fire",2);game.gems.add("ice",1);game.gold=2000
 game.mode="run"
 game.frontend.imbue_station(station)
 await process_frame
 check(game.mode=="imbue","Station opens its screen and pauses the game")
 var screen: RunImbue
 for n in game.frontend.menu.get_children():
  if n is RunImbue:screen=n
 check(screen!=null and screen.tiles.size()==4 and screen.data.weapons.size()==2,"The screen lists every element and every owned weapon")
 var held_count=0
 for e in screen.tiles:
  if screen.tiles[e].count>0:held_count+=1
 check(held_count==2,"Only elements the player holds can be picked up (%d)"%held_count)
 screen.tiles["fire"].pressed.emit();await process_frame
 var wid=int(screen.data.weapons[0].id)
 screen.slots["Slot_%d_0"%wid].pressed.emit();await process_frame
 check(screen.phase=="confirm" and game.gold==2000,"Choosing a socket asks to confirm and spends nothing yet")
 screen.fuse_button.chosen.emit();await create_timer(RunImbue.FUSE_TIME+0.4).timeout
 check(game.gold==1500 and game.gems.count("fire")==1 and screen.phase=="done","Fuse installs once: costs 500 and consumes one gem")
 var installed=0
 for id in game.weapons:installed+=WeaponSockets.gems(game.weapons[id]).size()
 check(installed==1,"Exactly one gem installed")
 var duplicate_blocked=true
 for id in game.weapons:
  if WeaponSockets.has_gem(game.weapons[id],"fire"):duplicate_blocked=ImbueRules.problem(game,id,"ice")=="no_free_socket"
 check(duplicate_blocked,"A full single-socket weapon refuses a second gem")
 game.resume()
 check(game.mode!="imbue","Leaving restores gameplay")

func shop_and_chests():
 rebuild(1,9)
 var shop=null
 for obj in game.interactables:
  if obj.kind=="Shop":shop=obj;break
 game.gold=1000;game.gems.reset()
 # Gems are Rare-tier candidates in the shop's offers (stocked like Rare items).
 var mixed_slots=0;var shops=0;var all_valid=true
 for stage_number in [1,2,3]:
  for seed_value in [9,3,17,42]:
   rebuild(stage_number,seed_value)
   for obj in game.interactables:
    if obj.kind!="Shop":continue
    for rep in 12:
     obj.erase("offers");obj.erase("sold");obj.used=false
     obj.offers=ShopSystem.offers("Rare" if rep%2==0 else obj.get("tier","Common"),game.available_items(),game.rng,0.0,true)
     shops+=1
     if obj.offers.size()!=3:all_valid=false
     var seen=[]
     for code in obj.offers:
      if GemRewards.is_gem_offer(code):
       mixed_slots+=1
       if GemRewards.offer_element(int(code)) in seen:all_valid=false
       seen.append(GemRewards.offer_element(int(code)))
      elif not (code is String and Catalog.item_exists(code)):all_valid=false
 check(shops>=10 and mixed_slots>0 and mixed_slots<shops*3,"Some, but not all, shop slots become gems (%d of %d slots)"%[mixed_slots,shops*3])
 check(all_valid,"Gem slots are valid and distinct within a shop")
 rebuild(1,9)
 for obj in game.interactables:
  if obj.kind=="Shop":shop=obj;break
 shop.erase("offers");shop.used=false;shop.erase("sold")
 shop["offers"]=[GemRewards.offer_code("ice"),"whetstone","salted_pork"]
 game.mode="shop"
 var gold_before=game.gold
 var result=GemRewards.buy_offer(game,shop,GemRewards.offer_code("ice"))
 check(result.ok and game.gold==gold_before-ShopSystem.gem_price(game.stage) and game.gems.count("ice")==1,"Buying a gem slot costs the Epic-tier stage price and adds it to the inventory (not installed)")
 check(shop.used and GemRewards.has_code(shop.sold,GemRewards.offer_code("ice")),"A gem purchase uses the shop's one purchase")
 game.mode="shop"
 check(not GemRewards.buy_offer(game,shop,GemRewards.offer_code("ice")).ok and game.gems.count("ice")==1,"A sold gem slot cannot be bought twice")
 shop.used=false;shop.sold=[];game.mode="shop";game.gold=ShopSystem.gem_price(game.stage)-1
 check(not GemRewards.buy_offer(game,shop,GemRewards.offer_code("ice")).ok and game.gold==ShopSystem.gem_price(game.stage)-1,"Insufficient gold buys nothing")
 game.gold=1000
 check(not GemRewards.buy_offer(game,shop,GemRewards.offer_code("fire")).ok and game.gold==1000,"A gem not on offer is refused")
 game.mode="run"
 # Chest gems
 var granted=0
 game.gems.reset()
 for i in 400:
  game.run_metrics["chests"]=i
  if GemRewards.roll_chest(game)!="":granted+=1
 check(granted>10 and granted<110 and game.gems.total()==granted,"Chests occasionally grant a gem (%d/400)"%granted)

func inventory_ui():
 game.gems.reset();game.gems.add("ice",3)
 game.weapons.clear();game.equip(0)
 WeaponSockets.install(game.weapons[0],"fire")
 game.mode="run"
 game.frontend.inventory()
 await process_frame
 var found_pips=false;var found_gems=false
 for n in RewardScreens.descendants(game.frontend.menu):
  if n is SocketPips:found_pips=true
  if n is Label and n.text=="Socket gems":found_gems=true
 check(found_pips and found_gems,"Build screen shows socket pips and the gem inventory")
 check(game.weapon_tooltip(0).find("Fire")>=0,"Weapon tooltip names the installed element")
 game.resume()

func save_load():
 rebuild(1,9)
 game.gems.add("fire",1)
 var shop=null
 for obj in game.interactables:
  if obj.kind=="Shop":shop=obj;break
 shop["offers"]=[GemRewards.offer_code("ice"),"whetstone","salted_pork"];shop["sold"]=[GemRewards.offer_code("ice")]
 check(game.save_run("user://test-imbue-run.json"),"Run with a station and shop gems saves")
 rebuild(1,9)
 check(game.load_run("user://test-imbue-run.json"),"Run loads")
 var shop2=null
 for obj in game.interactables:
  if obj.kind=="Shop":shop2=obj;break
 var loaded_offers=shop2.get("offers",[]).map(func(v): return v if v is String else int(v))
 var loaded_sold=shop2.get("sold",[]).map(func(v): return int(v))
 check(loaded_offers==[GemRewards.offer_code("ice"),"whetstone","salted_pork"] and loaded_sold==[GemRewards.offer_code("ice")],"Shop gem slots and sales survive save/load")
 check(GemRewards.is_gem_offer(shop2.offers[0]) and GemRewards.has_code(shop2.sold,GemRewards.offer_code("ice")),"Loaded (float) codes still read as gem slots and sales")
 check(ImbueStation.count(game)==1,"Station still exists after load")
