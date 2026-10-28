extends SceneTree
func _initialize():call_deferred("run")
func run():
 var first=JSON.parse_string(FileAccess.get_file_as_string("/tmp/grimdark-wrapper-frames/enemy_idle_0.json"));var bounds=AABB();var begin=true
 for surface in first:
  for v in surface.vertices:
   var p=Vector3(v[0],v[1],v[2]);bounds=AABB(p,Vector3.ZERO) if begin else bounds.expand(p);begin=false
 var scale_value=1.8/bounds.size.y;var shift=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)
 var material=StandardMaterial3D.new();material.albedo_texture=load("res://assets/grimdark/wrapper/MonsterPSX_Diffuse.png");material.roughness=1
 for state in ["enemy_idle","enemy_move"]:
  for frame in (2 if state=="enemy_idle" else 8):
   var data=JSON.parse_string(FileAccess.get_file_as_string("/tmp/grimdark-wrapper-frames/"+state+"_"+str(frame)+".json"));var result=ArrayMesh.new()
   for surface in data:
    var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(material)
    for i in surface.vertices.size():
     var v=surface.vertices[i];var n=surface.normals[i];var uv=surface.uv[i];st.set_normal(Vector3(n[0],n[1],n[2]));st.set_uv(Vector2(uv[0],1-uv[1]));st.add_vertex((Vector3(v[0],v[1],v[2])+shift)*scale_value)
    st.index();st.commit(result)
   ResourceSaver.save(result,"res://assets/grimdark/baked/enemies/Wrapper_"+state+"_"+str(frame)+".res",ResourceSaver.FLAG_COMPRESS)
 print("WRAPPER FRAME BAKE COMPLETE");quit()
