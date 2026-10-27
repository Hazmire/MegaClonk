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
 game.sandbox=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 check(game.announced_stages==[1] and is_instance_valid(game.frontend.stage_banner),"Stage one announces on new run")
 var first=game.frontend.stage_banner;game.show_stage_intro();check(first==game.frontend.stage_banner,"Repeated stage announcement is suppressed")
 var names=[];var palettes=[]
 for number in [1,2,3,4]:
  game.stage=number;game.build_stage();await process_frame
  var theme=StageThemes.config(number);names.append(theme.title);palettes.append(theme.moss_high)
  check(ForestAtmosphere.floor_material().get_shader_parameter("moss_high")==theme.moss_high,"Ground palette applies to stage "+str(number))
  check(ForestAtmosphere.grass_material().get_shader_parameter("color_gradient")==StageThemes.gradient(number),"Grass gradient applies to stage "+str(number))
  var env=game.world.get_child(0).environment
  check(env.fog_light_color==theme.fog and env.ambient_light_color==theme.ambient,"Sky/fog/light palette applies to stage "+str(number))
  var trees=game.prop_batches.get("mega_CommonTree_1")
  if number in [2,3] and trees!=null:
   var material=trees.multimesh.mesh.surface_get_material(0)
   check(material is ShaderMaterial and material.get_shader_parameter("foliage")==theme.foliage,"Actual tree material recolours foliage in stage "+str(number))
  var base=ImportedArt.mesh(ForestWorld.NATURE+"CommonTree_1.gltf",7.5,7)
  check(StageThemes.decor(base,number)==StageThemes.decor(base,number),"Stage decoration materials/meshes are reused")
 check(names[0]=="GREEN FOREST" and names[1]=="VIOLET FOREST" and names[2]=="CRIMSON FOREST" and names[3]==names[0],"Green/violet/crimson themes explicitly cycle after stage three")
 check(palettes[0]!=palettes[1] and palettes[1]!=palettes[2],"Stages change world materials rather than a screen overlay")
 game.stage=2;game.build_stage();game.show_stage_intro();check(game.announced_stages==[1,2],"New stage announces once")
 check(game.save_run("user://themes-test.json") and game.load_run("user://themes-test.json"),"Themed run saves and loads")
 var banner=game.frontend.stage_banner;game.build_stage();check(game.frontend.stage_banner==banner,"Stage rebuild does not replay introduction")
 game.world_content_version=0;game.stage=1;game.build_stage();game.player.active=false
 var digest=hash(str(game.map_layout.pois)+str(game.map_layout.elite));game.save_run("user://legacy-world-content.json")
 var data=JSON.parse_string(FileAccess.get_file_as_string("user://legacy-world-content.json"));data.erase("world_content_version");data.erase("additional_boss_count");data.erase("announced_stages")
 var file=FileAccess.open("user://legacy-world-content.json",FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 check(game.load_run("user://legacy-world-content.json") and game.world_content_version==0 and game.map_layout.pois.size()==12 and hash(str(game.map_layout.pois)+str(game.map_layout.elite))==digest,"Pre-update saves keep exact active-stage object layout")
 game.boss_dead=true;game.portal_state="exit"
 check(game.advance_stage() and game.world_content_version==1 and game.map_layout.poi_kinds.count("Chest")>=15,"Legacy runs adopt new object guarantees on the next stage")
 game.queue_free();await process_frame;await process_frame
 print("STAGE THEMES: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
