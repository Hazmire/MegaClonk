extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/rewards-v9/"+name+".png");print("CAPTURE "+name)
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/rewards-v9")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.invincible=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 game.weapons.clear()
 for id in [0,1,6,7]:game.equip(id);game.weapons[id].level=3
 for id in ["Might","Haste","Wisdom","Wind"]:game.apply_upgrade({"type":"tome","id":id})
 for id in ["whetstone","salted_pork","knucklebone","rusted_key","coven_sigil","tax_ledger"]:game.grant_item(id,true)
 game.gold=245;game.level=12;game.elapsed=149;game.health=83
 var rng=RandomNumberGenerator.new();rng.seed=327
 var normal={"choices":ShrineRewards.generate(game.stats,rng),"golden":false}
 var golden={"choices":ShrineRewards.generate(game.stats,rng,true),"golden":true}
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;DisplayServer.window_set_size(size);var suffix="_"+str(size.x)
  game.mode="run";game.frontend.enter_run();game.player.active=false;game.update_hud()
  if is_instance_valid(game.frontend.stage_banner):game.frontend.stage_banner.hide()
  await create_timer(0.5).timeout;await capture("hud"+suffix)
  game.active_shrine_reward=normal;RewardScreens.shrine(game.frontend,normal);await create_timer(0.4).timeout;await capture("shrine"+suffix)
  game.active_shrine_reward=golden;RewardScreens.shrine(game.frontend,golden);await create_timer(0.4).timeout;await capture("golden"+suffix)
  game.active_shrine_reward={};game.frontend.reward("hourglass_damned");await create_timer(0.5).timeout
  if size.x==1280:await capture("icon_cycling")
  game.frontend.chest_skip.call();await create_timer(0.2).timeout;await capture("chest"+suffix)
 root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
 game.frontend.upgrades();await create_timer(5).timeout;await capture("levelup_persistent")
 game.active_shrine_reward={};game.shrine_reward_queue.clear();game.mode="run";game.frontend.enter_run();game.player.active=false
 var shrine={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object;break
 shrine.golden=true;game.player.position=shrine.node.position;ShrineCharging.tick(game,shrine,0,4)
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=shrine.node.position+Vector3(-signf(shrine.node.position.x)*8,5,-signf(shrine.node.position.z)*10);camera.look_at(shrine.node.position+Vector3.UP*1.4);camera.current=true;game.frontend.hud_root.hide();game.notice.hide();await create_timer(0.5).timeout;await capture("golden_world")
 game.queue_free();await process_frame;await process_frame;quit()
