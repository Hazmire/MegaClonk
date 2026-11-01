"""Standalone Blender 4.3+ generator; no external assets or add-ons.
Run from the repository root:
blender -b -t 8 --python art/protagonist/generate_investigator.py
"""
import bpy
import math
import json
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/protagonist'
EXPORT = ROOT / 'assets/characters/investigator'
PREVIEW = ROOT / 'docs/images/protagonist'
for folder in (SOURCE, EXPORT, PREVIEW):
    folder.mkdir(parents=True, exist_ok=True)
sys.path.insert(0,str(SOURCE))
from animation_clips import build_actions, CLIPS
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
scene = bpy.context.scene
scene.render.fps = 24
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1


def material(name, value, roughness=.85, metallic=0):
    rgb = [int(value[i:i+2],16)/255 for i in (0,2,4)]
    rgb = [v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*rgb,1)
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*rgb,1)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Metallic'].default_value = metallic
    shader.inputs['Specular IOR Level'].default_value = .22 if not metallic else .5
    return m


COAT = material('01 | dark brown waxed canvas', '44352C')
FOLD = material('02 | worn brown edges and seams', '594738')
LINING = material('03 | coat lining and hat band', '262323')
HAT = material('04 | dark brown felt', '292422')
SHIRT = material('05 | charcoal shirt and trousers', '303439')
LEATHER = material('06 | gloves boots and radio', '202326', .72)
FACE = material('07 | featureless shadow', '171717', 1)
FACE.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.04
BRASS = material('08 | tarnished hardware', '827665', .55, .45)

parts = []
bones = {}


def bone(name, head, tail, parent=None):
    bones[name] = (head,tail,parent)


def part(obj, name, mat, bind='Chest', smooth=True):
    obj.name = name
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth = smooth
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    group = obj.vertex_groups.new(name=bind)
    group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    # These extra groups preserve named garment selections after joining.
    region = obj.vertex_groups.new(name='PART | '+name)
    region.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    parts.append(obj)
    return obj


def mesh(name, vertices, faces, mat, bind='Chest', smooth=True):
    data=bpy.data.meshes.new(name)
    data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True);bpy.context.view_layer.objects.active=obj
    return part(obj,name,mat,bind,smooth)


def ico(name,loc,scale,mat,bind='Chest',sub=2,smooth=True):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=min(4,sub+1),radius=1,location=loc)
    obj=bpy.context.object;obj.scale=scale
    return part(obj,name,mat,bind,smooth)


def box(name,loc,scale,mat,bind='Chest',bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    obj=bpy.context.object;obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    m=obj.modifiers.new('Rounded manufactured edges','BEVEL')
    m.width=bevel or min(.004,min(scale)*.16);m.segments=5
    bpy.ops.object.modifier_apply(modifier=m.name)
    return part(obj,name,mat,bind)


def refine(obj,levels=1):
    bpy.context.view_layer.objects.active=obj
    modifier=obj.modifiers.new('Smooth surface refinement','SUBSURF')
    modifier.levels=levels;modifier.render_levels=levels
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for polygon in obj.data.polygons:polygon.use_smooth=True
    return obj


def tube(name,points,radii,mat,bind='Chest',sides=10,smooth=True):
    # Support rings retain the silhouette while rounding the end transitions.
    points=list(points);radii=list(radii)
    p0=Vector(points[0]);p1=Vector(points[1])
    pn=Vector(points[-1]);pp=Vector(points[-2])
    points=[points[0],p0.lerp(p1,.045)]+points[1:-1]+[pn.lerp(pp,.045),points[-1]]
    radii=[radii[0],radii[0]*.955+radii[1]*.045]+radii[1:-1]+[radii[-1]*.955+radii[-2]*.045,radii[-1]]
    sides=max(16,sides*2)
    verts=[]
    previous_u=None
    for i,(point,radius) in enumerate(zip(points,radii)):
        p=Vector(point)
        direction=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized()
        if previous_u is None:
            ref=Vector((0,0,1)) if abs(direction.z)<.95 else Vector((0,1,0))
            u=direction.cross(ref).normalized()
        else:
            # Transport the radial frame along the curve. Changing the reference
            # axis midway twists adjacent rings and pinches a smooth sleeve.
            u=(previous_u-direction*previous_u.dot(direction)).normalized()
        v=direction.cross(u).normalized();previous_u=u
        for j in range(sides):
            t=math.tau*j/sides
            verts.append(p+radius*(u*math.cos(t)+v*math.sin(t)))
    faces=[tuple(reversed(range(sides)))]
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple((len(points)-1)*sides+j for j in range(sides)))
    obj=mesh(name,verts,faces,mat,bind,smooth)
    if max(radii)>.018:refine(obj,2 if max(radii)>.085 else 1)
    return obj


