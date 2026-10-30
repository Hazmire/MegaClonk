extends SceneTree
# Milestones 5 and 6: Imbued Amulet second sockets and the six elemental combinations.
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
 game.progress.storage_path="user://test-combos-profile.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 game.weapons.clear();game.enemies.clear();game.equip(0);game.equip(6)
 game.mode="run"
 amulet()
 await amulet_ui()
 combos()
 safety()
 print("COMBOS_AMULET: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

var spot=0.0
func dummy(hp: float=4000.0,kind: int=0,separate: bool=true) -> Dictionary:
 if separate:spot+=40.0
 var e=game.spawn_enemy(0,game.player.position+Vector3(20+fmod(spot,60.0),0,-30+spot*0.5))
 e.hp=hp;e.max_hp=hp;e.kind=kind;e.slow=0;e.frozen=0;e.burn=0;e.poison=0;e.age=30.0
 return e
func socket(weapon: int,gems: Array):
 game.weapons[weapon]["sockets"]={"unlocked":2 if gems.size()>1 else 1,"gems":gems.duplicate()}
func ticks(e: Dictionary,seconds: float,step: float=0.1):
 for i in int(round(seconds/step)):StatusManager.tick(game,e,step)

func amulet():
 check(game.amulets==0 and game.amulets_found==0,"A new run has no amulets")
 check(Catalog.item_exists("imbued_amulet") and Catalog.item_tier("imbued_amulet")=="legendary" and Catalog.item_consumable("imbued_amulet"),"The Imbued Amulet is a consumable Legendary item")
 check("imbued_amulet" in ItemDrops.available(game),"It is in the normal item pool")
 check(game.grant_item("imbued_amulet",true) and game.amulets==1 and game.amulets_found==1 and game.item_stacks("imbued_amulet")==0,"Acquiring it fills the bag, not the held-item list")
 check(game.grant_item("imbued_amulet",true) and game.amulets==2 and "imbued_amulet" in ItemDrops.available(game),"Several can be found and it stays in the pool")
 var rng_state=game.rng.state;var from_pool=0
 for i in 4000:
  if ItemDrops.roll_chest(game)=="imbued_amulet":from_pool+=1
 game.rng.state=rng_state
 check(from_pool>0 and from_pool<120,"Chests can roll it like any Legendary (%d/4000)"%from_pool)
 var shop_seen={"Common":0,"Rare":0,"Legendary":0};var shop_rng=RandomNumberGenerator.new();shop_rng.seed=5
 for i in 400:
  for tier_name in shop_seen:if "imbued_amulet" in ShopSystem.offers(tier_name,ItemDrops.available(game),shop_rng):shop_seen[tier_name]+=1
 check(shop_seen.Legendary>0 and shop_seen.Rare>0 and shop_seen.Common>=0,"Shops can sell it: Legendary %d, Rare %d, Standard %d of 400"%[shop_seen.Legendary,shop_seen.Rare,shop_seen.Common])
 var vase_hit=false
 for tier in ItemStats.DROPS.vase_tiers:if tier=="legendary":vase_hit=true
 check(not vase_hit,"Vases never carry it (Common/Uncommon only)")
 game.amulets=1;game.amulets_found=1
 var w=game.weapons[0]
 check(WeaponSockets.unlocked(w)==1,"Weapon starts with a single socket")
 var result=GemRewards.use_amulet(game,0)
 check(result.ok and WeaponSockets.unlocked(w)==2 and game.amulets==0,"Using the amulet unlocks the second socket and consumes it")
 game.amulets=1
 check(not GemRewards.use_amulet(game,0).ok and game.amulets==1,"A weapon cannot unlock a third socket and the amulet is kept")
 check(not GemRewards.use_amulet(game,99).ok and game.amulets==1,"An unowned weapon is refused and the amulet is kept")
 game.amulets=0
 check(GemRewards.use_amulet(game,6).reason=="no_amulet" and WeaponSockets.unlocked(game.weapons[6])==1,"No amulet means no unlock")
 # eligibility
 game.gems.add("fire",3);game.gems.add("ice",3);game.gold=5000;game.stage=1
 check(ImbueRules.install(game,0,"fire").ok,"First gem installs")
 check(ImbueRules.problem(game,0,"fire")=="duplicate_element","Second socket refuses the same element")
 check(ImbueRules.install(game,0,"ice").ok and WeaponSockets.combo(w).id=="thermal_shock","A different element installs and forms the combination")
 check(ImbueRules.problem(game,0,"corrosive")!="","A full weapon refuses a third gem")
 check(ImbueRules.problem(game,6,"ice")=="","A weapon without an amulet still takes one gem")
 ImbueRules.install(game,6,"ice")
 check(ImbueRules.problem(game,6,"fire")=="no_free_socket","A single-socket weapon refuses a second gem")
 # save/load
 game.amulets=1;game.amulets_found=1
 check(game.save_run("user://test-combos-run.json"),"Run with an amulet saves")
 game.amulets=0;game.amulets_found=0
 check(game.load_run("user://test-combos-run.json") and game.amulets==1 and game.amulets_found==1,"Amulet counts survive save/load")
 check(WeaponSockets.unlocked(game.weapons[0])==2 and WeaponSockets.gems(game.weapons[0])==["fire","ice"],"Both gems and the second socket survive save/load")
 game.amulets=0;game.amulets_found=0
func amulet_ui():
 game.weapons[0]["sockets"]={"unlocked":1,"gems":[]};game.amulets=1
 var station=ImbueStation.find(game)
 if station.is_empty():station={"node":Node3D.new(),"kind":"Imbue Station","used":false,"charge":0.0}
 game.frontend.imbue_station(station)
 await process_frame
 var screen: RunImbue
 for n in game.frontend.menu.get_children():
  if n is RunImbue:screen=n
 var button=screen.slots.get("Slot_0_1") if screen!=null else null
 check(button!=null and not button.disabled,"Station offers an enabled amulet slot for a single-socket weapon")
 if button:
  button.pressed.emit()
  await process_frame
 check(WeaponSockets.unlocked(game.weapons[0])==2 and game.amulets==0,"Pressing it unlocks the socket once")
 game.resume()

func combos():
 socket(0,["fire","ice"])
 # Thermal Shock
 var e=dummy()
 StatusManager.apply_chill(game,e,5);e.burn=5.0
 var hp=float(e.hp);var stacks=StatusManager.chill_stacks(e)
 game.hit(e,1,0)
 check(StatusManager.chill_stacks(e)<=stacks+1-3+0 and hp-float(e.hp)>=80.0,"Thermal Shock consumes 3 chill stacks and deals 2%% max HP (%.0f)"%(hp-float(e.hp)))
 var after=float(e.hp);e.burn=5.0
 game.hit(e,1,0)
 check(after-float(e.hp)<20.0,"Thermal Shock is on a per-target cooldown")
 ticks(e,3.2);StatusManager.apply_chill(game,e,5);e.burn=5.0;var h2=float(e.hp)
 game.hit(e,1,0)
 check(h2-float(e.hp)>70.0,"Thermal Shock fires again after its cooldown")
 var tank=dummy(100000000.0);StatusManager.apply_chill(game,tank,5);tank.burn=5.0
 var th=float(tank.hp);game.hit(tank,1,0)
 check(th-float(tank.hp)<=201.0+1.0,"Thermal Shock damage is capped at 200 (%.0f)"%(th-float(tank.hp)))
 var cold=dummy();cold.burn=5.0;StatusManager.apply_chill(game,cold,1);var ch=float(cold.hp);game.hit(cold,1,0)
 check(ch-float(cold.hp)<10.0,"Thermal Shock needs 3 chill stacks and burning")
 # Overcharge
 socket(0,["fire","electricity"])
 var o=dummy();o.burn=5.0;StatusManager.state(o)["stun"]={"left":2.0}
 var oh=float(o.hp);game.hit(o,1,0)
 check(oh-float(o.hp)>=80.0 and oh-float(o.hp)<=82.0,"Overcharge deals 2%% max HP to a burning, stunned target (%.0f)"%(oh-float(o.hp)))
 var o2=dummy();o2.burn=5.0;var o2h=float(o2.hp);game.hit(o2,1,0)
 check(o2h-float(o2.hp)<10.0,"Overcharge needs the stun (%.1f)"%(o2h-float(o2.hp)))
 # Caustic Combustion
 socket(0,["fire","corrosive"])
 var c=dummy();var neighbour=dummy(4000.0,0,false);neighbour.pos=c.pos+Vector3(1.5,0,0);var far=dummy(4000.0,0,false);far.pos=c.pos+Vector3(12,0,0)
 game.rebuild_grid()
 c.burn=5.0;StatusManager.apply_corrosive(game,c,0)
 var nh=float(neighbour.hp);var fh=float(far.hp);game.hit(c,1,0)
 check(nh-float(neighbour.hp)>=119.0 and nh-float(neighbour.hp)<=121.0,"Caustic Combustion hurts neighbours for 3%% max HP (%.0f)"%(nh-float(neighbour.hp)))
 check(float(far.hp)==fh,"Caustic Combustion has a limited radius")
 # Toxic Conduction
 socket(0,["electricity","corrosive"])
 var t=dummy();var group=[]
 for i in 5:
  var n=dummy(4000.0,0,false);n.pos=t.pos+Vector3(1.0+i*0.5,0,0);group.append(n)
 game.rebuild_grid()
 StatusManager.apply_corrosive(game,t,0);StatusManager.state(t)["stun"]={"left":2.0}
 game.hit(t,1,0)
 var poisoned=0;var hurt=0
 for n in group:
  if StatusManager.poisoned(n):poisoned+=1
  if float(n.hp)<4000.0-30.0:hurt+=1
 check(poisoned>=3 and hurt==3,"Toxic Conduction spreads to exactly 3 nearby enemies (%d poisoned, %d hurt)"%[poisoned,hurt])
 # Cryoshock
 socket(0,["ice","electricity"])
 var k=dummy();var kn=dummy(4000.0,0,false);kn.pos=k.pos+Vector3(2.0,0,0);game.rebuild_grid()
 StatusManager.apply_chill(game,k,2);StatusManager.state(k)["stun"]={"left":2.0}
 var kh=float(kn.hp);game.hit(k,1,0)
 check(StatusManager.chill_stacks(kn)==2 and kh-float(kn.hp)>=59.0 and kh-float(kn.hp)<=61.0,"Cryoshock chills neighbours (2 stacks) and deals 1.5%% max HP (%.0f)"%(kh-float(kn.hp)))
 # Blightfrost
 socket(0,["ice","corrosive"])
 var b=dummy();game.hit(b,1,0)
 check(StatusManager.poisoned(b) and StatusManager.chill_stacks(b)==1,"First Blightfrost hit applies poison and one chill stack")
 game.hit(b,1,0)
 check(StatusManager.chill_stacks(b)==3,"Hits on poisoned targets add an extra chill stack (3 after two hits)")
 socket(0,["ice"])
 var plain=dummy();StatusManager.apply_corrosive(game,plain,0);game.hit(plain,1,0);game.hit(plain,1,0)
 check(StatusManager.chill_stacks(plain)==2,"Ice alone adds only one stack per hit")
 # single effects remain with a pair
 socket(0,["corrosive","electricity"])
 var s=dummy();game.hit(s,1,0)
 check(StatusManager.poisoned(s),"A paired weapon keeps its individual element effects")

func safety():
 # No recursion: combo victims do not themselves fire combos or carry combo cooldowns.
 socket(0,["fire","corrosive"])
 var c=dummy();var victims=[]
 for i in 4:
  var v=dummy(4000.0,0,false);v.pos=c.pos+Vector3(1.0+i*0.3,0,0);v.burn=5.0;StatusManager.apply_corrosive(game,v,0);victims.append(v)
 game.rebuild_grid()
 c.burn=5.0;StatusManager.apply_corrosive(game,c,0);game.hit(c,1,0)
 var clean=true
 for v in victims:
  if v.has("fx") and v.fx.cd.keys().any(func(k): return str(k).begins_with("combo_")):clean=false
 check(clean,"Combo victims do not fire combos of their own")
 check(StatusManager.depth==0,"Re-entrancy depth returns to zero")
 # global budget
 Combos.window_start=-1.0;Combos.window_count=0
 game.elapsed=500.0
 var fired=0
 for i in 60:
  var x=dummy();x.burn=5.0;StatusManager.apply_corrosive(game,x,0)
  game.hit(x,1,0)
  if x.has("fx") and x.fx.cd.has("combo_caustic_combustion"):fired+=1
 check(fired==int(Elements.TUNING.combos.budget_per_second),"Combos respect the per-second budget (%d fired)"%fired)
 game.elapsed=502.0
 var y=dummy();y.burn=5.0;StatusManager.apply_corrosive(game,y,0);game.hit(y,1,0)
 check(y.has("fx") and y.fx.cd.has("combo_caustic_combustion"),"Budget refreshes the next second")
 # opposite install order gives the same combo
 socket(0,["corrosive","fire"])
 check(WeaponSockets.combo(game.weapons[0]).id=="caustic_combustion","Install order does not matter")
 # Unsocketed weapon never fires combos
 socket(0,[])
 var u=dummy();u.burn=5.0;StatusManager.apply_corrosive(game,u,0);var uh=float(u.hp);game.hit(u,1,0)
 check(uh-float(u.hp)<10.0,"Unsocketed weapons never trigger combos")
