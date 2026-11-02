"""Original reference-inspired cultist. Blender 4.3+, no external art or add-ons.
blender -b -t 8 --python-exit-code 1 --python art/cultist/generate_cultist.py
"""
import bpy
import math
import json
import numpy as np
from pathlib import Path
from mathutils import Vector, Euler

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/cultist'
EXPORT=ROOT/'assets/characters/cultist'
TEXTURES=EXPORT/'textures'
PREVIEW=ROOT/'docs/images/cultist'
for path in (SOURCE,EXPORT,TEXTURES,PREVIEW):path.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
scene=bpy.context.scene;scene.render.fps=24
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1


def field(n,rng,size=256):
    grid=rng.random((n,n))
    axis=np.linspace(0,n-1,size)
    horizontal=np.array([np.interp(axis,np.arange(n),row) for row in grid])
    result=np.array([np.interp(axis,np.arange(n),horizontal[:,i]) for i in range(size)]).T
    return np.repeat(np.repeat(result,2,axis=0),2,axis=1)


def cloth_texture(name,hood=False):
    rng=np.random.default_rng(412 if hood else 192)
    size=512;u,v=np.meshgrid(np.linspace(0,1,size),np.linspace(0,1,size))
    macro=field(7,rng);medium=field(22,rng);grain=field(160,rng)
    dirt=np.clip((macro-.36)*.85+(medium-.44)*.45,0,.62)
    for i in range(24):
        cx,cy=rng.random(2);rx=rng.uniform(.015,.08);ry=rng.uniform(.02,.12)
        stain=np.exp(-(((u-cx)/rx)**2+((v-cy)/ry)**2)*2.2)
        dirt+=stain*rng.uniform(.12,.35)
    dirt+=.48*(1-v)**4 if not hood else .20*(1-v)**2
    dirt=np.clip(dirt,0,.82)
    clean=np.array((132,126,113) if hood else (199,191,175),dtype=float)
    mud=np.array((48,43,33) if hood else (77,69,43),dtype=float)
    rgb=clean[None,None,:]*(1-dirt[:,:,None])+mud[None,None,:]*dirt[:,:,None]
    rgb*= (1-.085*(np.cos(u*math.tau*(9 if hood else 11))*.5+.5))[:,:,None]
    rgb+=(grain[:,:,None]-.5)*28+(medium[:,:,None]-.5)*15
    # Cloth binding along the bottom, with small pale, worn stitch marks.
    hem=(v>.015)&(v<.033)
    rgb[hem]*=.66
    stitches=(v>.039)&(v<.044)&((u*100)%1<.40)
    rgb[stitches]=np.array((131,126,111) if hood else (159,152,133))
    if not hood:
        seam=np.abs(u-.5)<.0035
        rgb[seam]*=.68
        edge=(np.abs(u-.5)>.0035)&(np.abs(u-.5)<.006)
        rgb[edge]*=1.08
        # An original broken-gate ritual mark, painted into the fabric.
        sigil=((u>.536)&(u<.570)&(v>.667)&(v<.892))
        sigil|=((u>.453)&(u<.560)&(v>.667)&(v<.701))
        sigil|=((u>.455)&(u<.546)&(v>.753)&(v<.782))
        sigil|=((u>.473)&(u<.540)&(v>.837)&(v<.891))
        wear=(grain>.12)&(medium>.20)
        paint=np.array((113,25,20))[None,None,:]*(.78+.28*grain[:,:,None])
        alpha=(sigil&wear).astype(float)*(.70+.25*medium)
        rgb=rgb*(1-alpha[:,:,None])+paint*alpha[:,:,None]
    rgb=np.clip(rgb/255,0,1).astype(np.float32)
    pixels=np.ones((size,size,4),dtype=np.float32);pixels[:,:,:3]=rgb
    image=bpy.data.images.new(name,width=size,height=size,alpha=False)
    image.colorspace_settings.name='sRGB';image.pixels.foreach_set(pixels.ravel())
    filename=str(TEXTURES/(name+'.png'))
    image.filepath_raw=filename;image.file_format='PNG';image.save()
    # Reload the encoded sRGB file so the authoring render and the exported GLB
    # use the same color-space conversion, rather than a generated image buffer.
    bpy.data.images.remove(image)
    image=bpy.data.images.load(filename,check_existing=False)
    image.colorspace_settings.name='sRGB';image.pack()
    return image


