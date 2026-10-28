extends SceneTree
# Weapon Overhaul 2.0 regression suite: roster, pools, card text, saves, per-weapon behaviour rules and socket procs.
var checks=0
var failures=[]
var game: Node3D
const ROSTER=[0,1,2,6,7,9,10,15]
const NAMES=["Sword","Firestaff","Lightning Staff","Bow","Revolver","Aura","Scythes","Shotgun"]
const EXPECTED={
 0:["count","radius","damage","haste"],
 1:["velocity","count","damage","radius"],
 2:["count","damage","radius","ricochet","haste"],
 6:["damage","haste","crit","crit_damage","count","velocity","radius"],
 7:["damage","haste","crit","crit_damage","count","velocity","ricochet"],
 9:["haste","damage","count","velocity","radius"],
 10:["haste","radius","damage"],
 15:["haste","radius","damage","crit","crit_damage","count"]}
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func same_set(a: Array,b: Array) -> bool:
 var x=a.duplicate();var y=b.duplicate();x.sort();y.sort();return x==y
func fresh():
 game.weapons.clear();game.enemies.clear();game.wrt.clear();game.projectiles.clear()
func dummy(pos: Vector3,hp: float=1000000.0) -> Dictionary:
 var e=game.spawn_enemy(0,pos)
 if not e.is_empty():e.hp=hp;e.max_hp=hp;e.speed=0.0
 return e
func total_hits() -> int:
 var n=0
 for k in game.wrt.counters.strike:n+=int(game.wrt.counters.strike[k])
 return n
func cast_once(id: int,frames: int):
 game.weapons[id].clock=0.0;game.rebuild_grid();run_frames(1)
 game.weapons[id].clock=9999.0;run_frames(frames)
