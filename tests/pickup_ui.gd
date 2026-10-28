extends SceneTree
# Feedback round: running gold/XP totals, gem banner, weapon sockets on the HUD.
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
 game.progress=Progress.new();game.progress.storage_path="user://test-pickup-ui.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 tally()
 await hud()
 print("PICKUP_UI: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func tally():
 var t=PickupTally.new()
 game.gold=0;game.xp=0.0;game.level=1
 t.reset(game)
 game.gold=10;t.update(game,0.1)
 check(t.gold_text()=="+10" and t.xp_text()=="","Gold gain shows a gold total only")
 game.gold=25;t.update(game,0.5)
 check(t.gold_text()=="+25","Gold gains accumulate (+25)")
 game.xp=20.0;t.update(game,0.1)
 game.xp=44.0;t.update(game,0.1)
 check(t.xp_text()=="+44","XP gains accumulate (+44)")
 game.gold-=10;t.update(game,0.1)
 check(t.gold_text()=="+25","Spending gold does not change the total")
 t.update(game,2.0)
 check(t.xp_text()=="+44","Totals persist inside the 4 second window")
 t.update(game,2.2)
 check(t.xp_text()=="" and t.gold_text()=="","Totals clear 4 seconds after the last gain")
 # Level-up: XP carried across a level boundary is counted once.
 var t2=PickupTally.new();game.level=3;game.xp=0.0;t2.reset(game)
 var threshold=Catalog.threshold(game.level)
 game.xp=threshold-5.0;t2.update(game,0.1)
 check(t2.xp_text()=="+%d"%roundi(threshold-5.0),"XP before a level-up is counted (%s)"%t2.xp_text())
 game.level+=1;game.xp=8.0;t2.update(game,0.1)
 check(t2.xp_text()=="+%d"%roundi(threshold-5.0+5.0+8.0),"A level-up neither loses nor doubles XP (%s)"%t2.xp_text())
 check(PickupTally.GOLD_COLOR.r>0.9 and PickupTally.GOLD_COLOR.g>0.7 and PickupTally.GOLD_COLOR.b<0.4,"Gold total is gold coloured")
 check(PickupTally.XP_COLOR.b>0.9 and PickupTally.XP_COLOR.r<0.5,"XP total is blue")
 game.level=1;game.xp=0.0;game.gold=0
func hud():
 game.mode="run"
 game.weapons.clear();game.equip(0)
 game.frontend.update_hud()
 var found=0
 for n in RewardScreens.descendants(game.frontend.loadout_icons):
  if n is SocketPips:found+=1
 check(found==1,"The top-left weapon icon shows its socket diamonds")
 WeaponSockets.install(game.weapons[0],"fire")
 game.frontend.update_hud()
 var filled=false
 for n in RewardScreens.descendants(game.frontend.loadout_icons):
  if n is SocketPips and n.gems==["fire"]:filled=true
 check(filled,"The HUD socket diamond updates when a gem is installed")
 game.gems.reset();game.gold=0
 game.gem_discovered("ice")
 check(game.frontend.gem_label.visible and game.frontend.gem_label.text.find("ICE")>=0,"Gem banner names the element")
 check(game.frontend.gem_label.get_theme_color("font_color").b>game.frontend.gem_label.get_theme_color("font_color").r,"Ice banner is coloured blue")
 game.gem_discovered("corrosive")
 var c=game.frontend.gem_label.get_theme_color("font_color")
 check(c.g>c.r and c.g>c.b,"Corrosive banner is coloured green")
 game.gem_discovered("fire")
 c=game.frontend.gem_label.get_theme_color("font_color")
 check(c.r>c.b,"Fire banner is coloured orange/red")
 for i in 300:game.frontend.update_tally(0.02)
 check(not game.frontend.gem_label.visible,"The banner disappears after its timer")
 WorldPickups.collect(game,{"kind":"gem","element":"electricity"})
 check(game.gems.count("electricity")==1 and game.frontend.gem_label.visible and game.frontend.gem_notice_left>3.0,"Picking up a gem raises the banner")