def shell(name,rings,start,end,mat,bind='Chest',steps=18,thickness=.006,folds=0):
    """Elliptical clothing shell with real thickness and restrained vertical folds."""
    rings=list(rings)
    first,second=rings[0],rings[1]
    last,previous=rings[-1],rings[-2]
    rings=[first,tuple(a*.955+b*.045 for a,b in zip(first,second))]+rings[1:-1]+[tuple(a*.955+b*.045 for a,b in zip(last,previous)),last]
    steps=max(32,steps*2)
    verts=[]
    for i,(z,rx,ry) in enumerate(rings):
        for j in range(steps+1):
            t=math.radians(start+(end-start)*j/steps)
            ripple=1+folds*math.cos(t*8)*(1-(z-rings[0][0])/max(.001,rings[-1][0]-rings[0][0]))
            verts.append((rx*math.sin(t)*ripple,-ry*math.cos(t)*ripple,z))
    faces=[]
    for i in range(len(rings)-1):
        for j in range(steps):
            a=i*(steps+1)+j
            faces.append((a,a+1,a+steps+2,a+steps+1))
    obj=mesh(name,verts,faces,mat,bind)
    modifier=obj.modifiers.new('Fabric thickness','SOLIDIFY');modifier.thickness=thickness
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return refine(obj,2 if rings[-1][0]-rings[0][0]>.5 else 1)


def plate(name,points,mat,bind='Chest',thickness=.008):
    obj=mesh(name,points,[tuple(range(len(points)))],mat,bind)
    modifier=obj.modifiers.new('Cloth edge','SOLIDIFY');modifier.thickness=thickness
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bevel=obj.modifiers.new('Soft lapel edge','BEVEL');bevel.width=.002;bevel.segments=3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return obj


bone('Root',(0,0,0),(0,0,.16))
bone('Hips',(0,0,1.03),(0,0,1.2),'Root')
bone('Spine',(0,0,1.2),(0,0,1.43),'Hips')
bone('Chest',(0,0,1.43),(0,0,1.64),'Spine')
bone('Neck',(0,0,1.64),(0,0,1.74),'Chest')
bone('Head',(0,0,1.74),(0,0,1.97),'Neck')
for side,suffix in [(1,'L'),(-1,'R')]:
    bone('Clavicle.'+suffix,(0,0,1.6),(side*.25,0,1.6),'Chest')
    bone('UpperArm.'+suffix,(side*.25,0,1.6),(side*.37,.005,1.31),'Clavicle.'+suffix)
    bone('Forearm.'+suffix,(side*.37,.005,1.31),(side*.43,-.025,1.055),'UpperArm.'+suffix)
    bone('Hand.'+suffix,(side*.43,-.025,1.055),(side*.447,-.035,.945),'Forearm.'+suffix)
    bone('Thigh.'+suffix,(side*.115,0,1.04),(side*.125,.015,.59),'Hips')
    bone('Shin.'+suffix,(side*.125,.015,.59),(side*.13,0,.17),'Thigh.'+suffix)
    bone('Foot.'+suffix,(side*.13,0,.17),(side*.13,-.17,.075),'Shin.'+suffix)
    for which in ('Front','Back'):
        y=-.09 if which=='Front' else .10
        base='Coat'+which+'.'+suffix
        bone(base,(side*.16,y,1.16),(side*.21,y,.79),'Hips')
        bone(base+'.Tip',(side*.21,y,.79),(side*.26,y,.43),base)

