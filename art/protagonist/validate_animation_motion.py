"""Checks requested poses, contacts, loop seams, and baked mesh transforms.
blender -b -t 4 --python art/protagonist/validate_animation_motion.py
"""
import bpy
import json
import numpy as np
from pathlib import Path

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[1]
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'Investigator.blend'))
s=bpy.context.scene;rig=bpy.data.objects['Investigator'];mesh=bpy.data.objects['Investigator_Mesh']
required={'Idle','Walk','Jump','Crouch','CrouchEnter','CrouchExit','Slide','CriticalWalk'}
assert required.issubset(set(bpy.data.actions.keys()))
report={}
heads={};feet={}
root_reference=rig.data.bones['Root'].matrix_local
for name in sorted(bpy.data.actions.keys()):
    action=bpy.data.actions[name];rig.animation_data.action=action
    start,end=action.frame_range
    samples=[];worst_contact=0
    for phase in (0,.125,.25,.375,.5,.625,.75,.875,1):
        s.frame_set(int(start+(end-start)*phase),subframe=(start+(end-start)*phase)%1)
        matrices={pb.name:pb.matrix.copy() for pb in rig.pose.bones}
        assert all(np.isfinite(np.array(m)).all() for m in matrices.values())
        assert np.max(np.abs(np.array(matrices['Root'])-np.array(root_reference)))<1e-5
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        data=evaluated.to_mesh();coords=np.empty(len(data.vertices)*3)
        data.vertices.foreach_get('co',coords);coords=coords.reshape((-1,3))
        assert np.isfinite(coords).all()
        low=coords.min(axis=0);high=coords.max(axis=0)
        evaluated.to_mesh_clear()
        assert low[2]>-.045, (name,phase,'mesh penetrates floor',low.tolist())
        zfeet={suffix:rig.pose.bones['Foot.'+suffix].head.z for suffix in ('L','R')}
        for suffix in ('L','R'):
            p=(phase+(0 if suffix=='L' else .5))%1
            planted=(name in ('Idle','Crouch','CrouchEnter','CrouchExit','Slide') or
                     name=='Walk' and p<.6 or name=='Run' and p<.48 or
                     name=='CriticalWalk' and p<(.66 if suffix=='L' else .72))
            if planted:worst_contact=max(worst_contact,abs(zfeet[suffix]-.17))
        samples.append({'phase':phase,'mesh_min_z':float(low[2]),'mesh_max_z':float(high[2]),'foot_ankle_z':zfeet})
        if phase==0:first=matrices
        if phase==.5:
            heads[name]=rig.pose.bones['Head'].tail.z
            feet[name]=zfeet
    assert worst_contact<.006,(name,'planted ankle drift',worst_contact)
    seam=max(np.max(np.abs(np.array(first[n])-np.array(matrices[n]))) for n in first)
    if action.get('loop'):assert seam<.0001,(name,'loop seam',float(seam))
    report[name]={'duration_seconds':float((end-start)/24),'loop':bool(action.get('loop')),
                  'max_planted_ankle_error_m':float(worst_contact),
                  'loop_endpoint_matrix_difference':float(seam), 'samples':samples}
assert heads['CriticalWalk']<heads['Walk']-.20,'Critical walk must visibly hunch'
assert heads['Crouch']<heads['Idle']-.35,'Crouch must be substantially lower'
assert min(feet['Jump'].values())>.45,'Jump must visibly leave the floor'
def endpoint(clip,final=False):
    rig.animation_data.action=bpy.data.actions[clip]
    s.frame_set(int(rig.animation_data.action.frame_range[1 if final else 0]))
    return {pb.name:np.array(pb.matrix) for pb in rig.pose.bones}
for a,af,b,bf in [('Idle',False,'CrouchEnter',False),('CrouchEnter',True,'Crouch',False),
                  ('Crouch',False,'Slide',False),('Slide',True,'Crouch',False),
                  ('CrouchExit',False,'Crouch',False),('CrouchExit',True,'Idle',False)]:
    x,y=endpoint(a,af),endpoint(b,bf)
    assert max(np.max(np.abs(x[n]-y[n])) for n in x)<.0001,(a,b,'transition mismatch')
path=ROOT/'assets/characters/investigator/motion_validation.json'
path.write_text(json.dumps({'checks':'passed','clips':report},indent=2)+'\n')
print('MOTION_VALIDATED',json.dumps({name:{k:v for k,v in value.items() if k!='samples'} for name,value in report.items()}))
