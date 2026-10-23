class_name ModelBuilder
extends RefCounted

static func cube(size: Vector3) -> BoxMesh:
 var m=BoxMesh.new(); m.size=size; return m
static func cone(radius: float, height: float, top: float = 0) -> CylinderMesh:
 var m=CylinderMesh.new(); m.bottom_radius=radius; m.top_radius=top; m.height=height; m.radial_segments=6; return m
static func part(mesh: Mesh, pos: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> Dictionary:
 return {"mesh":mesh,"transform":Transform3D(Basis.from_euler(rotation),pos),"color":Color(color)}
static func bake(parts: Array) -> ArrayMesh:
 var tool=SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for p in parts:
  var arrays=p.mesh.surface_get_arrays(0)
  var vertices=arrays[Mesh.ARRAY_VERTEX]
  var normals=arrays[Mesh.ARRAY_NORMAL]
  var indices=arrays[Mesh.ARRAY_INDEX]
  if indices.is_empty(): indices=range(vertices.size())
  for i in indices:
   tool.set_color(p.color)
   tool.set_normal(p.transform.basis*normals[i])
   tool.add_vertex(p.transform*vertices[i])
 return tool.commit()
static func material() -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.vertex_color_use_as_albedo=true
 m.roughness=0.85
 return m
static func node(parent: Node3D, name: String, parts: Array, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
 var n=MeshInstance3D.new()
 n.name=name; n.mesh=bake(parts); n.material_override=material(); n.position=pos
 parent.add_child(n)
 return n
static func enemy_parts(id: String) -> Array:
 var parts: Array=[]
 match id:
  "goblin","skeleton","archer","knight":
   var color={"goblin":"73a34d","skeleton":"ddd5b1","archer":"4b805c","knight":"464464"}[id]
   parts=[part(cube(Vector3(0.6,0.7,0.38)),Vector3(0,0.95,0),color),part(cube(Vector3(0.5,0.45,0.4)),Vector3(0,1.54,0),color)]
   for side in [-1,1]:
    if id=="goblin": parts.append(part(cone(0.19,0.42),Vector3(side*0.34,1.6,0),color,Vector3(0,0,side*-1.0)))
    parts.append(part(cube(Vector3(0.1,0.1,0.04)),Vector3(side*0.12,1.58,0.22),"ffdc76"))
   for side in [-1,1]:
    parts.append(part(cube(Vector3(0.18,0.65,0.22)),Vector3(side*0.43,1.0,0),color,Vector3(0,0,side*0.16)))
   if id=="skeleton":
    parts[0]=part(cube(Vector3(0.17,0.65,0.22)),Vector3(0,0.95,0),"e0d7b5")
    parts.append(part(cube(Vector3(0.15,0.65,0.15)),Vector3(0,0.9,0),"f8edcb"))
    for y in [0.8,1.0,1.2]: parts.append(part(cube(Vector3(0.8,0.05,0.25)),Vector3(0,y,0),"f8edcb"))
   if id=="archer":
    parts.append(part(cone(0.42,0.7),Vector3(0,1.95,0),"395844"))
    for y in [0.75,1.1,1.45]: parts.append(part(cube(Vector3(0.08,0.45,0.12)),Vector3(0.62,y,0.3),"b48c55",Vector3(0,0,(y-1.1)*1.8)))
   if id=="knight":
    parts.append(part(cube(Vector3(1.05,0.24,0.55)),Vector3(0,1.3,0),"746c9c"))
    parts.append(part(cone(0.3,0.65),Vector3(0,1.94,0),"a175cf"))
   if id=="goblin": parts.append(part(cube(Vector3(0.16,0.9,0.12)),Vector3(0.55,0.95,0.1),"cfb179",Vector3(0,0,-0.25)))
  "wolf","spider","scarab","bat","wisp","beetle":
   var colors={"wolf":"9cbbca","spider":"b55f69","scarab":"b58a40","bat":"8d6ca8","wisp":"78d8cb","beetle":"6b8e57"}
   var color=colors[id]
   parts=[part(cube(Vector3(0.65,0.55,1.25)),Vector3(0,0.65,0),color)]
   if id=="wolf":
    for side in [-1,1]:
     for z in [-0.4,0.4]: parts.append(part(cube(Vector3(0.17,0.5,0.18)),Vector3(side*0.28,0.25,z),color))
    parts.append(part(cube(Vector3(0.4,0.45,0.7)),Vector3(0,0.9,0.75),"d3e3e4"))
    for side in [-1,1]: parts.append(part(cone(0.17,0.4),Vector3(side*0.2,1.25,0.55),color))
    parts.append(part(cone(0.2,0.9),Vector3(0,0.8,-0.95),color,Vector3(-1.1,0,0)))
   elif id in ["spider","scarab","beetle"]:
    for side in [-1,1]:
     for z in [-0.45,0.0,0.45]: parts.append(part(cube(Vector3(0.9,0.1,0.12)),Vector3(side*0.65,0.4,z),color,Vector3(0,side*z,side*0.4)))
    if id=="spider": parts.append(part(cone(0.4,0.75,0.15),Vector3(0,1.05,-0.3),"f8ba61"))
    else: parts.append(part(cone(0.22,0.9),Vector3(0,1,0.65),"ebce83",Vector3(0.5,0,0)))
   else:
    for side in [-1,1]: parts.append(part(cone(0.65,0.15,0),Vector3(side*0.85,0.8,0),color,Vector3(0,0,side*0.4)))
    if id=="wisp":
     parts=[part(cone(0.3,1.5,0.05),Vector3(0,0.8,0),"b9fff2",Vector3(PI,0,0))]
     for side in [-1,1]: parts.append(part(cone(0.22,0.65),Vector3(side*0.6,1.2,0),"63bcd0"))
  "ogre","golem","brute","bulwark":
   var color={"ogre":"7d9760","golem":"7f969f","brute":"a75d65","bulwark":"5988a0"}[id]
   parts=[part(cube(Vector3(1.2,1.1,0.8)),Vector3(0,1.2,0),color),part(cube(Vector3(0.6,0.6,0.5)),Vector3(0,2.05,0),color)]
   for side in [-1,1]: parts.append(part(cube(Vector3(0.5,0.9,0.5)),Vector3(side*0.85,1.05,0),color))
   if id=="golem":
    for side in [-1,1]: parts.append(part(cone(0.35,0.9),Vector3(side*0.7,1.8,0),"bacbd0"))
   if id=="brute":
    for side in [-1,1]: parts.append(part(cone(0.2,0.95),Vector3(side*0.35,2.6,0),"e9c592",Vector3(0,0,side*-0.5)))
   if id=="bulwark": parts.append(part(cube(Vector3(1.7,1.4,0.22)),Vector3(0,1,0.65),"a8cad1"))
   if id=="ogre": parts.append(part(cube(Vector3(0.6,0.75,0.6)),Vector3(1.1,0.6,0.5),"9b744d"))
  "cactus":
   parts=[part(cone(0.5,2,0.38),Vector3(0,1,0),"588b58")]
   for side in [-1,1]:
    parts.append(part(cube(Vector3(0.65,0.3,0.3)),Vector3(side*0.55,0.9,0),"6b9e64"))
    parts.append(part(cone(0.18,0.9,0.1),Vector3(side*0.8,1.2,0),"7aab6b"))
   parts.append(part(cone(0.25,0.4),Vector3(0,2.15,0),"e3a5bd"))
  "mushroom":
   parts=[part(cone(0.28,1.2,0.22),Vector3(0,0.6,0),"d0bd87"),part(cone(0.95,0.75,0.2),Vector3(0,1.5,0),"8f70ac")]
   for side in [-1,1]: parts.append(part(cube(Vector3(0.15,0.12,0.12)),Vector3(side*0.3,1.5,0.6),"d6f58e"))
 return parts
