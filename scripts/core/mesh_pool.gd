class_name MeshPool
extends Node3D
# Retains transient mesh nodes and shares immutable mesh/material resources.
var idle: Dictionary = {}
var materials: Dictionary = {}
var meshes: Dictionary = {}
var created = 0
func acquire(key: String, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
 var node: MeshInstance3D
 if idle.has(key) and not idle[key].is_empty(): node=idle[key].pop_back()
 else:
  node=MeshInstance3D.new()
  if not meshes.has(key): meshes[key]=mesh
  node.mesh=meshes[key]
  if not materials.has(key):
   var material=StandardMaterial3D.new()
   material.albedo_color=color
   material.emission_enabled=true
   material.emission=color
   material.emission_energy_multiplier=0.7
   materials[key]=material
  node.material_override=materials[key]
  node.set_meta("pool_key",key)
  add_child(node)
  created+=1
 node.position=pos
 node.rotation=Vector3.ZERO
 node.scale=Vector3.ONE
 node.visible=true
 return node
func release(node: MeshInstance3D) -> void:
 node.hide()
 var key=node.get_meta("pool_key")
 if not idle.has(key): idle[key]=[]
 idle[key].append(node)
