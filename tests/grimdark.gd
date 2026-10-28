extends SceneTree
var failures=[]
var count=0
func verify(value: bool,message: String):
 count+=1
 if not value:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause"
 verify(game.player.avatar is KnightVisual,"Supplied Knight is the runtime player")
 verify(game.grimdark_renderer.viewport.size==Vector2i(640,360),"Default world renders at 640x360")
 verify(root.disable_3d and game.grimdark_renderer.viewport.world_3d==root.world_3d,"World shares physics but renders only once")
 verify(not game.grimdark_renderer.viewport.audio_listener_enable_3d,"Retro viewport does not duplicate positional audio")
 for model in BestiaryFrames.SOURCES:
  for state in ["enemy_idle","enemy_move"]:
   var mesh=BestiaryFrames.mesh(model,state,0)
   verify(mesh!=null and mesh.get_aabb().size.y>1.0,"Usable grounded frame "+model+state)
   verify(mesh.surface_get_material(0).shader==preload("res://shaders/grimdark_surface.gdshader"),"Supplied textured PSX shader "+model)
 for seed_value in 20:
  for stage_value in [1,2,3]:
   game.map_seed_override=seed_value;game.stage=stage_value;game.build_stage();game.mode="pause";game.player.active=false;await process_frame
   verify(game.forest_navigation.reachable(game.map_layout.portal),"Portal reachable %d/%d"%[seed_value,stage_value])
   for p in game.map_layout.pois:verify(game.forest_navigation.reachable(p),"POI reachable %d/%d"%[seed_value,stage_value])
   verify(game.portal_wind.guidance.valid,"Red guidance valid %d/%d"%[seed_value,stage_value])
   for key in game.prop_batches:
    var node=game.prop_batches[key]
    if str(key).begins_with("mega_CommonTree"):
     var source=str(node.get_meta("grimdark_source",""))
     verify(source!="","Tree has supplied source")
     if stage_value==3:verify(source.begins_with("dead_tree"),"Deadlands uses exclusively dead tree geometry")
    if stage_value==3:verify(not str(key).begins_with("wind_grass"),"Deadlands has no healthy grass batches")
   for object in game.interactables:verify(object.node.has_meta("grimdark_kind"),"Interactable uses supplied scenery: "+object.kind)
   verify(game.portal.has_node("PortalAsset/Ring"),"Supplied arch and rune portal load")
   print("GRIMDARK SEED ",seed_value," STAGE ",stage_value," OK")
 game.queue_free();await process_frame;await process_frame
 print("GRIMDARK RESULT: ",count," checks, ",failures.size()," failures, 20 seeds x 3 stages")
 quit(0 if failures.is_empty() else 1)
