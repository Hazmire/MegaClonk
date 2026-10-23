extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(label: String):
 await create_timer(0.2).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/combat_"+label+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.3).timeout
 game.next_run_seed=632;game.selected_weapon=7;game.selected_trait="seer";game.begin_run();game.settings.focus_pause=false;game.settings.shake=false
 game.mode="pause";game.player.active=false;game.weapons.clear();game.equip(7);game.enemies.clear()
 game.player.position=Vector3(0,1,0);game.player.zoom=8;game.player.arm.spring_length=8
 for i in 5:game.spawn_enemy(i,Vector3((i-2)*2,0,-4))
 game.update_enemies(0);game.frontend.update_hud()
 game.stats.crit=0;game.stats.evasion=0;game.invulnerability=0;game.hurt(2)
 for e in game.enemies:game.hit(e,1,7)
 game.update_enemies(0);game.frontend.update_hud();await capture("red_flash")
 game.player.avatar.set_damage_flash(false)
 for e in game.enemies:e.hit_time=0
 game.combat_fx.burst("explosion_small",Vector3(-2,1,-3),2.5)
 game.combat_fx.burst("sparks_shower",Vector3(2,2,-3),2,1)
 game.combat_fx.lightning(Vector3(0,1,-3));game.combat_fx.tick(0.15)
 await capture("particles")
 game.enemies.clear();game.boss_variant="colossus";game.spawn_enemy(8,Vector3(0,0,-12));game.spawn_enemy(9,Vector3(-9,0,-10));game.spawn_enemy(10,Vector3(9,0,-10));game.update_enemies(0);game.frontend.update_hud();await capture("bosses")
 game.enemies.clear();game.boss_variant="sovereign";game.spawn_enemy(8,Vector3(0,0,-10));game.update_enemies(0);game.frontend.update_hud();await capture("sovereign")
 game.frontend.inventory();await capture("build")
 game.frontend.unlocks();await capture("silver")
 game.frontend.shop({"tier":"Legendary","offers":[10,11,12],"sold":[],"used":false});game.gold=1000;await capture("shop")
 game.mode="pause";game.frontend.enter_run();game.frontend.update_hud()
 root.size=Vector2i(1920,1080);await capture("1080p")
 root.size=Vector2i(2560,1440);await capture("1440p")
 game.queue_free();await process_frame;await process_frame;quit()