# Torso, a plain shirt beneath an open coat.
box('Trouser pelvis',(0,0,1.10),(.38,.19,.18),SHIRT,'Hips',bevel=.025)
box('Trouser fly seam',(0,-.098,1.065),(.004,.004,.08),LINING,'Hips')
shirt=shell('Plain charcoal shirt',[(1.13,.19,.125),(1.32,.215,.135),(1.53,.245,.135),(1.65,.12,.1)],0,360,SHIRT,steps=20)
shell('Shirt collar',[(1.63,.09,.075),(1.70,.065,.06)],0,360,LINING,'Neck',steps=14)
box('Shirt placket',(0,-.137,1.47),(.025,.007,.26),LINING)
for z in (1.42,1.49,1.56):
    ico('Shirt button',(0,-.145,z),(.006,.005,.006),BRASS,sub=1)

# Coat upper body wraps around the back, with an open front and broad lapels.
shell('Duster torso',[(1.16,.226,.158),(1.34,.239,.166),(1.54,.277,.175),(1.66,.185,.12)],32,328,COAT,steps=24,folds=.015)
for side,suffix in [(1,'L'),(-1,'R')]:
    plate('Broad lapel '+suffix,[(side*.095,-.105,1.695),(side*.22,-.145,1.60),(side*.177,-.19,1.48),(side*.075,-.18,1.30),(side*.13,-.19,1.52)],FOLD)
    plate('Notched lapel inset '+suffix,[(side*.10,-.115,1.69),(side*.18,-.156,1.63),(side*.147,-.18,1.57)],COAT)
    tube('Front facing seam '+suffix,[(side*.074,-.174,1.18),(side*.083,-.179,1.31),(side*.17,-.185,1.49)],[.006,.006,.004],FOLD,sides=5)
    for z in (1.24,1.35,1.46):
        ico('Duster button '+suffix,(side*.155,-.156,z),(.011,.006,.011),BRASS,'Spine',sub=2)
shell('Raised back collar',[(1.62,.135,.103),(1.73,.108,.089)],58,302,FOLD,steps=18)
shell('Shoulder storm cape',[(1.49,.282,.192),(1.61,.283,.181),(1.675,.16,.121)],65,295,COAT,steps=20,thickness=.008)
shell('Storm cape hem',[(1.486,.283,.194),(1.502,.284,.194)],65,295,FOLD,steps=20,thickness=.004)
plate('Rear yoke center seam',[(-.006,.187,1.50),(.006,.187,1.50),(.005,.126,1.666),(-.005,.126,1.666)],FOLD)

# Four independently articulated coat panels; open front and a rear riding slit.
for side,suffix in [(1,'L'),(-1,'R')]:
    for which,angle0,angle1 in [('Front',16,94),('Back',94,175)]:
        if side<0:
            angle0,angle1=360-angle1,360-angle0
        bind='Coat'+which+'.'+suffix
        panel=shell('Duster '+which.lower()+' panel '+suffix,
            [(.43,.35,.255),(.62,.326,.241),(.82,.285,.209),(1.02,.259,.183),(1.18,.226,.159)],
            angle0,angle1,COAT,bind,steps=10,thickness=.009,folds=.045)
        # Smoothly blend pelvis, upper-tail and lower-tail bones over the fabric.
        main=panel.vertex_groups[bind]
        main.remove(list(range(len(panel.data.vertices))))
        hip=panel.vertex_groups.new(name='Hips');tip=panel.vertex_groups.new(name=bind+'.Tip')
        for v in panel.data.vertices:
            z=v.co.z
            wh=max(0,min(1,(z-1.04)/.14))
            wt=max(0,min(1,(.88-z)/.34))
            wm=1-wh-wt
            for group,weight in [(hip,wh),(main,wm),(tip,wt)]:
                if weight>0:group.add([v.index],weight,'REPLACE')
        # Narrow weathered hem and front/rear edge strips, bound to tail tips.
        shell('Weathered '+which.lower()+' hem '+suffix,[(.428,.351,.257),(.447,.351,.257)],angle0,angle1,FOLD,bind+'.Tip',steps=10,thickness=.004,folds=.025)
        edge_angle=math.radians(angle0 if (which=='Front')==(side>0) else angle1)
        points=[]
        for z,rx,ry in [(.44,.352,.258),(.8,.288,.213),(1.16,.229,.162)]:
            points.append((rx*math.sin(edge_angle),-ry*math.cos(edge_angle),z))
        # Upper and lower edge stitches remain with their respective tail bones.
        tube('Panel edge lower '+which+suffix,points[:2],[.004,.004],FOLD,bind+'.Tip',5)
        tube('Panel edge upper '+which+suffix,points[1:],[.004,.004],FOLD,bind,5)
    # Slanted welt pockets and broad understated cuffs.
    bind='CoatFront.'+suffix
    plate('Pocket welt '+suffix,[(side*.105,-.183,1.015),(side*.238,-.118,1.063),(side*.239,-.12,1.087),(side*.105,-.188,1.039)],LINING,bind)
    tube('Pocket lip '+suffix,[(side*.105,-.192,1.04),(side*.24,-.123,1.085)],[.009,.009],FOLD,bind,6)

