extends SceneTree
func _initialize():call_deferred("run")
func run():
 for id in ["Imp","Puglin"]:
  var scene=load("res://assets/quaternius/bestiary/"+id+".glb").instantiate();root.add_child(scene);await process_frame
  var rig=scene.get_node("Armature/Skeleton3D")
  var player=AnimationPlayer.new();scene.add_child(player);player.add_animation_library("",RigClips.library(rig,id));player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  var bounds=AABB();var first=true
  for mesh in scene.find_children("*","MeshInstance3D",true,false):
   bounds=mesh.get_aabb() if first else bounds.merge(mesh.get_aabb());first=false
  var scale_value=(1.25 if id=="Puglin" else 1.8)/bounds.size.y
  for state in ["enemy_idle","enemy_move"]:
   for frame in (2 if state=="enemy_idle" else 8):
    rig.reset_bone_poses();player.play(state);player.seek(player.get_animation(state).length*frame/(2 if state=="enemy_idle" else 8),true);player.advance(0)
    rig.force_update_all_bone_transforms()
    var result=ArrayMesh.new()
    for mesh in scene.find_children("*","MeshInstance3D",true,false):
     var transforms=[]
     for bind in mesh.skin.get_bind_count():
      var bone=rig.find_bone(mesh.skin.get_bind_name(bind))
      if bone<0:bone=mesh.skin.get_bind_bone(bind)
      transforms.append(rig.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind))
     for surface in mesh.mesh.get_surface_count():
      var arrays=mesh.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var uv=arrays[Mesh.ARRAY_TEX_UV];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS];var indices=arrays[Mesh.ARRAY_INDEX]
      var posed=PackedVector3Array();var posed_normals=PackedVector3Array();var per_vertex=int(bones.size()/vertices.size())
      for v in vertices.size():
       var point=Vector3.ZERO;var normal=Vector3.ZERO
       for weight in per_vertex:
        var k=v*per_vertex+weight
        if weights[k]>0:
         var transform=transforms[bones[k]];point+=(transform*vertices[v])*weights[k];normal+=(transform.basis*normals[v])*weights[k]
       posed.append((point-Vector3(0,bounds.position.y,0))*scale_value);posed_normals.append(normal.normalized())
      var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(mesh.mesh.surface_get_material(surface))
      for index in indices:
       tool.set_normal(posed_normals[index]);tool.set_uv(uv[index]);tool.add_vertex(posed[index])
      tool.index();tool.commit(result)
    var path="res://assets/quaternius/baked/%s_%s_%d.res"%[id,state,frame]
    var err=ResourceSaver.save(result,path,ResourceSaver.FLAG_COMPRESS)
    print("BAKED ",path," ",err," surfaces=",result.get_surface_count())
  scene.queue_free();await process_frame
 RigClips.reset();quit()
