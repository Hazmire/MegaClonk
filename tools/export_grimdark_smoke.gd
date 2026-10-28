extends SceneTree
func _initialize():call_deferred("run")
func require(value: bool,message: String) -> bool:
 if not value:push_error(message);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 if not require(game.player.avatar is KnightVisual and game.player.avatar.rig.get_bone_count()==14,"Compiled supplied Knight rig missing"):return
 if not require(game.grimdark_renderer.viewport.size==Vector2i(640,360) and root.disable_3d,"Compiled low-resolution world renderer missing"):return
 for kind in 8:
  for choice in 2:
   var config=EnemyCatalog.variant(kind,choice);var mesh=BestiaryFrames.mesh(config.visual_model,"enemy_move",2)
   if not require(mesh.get_surface_count()>0 and mesh.surface_get_material(0).shader.resource_path.ends_with("grimdark_surface.gdshader"),"Compiled horror frame/material missing"):return
 for stage_value in [1,2,3]:
  game.stage=stage_value;game.build_stage();game.player.active=false;await process_frame
  if not require(game.portal.has_node("PortalAsset/Ring") and game.portal_wind.guidance.valid,"Compiled supplied portal or red guidance missing"):return
  if not require(game.interactables.all(func(o):return o.node.has_meta("grimdark_kind")),"Compiled supplied interactables missing"):return
  if stage_value==3:
   for key in game.prop_batches:
    if str(key).begins_with("mega_CommonTree"):
     if not require(str(game.prop_batches[key].get_meta("grimdark_source","")).begins_with("dead_tree"),"Compiled Deadlands contains living trees"):return
 game.queue_free();await process_frame;await process_frame
 print("EXPORTED GRIMDARK V13 SMOKE COMPLETE");quit()
