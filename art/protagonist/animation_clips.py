"""Baked FK animation for the Investigator's existing 28-bone skeleton.

Analytical two-bone solves are baked into ordinary bone keys. No runtime IK,
constraints, add-ons, or root-motion support is required by the exported GLB.
"""
import math
import bpy
from mathutils import Vector, Matrix, Euler

CLIPS = {
    'Idle': {'frames':72, 'loop':True, 'description':'Quiet breathing and a small head/coat sway.'},
    'Walk': {'frames':32, 'loop':True, 'speed_mps':.85, 'description':'Measured walking with planted stance feet.'},
    'Jump': {'frames':36, 'loop':False, 'description':'Anticipation, takeoff, tucked airborne pose, landing and recovery.'},
    'Crouch': {'frames':48, 'loop':True, 'description':'Held crouch with subtle breathing; both feet grounded.'},
    'CrouchEnter': {'frames':12, 'loop':False, 'description':'Standing to the crouch pose.'},
    'CrouchExit': {'frames':12, 'loop':False, 'description':'Crouch pose to standing.'},
    'Slide': {'frames':30, 'loop':False, 'description':'Crouch to a low slide with one leg extended, returning to crouch.'},
    'CriticalWalk': {'frames':48, 'loop':True, 'speed_mps':.35, 'description':'Hunched, asymmetric limp with the left hand bracing the abdomen.'},
    'Run': {'frames':24, 'loop':True, 'speed_mps':1.8, 'description':'In-place run, retained from the original pack.'},
    'Interact': {'frames':40, 'loop':False, 'description':'Right-hand reach and recovery, retained from the original pack.'},
}


def ease(t):
    t=max(0,min(1,t))
    return t*t*(3-2*t)


def curve(t, points):
    for (a,x),(b,y) in zip(points,points[1:]):
        if t<=b:return x+(y-x)*ease((t-a)/(b-a))
    return points[-1][1]


def world_pose(rig):
    result={}
    for bone in rig.pose.bones:
        parent=bone.parent
        options={} if parent is None else {
            'parent_matrix':result[parent.name],
            'parent_matrix_local':parent.bone.matrix_local,
        }
        result[bone.name]=bone.bone.convert_local_to_pose(
            bone.matrix_basis,bone.bone.matrix_local,**options)
    return result


def set_world(rig, name, matrix, pose):
    pb=rig.pose.bones[name]
    options={} if pb.parent is None else {
        'parent_matrix':pose[pb.parent.name],
        'parent_matrix_local':pb.parent.bone.matrix_local,
    }
    basis=pb.bone.convert_local_to_pose(matrix,pb.bone.matrix_local,invert=True,**options)
    pb.matrix_basis=basis
    pose[name]=matrix


def aim_matrix(rest, head, target):
    old=(rest.tail_local-rest.head_local).normalized()
    new=(target-head).normalized()
    rotation=old.rotation_difference(new).to_matrix() @ rest.matrix_local.to_3x3()
    result=rotation.to_4x4();result.translation=head
    return result


def solve_limb(rig, first, second, end, target, hint, pose, end_rotation=None):
    a=rig.data.bones[first];b=rig.data.bones[second]
    head=pose[first].translation.copy()
    target=Vector(target)
    delta=target-head
    distance=delta.length
    direction=delta.normalized()
    l1=a.length;l2=b.length
    # Keep the solve stable at full extension. The keyed end remains connected.
    d=max(abs(l1-l2)+.0001,min(distance,l1+l2-.0001))
    target=head+direction*d
    along=(l1*l1-l2*l2+d*d)/(2*d)
    height=math.sqrt(max(0,l1*l1-along*along))
    hint=Vector(hint)
    bend=(hint-direction*hint.dot(direction)).normalized()
    joint=head+direction*along+bend*height
    set_world(rig,first,aim_matrix(a,head,joint),pose)
    set_world(rig,second,aim_matrix(b,joint,target),pose)
    final=(end_rotation or rig.data.bones[end].matrix_local.to_3x3()).to_4x4()
    final.translation=target
    set_world(rig,end,final,pose)


def foot_path(phase, stride, lift, stance=.6):
    phase=phase%1
    if phase<stance:
        return -stride/2+stride*phase/stance,0,0
    s=(phase-stance)/(1-stance)
    return stride/2-stride*ease(s),lift*math.sin(math.pi*s)**2,.12*math.sin(math.pi*s)


