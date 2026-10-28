class_name GrimdarkObjects
extends RefCounted
static func part(parent: Node3D,id: String,height: float=1.0,position: Vector3=Vector3.ZERO,stage: int=1) -> MeshInstance3D:
 var node=MeshInstance3D.new();node.mesh=GrimdarkMaterials.mesh(load("res://assets/grimdark/baked/props/"+id+".res"),stage)
 node.set_meta("grimdark_source",id);parent.add_child(node);node.scale=Vector3.ONE*height;node.position=position
 return node
static func populate(parent: Node3D,kind: String,stage: int) -> void:
 parent.set_meta("grimdark_kind",kind)
 match kind:
  "Chest","Free Chest":
   var chest=MeshInstance3D.new();chest.mesh=RewardDrops.mesh();parent.add_child(chest)
  "Shop":
   part(parent,"market_stall_round_red",3.0,Vector3.ZERO,stage)
   part(parent,"barrel",.85,Vector3(1.6,0,.5),stage)
  "Elite Statue":
   part(parent,"palace_shrine",1.0,Vector3.ZERO,stage)
   part(parent,"palace_Devilsface",1.7,Vector3.UP*.85,stage)
  "Boss Statue":
   part(parent,"palace_obelisk",3.1,Vector3.ZERO,stage)
   part(parent,"PS1_Skull",.65,Vector3(0,1.6,.5),stage)
  "Heal":
   part(parent,"palace_shrine",1.2,Vector3.ZERO,stage)
   part(parent,"PS1_Skull",.35,Vector3.UP*1.25,stage)
  _:
   part(parent,"palace_shrine",1.8,Vector3.ZERO,stage)
   if kind=="Risk Shrine":part(parent,"PS1_Skull",.55,Vector3.UP*1.8,stage)
   elif kind=="Stat Shrine":part(parent,"palace_obelisk",.9,Vector3.UP*1.5,stage)
static func portal(game: Node) -> void:
 var visual=Node3D.new();visual.name="PortalAsset";game.portal.add_child(visual)
 part(visual,"stone_archway",4.4,Vector3.ZERO,game.stage)
 var ring=MeshInstance3D.new();ring.name="Ring";var plane=QuadMesh.new();plane.size=Vector2(2.5,3.4);ring.mesh=plane;ring.position=Vector3(0,1.7,0);visual.add_child(ring)
 var material=ShaderMaterial.new();material.shader=preload("res://shaders/grimdark_portal.gdshader")
 material.set_shader_parameter("runes",preload("res://assets/grimdark/horror/PS1_Skull/MagicRunes_Emission.png"))
 ring.material_override=material;game.portal.set_meta("opening_material",material)
static func refresh_portal(game: Node) -> void:
 var material=game.portal.get_meta("opening_material",null) as ShaderMaterial
 if material:
  material.set_shader_parameter("portal_color",Color("9ba7a2") if game.portal_state=="exit" else Color("ff3454"))
  material.set_shader_parameter("pulse",.9 if game.portal_state=="summoned" else .55)
