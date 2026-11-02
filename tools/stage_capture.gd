extends SceneTree
# Real-render capture of the four stage dressings at 1920x1080 into docs/images/stages/ (Forward+ / llvmpipe under xvfb).
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/stage_capture.gd [-- only=1,2 shots=A,B,C]
var game: Node3D
var out="res://docs/images/stages/"
func _initialize() -> void:call_deferred("run")
func snap(label: String,wait: float=0.5) -> void:
 await create_timer(wait).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func look(position: Vector3,yaw: float,pitch: float) -> void:
 game.player.position=position;game.player.velocity=Vector3.ZERO;game.player.yaw=yaw;game.player.pitch=pitch;game.player.arm.rotation=Vector3(pitch,yaw,0)
func highest() -> Vector3:
 var best=Vector3(0,-1,0)
 for x in range(-80,81,4):
  for z in range(-80,81,4):
   var h=game.terrain_height(x,z)
   if h>best.y+0.01 or (absf(h-best.y)<=0.01 and Vector2(x,z).length()>Vector2(best.x,best.z).length()):best=Vector3(x,h,z)
 return best
var black_failures=0
# The lowest flat terrain cell nearest the north edge with 12 m of the same level behind it (the reference's shot == "low").
func lowest_spot() -> Vector3:
 var lowest=INF
 for x in range(-90,91,4):
  for z in range(-94,-40,4):lowest=minf(lowest,game.terrain_height(x,z))
 for z in range(-94,-40,2):
  for x in range(-82,83,2):
   var ok=true
   for dz in range(0,14,2):
    for dx in [-4,0,4]:ok=ok and is_equal_approx(game.terrain_height(x+dx,z+dz),lowest)
   if ok:return Vector3(x,lowest,z)
 return Vector3(0,lowest,-90)
# The void is a band of pure black across the frame just below the horizon. Dark silhouettes (the stage 4 backdrop art and timbers contain true black)
# are fine, so a row fails only when more than 0.5% of its pixels are pure black; the total is reported too.
func black_band(image: Image,label: String) -> void:
 var w=image.get_width();var h=image.get_height();var count=0;var worst=0.0
 for y in range(int(h*0.50),int(h*0.60),2):
  var row=0;var samples=0
  for x in range(0,w,2):
   var c=image.get_pixel(x,y);samples+=1
   if c.r8<=2 and c.g8<=2 and c.b8<=2:row+=1
  count+=row;worst=maxf(worst,float(row)/float(samples))
 print("BLACKBAND %s count=%d worst_row=%.1f%%"%[label,count,worst*100.0])
 if worst>0.005:black_failures+=1
func run() -> void:
 var stages=[1,2,3,4];var shots=["A","B","C","D"]
 for a in OS.get_cmdline_user_args():
  if a.begins_with("only="):stages=Array(a.substr(5).split(",")).map(func(v):return int(v))
  if a.begins_with("shots="):shots=Array(a.substr(6).split(","))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://stage-capture.json"
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.resume();game.settings.invincible=true;game.spawn_clock=999
 for s in stages:
  game.stage=s;game.build_stage();game.resume();game.spawn_clock=999;game.enemies.clear()
  game.set_physics_process(false);game.player.active=false
  await create_timer(0.8).timeout
  if "B" in shots:
   game.frontend.update_hud();look(game.map_layout.spawn+Vector3(0,0.5,0),0.0,-0.35);await snap("stage%d_B_gameplay"%s,1.2)
  game.frontend.run_hud.visible=false
  if "A" in shots:
   var p=Vector3(6,game.terrain_height(6,-80)+0.6,-80);look(p,-0.05,0.12);await snap("stage%d_A_edge"%s,1.2)
  if "D" in shots:
   var lp=lowest_spot();game.player.avatar.visible=false;look(lp+Vector3(0,0.1,12.0),0.0,0.03);await snap("stage%d_D_lowest"%s,1.2)
   black_band(root.get_texture().get_image(),"stage%d"%s);game.player.avatar.visible=true
  if "C" in shots:
   var top=highest();var yaw=atan2(-top.x,-top.z) if false else 0.0
   # look outward from the plateau toward the nearest border
   var dir=Vector3(top.x,0,top.z).normalized();if dir.length()<0.1:dir=Vector3(0,0,-1)
   yaw=atan2(-dir.x,-dir.z);look(top+Vector3(0,0.6,0),yaw,0.05);await snap("stage%d_C_plateau"%s,1.2)
  game.frontend.run_hud.visible=true
 quit(1 if black_failures>0 else 0)
