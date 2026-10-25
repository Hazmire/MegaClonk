extends SceneTree
func _initialize():
 for model in ["Goblin","Golem"]:
  for state in ["enemy_idle","enemy_move"]:
   for frame in (2 if state=="enemy_idle" else 8):
    var parts=ModelBuilder.enemy_parts(model.to_lower())
    var height=0.55 if model!="Golem" else 0.8
    for side in [-1,1]:
     var swing=sin(frame*TAU/8+side*PI/2)*0.55 if state=="enemy_move" else 0.0
     var pivot=Vector3(side*(0.18 if model!="Golem" else 0.36),height,0)
     var transform=Transform3D(Basis(Vector3.RIGHT,swing),pivot)
     var leg=ModelBuilder.part(ModelBuilder.cube(Vector3(0.22,0.55,0.28) if model!="Golem" else Vector3(0.48,0.8,0.5)),Vector3.ZERO,"456449" if model=="Goblin" else ("55516e" if model=="Knight" else "778b8d"))
     leg.transform=transform*Transform3D(Basis.IDENTITY,Vector3(0,-height/2,0));parts.append(leg)
    var mesh: ArrayMesh
    if model=="Golem":
     # Assemble the supplied Nature rock geometry into articulated stone limbs.
     var rock=ImportedArt.mesh("res://assets/quaternius/nature/Rock_Medium_1.gltf",1.0,1.2)
     var pieces=[]
     pieces.append({"p":Vector3(0,0.65,0),"s":Vector3(1.3,1.3,0.9),"r":0.0})
     pieces.append({"p":Vector3(0,1.9,0.08),"s":Vector3(0.65,0.65,0.65),"r":0.0})
     for side in [-1,1]:
      var angle=sin(frame*TAU/8+side*PI/2)*0.35 if state=="enemy_move" else 0.0
      pieces.append({"p":Vector3(side*0.35,0,0),"s":Vector3(0.55,0.75,0.7),"r":angle})
      pieces.append({"p":Vector3(side*0.95,0.65,0),"s":Vector3(0.65,1.0,0.75),"r":-angle})
     mesh=ArrayMesh.new()
     for piece in pieces:
      var transform=Transform3D(Basis(Vector3.RIGHT,piece.r).scaled(piece.s),piece.p)
      for surface in rock.get_surface_count():
       var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.append_from(rock,surface,transform);tool.set_material(rock.surface_get_material(surface));tool.commit(mesh)
     var eyes=[]
     for side in [-1,1]:eyes.append(ModelBuilder.part(ModelBuilder.cube(Vector3(0.12,0.1,0.08)),Vector3(side*0.13,2.22,0.38),"64e7dc"))
     var face=ModelBuilder.bake(eyes);var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.append_from(face,0,Transform3D.IDENTITY);tool.set_material(ModelBuilder.material());tool.commit(mesh)
    else:
     mesh=ModelBuilder.bake(parts);mesh.surface_set_material(0,ModelBuilder.material())
    ResourceSaver.save(mesh,"res://assets/quaternius/baked/%s_%s_%d.res"%[model,state,frame],ResourceSaver.FLAG_COMPRESS)
 print("Baked original Goblin/Knight/Golem limb cycles");quit()
