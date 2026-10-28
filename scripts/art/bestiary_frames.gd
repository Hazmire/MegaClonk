class_name BestiaryFrames
extends RefCounted
# Stable logical IDs preserve saved runs; geometry comes from the new supplied packs.
const SOURCES={"Goblin":"Character_Monster_01","Skeleton":"Character_Monster","Imp":"Character_Monster_02","Puglin":"Character_Monster_08","Knight":"Character_Killer_07","Golem":"Wrapper","BlightHusk":"Character_Monster_03","Behemoth":"Character_Monster_06","Champion":"Character_Monster_07","Hunter":"Character_Monster_04","Ghost":"Character_Monster_05"}
static var meshes: Dictionary={}
static var materials: Dictionary={}
static func source_path(model: String,state: String="enemy_idle",frame: int=0) -> String:
 return "res://assets/grimdark/baked/enemies/%s_%s_%d.res"%[SOURCES.get(model,SOURCES.Goblin),state,frame]
static func mesh(model: String,state: String,frame: int) -> ArrayMesh:
 var key=model+state+str(frame)
 if meshes.has(key):return meshes[key]
 var result=load(source_path(model,state,frame)).duplicate() as ArrayMesh
 # Preserve established creature collision/visual scale relationships.
 var factor=1.25/1.8 if model in ["Puglin","BlightHusk","Behemoth","Champion"] else 1.0
 if factor!=1.0:
  var rebuilt=ArrayMesh.new()
  for surface in result.get_surface_count():
   var arrays=result.surface_get_arrays(surface)
   var vertices=arrays[Mesh.ARRAY_VERTEX]
   for i in vertices.size():vertices[i]*=factor
   arrays[Mesh.ARRAY_VERTEX]=vertices
   rebuilt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   rebuilt.surface_set_material(surface,result.surface_get_material(surface))
  result=rebuilt
 for surface in result.get_surface_count():
  result.surface_set_material(surface,GrimdarkMaterials.material(result.surface_get_material(surface)))
 meshes[key]=result;return result
static func prewarm() -> void:
 for model in SOURCES:
  for frame in 8:mesh(model,"enemy_move",frame)
  for frame in 2:mesh(model,"enemy_idle",frame)