shell('Waist belt',[(1.145,.231,.162),(1.184,.231,.162)],0,360,LINING,'Hips',steps=24)
box('Belt buckle',(0,-.169,1.164),(.054,.013,.042),BRASS,'Hips',.004)
box('Buckle inset',(0,-.178,1.164),(.033,.006,.025),LINING,'Hips',.002)
box('Buckle pin',(0,-.184,1.164),(.004,.003,.028),BRASS,'Hips')

for side,suffix in [(1,'L'),(-1,'R')]:
    upper='UpperArm.'+suffix;lower='Forearm.'+suffix;hand='Hand.'+suffix
    tube('Tailored sleeve '+suffix,
        [(side*.224,0,1.603),(side*.265,0,1.575),(side*.306,0,1.49),
         (side*.34,.002,1.40),(side*.366,.005,1.32),(side*.376,.004,1.294),
         (side*.389,0,1.25),(side*.406,-.01,1.18),(side*.43,-.025,1.065)],
        [.098,.112,.105,.098,.087,.083,.085,.078,.068],COAT,upper,16)
    tube('Cuff facing '+suffix,[(side*.428,-.025,1.09),(side*.432,-.025,1.057)],[.071,.071],FOLD,lower,12)
    box('Cuff strap '+suffix,(side*.44,-.091,1.083),(.073,.012,.022),COAT,lower,.003)
    ico('Cuff stud '+suffix,(side*.445,-.103,1.083),(.006,.004,.006),BRASS,lower,sub=1)
    ico('Gloved palm '+suffix,(side*.441,-.03,1.014),(.054,.047,.073),LEATHER,hand,sub=2,smooth=True)
    for digit in range(4):
        x=side*(.407+digit*.022)
        tube('Glove finger '+suffix+str(digit),[(x,-.038,.996),(x,-.05,.955+abs(1.5-digit)*.005)],[.014,.012],LEATHER,hand,7,True)
    tube('Glove thumb '+suffix,[(side*.404,-.047,1.027),(side*.387,-.065,.995)],[.022,.015],LEATHER,hand,8,True)
    # Continuous trouser silhouette with concealed knee overlap.
    thigh='Thigh.'+suffix;shin='Shin.'+suffix;foot='Foot.'+suffix
    tube('Trouser leg '+suffix,
        [(side*.113,0,1.075),(side*.12,0,.92),(side*.123,0,.80),(side*.125,.01,.68),
         (side*.125,.015,.59),(side*.127,.008,.48),(side*.13,0,.30)],
        [.118,.109,.102,.09,.084,.076,.067],SHIRT,thigh,16)
    tube('Boot shaft '+suffix,[(side*.13,0,.13),(side*.13,.008,.34)],[.075,.084],LEATHER,shin,12)
    tube('Boot top rim '+suffix,[(side*.13,.008,.322),(side*.13,.008,.343)],[.085,.085],LINING,shin,12)
    box('Boot sole '+suffix,(side*.13,-.087,.041),(.174,.328,.065),LINING,foot,.015)
    box('Rounded leather toe '+suffix,(side*.13,-.12,.102),(.164,.25,.115),LEATHER,foot,.043)
    box('Boot heel '+suffix,(side*.13,.028,.026),(.153,.093,.045),LEATHER,foot,.008)
    box('Boot ankle '+suffix,(side*.13,-.015,.15),(.15,.151,.13),LEATHER,foot,.025)
    for z in (.18,.212,.244):
        tube('Boot lacing '+suffix,[(side*.10,-.072,z),(side*.16,-.072,z-.01)],[.003,.003],LINING,shin,5)