def srgb(value):
    rgb=[int(value[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(c/12.92 if c<.04045 else ((c+.055)/1.055)**2.4 for c in rgb)+(1,)


def material(name,color,texture=None,emission=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=srgb(color)
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=m.diffuse_color
    shader.inputs['Roughness'].default_value=.97
    shader.inputs['Specular IOR Level'].default_value=.12
    if texture:
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=texture;node.interpolation='Closest'
        m.node_tree.links.new(node.outputs['Color'],shader.inputs['Base Color'])
    if emission:
        shader.inputs['Emission Color'].default_value=m.diffuse_color
        shader.inputs['Emission Strength'].default_value=emission
    return m


ROBE=material('Cultist | stained ivory cloth','C7BFAF',cloth_texture('Cultist_Robe_BaseColor'))
HOOD=material('Cultist | ash-darkened hood','847E71',cloth_texture('Cultist_Hood_BaseColor',True))
DARK=material('Cultist | shadow lining and leather','211E19')
ROPE=material('Cultist | old brown rope','32251A')
FIBER=material('Cultist | rope fibers','594A31')
RED=material('Cultist | recessed red eyes','922D20',emission=.16)
parts=[];bones={}


def bone(name,head,tail,parent=None):bones[name]=(head,tail,parent)


def mesh(name,verts,faces,mat,bind,uvs=None,smooth=True):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    obj.data.materials.append(mat)
    for poly in data.polygons:poly.use_smooth=smooth
    if uvs:
        uv=data.uv_layers.new(name='UVMap')
        for loop in data.loops:uv.data[loop.index].uv=uvs[loop.vertex_index]
    group=obj.vertex_groups.new(name=bind);group.add(list(range(len(verts))),1,'REPLACE')
    region=obj.vertex_groups.new(name='PART | '+name);region.add(list(range(len(verts))),1,'REPLACE')
    parts.append(obj)
    return obj


def solidify(obj,width=.008,lining=True):
    if lining:obj.data.materials.append(DARK)
    modifier=obj.modifiers.new('Fabric thickness','SOLIDIFY');modifier.thickness=width
    if lining:modifier.material_offset=1;modifier.material_offset_rim=1
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def ellipsoid(name,loc,scale,mat,bind,segments=16,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=loc)
    obj=bpy.context.object;obj.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    verts=[v.co.copy() for v in obj.data.vertices];faces=[tuple(p.vertices) for p in obj.data.polygons]
    bpy.data.objects.remove(obj,do_unlink=True)
    return mesh(name,verts,faces,mat,bind)


def tube(name,points,radii,mat,bind,sides=10,cloth=False):
    verts=[];uv=[];previous_u=None
    for i,(point,radius) in enumerate(zip(points,radii)):
        point=Vector(point)
        d=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized()
        if previous_u is None:
            ref=Vector((0,0,1)) if abs(d.z)<.95 else Vector((0,1,0))
            u=d.cross(ref).normalized()
        else:u=(previous_u-d*previous_u.dot(d)).normalized()
        v=d.cross(u).normalized();previous_u=u
        for j in range(sides+1):
            angle=math.tau*j/sides
            verts.append(point+radius*(u*math.cos(angle)+v*math.sin(angle)))
            uv.append((.65+.32*j/sides,.94-.92*i/(len(points)-1)))
    faces=[]
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*(sides+1)+j
            faces.append((a,a+1,a+sides+2,a+sides+1))
    if not cloth:
        faces.extend([tuple(reversed(range(sides+1))),tuple((len(points)-1)*(sides+1)+j for j in range(sides+1))])
    obj=mesh(name,verts,faces,mat,bind,uv)
    if cloth:solidify(obj,.012)
    return obj


def cloth_shell(name,rings,bind,steps=64,folds=.04):
    verts=[];uv=[]
    for z,rx,ry in rings:
        for j in range(steps+1):
            angle=-math.pi+math.tau*j/steps
            rip=1+folds*(.75*math.cos(angle*10)+.25*math.cos(angle*17))
            zz=z+(.009*math.sin(angle*13) if z<.12 else 0)
            verts.append((rx*math.sin(angle)*rip,-ry*math.cos(angle)*rip,zz))
            uv.append((j/steps,max(0,min(1,zz/1.5))))
    faces=[]
    for i in range(len(rings)-1):
        for j in range(steps):
            a=i*(steps+1)+j;faces.append((a,a+1,a+steps+2,a+steps+1))
    obj=mesh(name,verts,faces,ROBE,bind,uv);solidify(obj,.009)
    return obj


def rope_ring(name,z,rx,ry,radius,phase=0):
    verts=[];uv=[];steps=88;sides=6
    for i in range(steps+1):
        t=math.tau*i/steps
        for j in range(sides):
            s=math.tau*j/sides
            r=radius*(1+.12*math.sin(t*27+s*2+phase))
            verts.append(((rx+r*math.cos(s))*math.sin(t),-(ry+r*math.cos(s))*math.cos(t),z+r*math.sin(s)+.008*math.sin(t*3+phase)))
            uv.append((i/steps,j/sides))
    faces=[]
    for i in range(steps):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    return mesh(name,verts,faces,ROPE,'Hips',uv)


# Human proportions under a deliberately tall, tapered full-face hood.
bone('Root',(0,0,0),(0,0,.15))
bone('Hips',(0,0,.88),(0,0,1.04),'Root')
bone('Spine',(0,0,1.04),(0,0,1.20),'Hips')
bone('Chest',(0,0,1.20),(0,0,1.40),'Spine')
bone('Neck',(0,0,1.40),(0,0,1.55),'Chest')
bone('Head',(0,0,1.55),(0,0,1.95),'Neck')
for side,suffix in [(1,'L'),(-1,'R')]:
    bone('Clavicle.'+suffix,(0,0,1.365),(side*.29,0,1.365),'Chest')
    bone('UpperArm.'+suffix,(side*.30,0,1.37),(side*.43,0,1.10),'Clavicle.'+suffix)
    bone('Forearm.'+suffix,(side*.43,0,1.10),(side*.50,-.015,.85),'UpperArm.'+suffix)
    bone('Hand.'+suffix,(side*.50,-.015,.85),(side*.50,-.025,.72),'Forearm.'+suffix)
    bone('Thigh.'+suffix,(side*.13,0,.90),(side*.14,.01,.50),'Hips')
    bone('Shin.'+suffix,(side*.14,.01,.50),(side*.14,0,.10),'Thigh.'+suffix)
    bone('Foot.'+suffix,(side*.14,0,.10),(side*.14,-.18,.05),'Shin.'+suffix)
    for which,y in [('Front',-.09),('Back',.09)]:
        name='Skirt'+which+'.'+suffix
        bone(name,(side*.17,y,.96),(side*.20,y,.55),'Hips')
        bone(name+'.Tip',(side*.20,y,.55),(side*.25,y,.16),name)

upper=cloth_shell('Robe chest',[(.87,.254,.174),(.96,.256,.176),(1.12,.277,.185),(1.29,.31,.188),(1.40,.32,.18),(1.44,.24,.15)],'Chest',folds=.022)
skirt=cloth_shell('Long robe skirt',[(.065,.445,.32),(.10,.442,.315),(.27,.414,.29),(.47,.38,.26),(.68,.335,.227),(.86,.279,.185),(.965,.255,.175)],'Hips',folds=.053)


def reset_weights(obj,initial):
    obj.vertex_groups[initial].remove(list(range(len(obj.data.vertices))))


reset_weights(upper,'Chest')
for v in upper.data.vertices:
    chest=max(0,min(1,(v.co.z-1.07)/.27))
    for name,weight in [('Chest',chest),('Spine',1-chest)]:
        group=upper.vertex_groups.get(name) or upper.vertex_groups.new(name=name)
        if weight>0:group.add([v.index],weight,'REPLACE')
reset_weights(skirt,'Hips')
for v in skirt.data.vertices:
    x,y,z=v.co
    hip=max(0,min(1,(z-.72)/.245))
    lower=max(0,min(1,(.64-z)/.40))
    left=max(0,min(1,.5+x/.24));front=max(0,min(1,.5-y/.23))
    if hip>0:skirt.vertex_groups['Hips'].add([v.index],hip,'REPLACE')
    for side,suffix,weight_side in [(1,'L',left),(-1,'R',1-left)]:
        for which,weight_front in [('Front',front),('Back',1-front)]:
            for tip,weight_tip in [(False,1-lower),(True,lower)]:
                name='Skirt'+which+'.'+suffix+('.Tip' if tip else '')
                weight=(1-hip)*weight_side*weight_front*weight_tip
                if weight>0:
                    group=skirt.vertex_groups.get(name) or skirt.vertex_groups.new(name=name)
                    group.add([v.index],weight,'REPLACE')

# Oversized open bell sleeves, with the painted chest area excluded from their UVs.
GLOVE=material('Cultist | worn work gloves','6B614A')
for side,suffix in [(1,'L'),(-1,'R')]:
    sleeve=tube('Bell sleeve '+suffix,[(side*.285,0,1.375),(side*.33,0,1.30),(side*.39,0,1.18),
        (side*.435,0,1.08),(side*.47,-.005,.96),(side*.50,-.015,.84)],
        [.12,.128,.132,.13,.155,.18],ROBE,'UpperArm.'+suffix,sides=20,cloth=True)
    reset_weights(sleeve,'UpperArm.'+suffix)
    for vertex in sleeve.data.vertices:
        upper_weight=max(0,min(1,(vertex.co.z-1.03)/.16))
        for name,weight in [('UpperArm.'+suffix,upper_weight),('Forearm.'+suffix,1-upper_weight)]:
            group=sleeve.vertex_groups.get(name) or sleeve.vertex_groups.new(name=name)
            if weight>0:group.add([vertex.index],weight,'REPLACE')
    ellipsoid('Gloved hand '+suffix,(side*.50,-.025,.79),(.067,.059,.09),GLOVE,'Hand.'+suffix)
    ellipsoid('Glove thumb '+suffix,(side*.45,-.047,.81),(.029,.038,.045),GLOVE,'Hand.'+suffix,12,6)
    ellipsoid('Boot toe '+suffix,(side*.14,-.16,.057),(.085,.20,.052),DARK,'Foot.'+suffix)
    ellipsoid('Boot ankle '+suffix,(side*.14,0,.105),(.076,.085,.095),DARK,'Foot.'+suffix)

# Elliptical cord wraps, crossed front strands, a knot, and hanging tails.
for i,z in enumerate((.894,.931,.968)):
    rope_ring('Waist rope wrap '+str(i),z,.275+i*.003,.19+i*.003,.025,i*.7)
tube('Crossed cord',[(.26,-.10,.965),(.15,-.192,.94),(-.06,-.216,.915),(-.24,-.13,.885)],[.026,.026,.026,.024],ROPE,'Hips',8)
tube('Crossed upper cord',[(-.25,-.12,.98),(-.08,-.215,.967),(.13,-.205,.93),(.26,-.10,.92)],[.022,.022,.022,.022],ROPE,'Hips',8)
ellipsoid('Rope knot',(-.23,-.147,.935),(.055,.043,.052),ROPE,'Hips',12,6)
tube('Hanging rope A',[(-.23,-.15,.92),(-.265,-.20,.80),(-.25,-.22,.69)],[.019,.019,.010],ROPE,'Hips',8)
tube('Hanging rope B',[(-.21,-.17,.92),(-.18,-.23,.83),(-.20,-.24,.75)],[.017,.017,.009],ROPE,'Hips',8)
for i in range(3):
    tube('Cord fiber '+str(i),[(-.20+i*.008,-.215,.913),(-.07+i*.008,-.236,.924),(.13+i*.008,-.212,.948)],[.002,.002,.002],FIBER,'Hips',5)

# Hood topology deliberately leaves two real eye windows; all other facial
# anatomy is hidden. The dark inner shell also forms each opening's rim.
hood_rings=[(1.36,.50,.38),(1.39,.495,.378),(1.46,.445,.35),(1.58,.40,.31),
    (1.68,.34,.285),(1.735,.30,.26),(1.805,.265,.23),(1.88,.225,.20),
    (2.0,.16,.145),(2.12,.09,.08),(2.255,.018,.014)]
angles=sorted(set(list(range(-180,181,6))+[-25,-21,-17,-13,-9,9,13,17,21,25]))
verts=[];uv=[];stride=len(angles)
for z,rx,ry in hood_rings:
    for degree in angles:
        angle=math.radians(degree)
        wrinkle=.08*max(0,(1.95-z)/.59)*math.cos(angle*7)+.015*math.sin(angle*13)
        x=rx*math.sin(angle)*(1+wrinkle)
        y=-ry*math.cos(angle)*(1+wrinkle)
        zz=z+(.012*math.sin(angle*5)+.004*math.cos(angle*11) if z<1.41 else 0)
        verts.append((x,y,zz));uv.append(((degree+180)/360,(z-1.34)/.96))
faces=[]
for i in range(len(hood_rings)-1):
    for j in range(stride-1):
        mid=(angles[j]+angles[j+1])/2
        eye_window=9<abs(mid)<25 and hood_rings[i][0]>=1.735 and hood_rings[i+1][0]<=1.805
        if eye_window:continue
        a=i*stride+j;faces.append((a,a+1,a+stride+1,a+stride))
apex=len(verts);verts.append((.012,.014,2.295));uv.append((.5,1))
for j in range(stride-1):faces.append(((len(hood_rings)-1)*stride+j,(len(hood_rings)-1)*stride+j+1,apex))
hood=mesh('Pointed hood with eye openings',verts,faces,HOOD,'Head',uv);solidify(hood,.012)
ellipsoid('Black hood interior',(0,.045,1.65),(.18,.15,.23),DARK,'Head')
for side in (-1,1):
    t=math.radians(side*17)
    center=Vector((.2825*math.sin(t),-.245*math.cos(t),1.77))
    u=Vector((.2825*math.cos(t),.245*math.sin(t),0)).normalized()
    v=Vector((-.5*math.sin(t),.43*math.cos(t),1)).normalized()
    normal=u.cross(v).normalized()
    def eye_patch(name,inset,w,h,mat):
        c=center-normal*inset
        vertices=[c-u*w-v*h,c+u*w-v*h,c+u*w+v*h,c-u*w+v*h]
        return mesh(name,vertices,[(0,1,2,3)],mat,'Head')
    eye_patch('Recessed black eye socket '+str(side),.020,.037,.025,DARK)
    eye_patch('Dim red eye '+str(side),.011,.015,.011,RED)

# Join surfaces while retaining named selection groups and blended skin weights.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
body=bpy.context.object;body.name='RiftCultist_Mesh'
tri=body.modifiers.new('Game triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=tri.name)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
unique=list(dict.fromkeys(body.data.materials))
indices=[unique.index(body.data.materials[face.material_index]) for face in body.data.polygons]
body.data.materials.clear()
for mat in unique:body.data.materials.append(mat)
for poly,index in zip(body.data.polygons,indices):poly.material_index=index
data=bpy.data.armatures.new('RiftCultist_Skeleton');rig=bpy.data.objects.new('RiftCultist',data)
bpy.context.collection.objects.link(rig);bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for name,(head,tail,parent) in bones.items():
    b=data.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
body.parent=rig;modifier=body.modifiers.new('Cultist skeleton','ARMATURE');modifier.object=rig
rig.show_in_front=True;data.display_type='STICK'
rig['description']='Ash-stained pointed hood, recessed red eyes, old ivory robe, rope belt, and an original red ritual mark.'
rig['forward']='Blender -Y / glTF +Z';rig.animation_data_create()


def pose_matrices():
    result={}
    for pb in rig.pose.bones:
        options={} if pb.parent is None else {'parent_matrix':result[pb.parent.name], 'parent_matrix_local':pb.parent.bone.matrix_local}
        result[pb.name]=pb.bone.convert_local_to_pose(pb.matrix_basis,pb.bone.matrix_local,**options)
    return result


def set_pose_matrix(name,matrix,pose):
    pb=rig.pose.bones[name]
    options={} if pb.parent is None else {'parent_matrix':pose[pb.parent.name], 'parent_matrix_local':pb.parent.bone.matrix_local}
    pb.matrix_basis=pb.bone.convert_local_to_pose(matrix,pb.bone.matrix_local,invert=True,**options)
    pose[name]=matrix


def aim_matrix(name,head,target):
    rest=rig.data.bones[name]
    q=(rest.tail_local-rest.head_local).normalized().rotation_difference((target-head).normalized())
    matrix=(q.to_matrix()@rest.matrix_local.to_3x3()).to_4x4();matrix.translation=head
    return matrix


def solve_leg(suffix,ankle,pose):
    first='Thigh.'+suffix;second='Shin.'+suffix;end='Foot.'+suffix
    head=pose[first].translation.copy();a=rig.data.bones[first].length;b=rig.data.bones[second].length
    delta=ankle-head;direction=delta.normalized();distance=min(delta.length,a+b-.0001)
    ankle=head+direction*distance
    along=(a*a-b*b+distance*distance)/(2*distance)
    bend=Vector((0,-1,0));bend=(bend-direction*bend.dot(direction)).normalized()
    joint=head+direction*along+bend*math.sqrt(max(0,a*a-along*along))
    set_pose_matrix(first,aim_matrix(first,head,joint),pose)
    set_pose_matrix(second,aim_matrix(second,joint,ankle),pose)
    matrix=rig.data.bones[end].matrix_local.copy();matrix.translation=ankle
    set_pose_matrix(end,matrix,pose)


clip_frames={'Idle':72,'Walk':40,'Attack':30}
for clip,length in clip_frames.items():
    action=bpy.data.actions.new(clip);action.use_fake_user=True;rig.animation_data.action=action
    previous={}
    for frame in range(length+1):
        t=frame/length;wave=math.sin(math.tau*t)
        attack=math.sin(math.pi*max(0,min(1,(t-.14)/.72)))**2 if clip=='Attack' else 0
        for pb in rig.pose.bones:
            pb.rotation_mode='QUATERNION';pb.location=(0,0,0);pb.scale=(1,1,1)
            rotation=Vector((0,0,0));name=pb.name;side=1 if '.L' in name else -1
            if name=='Hips':pb.location.y=(-.045-.008*math.cos(math.tau*t*2) if clip=='Walk' else .003*wave if clip=='Idle' else -.015*attack)
            if name=='Chest':rotation.x=.012*wave if clip=='Idle' else .045 if clip=='Walk' else .12*attack
            if name=='Head':rotation.z=.018*wave if clip=='Idle' else .009*wave;rotation.x=.025*attack
            if name.startswith('UpperArm'):
                rotation.x=.13*wave*side if clip=='Walk' else .01*wave
                if clip=='Attack':rotation.x=(-.82 if side<0 else -.22)*attack
            if name.startswith('Forearm'):
                rotation.x=-.04
                if clip=='Attack':rotation.x-=.37*attack
            if name.startswith('Skirt'):
                tip=name.endswith('.Tip');phase=math.sin(math.tau*t+side*.4-(.6 if tip else 0))
                rotation.x=(-.13*wave*side if clip=='Walk' else .006*wave)*(.45 if tip else 1)
                rotation.z=.012*phase if clip=='Walk' else .004*wave
            pb.rotation_quaternion=Euler(rotation,'XYZ').to_quaternion()
        pose=pose_matrices()
        for side,suffix in [(1,'L'),(-1,'R')]:
            ankle=Vector((side*.14,0,.10))
            if clip=='Walk':
                phase=(t+(0 if side==1 else .5))%1
                if phase<.62:ankle.y=-.18+.36*phase/.62
                else:
                    swing=(phase-.62)/.38
                    ankle.y=.18-.36*(swing*swing*(3-2*swing));ankle.z+=.055*math.sin(math.pi*swing)**2
            solve_leg(suffix,ankle,pose)
        for pb in rig.pose.bones:
            q=pb.rotation_quaternion.copy()
            if pb.name in previous and q.dot(previous[pb.name])<0:q.negate()
            pb.rotation_quaternion=q;previous[pb.name]=q
            pb.keyframe_insert('rotation_quaternion',frame=frame+1,group=pb.name)
            pb.keyframe_insert('location',frame=frame+1,group=pb.name)
    for fcurve in action.fcurves:
        for key in fcurve.keyframe_points:key.interpolation='LINEAR'
    action['loop']=clip!='Attack'
rig.animation_data.action=bpy.data.actions['Idle'];scene.frame_start=1;scene.frame_end=73;scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'RiftCultist.glb'),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,
    export_cameras=False,export_lights=False)


def point_at(obj,target):obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
studio=bpy.data.collections.new('STUDIO - excluded from GLB');scene.collection.children.link(studio)
def move_to_studio(obj):
    for collection in list(obj.users_collection):collection.objects.unlink(obj)
    studio.objects.link(obj)
floor=material('Studio charcoal','161B20')
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.012));bpy.context.object.data.materials.append(floor);move_to_studio(bpy.context.object)
for name,loc,energy,color,size in [
    ('Overcast key',(-3,-5,7),1050,(1,.91,.79),4),
    ('Cold fill',(4,-2,4),460,(.66,.79,1),4),
    ('Rim',(1,4,6),1400,(.8,.86,.75),3)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.color=color;light.shape='DISK';light.size=size
    obj=bpy.data.objects.new(name,light);studio.objects.link(obj);obj.location=loc;point_at(obj,(0,0,1.1))
camera=bpy.data.objects.new('Preview camera',bpy.data.cameras.new('Preview camera'));studio.objects.link(camera)
camera.location=(2.6,-7,2.7);point_at(camera,(0,0,1.13));camera.data.type='ORTHO';camera.data.ortho_scale=2.85;scene.camera=camera
scene.world.color=(.10,.10,.10)
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.04;scene.cycles.max_bounces=4
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
scene.render.resolution_x=1000;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.render.filepath=str(PREVIEW/'RiftCultist.png')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.color_type='MATERIAL';area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'RiftCultist.blend'),compress=True)
bpy.ops.render.render(write_still=True)

