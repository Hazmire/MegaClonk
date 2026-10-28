extends SceneTree
func _initialize():call_deferred("run")
func run():
 for entry in [["Autopsy",1.8,"res://assets/enemies_corrected/autopsy/Material_Diffuse.png"],["Crab",0.65,"res://assets/enemies_corrected/crab/crab_bone.png"],["EliteKnight",1.8,"res://assets/grimdark/characters/Character_Killer_07.png"],["HoodChampion",1.8,"res://assets/grimdark/characters/Character_Monster_07.png"],["HoodBrute",1.8,"res://assets/grimdark/characters/Character_Monster_08.png"]]:
  var id=entry[0];var first=JSON.parse_string(FileAccess.get_file_as_string("/tmp/bonk-corrected-frames/"+id+"_enemy_idle_0.json"));var bounds=AABB();var begin=true
  for surface in first:
   for v in surface.vertices:
    var p=Vector3(v[0],v[1],v[2]);bounds=AABB(p,Vector3.ZERO) if begin else bounds.expand(p);begin=false
  var factor=float(entry[1])/bounds.size.y;var shift=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)
  var material=StandardMaterial3D.new();material.albedo_texture=load(entry[2]);material.roughness=1.0
  for state in ["enemy_idle","enemy_move"]:
   for frame in (2 if state=="enemy_idle" else 8):
    var data=JSON.parse_string(FileAccess.get_file_as_string("/tmp/bonk-corrected-frames/"+id+"_"+state+"_"+str(frame)+".json"));var result=ArrayMesh.new()
    for surface in data:
     var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(material)
     for i in surface.vertices.size():
      var v=surface.vertices[i];var n=surface.normals[i];var uv=surface.uv[i];st.set_normal(Vector3(n[0],n[1],n[2]));st.set_uv(Vector2(uv[0],1-uv[1]));st.add_vertex((Vector3(v[0],v[1],v[2])+shift)*factor)
     st.index();st.commit(result)
    ResourceSaver.save(result,"res://assets/grimdark/baked/enemies/"+id+"_"+state+"_"+str(frame)+".res",ResourceSaver.FLAG_COMPRESS)
  print("CORRECTED FRAME BAKE ",id," bounds=",bounds)
 quit()