# Plain featureless head. No ears, nose, eye sockets, mouth, or face texture.
tube('Shadowed neck',[(0,0,1.66),(0,0,1.77)],[.065,.071],FACE,'Neck',14,True)
ico('Unfeatured face',(0,-.013,1.825),(.103,.096,.149),FACE,'Head',sub=3,smooth=True)

# Broad brim with a turned edge and a pinched, creased felt crown.
hat_start=len(parts)
verts=[];faces=[];segments=80
for ring,(rx,ry,z) in enumerate([(.145,.13,1.963),(.23,.205,1.955),(.34,.286,1.947),(.35,.294,1.958)]):
    for j in range(segments):
        t=math.tau*j/segments
        tilt=.018*math.sin(t)**2-.012*math.cos(t)-.03*max(0,math.cos(t))
        verts.append((rx*math.sin(t),-ry*math.cos(t),z+tilt))
for ring in range(3):
    for j in range(segments):
        a=ring*segments+j;b=ring*segments+(j+1)%segments
        faces.append((a,b,b+segments,a+segments))
brim=mesh('Broad felt hat brim',verts,faces,HAT,'Head',True)
modifier=brim.modifiers.new('Brim thickness','SOLIDIFY');modifier.thickness=.012
bpy.ops.object.modifier_apply(modifier=modifier.name)
refine(brim,2)
verts=[];faces=[];segments=64
for level,(rx,ry,z) in enumerate([(.155,.136,1.96),(.158,.139,2.015),(.139,.117,2.105),(.075,.061,2.076)]):
    for j in range(segments):
        t=math.tau*j/segments
        pinch=1-(.16*max(0,math.cos(t))*abs(math.sin(2*t)) if level>=2 else 0)
        verts.append((rx*math.sin(t)*pinch,-ry*math.cos(t),z+.006*math.cos(2*t)))
for level in range(3):
    for j in range(segments):
        a=level*segments+j;b=level*segments+(j+1)%segments
        faces.append((a,b,b+segments,a+segments))
faces.append(tuple(range(3*segments,4*segments)))
refine(mesh('Pinched fedora crown',verts,faces,HAT,'Head'),2)
shell('Dark grosgrain hatband',[(1.968,.158,.139),(1.995,.161,.142)],0,360,LINING,'Head',steps=32,thickness=.004)
box('Hatband knot',(-.159,0,1.982),(.012,.049,.029),LINING,'Head',.004)
for obj in parts[hat_start:]:
    obj.location.z-=.075

# Analog belt radio and a small leather document pouch: no modern tactical gear.
box('Analog field radio',(-.232,-.09,1.185),(.079,.062,.142),LEATHER,'Hips',.007)
box('Radio speaker',(-.232,-.125,1.206),(.057,.009,.055),LINING,'Hips',.004)
for z in (1.19,1.202,1.214):
    box('Radio grille',(-.232,-.132,z),(.045,.004,.003),BRASS,'Hips')
tube('Radio aerial',[(-.252,-.08,1.252),(-.252,-.08,1.346)],[.006,.004],LEATHER,'Hips',7)
ico('Radio channel dial',(-.212,-.08,1.259),(.011,.011,.012),BRASS,'Hips',sub=1)
box('Leather document pouch',(.229,.055,1.095),(.065,.122,.141),COAT,'Hips',.009)
box('Pouch flap',(.267,.055,1.136),(.009,.126,.064),FOLD,'Hips',.004)
ico('Pouch snap',(.275,.055,1.124),(.005,.008,.008),BRASS,'Hips',sub=1)