# A second native Blender scene provides front, three-quarter and rear views.
rig.animation_data_clear()
for pb in rig.pose.bones:pb.rotation_quaternion=(1,0,0,0);pb.location=(0,0,0)
rig.location.x=-1.65
for x,angle,label in [(0,-.5,'Three-quarter'),(1.65,math.pi,'Rear')]:
    copy=rig.copy();copy.data=rig.data.copy();copy.animation_data_clear();copy.name='Cultist '+label
    scene.collection.objects.link(copy);copy.location.x=x;copy.rotation_euler.z=angle
    duplicate=body.copy();duplicate.name='Robe '+label;scene.collection.objects.link(duplicate);duplicate.parent=copy
    for modifier in duplicate.modifiers:
        if modifier.type=='ARMATURE':modifier.object=copy
camera.location=(0,-9,3.0);point_at(camera,(0,0,1.10));camera.data.ortho_scale=5.7
bpy.context.view_layer.update()
def caption(text,x,y,size,color):
    curve=bpy.data.curves.new(text,'FONT');curve.body=text;curve.align_x='CENTER';curve.size=size;curve.space_character=1.15
    obj=bpy.data.objects.new(text,curve);studio.objects.link(obj);obj.rotation_euler=camera.rotation_euler
    obj.location=camera.matrix_world@Vector((x,y,-7))
    mat=material('Type '+text,color);shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Emission Color'].default_value=mat.diffuse_color;shader.inputs['Emission Strength'].default_value=.7
    curve.materials.append(mat)
