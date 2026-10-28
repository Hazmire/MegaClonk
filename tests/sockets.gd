extends SceneTree
# Milestone 1: gem/socket data, gem inventory, imbue transactions and the central status
# framework. Element behaviours are covered by later milestones' suites.
var checks=0
var failures=[]
var game: Node3D
class StubGame:
 var gold=0
 var stage=1
 var weapons={}
 var gems=GemInventory.new()
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 elements()
 inventory()
 sockets()
 imbue()
 status_framework()
 await integration()
 print("SOCKETS: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func elements():
 check(Elements.IDS.size()==4 and Elements.IDS.size()==Elements.DATA.size(),"Exactly four elements defined")
 var colors={}
 for id in Elements.IDS:
  colors[Elements.color(id).to_html(false)]=true
  check(not Elements.display_name(id).is_empty() and not Elements.summary(id).is_empty(),"Element metadata: "+id)
 check(colors.size()==4,"Element colours are all distinct")
 check(Elements.color("corrosive").g>Elements.color("corrosive").r and Elements.color("ice").b>Elements.color("ice").r and Elements.color("fire").r>Elements.color("fire").b and Elements.color("electricity").b>Elements.color("electricity").g,"Colours read as green, light blue, orange-red, purple")
 check(Elements.COMBOS.size()==6,"Six dual-element combinations defined")
 var names={};var pairs=0
 for a in Elements.IDS:
  for b in Elements.IDS:
   var combo=Elements.combo(a,b)
   if a==b:check(combo.is_empty(),"No duplicate-element combo: "+a)
   else:
    pairs+=1
    check(not combo.is_empty() and combo.id==Elements.combo(b,a).id,"Combo is order independent: %s/%s"%[a,b])
    names[combo.id]=true
 check(pairs==12 and names.size()==6,"All six unique combinations reachable from all 12 ordered pairs")
 check(Elements.combo("fire","ice").name=="Thermal Shock" and Elements.combo("electricity","corrosive").name=="Toxic Conduction" and Elements.combo("fire","corrosive").name=="Caustic Combustion" and Elements.combo("ice","corrosive").name=="Blightfrost" and Elements.combo("fire","electricity").name=="Overcharge" and Elements.combo("ice","electricity").name=="Cryoshock","Combination names match the specification")
 check(Elements.combo("fire","water").is_empty() and not Elements.valid(""),"Unknown elements rejected")
 check(Elements.is_boss_kind(8) and Elements.is_boss_kind(9) and Elements.is_boss_kind(10) and not Elements.is_boss_kind(0) and not Elements.is_boss_kind(5),"Boss and miniboss kinds classified")

func inventory():
 var gems=GemInventory.new()
 check(gems.total()==0 and gems.count("fire")==0,"Inventory starts empty")
 check(gems.add("fire") and gems.add("fire",2) and gems.add("ice"),"Gems added")
 check(gems.count("fire")==3 and gems.count("ice")==1 and gems.total()==4,"Quantities stack per element")
 check(not gems.add("water") and not gems.add("fire",0) and not gems.add("fire",-3),"Invalid adds rejected")
 check(not gems.remove("ice",2) and gems.count("ice")==1,"Over-removal rejected without changing the stack")
 check(gems.remove("fire") and gems.count("fire")==2,"Removal consumes exactly one")
 check(not gems.remove("corrosive") and gems.count("corrosive")==0,"Cannot remove what is not owned")
 var copy=GemInventory.new();copy.restore(JSON.parse_string(JSON.stringify(gems.serialize())))
 check(copy.count("fire")==2 and copy.count("ice")==1 and copy.total()==3,"Round trip through JSON")
 copy.restore({"fire":-4,"ice":"junk","water":9,"electricity":2.0})
 check(copy.count("fire")==0 and copy.count("ice")==0 and copy.count("electricity")==2 and copy.total()==2,"Restore sanitises negative, malformed and unknown entries")
 copy.restore(null);check(copy.total()==0,"Restore tolerates missing data")
 gems.reset();check(gems.total()==0,"Reset clears every stack")

func sockets():
 var state={"level":3}
 WeaponSockets.ensure(state)
 check(WeaponSockets.unlocked(state)==1 and WeaponSockets.free_sockets(state)==1 and WeaponSockets.gems(state).is_empty(),"Every weapon starts with one empty socket")
 check(WeaponSockets.combo(state).is_empty(),"Empty socket gives no combination")
 check(WeaponSockets.install_problem(state,"water")=="invalid_element","Invalid element reported")
 check(WeaponSockets.install(state,"fire") and WeaponSockets.has_gem(state,"fire") and WeaponSockets.free_sockets(state)==0,"Gem installs into the free socket")
 check(WeaponSockets.install_problem(state,"ice")=="no_free_socket" and not WeaponSockets.install(state,"ice"),"No installation without a free socket")
 check(WeaponSockets.gems(state).size()==1,"A weapon never exceeds its unlocked sockets")
 check(WeaponSockets.can_unlock_second(state) and WeaponSockets.unlock_second(state) and WeaponSockets.unlocked(state)==2,"Second socket unlocks once")
 check(not WeaponSockets.can_unlock_second(state) and not WeaponSockets.unlock_second(state),"Second socket cannot be unlocked twice")
 check(WeaponSockets.gems(state).size()==1 and WeaponSockets.free_sockets(state)==1,"Unlocking does not install a gem")
 check(WeaponSockets.install_problem(state,"fire")=="duplicate_element" and not WeaponSockets.install(state,"fire"),"Duplicate element rejected")
 check(WeaponSockets.install(state,"ice") and WeaponSockets.combo(state).name=="Thermal Shock","Second element installs and names the combination")
 check(state.level==3,"Socket state does not disturb other weapon fields")
 var reversed={};WeaponSockets.ensure(reversed);WeaponSockets.unlock_second(reversed)
 WeaponSockets.install(reversed,"ice");WeaponSockets.install(reversed,"fire")
 check(WeaponSockets.combo(reversed).id==WeaponSockets.combo(state).id,"Installation order does not change the combination")
 var restored={"level":9}
 WeaponSockets.restore(restored,JSON.parse_string(JSON.stringify(WeaponSockets.serialize(state))))
 check(WeaponSockets.unlocked(restored)==2 and WeaponSockets.gems(restored)==["fire","ice"],"Socket state round trips through JSON")
 WeaponSockets.restore(restored,{"unlocked":1,"gems":["fire","ice","fire","water"]})
 check(WeaponSockets.gems(restored)==["fire"],"Restore never keeps more gems than sockets, nor duplicates or unknown elements")
 WeaponSockets.restore(restored,{"unlocked":99,"gems":["fire","ice","corrosive"]})
 check(WeaponSockets.unlocked(restored)==2 and WeaponSockets.gems(restored)==["fire","ice"],"Restore clamps unlocked sockets to the maximum")
 WeaponSockets.restore(restored,"garbage")
 check(WeaponSockets.unlocked(restored)==1 and WeaponSockets.gems(restored).is_empty(),"Restore tolerates malformed data")

func imbue():
 check(ImbueRules.cost(1)==500 and ImbueRules.cost(2)==1000 and ImbueRules.cost(3)==1500,"Stage costs are 500, 1000 and 1500")
 check(ImbueRules.cost(0)==500 and ImbueRules.cost(9)==1500,"Out-of-range stages clamp safely")
 var g=StubGame.new()
 g.weapons[0]={};WeaponSockets.ensure(g.weapons[0])
 g.gems.add("fire",2);g.gold=1200
 var result=ImbueRules.install(g,0,"fire")
 check(result.ok and result.cost==500 and g.gold==700 and g.gems.count("fire")==1 and WeaponSockets.gems(g.weapons[0])==["fire"],"Installation consumes one gem and deducts gold exactly once")
 var before=[g.gold,g.gems.serialize(),WeaponSockets.serialize(g.weapons[0])]
 var cases=[["no free socket",0,"ice"],["unowned weapon",5,"fire"],["invalid element",0,"water"]]
 g.gems.add("ice",1)
 for c in cases:
  var failed=ImbueRules.install(g,c[1],c[2])
  check(not failed.ok and g.gold==before[0] and g.gems.count("ice")==1 and WeaponSockets.serialize(g.weapons[0])==before[2],"Rejected, nothing consumed: "+c[0])
 g.weapons[1]={};WeaponSockets.ensure(g.weapons[1])
 g.gems.remove("ice",1)
 var missing=ImbueRules.install(g,1,"ice")
 check(not missing.ok and missing.reason=="no_gem" and g.gold==700 and WeaponSockets.gems(g.weapons[1]).is_empty(),"Rejected, no gem owned: nothing consumed")
 g.gems.add("ice",1);g.gold=499
 var poor=ImbueRules.install(g,1,"ice")
 check(not poor.ok and poor.reason=="insufficient_gold" and g.gold==499 and g.gems.count("ice")==1 and WeaponSockets.gems(g.weapons[1]).is_empty(),"Rejected, insufficient gold: nothing consumed")
 g.stage=3;g.gold=1499
 check(ImbueRules.install(g,1,"ice").reason=="insufficient_gold","Stage 3 requires 1500 gold")
 g.gold=1500
 check(ImbueRules.install(g,1,"ice").ok and g.gold==0,"Stage 3 install costs exactly 1500")
 var third=ImbueRules.install(g,1,"fire")
 check(not third.ok and g.gold==0,"Second install blocked until the second socket is unlocked")
 g.weapons[1].sockets.unlocked=2;g.gems.add("fire",1);g.gold=ImbueRules.cost(3)
 check(ImbueRules.install(g,1,"fire").ok and WeaponSockets.combo(g.weapons[1]).name=="Thermal Shock","Second installation works after the unlock and costs gold again")

func status_framework():
 var e={"kind":0,"hp":100.0,"max_hp":100.0}
 check(not StatusManager.active(e) and StatusManager.cooldown_ready(e,"stun_proc"),"No status state is allocated for untouched enemies")
 check(not e.has("fx"),"Querying cooldowns does not create state")
 StatusManager.start_cooldown(e,"stun_proc",1.5)
 check(e.has("fx") and not StatusManager.cooldown_ready(e,"stun_proc"),"Starting a cooldown creates state and blocks the proc")
 StatusManager.tick(null,e,1.0)
 check(StatusManager.active(e) and not StatusManager.cooldown_ready(e,"stun_proc"),"Cooldown persists until it expires")
 StatusManager.tick(null,e,0.6)
 check(StatusManager.cooldown_ready(e,"stun_proc") and not e.has("fx"),"Expired cooldown releases the proc and frees empty state")
 StatusManager.start_cooldown(e,"x",0.0)
 check(not e.has("fx"),"Zero-length cooldowns allocate nothing")
 StatusManager.start_cooldown(e,"a",5.0)
 StatusManager.clear(e)
 check(not e.has("fx"),"Clear removes all status state")
 check(JSON.parse_string(JSON.stringify({"fx":{"cd":{"a":1.5}}})).fx.cd.a==1.5,"Status state is JSON safe")
 check(StatusManager.enter() and StatusManager.enter() and not StatusManager.enter(),"Re-entrancy is bounded at two levels")
 StatusManager.leave();check(StatusManager.enter(),"A level frees up after leave()")
 StatusManager.leave();StatusManager.leave();StatusManager.leave();StatusManager.leave()
 check(StatusManager.depth==0 and StatusManager.enter(),"Depth never underflows")
 StatusManager.leave()
 check(StatusManager.modify_damage(StubGame.new(),e,37.5,true,0)==37.5,"Damage hook leaves damage alone for unsocketed weapons")
 var g=StubGame.new();g.weapons[0]={};WeaponSockets.ensure(g.weapons[0])
 check(StatusManager.weapon_elements(g,0).is_empty() and StatusManager.weapon_elements(g,-3).is_empty() and StatusManager.weapon_elements(g,9).is_empty(),"Unsocketed, non-weapon and unknown sources have no elements")
 WeaponSockets.install(g.weapons[0],"ice")
 check(StatusManager.weapon_elements(g,0)==["ice"],"Elements are read from the weapon that dealt the hit")
 check(StatusManager.is_boss({"kind":8}) and not StatusManager.is_boss({"kind":2}),"Boss classification reads the enemy kind")

func integration():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-sockets-profile.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true
 game.spawn_clock=999
 await physics_frame
 check(game.gems.total()==0,"New run starts with an empty gem inventory")
 for id in game.weapons:
  check(WeaponSockets.unlocked(game.weapons[id])==1 and WeaponSockets.gems(game.weapons[id]).is_empty(),"Starting weapon has one empty socket")
 game.weapons.clear()
 game.equip(0);game.equip(6)
 check(WeaponSockets.unlocked(game.weapons[0])==1 and WeaponSockets.unlocked(game.weapons[6])==1,"Newly equipped weapons get a default socket")
 game.mode="pause";game.player.active=false;game.enemies.clear()
 game.gems.add("fire",1);game.gems.add("electricity",2);game.gold=1000;game.stage=1
 var result=ImbueRules.install(game,0,"fire")
 check(result.ok and game.gold==500 and game.gems.count("fire")==0 and WeaponSockets.has_gem(game.weapons[0],"fire"),"Stage 1 install on the real game costs 500 and consumes the gem")
 var gold_before=game.gold
 check(not ImbueRules.install(game,6,"fire").ok and game.gold==gold_before,"Failed install on the real game consumes nothing")
 game.equip(0)
 check(game.weapons[0].level==2 and WeaponSockets.gems(game.weapons[0])==["fire"],"Weapon level-up keeps its gem")
 game.weapons[0].rarity="epic"
 check(WeaponSockets.gems(game.weapons[0])==["fire"],"Rarity change keeps its gem")
 game.weapons[0].sockets.unlocked=2
 game.stage=2;game.build_stage()
 check(game.gems.count("electricity")==2 and WeaponSockets.gems(game.weapons[0])==["fire"] and WeaponSockets.unlocked(game.weapons[0])==2,"Gems and sockets persist across a stage transition")
 check(game.save_run("user://test-sockets-run.json"),"Run with sockets saves")
 game.gems.reset();game.weapons[0].sockets={"unlocked":1,"gems":[]}
 check(game.load_run("user://test-sockets-run.json"),"Run with sockets loads")
 check(game.gems.count("electricity")==2 and WeaponSockets.gems(game.weapons[0])==["fire"] and WeaponSockets.unlocked(game.weapons[0])==2 and WeaponSockets.unlocked(game.weapons[6])==1,"Gems and sockets survive save and load")
 var old=JSON.parse_string(FileAccess.get_file_as_string("user://test-sockets-run.json"))
 old.erase("gems")
 for id in old.weapons:old.weapons[id].erase("sockets")
 var legacy=FileAccess.open("user://test-sockets-legacy.json",FileAccess.WRITE);legacy.store_string(JSON.stringify(old));legacy.close()
 check(game.load_run("user://test-sockets-legacy.json") and game.gems.total()==0 and WeaponSockets.unlocked(game.weapons[0])==1 and WeaponSockets.gems(game.weapons[0]).is_empty(),"Saves from before sockets load with defaults")
 game.mode="pause";game.player.active=false;game.enemies.clear()
 var e=game.spawn_enemy(0,game.player.position+Vector3(0,0,-3))
 game.rebuild_grid()
 game.stats.crit=0
 game.hit(e,5,0)
 check(not e.has("fx"),"Hits from unsocketed weapons allocate no status state")
 game.weapons[0].sockets={"unlocked":1,"gems":["ice"]}
 var hp=e.hp
 game.hit(e,5,0)
 check(e.hp==hp-5,"An ice gem does not change the hit's own damage")
 StatusManager.start_cooldown(e,"stun_proc",5.0)
 game.hit(e,1,-1)
 check(e.has("fx"),"Status state survives unrelated damage")
 var index=game.enemies.find(e)
 e.hp=0;game.kill_enemy(index)
 check(not e.has("fx") and game.enemies.find(e)==-1,"Status state is cleared when the enemy dies")
 game.begin_run()
 check(game.gems.total()==0,"Gems do not persist into a new run")
 for id in game.weapons:
  check(WeaponSockets.unlocked(game.weapons[id])==1 and WeaponSockets.gems(game.weapons[id]).is_empty(),"Sockets reset for a new run")
 game.queue_free()
