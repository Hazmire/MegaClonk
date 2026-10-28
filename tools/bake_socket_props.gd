extends SceneTree
# Bakes only the models added for breakable vases (and later the Imbue Station) into unit-height
# meshes under assets/grimdark/baked/props, using the same ImportedArt pipeline as
# bake_grimdark.gd. Kept separate so existing baked assets are never regenerated.
const MODELS=["stone_square_half_1m","wood_support_metal_ring"] # terracotta vases were baked in the previous step
func _initialize():call_deferred("run")
func run():
 for id in MODELS:
  var mesh=ImportedArt.mesh("res://assets/grimdark/medieval/"+id+".glb",1)
  var path="res://assets/grimdark/baked/props/"+id+".res"
  DirAccess.make_dir_recursive_absolute(path.get_base_dir())
  var result=ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
  print("BAKE ",id," ",mesh.get_aabb()," surfaces=",mesh.get_surface_count()," result=",result)
 print("SOCKET PROPS BAKE COMPLETE")
 quit()