caption('R I F T   C U L T I S T',0,1.62,.15,'DDD0B9')
caption('POINTED HOOD  /  ASH-STAINED CLOTH  /  RECESSED RED EYES',0,1.37,.052,'A6B2B5')
for x,label in [(-1.65,'FRONT'),(0,'THREE-QUARTER'),(1.65,'REAR')]:caption(label,x,-1.35,.08,'C5B299')
caption('BLENDER + GLB  /  RIGGED  /  ORIGINAL PAINTED TEXTURES',0,-1.61,.047,'A6B2B5')
scene.render.resolution_x=1800;scene.render.resolution_y=1200
scene.render.filepath=str(PREVIEW/'RiftCultist_Turnaround.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'RiftCultist_Turnaround.blend'),compress=True)
bpy.ops.render.render(write_still=True)
vertices=[v.co for v in body.data.vertices]
report={'name':'Rift Cultist','generator':'Blender '+bpy.app.version_string,
    'triangles':len(body.data.polygons),'vertices_blender':len(body.data.vertices),'bones':len(data.bones),'materials':len(body.data.materials),
    'animations_seconds':{name:frames/24 for name,frames in clip_frames.items()},
    'looping_clips':['Idle','Walk'],'non_looping_clips':['Attack'],
    'bounds_blender_m':{'min':[min(v[i] for v in vertices) for i in range(3)],'max':[max(v[i] for v in vertices) for i in range(3)]},
    'texture_resolution':[512,512],'textures':['textures/Cultist_Robe_BaseColor.png','textures/Cultist_Hood_BaseColor.png'],
    'forward':'Blender -Y; glTF +Z','up':'Blender Z; glTF Y','units':'metres',
    'design':'Reference-inspired tall pointed hood, real eye openings, dim red eyes, stained ivory bell-sleeved robe, rope belt and original red broken-gate sigil.',
    'external_art_used':False,'runtime_roster_integration':False}
(EXPORT/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print('CULTIST_COMPLETE',json.dumps(report))
