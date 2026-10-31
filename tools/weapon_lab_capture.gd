extends SceneTree
# Real-render capture of all eight weapons through the Weapon Lab. Run under a display (xvfb) with a
# software or real GPU renderer; headless cannot render. Writes PNG frames to docs/images/weapons/.
# usage: xvfb-run -a tools/godot.sh --path . --rendering-driver vulkan --resolution 1280x720 --script tools/weapon_lab_capture.gd [-- only=sword]
var game: Node
var lab: WeaponLab
var out_dir="res://docs/images/weapons/"
var only=""
var cam: Camera3D
func _initialize():call_deferred("run")
func snap(label: String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out_dir+label+".png");print("CAPTURE "+label)
func shot(label: String,view_kind: String="gameplay",look_offset: Vector3=Vector3(0,1.0,-5.0),fov: float=60.0):
 if is_instance_valid(cam):cam.queue_free()
 cam=lab.camera(lab.view(view_kind),game.player.position+look_offset,fov)
 await process_frame
 await snap(label)
func setup_run():
 game.sandbox=true;game.settings.focus_pause=false;game.settings.reduced=false;game.settings.visual_intensity=1;game.settings.numbers=true
 game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause"
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 game.spawn_clock=999;game.settings.invincible=true
 lab=WeaponLab.new(game);lab.hide_hud()
func sequence(label: String,id: int,frames_after_cast: Array,view_kind: String="gameplay",look: Vector3=Vector3(0,1.0,-5.0),fov: float=60.0,dt: float=1.0/60.0):
 lab.until_cast(id,1)
 var last=0
 for f in frames_after_cast:
  lab.step(int(f)-last,dt);last=int(f)
  await shot("%s_f%02d"%[label,int(f)],view_kind,look,fov)
func want(name: String) -> bool:return only=="" or only==name
func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
 for a in OS.get_cmdline_user_args():
  if a.begins_with("only="):only=a.substr(5)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 setup_run()
 await process_frame
 # Every weapon is shown from the same default distances; dummies sit 7-9 m out so effects read at 640x360.
 if want("sword"):
  lab.prepare(0);lab.dummies("arc",7,3.4);lab.step(60)
  await sequence("sword_arc",0,[1,3,5,8,12],"close",Vector3(0,1.0,-3.0),55.0)
  lab.prepare(0,{"count":3.0,"haste":2.0});lab.dummies("arc",9,3.4);lab.step(60)
  await sequence("sword_burst",0,[2,9,16,23,30],"close",Vector3(0,1.0,-3.0),55.0)
 if want("firestaff"):
  lab.prepare(1,{"count":2.0});lab.dummies("cluster",5,9.0);lab.step(60)
  await sequence("fireball",1,[3,8,14,20],"mid",Vector3(0,1.0,-6.0))
  await sequence("fireball_impact",1,[24,26,30,36,44],"side",Vector3(0,1.0,-8.0),50.0)
 if want("lightning"):
  lab.prepare(2,{"count":2.0,"ricochet":3.0});lab.dummies("cluster",9,8.0);lab.step(60)
  await sequence("lightning",2,[0,1,3,6,9,14],"mid",Vector3(0,3.0,-8.0))
 if want("bow"):
  lab.prepare(6,{"count":4.0});lab.dummies("line",5,8.0);lab.step(60)
  await sequence("bow",6,[2,6,10,14],"side",Vector3(0,1.0,-6.0),55.0)
 if want("revolver"):
  lab.prepare(7,{"count":2.0,"ricochet":2.0});lab.dummies("cluster",6,9.0);lab.step(60)
  await sequence("revolver",7,[1,3,6,10,16],"side",Vector3(0,1.0,-6.0),55.0)
 if want("aura"):
  lab.prepare(10);lab.dummies("ring",18,3.5);lab.step(60)
  await shot("aura_idle","gameplay",Vector3(0,0.5,0))
  await sequence("aura_pulse",10,[1,3,6,12],"gameplay",Vector3(0,0.5,0))
 if want("scythes"):
  lab.prepare(9,{"count":2.0});lab.dummies("cluster",5,8.0);lab.step(60)
  await sequence("scythes",9,[6,18,30,45,60,80],"top",Vector3(0,0.0,-4.0),55.0)
 if want("shotgun"):
  for pellets in [0,1,3,6]:
   lab.prepare(15,{"count":float(pellets)});lab.dummies("cluster",7,7.0);lab.step(60)
   await sequence("shotgun_%dpellets"%(6+pellets),15,[2,4],"top",Vector3(0,0.0,-3.0),40.0)
 game.queue_free();await process_frame;await process_frame
 quit(0)
