"""Blender4.3.2 background: build an actual zombie skeletal gait and bake supplied crab Walk."""
import bpy,math,json,os
from pathlib import Path
from mathutils import Vector,Quaternion
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('BONK_CORRECTED_FRAMES','/tmp/bonk-corrected-frames'));OUT.mkdir(exist_ok=True)
def pose(bone,axis,angle):
 b=arm.pose.bones.get(bone)
 if b:
  local=b.bone.matrix_local.to_3x3().inverted()@Vector(axis)
  b.rotation_mode='QUATERNION';b.rotation_quaternion=b.rotation_quaternion@Quaternion(local.normalized(),angle)
def bake(id,arm,meshes,actions):
 yaw=0.0
 if id in ['EliteKnight','HoodChampion','HoodBrute']:
  f=arm.matrix_world.to_3x3()@forward
  yaw=-math.atan2(f.x,-f.y)
 def convert(p):
  return [math.cos(yaw)*p.x-math.sin(yaw)*p.y,p.z,-math.sin(yaw)*p.x-math.cos(yaw)*p.y]
 if arm.animation_data:
  for t in arm.animation_data.nla_tracks:t.mute=True
 for state,action,count in [('enemy_idle',actions[0],2),('enemy_move',actions[1],8)]:
  arm.animation_data.action=action
  for frame in range(count):
   at=action.frame_range[0]+(action.frame_range[1]-action.frame_range[0])*(frame+.25)/count
   bpy.context.scene.frame_set(int(at),subframe=at%1);bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();surfaces=[]
   for obj in meshes:
    ev=obj.evaluated_get(deps);mesh=ev.to_mesh();mesh.calc_loop_triangles();normal=ev.matrix_world.to_3x3().inverted().transposed();vertices=[];normals=[];uvs=[]
    for tri in mesh.loop_triangles:
     for loop in tri.loops:
      p=ev.matrix_world@mesh.vertices[mesh.loops[loop].vertex_index].co;n=(normal@mesh.corner_normals[loop].vector).normalized();uv=mesh.uv_layers.active.data[loop].uv if mesh.uv_layers.active else (0,0)
      vertices.append(convert(p));normals.append(convert(n));uvs.append(list(uv))
    surfaces.append({'vertices':vertices,'normals':normals,'uv':uvs});ev.to_mesh_clear()
   (OUT/(id+'_'+state+'_'+str(frame)+'.json')).write_text(json.dumps(surfaces))
 print('BAKED',id)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'assets/enemies_corrected/source_only/AutopsyZombieItch.fbx'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.data.objects if o.type=='MESH']
arm.animation_data_clear();arm.animation_data_create()
for obj in meshes:
 if obj.data.shape_keys:obj.data.shape_keys.animation_data_clear()
# Original file supplies an A-pose, not a locomotion clip. Animate the actual90-bone rig.
actions=[]
for state in ['Idle','Walk']:
 action=bpy.data.actions.new('Autopsy_'+state);arm.animation_data.action=action
 for frame in range(25):
  phase=math.tau*frame/24
  for b in arm.pose.bones:b.matrix_basis.identity()
  for side,sign in [('l',1),('r',-1)]:
   swing=math.sin(phase)*sign if state=='Walk' else 0.0
   pose('thigh_'+side,(1,0,0),swing*.42)
   pose('calf_'+side,(1,0,0),-max(0,-swing)*.58)
   pose('foot_'+side,(1,0,0),-swing*.14)
   pose('upperarm_'+side,(0,1,0),sign*.48)
   pose('upperarm_'+side,(1,0,0),-.25-swing*.12)
   pose('lowerarm_'+side,(1,0,0),-.18)
  pose('spine_02',(1,0,0),.10)
  pose('head',(0,1,0),math.sin(phase)*.035)
  for b in arm.pose.bones:
   b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
 actions.append(action)
# Replace broken external FBX texture paths with a deliberately simple supplied diffuse.
image=bpy.data.images.load(str(ROOT/'assets/enemies_corrected/autopsy/Material_Diffuse.png'),check_existing=True)
for obj in meshes:
 mat=bpy.data.materials.new('Autopsy_Diffuse');mat.use_nodes=True
 bsdf=mat.node_tree.nodes.get('Principled BSDF');tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);bsdf.inputs['Roughness'].default_value=1
 obj.data.materials.clear();obj.data.materials.append(mat)
arm.animation_data.action=actions[0];bpy.context.scene.frame_set(0)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/enemies_corrected/autopsy/Autopsy_ready.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS')
bake('Autopsy',arm,meshes,actions)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/enemies_corrected/crab/crab_bone.glb'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.name=='crab']
bake('Crab',arm,meshes,[next(a for a in bpy.data.actions if a.name.startswith('Idle_')),next(a for a in bpy.data.actions if a.name.startswith('Walk_'))])

# Retain the existing elite/boss silhouettes, but animate their real skinned limbs.
for id,source in [('EliteKnight','Character_Killer_07'),('HoodChampion','Character_Monster_07'),('HoodBrute','Character_Monster_08')]:
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(ROOT/('assets/grimdark/characters/'+source+'.fbx')))
 arm=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.data.objects if o.type=='MESH'];arm.animation_data_clear();arm.animation_data_create();actions=[]
 left=(arm.data.bones['mixamorig:LeftArm'].head_local-arm.data.bones['mixamorig:RightArm'].head_local).normalized();up=(arm.data.bones['mixamorig:Head'].head_local-arm.data.bones['mixamorig:Hips'].head_local).normalized();forward=left.cross(up).normalized()
 for state in ['Idle','Walk']:
  action=bpy.data.actions.new(id+'_'+state);arm.animation_data.action=action
  for frame in range(25):
   phase=math.tau*frame/24
   for b in arm.pose.bones:b.matrix_basis.identity()
   for side,sign in [('Left',1),('Right',-1)]:
    swing=math.sin(phase)*sign if state=='Walk' else 0.0
    pose('mixamorig:'+side+'UpLeg',left,swing*.4)
    pose('mixamorig:'+side+'Leg',left,-max(0,-swing)*.55)
    pose('mixamorig:'+side+'Foot',left,-swing*.12)
    pose('mixamorig:'+side+'Arm',forward,-sign*.85)
    pose('mixamorig:'+side+'Arm',left,-swing*.22)
    pose('mixamorig:'+side+'ForeArm',left,-.2)
   pose('mixamorig:Head',(0,1,0),math.sin(phase)*.025)
   for b in arm.pose.bones:b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
  actions.append(action)
 bake(id,arm,meshes,actions)