def pose_frame(rig,clip,t,gameplay=False):
    wave=math.sin(math.tau*t)
    breathing=wave
    crouch=(1 if clip in ('Crouch','Slide') else ease(t) if clip=='CrouchEnter'
            else 1-ease(t) if clip=='CrouchExit' else 0)
    slide=math.sin(math.pi*t)**2 if clip=='Slide' else 0
    critical=clip=='CriticalWalk'
    moving=clip in ('Walk','Run','CriticalWalk')
    running=clip=='Run'
    jump_lift=curve(t,[(0,0),(.16,-.14),(.25,-.015),(.48,.42),(.63,.26),(.73,-.06),(.81,-.15),(.95,0),(1,0)]) if clip=='Jump' else 0
    air=math.sin(math.pi*(t-.24)/.50)**1.3 if clip=='Jump' and .24<t<.74 else 0
    reach=math.sin(math.pi*t)**2 if clip=='Interact' else 0
    rotations={name:Vector((0,0,0)) for name in rig.pose.bones.keys()}
    hips=Vector((0,0,0))
    hips.z=.004*breathing if clip=='Idle' else 0
    if moving:
        hips.z=(-.09+.009*math.cos(math.tau*t*2) if critical
                else -.10-.022*math.cos(math.tau*t*2) if running
                else -.065-.012*math.cos(math.tau*t*2))
        hips.x=.012*wave if critical else .009*wave
        rotations['Hips'].z=(.025 if critical else .018)*wave
        rotations['Chest'].z=-.025*wave
    if critical:
        hips.y=.035
        rotations['Hips'].x=.07
        rotations['Spine'].x=.48+.018*wave
        rotations['Chest'].x=.22+.018*math.sin(math.tau*t+.5)
        rotations['Head'].x=.18
        rotations['Neck'].z=-.04
    elif running:
        rotations['Spine'].x=.13
    elif clip=='Walk':
        rotations['Spine'].x=.035
    elif clip=='Idle':
        rotations['Chest'].x=.006*breathing
        rotations['Head'].z=.017*breathing
    if crouch:
        hips.y+=.11*crouch
        hips.z+=(-.43+.003*breathing if clip=='Crouch' else -.43)*crouch
        rotations['Hips'].x=.16*crouch
        rotations['Spine'].x=.19*crouch
        rotations['Chest'].x=.04*crouch
        rotations['Head'].x=-.16*crouch
    if slide:
        hips.z-=.14*slide
        hips.y+=.035*slide
        rotations['Hips'].x-=.28*slide
        rotations['Spine'].x-=.24*slide
        rotations['Head'].x+=.20*slide
    if gameplay and crouch:
        # The live controller has a 0.95 m low capsule. Deepen the squat and
        # counter-rotate the head rather than squash or sink the whole mesh.
        hips.z=(-.742-.04*slide)*crouch
        rotations['Hips'].x=(.16-.05*slide)*crouch
        rotations['Spine'].x=(.74+.10*slide)*crouch
        rotations['Chest'].x=(.10-.03*slide)*crouch
        rotations['Head'].x=(-.60+.05*slide)*crouch
    if clip=='Jump':
        hips.z=min(0,jump_lift) if gameplay else jump_lift
        rotations['Spine'].x=.10*max(0,-jump_lift)/.15-.05*air
        rotations['Head'].x=.04*air
    if reach:
        rotations['Chest'].x=.05*reach
        rotations['Head'].x=.13*reach
    for side,suffix in [(1,'L'),(-1,'R')]:
        gait=wave*side
        rotations['UpperArm.'+suffix].x=(.36 if running else .24)*gait if moving else .012*breathing
        rotations['Forearm.'+suffix].x=-.50 if running else -.06 if moving else -.035
        if critical:
            rotations['UpperArm.'+suffix].x=-.30+.055*gait
            rotations['Forearm.'+suffix].x=-.18
        if crouch:
            rotations['UpperArm.'+suffix].x=-.48*crouch
            rotations['Forearm.'+suffix].x=-.65*crouch
        if slide:
            rotations['UpperArm.'+suffix].x+=.75*slide
            rotations['UpperArm.'+suffix].z+=side*.24*slide
            rotations['Forearm.'+suffix].x+=.35*slide
        if clip=='Jump':
            rotations['UpperArm.'+suffix].x=-1.1*air-.22*max(0,-jump_lift)/.15
            rotations['Forearm.'+suffix].x=-.38*air-.10
        if reach and suffix=='R':
            rotations['UpperArm.R'].x=-1.05*reach
            rotations['Forearm.R'].x=-.5*reach
        for which in ('Front','Back'):
            for tip in (False,True):
                name='Coat'+which+'.'+suffix+('.Tip' if tip else '')
                phase=math.sin(math.tau*t+side*.65-(.65 if tip else 0))
                swing=(.62 if running else .30 if critical else .48)*(.40 if tip else 1)
                if moving:
                    rotations[name].x=(max(0,-gait)*swing if which=='Back' else -max(0,gait)*swing)+.02*phase
                    rotations[name].z=side*(.06 if running else .025)*abs(wave)
                else:rotations[name].x=.009*breathing
                if crouch:
                    rotations[name].x=(.90 if which=='Back' else -.72)*crouch*(.3 if tip else 1)
                    rotations[name].z=side*.12*crouch
                if slide:
                    rotations[name].x+=(.38 if which=='Back' else -.18)*slide
                    rotations[name].z+=side*.18*slide
                if clip=='Jump':
                    rotations[name].x+=(.40 if which=='Back' else -.36)*air*(.5 if tip else 1)
                    rotations[name].z=side*.12*air
    for pb in rig.pose.bones:
        pb.rotation_mode='QUATERNION'
        pb.location=(0,0,0);pb.scale=(1,1,1)
        pb.rotation_quaternion=Euler(rotations[pb.name],'XYZ').to_quaternion()
    rig.pose.bones['Hips'].location=rig.data.bones['Hips'].matrix_local.to_3x3().inverted()@hips
    pose=world_pose(rig)
    for side,suffix in [(1,'L'),(-1,'R')]:
        ankle=Vector((side*.13,0,.17))
        pitch=0
        if moving:
            phase=t+(0 if side==1 else .5)
            if critical:
                y,z,pitch=foot_path(phase,.30 if side==1 else .23,.045 if side==1 else .018,.66 if side==1 else .72)
            else:y,z,pitch=foot_path(phase,.80 if running else .68,.17 if running else .075,.48 if running else .6)
            ankle.y+=y;ankle.z+=z
        if crouch:
            ankle.x+=side*.028*crouch
            ankle.y-=.02*crouch
        if slide:
            ankle.y+=(-.52 if side==1 else .15)*slide
            ankle.x+=side*.025*slide
        if clip=='Jump':
            ankle.z+=(0 if gameplay else max(0,jump_lift))+.2*air
            ankle.y+=.10*air
            pitch=-.16*air
        rest=rig.data.bones['Foot.'+suffix].matrix_local.to_3x3()
        orientation=Euler((pitch,0,0)).to_matrix()@rest
        solve_limb(rig,'Thigh.'+suffix,'Shin.'+suffix,'Foot.'+suffix,ankle,(0,-1,0),pose,orientation)
    # Drape the long panels around the solved legs. A separate sine-wave swing
    # cannot clear deeply bent knees reliably, especially in the injured walk.
    coat_fit=1 if moving else crouch
    if clip=='Jump':coat_fit=max(air,min(1,max(0,-jump_lift)/.15))
    if coat_fit>0:
        for side,suffix in [(1,'L'),(-1,'R')]:
            knee=pose['Shin.'+suffix].translation
            ankle=pose['Foot.'+suffix].translation
            for which in ('Front','Back'):
                direction=-1 if which=='Front' else 1
                main='Coat'+which+'.'+suffix;tip=main+'.Tip'
                target=knee+Vector((side*.08,direction*.08,.07))
                desired=aim_matrix(rig.data.bones[main],pose[main].translation,target)
                q=pose[main].to_quaternion().slerp(desired.to_quaternion(),coat_fit)
                matrix=q.to_matrix().to_4x4();matrix.translation=pose[main].translation
                set_world(rig,main,matrix,pose)
                pb=rig.pose.bones[tip]
                current=pb.bone.convert_local_to_pose(pb.matrix_basis,pb.bone.matrix_local,
                    parent_matrix=pose[main],parent_matrix_local=pb.parent.bone.matrix_local)
                hem=ankle+Vector((side*.11,direction*.14,.20))
                if clip=='Jump' and which=='Front':
                    # Tucked ankles move behind the knees. Keep the front hem
                    # ahead of the knees rather than pulling it through them.
                    hem.y=min(hem.y,knee.y-.20)
                desired=aim_matrix(rig.data.bones[tip],current.translation,hem)
                q=current.to_quaternion().slerp(desired.to_quaternion(),coat_fit)
                matrix=q.to_matrix().to_4x4();matrix.translation=current.translation
                set_world(rig,tip,matrix,pose)
    if critical:
        chest=pose['Chest']@rig.data.bones['Chest'].matrix_local.inverted()
        target=chest@Vector((.035,-.235,1.39))
        orientation=chest.to_3x3()@rig.data.bones['Hand.L'].matrix_local.to_3x3()
        solve_limb(rig,'UpperArm.L','Forearm.L','Hand.L',target,(1,.15,-.1),pose,orientation)


