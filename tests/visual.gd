extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await create_timer(1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/workspace/MegaClonk/builds/menu.png")
 game.sandbox=true
 game.begin_run()
 game.settings.invincible=true
 for i in 70: game.spawn_enemy()
 await create_timer(2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/workspace/MegaClonk/builds/gameplay.png")
 for biome in [1,2]:
  game.biome=biome
  game.build_stage()
  game.resume()
  await create_timer(0.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/workspace/MegaClonk/builds/biome_%d.png"%biome)
 game.show_upgrades()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/workspace/MegaClonk/builds/upgrades.png")
 game.pause_menu()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/workspace/MegaClonk/builds/pause.png")
 game.queue_free()
 await create_timer(0.15).timeout
 quit()
