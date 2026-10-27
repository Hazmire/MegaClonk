class_name WeaponArt
extends RefCounted
static var cache: Dictionary={}
static func mesh(kind: String) -> Mesh:
 if cache.has(kind):return cache[kind]
 if kind=="stone":
  var rock=ImportedArt.mesh("res://assets/quaternius/nature/Rock_Medium_1.gltf",2.4,3.0)
  var result=ArrayMesh.new();var shift=Transform3D(Basis.IDENTITY,-rock.get_aabb().get_center())
  for surface in rock.get_surface_count():
   var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.append_from(rock,surface,shift);tool.set_material(rock.surface_get_material(surface));tool.commit(result)
  cache[kind]=result;return result
 var parts=[]
 match kind:
  "shield":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.9,0.18,0.9),Vector3.ZERO,"526d86",Vector3(PI/2,0,0)),ModelBuilder.part(ModelBuilder.cube(Vector3(0.12,1.3,0.1)),Vector3(0,0,0.13),"e5c975"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.9,0.12,0.1)),Vector3(0,0.15,0.14),"e5c975")]
  "blade","wave","dagger":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.22,1.5,0),Vector3(0,0,-0.4),"c7fbf2",Vector3(-PI/2,0,0)),ModelBuilder.part(ModelBuilder.cube(Vector3(0.65,0.1,0.12)),Vector3(0,0,0.4),"568b9f"),ModelBuilder.part(ModelBuilder.cone(0.08,0.4,0.08),Vector3(0,0,0.65),"6b5344",Vector3(PI/2,0,0))]
  "bullet","scatter":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.055,0.42,0.025),Vector3.ZERO,"d8b35e",Vector3(PI/2,0,0))]
  "bounce":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.1,0.8,0.1),Vector3.ZERO,"e5d9b9",Vector3(PI/2,0,0))]
   for z in [-0.4,0.4]:
    for x in [-0.08,0.08]:parts.append(ModelBuilder.part(ModelBuilder.cone(0.14,0.18,0.14),Vector3(x,0,z),"f3e8d0"))
  "return":
   for i in 5:parts.append(ModelBuilder.part(ModelBuilder.cone(0.14,0.35,0.12),Vector3(sin(i*0.35)*0.55,0,(i-2)*0.26),"ebcc36",Vector3(PI/2,0,i*0.35)))
  "lob":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.055,1.2,0.055),Vector3(0,-0.3,0),"946643"),ModelBuilder.part(ModelBuilder.cone(0.5,0.15,0.1),Vector3(0.2,0.3,0),"c4cfce",Vector3(0,0,PI/2))]
  "dice":
   parts=[ModelBuilder.part(ModelBuilder.cube(Vector3(0.5,0.5,0.5)),Vector3.ZERO,"efe9d8")]
   for x in [-0.14,0.14]:parts.append(ModelBuilder.part(ModelBuilder.cone(0.05,0.03,0.05),Vector3(x,0.265,0.14),"252637"))
 var result=ModelBuilder.bake(parts);result.surface_set_material(0,ModelBuilder.material());cache[kind]=result;return result