def build_actions(rig, clear=True, gameplay=False):
    rig.animation_data_create()
    rig.animation_data.action=None
    if clear:
        for action in list(bpy.data.actions):bpy.data.actions.remove(action)
    for name,metadata in CLIPS.items():
        action=bpy.data.actions.new(name);action.use_fake_user=True
        rig.animation_data.action=action
        last={}
        for frame in range(metadata['frames']+1):
            pose_frame(rig,name,frame/metadata['frames'],gameplay=gameplay)
            for pb in rig.pose.bones:
                # Equivalent q/-q rotations must stay on the same quaternion
                # hemisphere so linear interpolation cannot introduce a spin.
                q=pb.rotation_quaternion.copy()
                if pb.name in last and q.dot(last[pb.name])<0:q.negate()
                pb.rotation_quaternion=q;last[pb.name]=q
                pb.keyframe_insert('rotation_quaternion',frame=frame+1,group=pb.name)
                pb.keyframe_insert('location',frame=frame+1,group=pb.name)
        for fcurve in action.fcurves:
            for key in fcurve.keyframe_points:key.interpolation='LINEAR'
        for key,value in metadata.items():action[key]=value
    rig.animation_data.action=bpy.data.actions['Idle']
    bpy.context.scene.render.fps=24
    bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=73
    bpy.context.scene.frame_set(1)
    return {name:meta['frames']/24 for name,meta in CLIPS.items()}
