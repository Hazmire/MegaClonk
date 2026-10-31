extends SceneTree
# Feedback pass 1: uncapped crit + megacrit, scythe count, random-target revolver/firestaff, fixed border rarity, level-up skip keys,
# no-fanfare reroll, socket-hover charge, hit/pickup loudness.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func enemy_at(p: Vector3,hp: float=1e9) -> Dictionary:
 var e=game.spawn_enemy(0,game.player.position+p)
 if not e.is_empty():e.hp=hp;e.max_hp=hp;e.speed=0.0
 return e
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-feedback1.json";game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume();game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 # --- crit is uncapped; over 100% rolls megacrits (1.5x a crit) ---
 game.weapons.clear();game.equip(0);game.enemies.clear()
 var e=enemy_at(Vector3(2,0,0));game.rebuild_grid()
 game.stats.crit=1.0;game.stats.crit_damage=2.0;game.stats.damage=1.0
 var hp0=e.hp;game.hit(e,10.0,0);var normal=hp0-e.hp
 check(is_equal_approx(normal,20.0),"Exactly 100% crit always crits (x2)")
 game.stats.crit=2.0;hp0=e.hp;game.hit(e,10.0,0);check(is_equal_approx(hp0-e.hp,30.0),"200% crit always megacrits (x2 x1.5 = 30)")
 game.stats.crit=1.5;var mega=0;var plain=0
 for i in 400:
  hp0=e.hp;game.hit(e,10.0,0);var d=hp0-e.hp
  if is_equal_approx(d,30.0):mega+=1
  elif is_equal_approx(d,20.0):plain+=1
 check(mega+plain==400 and mega>140 and mega<260,"150%% crit: every hit crits, about half are megacrits (%d/400)"%mega)
 game.stats.crit=0.0
 check(RunData.shown("crit",3.5)==3.5 and WeaponStats.resolve(game,0,game.weapons[0]).crit_chance>=0.0,"Crit chance is not clamped for display or weapon stats")
 # --- scythes: one in flight at count 1 ---
 game.weapons.clear();game.equip(9);game.enemies.clear();enemy_at(Vector3(6,0,0));game.rebuild_grid()
 var r=WeaponStats.resolve(game,9,game.weapons[9])
 check(r.count==1 and game.wrt.fire_scythes(9,r) and game.wrt.scythes.size()==1,"Scythes start with one projectile")
 check(not game.wrt.fire_scythes(9,r) and game.wrt.scythes.size()==1,"No second scythe is thrown while the first is still out")
 # --- revolver / firestaff target random enemies ---
 game.weapons.clear();game.equip(7)
 game.enemies.clear()
 for p in [Vector3(8,0,0),Vector3(-8,0,0),Vector3(0,0,8),Vector3(0,0,-8)]:enemy_at(p)
 game.rebuild_grid()
 game.weapons[7].upgrades={"count":4.0};game.wrt.bullets.clear()
 var rr=WeaponStats.resolve(game,7,game.weapons[7]);var spreads={}
 for k in 12:
  game.wrt.bullets.clear();game.wrt.fire_revolver(7,rr)
  for b in game.wrt.bullets:spreads["%d,%d"%[roundi(b.dir.x*3),roundi(b.dir.z*3)]]=true
 check(rr.count==5 and spreads.size()>=3,"Revolver bullets fly at different random enemies, not parallel lanes (%d directions)"%spreads.size())
 game.weapons.clear();game.equip(1);game.weapons[1].upgrades={"count":4.0};spreads={}
 var fr=WeaponStats.resolve(game,1,game.weapons[1])
 for k in 12:
  game.wrt.fireballs.clear();game.wrt.fire_firestaff(1,fr)
  for b in game.wrt.fireballs:spreads["%d,%d"%[roundi(b.dir.x*3),roundi(b.dir.z*3)]]=true
 check(spreads.size()>=3,"Firestaff fireballs fly at random enemies, not a fan (%d directions)"%spreads.size())
 # --- border rarity fixed at first pick ---
 game.tomes.clear();game.tome_rarities.clear()
 game.apply_upgrade({"type":"tome","id":"Might","tier":"common","key":"t"});game.apply_upgrade({"type":"tome","id":"Might","tier":"epic","key":"t"})
 check(game.equipment_meta("tomes","Might",2).rarity=="common","A tome upgrade does not change the tome's border rarity")
 game.weapons.clear();game.equip(0);var before=game.weapons[0].get("rarity","common")
 game.apply_upgrade({"type":"weapon","id":0,"tier":"legendary","key":"w0","expected_level":1})
 check(game.weapons[0].get("rarity","common")==before,"A weapon upgrade does not change the weapon's border rarity")
 # --- amulet is a legendary item entry ---
 game.amulets=2
 var am=RunData.items(game).filter(func(i):return i.id=="imbued_amulet")
 check(am.size()==1 and am[0].stacks==2 and am[0].tier==FogPalette.Rarity.LEGENDARY,"The Imbued Amulet is listed as a Legendary item")
 game.amulets=0
 # --- socket hover charge ---
 var a=game.audio;a.charge(true)
 for i in 12:a.charge_tick(0.016)
 var up=a.charge_level;a.charge(false)
 for i in 4:a.charge_tick(0.016)
 var mid=a.charge_level;a.charge(true);a.charge_tick(0.016)
 check(up>0.9 and mid<up and mid>0.0 and a.charge_level>mid,"Hover charges up, charges down gradually, and a quick re-hover resumes without a restart")
 a.charge(false);for i in 40:a.charge_tick(0.016)
 check(a.charge_level==0.0,"Leaving charges all the way down")
 check((load("res://assets/audio/fog/ui/socket_hover.wav") as AudioStreamWAV).loop_mode==AudioStreamWAV.LOOP_DISABLED,"The shared hover stream is never modified (the charge uses a private copy)")
 # --- loudness floors ---
 var ev=a.events
 for id in ["weapon.sword.hit","weapon.firestaff.impact","weapon.bow.hit","weapon.revolver.hit","weapon.scythes.hit","weapon.shotgun.hit"]:check(float(ev[id].gain_db)>=-6.0,"%s is audible (gain %s dB)"%[id,ev[id].gain_db])
 check(float(ev["pickup.gold"].gain_db)>=-22.0 and float(ev["pickup.xp"].gain_db)>=-10.0 and float(ev["gem.pickup"].gain_db)>=-8.0 and float(ev["reward.chest.tick"].gain_db)>=-8.0,"Gold, XP, gem and chest-reel sounds were raised")
 print("FEEDBACK_PASS_1: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)
