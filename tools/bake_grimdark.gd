extends SceneTree
func _initialize():call_deferred("run")
func save(mesh: Mesh,name: String):
 var path="res://assets/grimdark/baked/"+name+".res";DirAccess.make_dir_recursive_absolute(path.get_base_dir());ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS);print("BAKE ",name," ",mesh.get_aabb())
func posed_mesh(node: MeshInstance3D) -> ArrayMesh:
 if node.skin==null:return node.mesh
 var rig=node.get_node(node.skeleton) as Skeleton3D;rig.force_update_all_bone_transforms();var transforms=[]
 for i in node.skin.get_bind_count():
  var bone=rig.find_bone(node.skin.get_bind_name(i))
  if bone<0:bone=node.skin.get_bind_bone(i)
  transforms.append(rig.get_bone_global_pose(bone)*node.skin.get_bind_pose(i))
 var result=ArrayMesh.new()
 for surface in node.mesh.get_surface_count():
  var arrays=node.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS];var per_vertex=int(bones.size()/vertices.size());var posed=PackedVector3Array();var posed_normals=PackedVector3Array()
  for v in vertices.size():
   var point=Vector3.ZERO;var normal=Vector3.ZERO
   for j in per_vertex:
    var k=v*per_vertex+j
    if weights[k]>0:point+=(transforms[bones[k]]*vertices[v])*weights[k];normal+=(transforms[bones[k]].basis*normals[v])*weights[k]
   posed.append(point);posed_normals.append(normal.normalized())
  arrays[Mesh.ARRAY_VERTEX]=posed;arrays[Mesh.ARRAY_NORMAL]=posed_normals;arrays[Mesh.ARRAY_BONES]=null;arrays[Mesh.ARRAY_WEIGHTS]=null
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);result.surface_set_material(surface,node.mesh.surface_get_material(surface))
 return result
func part(node: MeshInstance3D) -> ArrayMesh:
 var box=node.global_transform*node.mesh.get_aabb();var factor=1.0/maxf(.001,box.size.y);var offset=Vector3(-box.get_center().x,-box.position.y,-box.get_center().z)*factor
 var normalizer=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*factor),offset);var result=ArrayMesh.new()
 for surface in node.mesh.get_surface_count():
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.append_from(node.mesh,surface,normalizer*node.global_transform);st.set_material(node.mesh.surface_get_material(surface));st.commit(result)
 return result
func animated(base: Mesh,height: float,state: String,frame: int) -> ArrayMesh:
 var result=ArrayMesh.new();var phase=TAU*(frame+0.5 if state=="enemy_move" else frame)/(8 if state=="enemy_move" else 2)
 for surface in base.get_surface_count():
  var arrays=base.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX]
  for i in vertices.size():
   var p=vertices[i];p*=height
   if state=="enemy_move":
    var leg=1 if p.x>=0 else -1;var weight=clampf(1-p.y/(height*.55),0,1);p.z+=sin(phase)*leg*.15*weight;p.y+=maxf(0,sin(phase)*leg)*.08*weight+absf(sin(phase))*.012
   else:
    var weight=clampf((p.y/height-.45)*2,0,1);p.x*=1+cos(phase)*.012*weight;p.y+=cos(phase)*.008*weight
   vertices[i]=p
  arrays[Mesh.ARRAY_VERTEX]=vertices;result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);result.surface_set_material(surface,base.surface_get_material(surface))
 return result
func run():
 for pair in [["forest","res://assets/grimdark/horror/PS1_ForestAsset/PS1_NaturAssetCollection.fbx"],["palace","res://assets/grimdark/horror/PS1_Palast_Assets/PS1_PalastAssetCollection.fbx"]]:
  var scene=load(pair[1]).instantiate();root.add_child(scene);await process_frame
  for node in scene.find_children("*","MeshInstance3D",true,false):
   if node.mesh:save(part(node),"props/"+pair[0]+"_"+str(node.name))
  scene.queue_free();await process_frame
 for folder in ["trees","medieval"]:
  for file in DirAccess.get_files_at("res://assets/grimdark/"+folder):
   if not file.ends_with(".glb"):continue
   save(ImportedArt.mesh("res://assets/grimdark/"+folder+"/"+file,1),"props/"+file.get_basename())
 for id in ["PS1_Skull","PS1_Skeleton","ps1_Sword"]:
  var scene=load("res://assets/grimdark/horror/PS1_Skull/"+id+".fbx").instantiate();root.add_child(scene);await process_frame
  var node=scene.find_children("*","MeshInstance3D",true,false)[0];node.mesh=posed_mesh(node);save(part(node),"props/"+id);scene.queue_free();await process_frame
 for file in DirAccess.get_files_at("res://assets/grimdark/characters"):
  if not file.ends_with(".fbx"):continue
  var id=file.get_basename();var scene=load("res://assets/grimdark/characters/"+file).instantiate();root.add_child(scene);await process_frame
  var node=scene.find_children("*","MeshInstance3D",true,false)[0]
  if node.skin==null:node.rotate_y(-PI/2)
  node.mesh=posed_mesh(node);var base=part(node)
  for state in ["enemy_idle","enemy_move"]:
   for frame in (2 if state=="enemy_idle" else 8):save(animated(base,1.8,state,frame),"enemies/"+id+"_"+state+"_"+str(frame))
  scene.queue_free();await process_frame
 print("GRIMDARK BAKE COMPLETE");quit()