func run_frames(n: int):
 for f in n:
  game.rebuild_grid();game.update_weapons(1.0/60.0)
  for e in game.enemies:e.hit_time=maxf(0,e.hit_time-1.0/60.0)
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-weapons-regression.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 game.mode="run"
 # --- roster ---------------------------------------------------------------------------------
 check(same_set(Catalog.ACTIVE_WEAPONS,ROSTER) and Catalog.WEAPONS.size()==8,"Roster is exactly the eight specified weapons")
 var names=[]
 for id in ROSTER:names.append(Catalog.weapon_name(id))
 check(same_set(names,NAMES),"Roster names match the specification")
 for banned in ["Chunkers","Mines","Bones","Bone","Bananarang"]:check(not names.has(banned),"%s is not in the roster"%banned)
 var removed=[]
 for id in 40:if not id in ROSTER:removed.append(id)
 check(removed.all(func(id):return not Catalog.weapon_exists(id) and not WeaponUpgrades.POOLS.has(id)),"No removed weapon id exists in the catalog or upgrade pools")
 check(LoadoutCatalog.entries("weapons").size()==8,"Loadout/unlock list shows eight weapons")
 # --- upgrade pools ---------------------------------------------------------------------------
 var rnd=RandomNumberGenerator.new();rnd.seed=77
 for id in ROSTER:
  check(same_set(WeaponUpgrades.pool(id),EXPECTED[id]),"%s upgrade pool matches the specification"%Catalog.weapon_name(id))
  var seen={}
  for i in 300:
   var state={"level":1,"upgrades":{}}
   seen[WeaponUpgrades.proposal(id,rnd,state).attribute]=true
  check(seen.keys().all(func(k):return k in EXPECTED[id]) and seen.size()==EXPECTED[id].size(),"%s only ever proposes its own stats (and all of them appear)"%Catalog.weapon_name(id))
 check(not "crit" in WeaponUpgrades.pool(0) and not "velocity" in WeaponUpgrades.pool(0),"Sword never offers Crit Chance or Projectile Speed")
 check(not "ricochet" in WeaponUpgrades.pool(15) and not "ricochet" in WeaponUpgrades.pool(6),"Shotgun and Bow never offer Projectile Bounces")
 # --- card text -------------------------------------------------------------------------------
 game.begin_run();game.build_stage();game.resume();game.mode="run";fresh();game.equip(0)
 var text=WeaponUpgrades.description(0,game.weapons[0],"count",game)
 check(text.begins_with("Projectile Count: ") and text.contains("→") and text.contains("slash"),"Sword card reads 'Projectile Count: n slashes → n+1 slashes' (%s)"%text)
 for id in ROSTER:
  fresh();game.equip(id)
  for key in WeaponUpgrades.open_keys(id,game.weapons[id]):
   var d=WeaponUpgrades.description(id,game.weapons[id],key,game)
   check(d.contains("→") and d.begins_with(WeaponUpgrades.label(id,key)+": "),"%s %s card shows current → new value"%[Catalog.weapon_name(id),key])
 # --- pools in play: rewards only ever contain roster weapons --------------------------------------
 fresh()
 var leaked=false
 for i in 40:
  for c in game.upgrade_pool():
   if c.type=="weapon" and not int(c.id) in ROSTER:leaked=true
 check(not leaked,"Upgrade pool never offers a removed weapon")
 # --- acquisition / max level ---------------------------------------------------------------------
 fresh();game.equip(15)
 for i in 12:
  var choice=game.upgrade_pool().filter(func(c):return c.type=="weapon" and c.id==15)
  if choice.is_empty():break
  game.apply_upgrade(choice[0])
 check(game.weapons[15].level==10,"Weapon stops at max level 10")
 check(game.upgrade_pool().filter(func(c):return c.type=="weapon" and c.id==15).is_empty(),"A maxed weapon leaves the upgrade pool")
 var cap_ok=true
 for id in ROSTER:
  var st={"level":10,"upgrades":{"count":99.0,"ricochet":99.0}}
  var r=WeaponStats.resolve(game,id,st)
  if int(r.count)>WeaponUpgrades.count_cap(id) or int(r.bounces)>int(WeaponStats.CAPS.ricochet):cap_ok=false
 check(cap_ok,"Projectile count and bounces are capped for every weapon")
 # --- behaviour rules -------------------------------------------------------------------------------
 var sizes=[]
 for n in [0,1,3,6]:sizes.append(int(WeaponStats.resolve(game,15,{"level":1,"upgrades":{"count":float(n)}}).count))
 check(sizes==[6,7,9,12],"Shotgun fires 6/7/9/12 pellets with count upgrades (%s)"%str(sizes))
 var narrow=WeaponStats.resolve(game,15,{"level":1,"upgrades":{}});var wide=WeaponStats.resolve(game,15,{"level":1,"upgrades":{"radius":3.0}})
 check(float(wide.cone_deg)>float(narrow.cone_deg) and float(wide.range)<=float(WeaponStats.SHOTGUN.range_max) and float(wide.cone_deg)/float(narrow.cone_deg)>float(wide.range)/float(narrow.range),"Shotgun Size widens the cone without extending range")
 var a0=WeaponStats.resolve(game,10,{"level":1,"upgrades":{}});var a1=WeaponStats.resolve(game,10,{"level":1,"upgrades":{"haste":3.0}})
 check(float(a1.interval)<float(a0.interval) and is_equal_approx(float(a1.radius),float(a0.radius)) and is_equal_approx(float(a1.damage),float(a0.damage)),"Aura Attack Speed changes pulse rate only")
 var r0=WeaponStats.resolve(game,2,{"level":1,"upgrades":{"radius":2.0}});var r1=WeaponStats.resolve(game,2,{"level":1,"upgrades":{}})
 check(float(r0.strike_radius)>float(r1.strike_radius),"Lightning Size raises strike radius")
 # Sword: burst slashes, at most one hit per enemy per slash
 fresh();game.equip(0);game.weapons[0].upgrades={"count":2.0}
 var sword_target=dummy(game.player.position+Vector3(2.0,0,0))
 cast_once(0,90)
 var slashes=int(game.wrt.counters.strike.get("slash",0))
 check(slashes>=1 and slashes<=3,"Sword burst of 3 deals at most one hit per slash on one enemy (%d)"%slashes)
 # Lightning: initial strikes land on separate targets
 fresh();game.equip(2);game.weapons[2].upgrades={"count":2.0}
 for i in 6:dummy(game.player.position+Vector3(cos(i)*4.0,0,sin(i)*4.0+0.5))
 game.wrt.counters.strike.clear();cast_once(2,40)
 var struck=int(game.wrt.counters.strike.get("strike",0))
 check(struck==3,"Lightning with count 3 opens with three strikes on separate enemies (%d)"%struck)
 fresh();game.equip(2);game.weapons[2].upgrades={"ricochet":2.0}
 for i in 6:dummy(game.player.position+Vector3(cos(i)*4.0,0,sin(i)*4.0+0.5))
 game.rebuild_grid();game.wrt.counters.strike.clear();cast_once(2,120)
 var chained=int(game.wrt.counters.strike.get("chain",0))
 check(chained>0,"Lightning bounces actually chain to further enemies (%d links)"%chained)
 check(chained<=3*int(WeaponStats.resolve(game,2,game.weapons[2]).bounces)+3,"Lightning chain obeys its bounce limit (%d links)"%chained)
 # Bow: piercing, one hit per enemy per arrow
 fresh();game.equip(6);game.weapons[6].upgrades={"count":2.0}
 var line=[dummy(game.player.position+Vector3(0,0,-4.0)),dummy(game.player.position+Vector3(0,0,-7.0))]
 cast_once(6,120)
 var arrows=int(game.wrt.counters.strike.get("arrow",0))
 check(arrows>=2 and arrows<=6,"Bow arrows pierce but hit each enemy at most once per arrow (%d hits, 3 arrows, 2 enemies)"%arrows)
 # Revolver: ricochet reaches another enemy without ping-pong
 fresh();game.equip(7);game.weapons[7].upgrades={"ricochet":2.0}
 dummy(game.player.position+Vector3(0,0,-5.0));dummy(game.player.position+Vector3(3.0,0,-6.0));dummy(game.player.position+Vector3(-3.0,0,-6.5))
 cast_once(7,180)
 var bullet=int(game.wrt.counters.strike.get("bullet",0))
 check(bullet>=1 and bullet<=int(game.wrt.counters.casts.get(7,1))*(1+2+1)+4,"Revolver ricochet stays bounded (%d hits)"%bullet)
 # Scythes: return and are never lost
 fresh();game.equip(9)
 dummy(game.player.position+Vector3(0,0,-6.0))
 var farthest=0.0
 cast_once(9,0)
 for f in 600:
  run_frames(1)
  for s in game.wrt.scythes:farthest=maxf(farthest,s.pos.distance_to(game.player.position))
 check(game.wrt.scythes.size()<=WeaponRuntime.MAX_SCYTHES and farthest<60.0,"Scythes stay bounded and near the player (max distance %.1f)"%farthest)
 check(int(game.wrt.counters.casts.get(9,0))>=1 and farthest>3.0,"Scythes were thrown outward (max distance %.1f)"%farthest)
 check(game.wrt.scythes.is_empty(),"Every thrown scythe returned to the player within 10 s (%d left)"%game.wrt.scythes.size())
 # Shotgun: each pellet is its own hit
 fresh();game.equip(15)
 for i in 5:dummy(game.player.position+Vector3((i-2)*0.5,0,-3.0))
 cast_once(15,30)
 var pellets=int(game.wrt.counters.strike.get("pellet",0))
 check(pellets>=1 and pellets<=6,"Shotgun hits are per-pellet and never exceed the pellet count (%d)"%pellets)
 # Firestaff + Aura fire at all
 for id in [1,10]:
  fresh();game.equip(id)
  for i in 6:dummy(game.player.position+Vector3(cos(i)*3.0,0,sin(i)*3.0))
  game.wrt.counters.strike.clear();cast_once(id,150)
  check(total_hits()>0,"%s damages nearby enemies"%Catalog.weapon_name(id))
 # --- sockets: exactly one proc per hit for every hit source ---------------------------------------
 for id in ROSTER:
  fresh();game.equip(id)
  game.weapons[id].sockets={"unlocked":1,"gems":["ice"]}
  var e=dummy(game.player.position+Vector3(0,0,-3.0))
  if id==2:
   game.weapons[2].upgrades={"ricochet":2.0};dummy(game.player.position+Vector3(2.5,0,-3.0));dummy(game.player.position+Vector3(-2.5,0,-3.5))
  game.rebuild_grid();game.wrt.counters.strike.clear()
  var chill_checked=0;var hits_seen=0;var duplicates=false
  for f in 240:
   game.weapons[id].clock=0.0 if f==0 else 9999.0
   var before=total_hits();var stacks_before=StatusManager.chill_stacks(e)
   run_frames(1)
   var dh=total_hits()-before;var ds=StatusManager.chill_stacks(e)-stacks_before
   if ds>dh:duplicates=true
   hits_seen+=dh
   if StatusManager.chill_stacks(e)>=int(Elements.TUNING.ice.max_stacks):break
  check(hits_seen>0 and not duplicates,"%s: ice socket procs once per hit, never doubled (%d hits)"%[Catalog.weapon_name(id),hits_seen])
 # --- saves / stage persistence ------------------------------------------------------------------------
 fresh();game.equip(0);game.equip(9);game.weapons[9].upgrades={"count":1.0};game.weapons[9].level=4
 game.weapons[9].sockets={"unlocked":1,"gems":["fire"]}
 game.stage=2;game.build_stage()
 check(game.weapons.has(9) and game.weapons[9].level==4 and WeaponSockets.has_gem(game.weapons[9],"fire") and float(game.weapons[9].upgrades.count)==1.0,"Weapon level, upgrades and gems persist across a stage transition")
 check(game.save_run("user://test-weapons-run.json"),"Run saves")
 var raw=JSON.parse_string(FileAccess.get_file_as_string("user://test-weapons-run.json"))
 for old_id in ["3","4","5","8","13","31"]:raw.weapons[old_id]={"level":3,"clock":0.0,"upgrades":{}}
 var f=FileAccess.open("user://test-weapons-old.json",FileAccess.WRITE);f.store_string(JSON.stringify(raw));f.close()
 check(game.load_run("user://test-weapons-old.json"),"A save that still contains removed weapons loads")
 check(game.weapons.keys().all(func(k):return int(k) in ROSTER) and game.weapons.has(0) and game.weapons.has(9),"Removed weapons are dropped from a loaded save; the rest is kept")
 var after_load=game.upgrade_pool().filter(func(c):return c.type=="weapon" and not int(c.id) in ROSTER)
 check(after_load.is_empty(),"Removed weapons do not reappear after loading")
 game.weapons.clear();game.load_run("user://test-weapons-old.json")
 check(not game.weapons.is_empty(),"A game never ends up with zero weapons after sanitising an old save")
 print("WEAPONS_REGRESSION: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free();await process_frame;await process_frame
 quit(1 if failures.size()>0 else 0)
