extends Node3D
var ranger: RangerVisual
var monsters: Array=[]
var state="idle"
func _ready() -> void:
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("60838e");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=0.65;add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.light_energy=1;add_child(light)
 var camera=Camera3D.new();camera.position=Vector3(6,4,12);add_child(camera);camera.look_at(Vector3(0,1,0));camera.current=true
 var floor_mesh=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(35,35);floor_mesh.mesh=plane;var mat=StandardMaterial3D.new();mat.albedo_color=Color("4c6840");floor_mesh.material_override=mat;add_child(floor_mesh)
 ranger=RangerVisual.new();add_child(ranger);ranger.position=Vector3(-3,0,0)
 for i in 2:
  var id=["Imp","Puglin"][i];var model=load("res://assets/quaternius/bestiary/"+id+".glb").instantiate();add_child(model);model.position=Vector3(i*3,0,0)
  var rig=model.get_node("Armature/Skeleton3D");var player=AnimationPlayer.new();model.add_child(player);player.add_animation_library("",RigClips.library(rig,id));player.play("enemy_move");monsters.append(player)
 for i in 5:
  var mesh=MeshInstance3D.new();var name=["CommonTree_1","Bush_Common","Rock_Medium_1","Flower_3_Group","Fern_1"][i]
  mesh.mesh=ImportedArt.mesh("res://assets/quaternius/nature/"+name+".gltf",4 if i==0 else 0.9,4);add_child(mesh);mesh.position=Vector3((i-2)*3,0,-5)
 var layer=CanvasLayer.new();add_child(layer);var box=VBoxContainer.new();box.position=Vector2(25,25);layer.add_child(box)
 var label=Label.new();label.text="ASSET SHOWCASE • Ranger / Imp / Puglin • Nature MegaKit";box.add_child(label)
 var choose=OptionButton.new()
 for name in ["idle","run","jump","airborne","fall","land","crouch","slide","hit","death","glide"]:choose.add_item(name)
 box.add_child(choose);choose.item_selected.connect(func(i):state=choose.get_item_text(i))
 var note=Label.new();note.text="Enemy rigs: retargeted UAL locomotion. Escape returns to menu.";box.add_child(note)
func _process(delta: float) -> void:ranger.animate(state,4 if state in ["run","crouch"] else 0,delta)
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):get_tree().change_scene_to_file("res://scenes/main/main.tscn")
func _exit_tree() -> void:RigClips.reset()
