extends SceneTree
func _initialize():call_deferred("run")
func require(value: bool,message: String) -> bool:
 if not value:push_error(message);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.reduced=false;game.settings.visual_intensity=1;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 game.add_xp_drop(game.player.position+Vector3(20,1,0),1);game.pickups[0].age=100;game.update_pickups(0.1)
 if not require(not game.pickups[0].get("attracted",false),"Compiled XP attracted outside range"):return
 var rng=RandomNumberGenerator.new();rng.seed=981
 game.active_shrine_reward={"choices":ShrineRewards.generate(game.stats,rng,true),"golden":true}
 RewardScreens.shrine(game.frontend,game.active_shrine_reward);await process_frame
 if not require(game.active_shrine_reward.choices.size()==3 and game.active_shrine_reward.choices.all(func(c):return c.rarity=="legendary"),"Compiled Golden Shrine choices lost Legendary guarantee"):return
 var fixed=JSON.stringify(game.active_shrine_reward)
 game.save_run("user://export-v9.json");game.load_run("user://export-v9.json");await process_frame
 if not require(JSON.stringify(game.active_shrine_reward)==fixed,"Compiled shrine choices rerolled on load"):return
 var choice=game.active_shrine_reward.choices[0];var before=float(game.stats[choice.stat]);ShrineRewards.select(game,0)
 if not require(is_equal_approx(float(game.stats[choice.stat])-before,float(choice.amount)),"Compiled stat card applied a different amount"):return
 game.frontend.reward(Catalog.ITEMS[10]);await process_frame;var image: TextureRect;var effect: RewardCelebration
 for node in RewardScreens.descendants(game.frontend.menu):
  if node.name=="CyclingIcon":image=node
  if node is RewardCelebration and node.confetti:effect=node
 if not require(image!=null and effect!=null,"Compiled cycling icon/continuous celebration missing"):return
 effect._process(15)
 if not require(effect.is_processing() and effect.particles.size()>0,"Compiled confetti ended before screen closed"):return
 var count=game.items.size();game.frontend.chest_skip.call()
 if not require(image.texture==UIAssets.icon("items","10") and game.items.size()==count,"Compiled reveal mismatched or granted another item"):return
 game.resume();game.tomes={"Wind":2};game.update_hud();await process_frame
 var row=game.frontend.loadout_icons.get_node("EquippedItems")
 if not require(row.get_node("Weapons").get_child_count()==game.weapons.size() and row.get_node("Tomes").get_child_count()==game.tomes.size(),"Compiled HUD contains empty or missing equipment"):return
 game.player.camera.current=true;game.player.camera.global_rotation=Vector3(-0.7,0.8,0);game.player.avatar.rotation.y=-1
 var forward=-game.player.camera.global_basis.z
 if not require(game.frontend.minimap.camera_facing().distance_to(Vector2(forward.x,forward.z).normalized())<0.001,"Compiled minimap does not face camera"):return
 game.queue_free();await process_frame;await process_frame
 print("EXPORTED REWARDS AI V9 SMOKE COMPLETE");quit()
