extends SceneTree
func _initialize():call_deferred("run")
func source_transform(node: Node3D) -> Transform3D:
 return source_transform(node.get_parent())*node.transform if node.get_parent() is Node3D else node.transform
func run():
 DirAccess.make_dir_recursive_absolute("res://assets/art_reset/baked")
 var scene=load("res://assets/art_reset/forest/PSX_Forest_AssetCollection_byStarkCrafts.fbx").instantiate()
 var nodes=scene.find_children("*","MeshInstance3D",true,false)
 for node in nodes:
  var imported_transform=source_transform(node)
  var bounds=imported_transform*node.mesh.get_aabb();var factor=1/maxf(0.01,bounds.size.y);var offset=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)
  var result=ArrayMesh.new()
  for i in node.mesh.get_surface_count():
   var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);surface.append_from(node.mesh,i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*factor),offset*factor)*imported_transform);surface.commit(result)
   var material=node.mesh.surface_get_material(i).duplicate() as BaseMaterial3D
   if material.albedo_texture and material.albedo_texture.get_image().detect_alpha()!=Image.ALPHA_NONE:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;material.alpha_scissor_threshold=0.45
   material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=0.95
   result.surface_set_material(i,material)
  var path="res://assets/art_reset/baked/"+str(node.name).strip_edges()+".res"
  if ResourceSaver.save(result,path)!=OK:push_error("Failed baking "+path);quit(1);return
  print("BAKED ",path," ",result.get_aabb())
 scene.free();quit()
