class_name ImportedArt
extends RefCounted
static var cache: Dictionary={}
static func collect(node: Node3D, transform: Transform3D, parts: Array) -> void:
 var next=transform*node.transform
 if node is MeshInstance3D and node.mesh:parts.append({"mesh":node.mesh,"transform":next})
 for child in node.get_children():
  if child is Node3D:collect(child,next,parts)
static func mesh(path: String, height: float, max_width: float=1000) -> ArrayMesh:
 var key=path+str(height)+str(max_width)
 if cache.has(key):return cache[key]
 var resource=load(path);var parts=[]
 if resource is PackedScene:
  var scene=resource.instantiate();collect(scene,Transform3D.IDENTITY,parts);scene.free()
 elif resource is Mesh:parts.append({"mesh":resource,"transform":Transform3D.IDENTITY})
 var bounds=AABB();var first=true
 for p in parts:
  var b=p.transform*p.mesh.get_aabb()
  bounds=b if first else bounds.merge(b);first=false
 var scale_factor=minf(height/maxf(0.01,bounds.size.y),max_width/maxf(bounds.size.x,bounds.size.z))
 var offset=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)
 var normalize=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_factor),offset*scale_factor)
 var result=ArrayMesh.new()
 for p in parts:
  for surface in p.mesh.get_surface_count():
   var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.append_from(p.mesh,surface,normalize*p.transform);tool.commit(result)
   result.surface_set_material(result.get_surface_count()-1,p.mesh.surface_get_material(surface))
 cache[key]=result;return result