# Assemble a single editable skinned mesh, retaining semantic selection groups.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join()
body=bpy.context.object;body.name='Investigator_Mesh'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
tri=body.modifiers.new('Export triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=tri.name)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.uv.smart_project(island_margin=.01)
bpy.ops.object.mode_set(mode='OBJECT')
unique=list(dict.fromkeys(body.data.materials))
indices=[unique.index(body.data.materials[p.material_index]) for p in body.data.polygons]
body.data.materials.clear()
for m in unique:body.data.materials.append(m)
for p,i in zip(body.data.polygons,indices):p.material_index=i

# Blend the upper torso and sleeves near their joints. Coat panels already carry
# explicit multi-bone weights; rigid hardware, hat, and gloves stay rigid.
def blend_region(region,low,high,parent,child):
    selection=body.vertex_groups.get('PART | '+region)
    if selection is None:return
    pg=body.vertex_groups.get(parent) or body.vertex_groups.new(name=parent)
    cg=body.vertex_groups.get(child) or body.vertex_groups.new(name=child)
    for v in body.data.vertices:
        if any(g.group==selection.index for g in v.groups):
            weight=max(0,min(1,(v.co.z-low)/(high-low)))
            pg.add([v.index],1-weight,'REPLACE');cg.add([v.index],weight,'REPLACE')

for region in ('Duster torso','Plain charcoal shirt'):
    blend_region(region,1.18,1.50,'Spine','Chest')
for side,suffix in [(1,'L'),(-1,'R')]:
    blend_region('Tailored sleeve '+suffix,1.25,1.39,'Forearm.'+suffix,'UpperArm.'+suffix)
    blend_region('Trouser leg '+suffix,.53,.69,'Shin.'+suffix,'Thigh.'+suffix)

data=bpy.data.armatures.new('Investigator_Skeleton')
rig=bpy.data.objects.new('Investigator',data);bpy.context.collection.objects.link(rig)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for name,(head,tail,parent) in bones.items():
    b=data.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front=True;data.display_type='STICK'
body.parent=rig
modifier=body.modifiers.new('Investigator skeleton','ARMATURE');modifier.object=rig
rig['design']='1990s rural Appalachian horror; dark brown duster, dark hat, no facial features.'
rig['forward']='Blender -Y / glTF +Z'
rig['animation_note']='Baked FK and foot contacts; root stationary; Jump has a 0.42 m local hip arc.'
rig.animation_data_create()


clips=build_actions(rig)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);body.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'Investigator.glb'),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_anim_slide_to_zero=True,
    export_frame_range=False,export_force_sampling=True,export_skins=True,export_def_bones=True,
    export_cameras=False,export_lights=False)


def point_at(obj,target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()


studio=bpy.data.collections.new('STUDIO - excluded from GLB');scene.collection.children.link(studio)
def studio_object(obj):
    for col in list(obj.users_collection):col.objects.unlink(obj)
    studio.objects.link(obj)


floor=material('Studio | charcoal','161C21')
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.012))
bpy.context.object.data.materials.append(floor);studio_object(bpy.context.object)
for name,loc,power,color,size in [
    ('Soft overcast key',(-3,-4,5),650,(1,.89,.78),4),
    ('Cold window fill',(3,-1,3),125,(.65,.78,1),3),
    ('Pale green rim',(1,3,4),900,(.75,.88,.8),3)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.color=color;light.shape='DISK';light.size=size
    obj=bpy.data.objects.new(name,light);studio.objects.link(obj);obj.location=loc;point_at(obj,(0,0,1.1))
cam_data=bpy.data.cameras.new('Presentation camera');cam=bpy.data.objects.new('Presentation camera',cam_data)
studio.objects.link(cam);cam.location=(3.0,-6.5,2.9);point_at(cam,(0,0,1.09))
cam_data.type='ORTHO';cam_data.ortho_scale=2.65;scene.camera=cam
scene.world.color=(.055,.055,.055)
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.035;scene.cycles.max_bounces=4
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG';scene.render.resolution_percentage=100
scene.render.resolution_x=1000;scene.render.resolution_y=1200
scene.render.filepath=str(PREVIEW/'Investigator.png')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.color_type='MATERIAL'
            area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'Investigator.blend'),compress=True)
