extends SceneTree
var failures=[]
var checks=0
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="run";game.enemies.clear()
 check(not game.audio.events.keys().any(func(e):return str(e).begins_with("enemy.")),"Registry contains no enemy hit/death/explosion sounds")
 game.audio.set_process(false);game.audio.clock=100
 var before=game.audio.accepted
 game.play_sound("death");game.play_sound("enemy.death");game.play_sound("enemy.hit")
 check(game.audio.accepted==before,"Legacy enemy damage/death calls are silent")
 var enemy=game.spawn_enemy(0,game.player.position+Vector3.RIGHT*6);enemy.hp=10;game.hit(enemy,100,7);var after_hit=game.audio.accepted;game.kill_enemy(game.enemies.find(enemy))
 check(game.audio.accepted==after_hit,"Killing an enemy emits no extra sound")
 var bug=game.spawn_enemy(1,game.player.position+Vector3.RIGHT*20);bug.variant=OrdinaryRoster.variant(1,0);bug.detonated=false;before=game.audio.accepted;EnemySimulation.detonate(game,bug)
 check(game.audio.accepted==before,"Self-destruction does not add an enemy sound")
 game.schedule_blast(game.player.position+Vector3.RIGHT*20,3,10,0);game.update_blasts(.1)
 check(game.audio.accepted==before,"Death-triggered blast cleanup remains silent")
 game.weapons.clear();game.equip(7);game.equip(0);game.tomes={"Wind":2,"Wisdom":3};game.health=37;game.stats.max_health=100;game.update_hud();await process_frame
 var hud_rows=game.frontend.run_hud.build_box;var weapons=hud_rows.get_child(1);var tomes=hud_rows.get_child(3)
 check(weapons.get_children().filter(func(n):return n.tooltip_text!="").size()==2 and tomes.get_children().filter(func(n):return n.tooltip_text!="").size()==2,"Weapons and tomes have independent complete rows")
 check(tomes.position.y>=weapons.position.y+weapons.size.y,"Tomes are positioned beneath weapons")
 check(game.frontend.health_text.text=="37 / 100" and game.frontend.health_text.get_parent()==game.health_bar,"Current and maximum HP are written inside the health bar")
 check(game.frontend.character_health.size.y<=7.1,"Character health bar remains thin after theme layout")
 check(game.health_bar.value==37 and game.frontend.character_health.value==37,"Both health bars follow actual player health")
 var left=game.frontend.run_hud.health_bar.fill_material.get_shader_parameter("fill_color");var world=game.frontend.character_health.get_theme_stylebox("fill")
 check(left==FogPalette.RUST and world.bg_color==FrontEnd.HEALTH_COLOR and left.r<.6,"Both health bars use the same dark red fill")
 game.frontend.update_character_health();var target=game.player.camera.unproject_position(game.player.global_position+Vector3.UP*.05)+Vector2(-32,12)
 check(game.frontend.character_health.position.distance_to(target)<.01,"Small bar projects just beneath the character's feet")
 game.mode="pause";game.frontend.update_character_health();check(not game.frontend.character_health.visible,"Character bar hides outside gameplay")
 check(is_equal_approx(float(game.audio.events["weapon.revolver.fire"].base_pitch),1.0) and is_equal_approx(float(game.audio.events["weapon.aura.pulse"].base_pitch),1.0) and game.audio.events["weapon.revolver.fire"].files!=game.audio.events["weapon.aura.pulse"].files,"Finished Fog samples play at original pitch (no dark pass) with distinct event pools")
 game.queue_free();await process_frame;await process_frame
 print("DARK FEEDBACK: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
