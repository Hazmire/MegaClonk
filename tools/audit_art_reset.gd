extends SceneTree
func _initialize():call_deferred("run")
func describe(node: Node,world: Transform3D):
 var transform=world*node.transform if node is Node3D else world
 if node is MeshInstance3D and node.mesh:
  var materials=[]
  for i in node.mesh.get_surface_count():
   var material=node.mesh.surface_get_material(i)
   materials.append({"name":material.resource_name if material else "none","texture":material.albedo_texture.resource_path if material is BaseMaterial3D and material.albedo_texture else "none"})
  print("ASSET_MESH ",JSON.stringify({"name":node.name,"bounds":str(transform*node.mesh.get_aabb()),"surfaces":node.mesh.get_surface_count(),"materials":materials}))
 for child in node.get_children():describe(child,transform)
func run():
 for path in ["res://assets/art_reset/portal/Portal_01.fbx","res://assets/art_reset/forest/PSX_Forest_AssetCollection_byStarkCrafts.fbx"]:
  print("ASSET ",path);var scene=load(path).instantiate();describe(scene,Transform3D.IDENTITY);scene.free()
 quit()
