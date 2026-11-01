"""Refresh the saved Investigator animations without rebuilding geometry.
blender -b -t 8 --python art/protagonist/animate_investigator.py
"""
import bpy
import json
import sys
from pathlib import Path

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[1]
EXPORT=ROOT/'assets/characters/investigator'
sys.path.insert(0,str(SOURCE))
from animation_clips import build_actions,CLIPS

bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'Investigator.blend'))
bpy.context.preferences.filepaths.save_version=0
rig=bpy.data.objects['Investigator'];mesh=bpy.data.objects['Investigator_Mesh']
assert len(rig.data.bones)==28 and len(mesh.data.polygons)==196248
durations=build_actions(rig)
rig['animation_note']='Baked FK with solved foot contacts; root stationary; Jump has a 0.42 m local hip arc.'
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'Investigator.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'Investigator.glb'),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,
    export_cameras=False,export_lights=False)
manifest=json.loads((EXPORT/'manifest.json').read_text())
manifest['animations_seconds']=durations
manifest['looping_clips']=[name for name,meta in CLIPS.items() if meta['loop']]
manifest['non_looping_clips']=[name for name,meta in CLIPS.items() if not meta['loop']]
manifest['animation_details']=CLIPS
manifest['root_motion']='None. Slide is stationary horizontally; game controller supplies travel.'
manifest['jump_motion']='Local hips provide a 0.42 m visual arc; match or remove this channel for a physics-driven jump.'
(EXPORT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

turnaround=SOURCE/'Investigator_Turnaround.blend'
if turnaround.exists():
    bpy.ops.wm.open_mainfile(filepath=str(turnaround))
    bpy.context.preferences.filepaths.save_version=0
    build_actions(bpy.data.objects['Investigator'])
    for obj in bpy.context.scene.objects:
        if obj.type=='ARMATURE':
            obj.animation_data_clear()
            for pb in obj.pose.bones:
                pb.rotation_quaternion=(1,0,0,0);pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(turnaround),compress=True)
print('INVESTIGATOR_ANIMATIONS_COMPLETE',json.dumps(durations))
