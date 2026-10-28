"""Run with Blender4.3.2 --background --python. Preserve supplied meshes/clips."""
import bpy,json,math,os
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(os.environ.get('MEGACLONK_PSX_SOURCE','/tmp/megaclonk-psx-source'))
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'knight/knight/knight.blend'))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
for image in bpy.data.images:
 if 'knightlowres' in image.name:
  image.filepath=str(SOURCE/'knight/knight/knightlowres.png');image.reload()
for obj in list(bpy.data.objects):
 if obj.type=='MESH':
  bpy.context.view_layer.objects.active=obj;obj.select_set(True)
  for modifier in list(obj.modifiers):
   if modifier.type=='MIRROR':bpy.ops.object.modifier_apply(modifier=modifier.name)
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
if arm.animation_data:
 for track in arm.animation_data.nla_tracks:track.mute=True
 arm.animation_data.action=next(a for a in bpy.data.actions if 'idle' in a.name)
bpy.context.scene.frame_set(0);bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();points=[]
for obj in [o for o in bpy.data.objects if o.type=='MESH']:
 ev=obj.evaluated_get(deps);points.extend(ev.matrix_world@v.co for v in ev.data.vertices)
lo=Vector(tuple(min(p[k] for p in points) for k in range(3)));hi=Vector(tuple(max(p[k] for p in points) for k in range(3)));scale=1.8/(hi.z-lo.z)
normalizer=bpy.data.objects.new('GroundAlignedKnight',None);bpy.context.collection.objects.link(normalizer)
for o in list(bpy.context.scene.objects):
 if o!=normalizer and not o.parent:o.parent=normalizer
normalizer.scale=(scale,)*3;normalizer.location=Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z))*scale
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/grimdark/knight/Knight_ready.glb'),export_format='GLB',export_animations=True,export_yup=True,export_nla_strips=True)
print('KNIGHT_NORMALIZED',list(lo),list(hi),scale)
# Bake Wrapper supplied actions to common static frame format for horde instancing.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(SOURCE/'TheWrapper.V2.1/MonsterPSX.fbx'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.data.objects if o.type=='MESH']
if arm.animation_data:
 for track in arm.animation_data.nla_tracks:track.mute=True
out=Path('/tmp/grimdark-wrapper-frames');out.mkdir(exist_ok=True)
for state,token,count in [('enemy_idle','Idle_Watchful',2),('enemy_move','Walk_Nervous',8)]:
 action=next(a for a in bpy.data.actions if token in a.name);arm.animation_data.action=action
 for frame in range(count):
  bpy.context.scene.frame_set(int(action.frame_range[0]+(action.frame_range[1]-action.frame_range[0])*frame/count));bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();surfaces=[]
  for obj in meshes:
   ev=obj.evaluated_get(deps);m=ev.to_mesh();m.calc_loop_triangles();normal=ev.matrix_world.to_3x3().inverted().transposed();points=[];normals=[];uv=[]
   for tri in m.loop_triangles:
    for loop in tri.loops:
     p=ev.matrix_world@m.vertices[m.loops[loop].vertex_index].co;n=(normal@m.corner_normals[loop].vector).normalized();t=m.uv_layers.active.data[loop].uv if m.uv_layers.active else (0,0)
     points.append([p.x,p.z,-p.y]);normals.append([n.x,n.z,-n.y]);uv.append(list(t))
   surfaces.append({'vertices':points,'normals':normals,'uv':uv});ev.to_mesh_clear()
  (out/(state+'_'+str(frame)+'.json')).write_text(json.dumps(surfaces))
print('WRAPPER_FRAMES_COMPLETE')
