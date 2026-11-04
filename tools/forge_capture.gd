extends SceneTree
# Real-render captures of the forging moment into docs/images/fusions/ (xvfb + vulkan llvmpipe).
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/forge_capture.gd [-- weapons=sword,bow fusion=steamforged times=0.6,0.9,1.2,1.5,1.8,2.6]
var out="res://docs/images/fusions/"
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var weapons=["sword","firestaff","lightning_staff","bow","revolver","scythe","aura","shotgun"];var fusion="steamforged";var times=[0.6,0.9,1.2,1.5,1.8,2.6]
 for a in OS.get_cmdline_user_args():
  if a.begins_with("weapons="):weapons=Array(a.substr(8).split(","))
  if a.begins_with("fusion="):fusion=a.substr(7)
  if a.begins_with("times="):times=Array(a.substr(6).split(",")).map(func(x):return float(x))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 var gems=[]
 for k in Fusions.BY_GEMS:if Fusions.BY_GEMS[k]==fusion:gems=k.split("+")
 for key in weapons:
  var cur=[0.0]
  var f=ForgeScene.new().setup(fusion,Array(gems),key,"%s %s"%[Fusions.display_name(fusion),key.capitalize().replace("_"," ")])
  f.time_source=func():return cur[0]
  root.add_child(f)
  var tt=0.0
  for t in times:
   while tt<t:
    tt=minf(tt+1.0/30.0,t);cur[0]=tt;await process_frame
   cur[0]=t;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+"forge_%s_%s_t%03d.png"%[fusion,key,int(t*100)]);print("SHOT ",key," ",t)
  f.queue_free();await create_timer(0.3).timeout
 quit()
