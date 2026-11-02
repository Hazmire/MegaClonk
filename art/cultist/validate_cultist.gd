extends SceneTree
var failures: Array[String]=[]
func check(value: bool,message: String):
 if not value:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var path="res://assets/characters/cultist/RiftCultist.glb"
 if not ResourceLoader.exists(path):path="res://RiftCultist.glb"
 var packed=load(path) as PackedScene
 if packed==null:push_error("Cultist GLB did not import");quit(1);return
 var model=packed.instantiate();root.add_child(model);await process_frame
 var rigs=model.find_children("*","Skeleton3D",true,false)
 var players=model.find_children("*","AnimationPlayer",true,false)
 var meshes=model.find_children("*","MeshInstance3D",true,false)
 if rigs.size()!=1 or players.size()!=1 or meshes.size()!=1:
  push_error("Expected one rig, player and skinned mesh");quit(1);return
 var rig=rigs[0] as Skeleton3D;var player=players[0] as AnimationPlayer;var mesh=meshes[0] as MeshInstance3D
 check(rig.get_bone_count()==28 and mesh.skin!=null,"Cultist skeleton/skin missing")
 check(mesh.mesh.get_surface_count()==9,"Cultist material surfaces missing")
 var triangles=0;var textures=0
 for surface in mesh.mesh.get_surface_count():
  var arrays=mesh.mesh.surface_get_arrays(surface)
  triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
  check(arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_NORMAL].size(),"Normals missing")
  check(arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_TEX_UV].size(),"UVs missing")
  check(arrays[Mesh.ARRAY_BONES].size()>0 and arrays[Mesh.ARRAY_WEIGHTS].size()>0,"Skin data missing")
  var mat=mesh.mesh.surface_get_material(surface) as BaseMaterial3D
  if mat!=null and mat.albedo_texture!=null:
   textures+=1;check(mat.albedo_texture.get_width()==512 and mat.albedo_texture.get_height()==512,"Embedded texture resolution changed")
 check(textures==2,"Both cloth textures must survive import")
 player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 var clips={}
 for clip in ["Idle","Walk","Attack"]:
  check(player.has_animation(clip),"Missing clip "+clip)
  if not player.has_animation(clip):continue
  var animation=player.get_animation(clip)
  player.play(clip);player.seek(0,true);player.advance(0);rig.force_update_all_bone_transforms()
  var rest=[]
  for bone in rig.get_bone_count():rest.append(rig.get_bone_pose(bone))
  var start=rig.get_bone_global_pose(rig.find_bone("Root"))
  player.seek(animation.length*.4,true);player.advance(0);rig.force_update_all_bone_transforms()
  var moved=false
  for bone in rig.get_bone_count():
   check(rig.get_bone_pose(bone).is_finite(),"Non-finite animation transform")
   if not rig.get_bone_pose(bone).is_equal_approx(rest[bone]):moved=true
  check(moved,"Clip does not animate the imported skeleton: "+clip)
  check(start.is_equal_approx(rig.get_bone_global_pose(rig.find_bone("Root"))),"Root motion should remain stationary")
  clips[clip]={"duration_seconds":animation.length,"tracks":animation.get_track_count(),"deforms_skeleton":moved}
 var report={"engine":Engine.get_version_info().string,"checks":"passed" if failures.is_empty() else "failed","triangles":triangles,"bones":rig.get_bone_count(),"materials":mesh.mesh.get_surface_count(),"embedded_cloth_textures":textures,"clips":clips,"failures":failures}
 var out="res://assets/characters/cultist/godot_validation.json" if path.begins_with("res://assets/") else "res://godot_validation.json"
 var file=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n")
 print("CULTIST_IMPORT_VALIDATED ",JSON.stringify(report))
 model.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
