"""Build physics-compatible clips without changing the editable art model.
blender -b -t 8 --python-exit-code 1 --python art/protagonist/build_gameplay_asset.py
"""
import bpy
import sys
import json
import numpy as np
from pathlib import Path

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[1]
sys.path.insert(0,str(SOURCE))
from animation_clips import build_actions
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'Investigator.blend'))
rig=bpy.data.objects['Investigator'];mesh=bpy.data.objects['Investigator_Mesh']
build_actions(rig,gameplay=True)
scene=bpy.context.scene
scale=1.8/2.020439863204956
bounds={}
for clip in ('Idle','Crouch','Slide','Jump','CriticalWalk'):
    rig.animation_data.action=bpy.data.actions[clip]
    rows=[]
    for phase in (0,.125,.25,.375,.5,.625,.75,.875,1):
        frame=1+phase*(rig.animation_data.action.frame_range[1]-1)
        scene.frame_set(int(frame),subframe=frame%1)
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        data=evaluated.to_mesh();vertices=np.empty(len(data.vertices)*3)
        data.vertices.foreach_get('co',vertices);vertices=vertices.reshape((-1,3))
        rows.append({'phase':phase,'min_y_game':float(vertices[:,2].min()*scale),'max_y_game':float(vertices[:,2].max()*scale)})
        evaluated.to_mesh_clear()
    bounds[clip]=rows
    if clip in ('Crouch','Slide'):
        assert max(row['max_y_game'] for row in rows)<.95,(clip,rows)
        assert min(row['min_y_game'] for row in rows)>-.04,(clip,rows)
rig.animation_data.action=bpy.data.actions['Idle'];scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True)
bpy.context.view_layer.objects.active=rig
out=ROOT/'assets/characters/investigator'
bpy.ops.export_scene.gltf(filepath=str(out/'Investigator_Gameplay.glb'),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,
    export_cameras=False,export_lights=False)
(out/'gameplay_profile.json').write_text(json.dumps({'scale':scale,'capsule_standing':1.8,'capsule_crouched':.95,
    'jump':'No positive hip arc; physics supplies height. Anticipation/landing compression retained.',
    'bounds':bounds},indent=2)+'\n')
print('GAMEPLAY_ASSET_READY',json.dumps({'scale':scale,'crouch_max_y':max(x['max_y_game'] for x in bounds['Crouch']),'slide_max_y':max(x['max_y_game'] for x in bounds['Slide'])}))
