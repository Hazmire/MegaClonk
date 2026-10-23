extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/"+name+".png")
func run() -> void:
 var game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await create_timer(0.5).timeout
 await capture("overhaul_menu")
 game.sandbox=true; game.next_run_seed=500; game.begin_run()
 game.settings.invincible=true; game.settings.focus_pause=false
 game.spawn_clock=999
 game.player.position=Vector3(0,1,0)
 game.player.yaw=PI
 game.player.pitch=-0.35
 game.player.zoom=8
 await create_timer(0.5).timeout
 game.mode="pause"; game.player.active=false
 # Gallery at ground level. Camera faces +Z, revealing faces and silhouettes.
 game.player.position=Vector3(0,0,-12)
 game.player.arm.rotation=Vector3(-0.2,PI,0)
 game.player.arm.spring_length=11
 game.player.avatar.hide()
 for kind in 8:
  for choice in 2:
   game.variants.selections[kind]=choice
   var e=game.spawn_enemy(kind,Vector3((kind%4)*4.5-6.75,0,(kind/4)*7+choice*3.0+2))
   e.pos.y=game.terrain_height(e.pos.x,e.pos.z)+0.65
   e.age=1.2+kind
 game.update_enemies(0.001)
 await create_timer(0.3).timeout
 await capture("overhaul_enemy_gallery")
 game.enemies.clear(); game.enemy_view.begin_frame(); game.enemy_view.end_frame()
 game.player.avatar.show()
 game.player.position=Vector3(0,0,0)
 game.player.arm.rotation=Vector3(-0.25,PI,0)
 game.player.arm.spring_length=5
 for pose in ["idle","run","crouch","slide","jump"]:
  for i in 12: game.player.avatar.animate(pose,8,0.016)
  await capture("overhaul_player_"+pose)
 game.player.zoom=12
 game.player.yaw=0
 game.player.pitch=-0.4
 game.mode="run"; game.player.active=true
 game.weapons.clear()
 for id in [1,6,31,35]: game.equip(id)
 for i in 60: game.spawn_enemy(i%8)
 await create_timer(1.0).timeout
 await capture("overhaul_combat")
 game.queue_free()
 await create_timer(0.15).timeout
 quit()