if '--skip-portrait' not in sys.argv:bpy.ops.render.render(write_still=True)

# Three views of the actual mesh and rig, all sharing the same source geometry.
rig.animation_data.action=None
for pb in rig.pose.bones:
    pb.rotation_euler=(0,0,0);pb.rotation_quaternion=(1,0,0,0);pb.location=(0,0,0)
rig.location.x=-1.55
for angle,x,label in [(math.radians(-35),0,'Three-quarter'),(math.pi,1.55,'Rear')]:
    copy=rig.copy();copy.data=rig.data.copy();copy.name='Investigator '+label;scene.collection.objects.link(copy)
    copy.animation_data_clear();copy.location.x=x;copy.rotation_euler.z=angle
    duplicate=body.copy();duplicate.name='Mesh '+label;scene.collection.objects.link(duplicate);duplicate.parent=copy
    for modifier in duplicate.modifiers:
        if modifier.type=='ARMATURE':modifier.object=copy
cam.location=(0,-9,3.1);point_at(cam,(0,0,1.15));cam_data.ortho_scale=5.35
bpy.context.view_layer.update()


def caption(text,x,y,size,color):
    data=bpy.data.curves.new(text,'FONT');data.body=text;data.align_x='CENTER';data.size=size;data.space_character=1.15
    obj=bpy.data.objects.new(text,data);studio.objects.link(obj);obj.rotation_euler=cam.rotation_euler
    obj.location=cam.matrix_world@Vector((x,y,-7))
    m=material('Type | '+text,color)
    shader=m.node_tree.nodes.get('Principled BSDF');shader.inputs['Emission Color'].default_value=m.diffuse_color;shader.inputs['Emission Strength'].default_value=.7
    data.materials.append(m)


caption('T H E   I N V E S T I G A T O R',0,1.47,.125,'D7C8B3')
caption('1990s  /  APPALACHIAN HORROR  /  PROTAGONIST STUDY',0,1.26,.051,'95A4A6')
for x,title,detail in [(-1.55,'FRONT','FEATURELESS / SHADOWED FACE'),(0,'THREE-QUARTER','DARK BROWN DUSTER / FELT HAT'),(1.55,'REAR','STORM CAPE / SPLIT COAT TAILS')]:
    caption(title,x,-1.27,.073,'C5B299');caption(detail,x,-1.41,.036,'95A4A6')
scene.render.resolution_x=1800;scene.render.resolution_y=1120
scene.render.filepath=str(PREVIEW/'Investigator_Turnaround.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'Investigator_Turnaround.blend'),compress=True)
bpy.ops.render.render(write_still=True)

vertices=[v.co for v in body.data.vertices]
report={'name':'The Investigator','generator':'Blender '+bpy.app.version_string,
    'triangles':len(body.data.polygons),'vertices_blender':len(body.data.vertices),
    'bones':len(rig.data.bones),'materials':len(body.data.materials),'animations_seconds':clips,
    'bounds_blender_m':{'min':[min(v[i] for v in vertices) for i in range(3)],'max':[max(v[i] for v in vertices) for i in range(3)]},
    'forward':'Blender -Y; glTF +Z','up':'Blender Z; glTF Y','units':'metres',
    'design':'Smooth high-density dark brown duster, lowered hat with downturned front brim, featureless shadowed face. 1990s Appalachian horror investigator.',
    'surface_style':'Smooth shaded, rounded edges, subdivided garments and hat',
    'hat_lowering_m':.075,
    'facial_features':False,'external_assets':False,
    'looping_clips':[name for name,meta in CLIPS.items() if meta['loop']],
    'non_looping_clips':[name for name,meta in CLIPS.items() if not meta['loop']],
    'animation_details':CLIPS,
    'root_motion':'None. Slide is stationary horizontally; game controller supplies travel.',
    'jump_motion':'Local hips provide a 0.42 m visual arc; match or remove this channel for a physics-driven jump.'}
(EXPORT/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print('INVESTIGATOR_COMPLETE',json.dumps(report))
