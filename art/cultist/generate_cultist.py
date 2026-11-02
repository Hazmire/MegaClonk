"""Rift Bellkeeper: revised original cultist. Blender 4.3+, no external art.
blender -b -t 8 --python-exit-code 1 --python art/cultist/generate_cultist.py
"""
import bpy
import bmesh
import math
import json
import sys
import numpy as np
from pathlib import Path
from mathutils import Vector, Euler

NO_RENDER='--no-render' in sys.argv

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
    clean=np.array((77,90,83) if hood else (172,168,148),dtype=float)
    mud=np.array((29,36,33) if hood else (70,63,44),dtype=float)
    rgb=clean[None,None,:]*(1-dirt[:,:,None])+mud[None,None,:]*dirt[:,:,None]
    rgb*= (1-.085*(np.cos(u*math.tau*(9 if hood else 11))*.5+.5))[:,:,None]
    rgb+=(grain[:,:,None]-.5)*28+(medium[:,:,None]-.5)*15
    # Cloth binding along the bottom, with small pale, worn stitch marks.
    hem=(v>.015)&(v<.033)
    rgb[hem]*=.66
    stitches=(v>.039)&(v<.044)&((u*100)%1<.40)
    rgb[stitches]=np.array((131,126,111) if hood else (159,152,133))
    if not hood:
        # Offset tailoring and a contrasting repaired side panel break the
        # symmetry of the original ivory robe and central placket.
        panel=(u>.60)&(u<.84)&(v<.73)
        rgb[panel]=rgb[panel]*np.array((.47,.55,.51))
        placket=.47+.055*(v-.3)
        seam=np.abs(u-placket)<.0035
        rgb[seam]*=.68
        edge=(np.abs(u-placket)>.0035)&(np.abs(u-placket)<.006)
        rgb[edge]*=1.08
        # Broken concentric stitch circles replace the reference-like red glyph.
        dx=(u-.488)/.057;dy=(v-.765)/.083
        radius=np.sqrt(dx*dx+dy*dy);angle=np.arctan2(dy,dx)
        stitches=((angle/math.tau*36)%1)<.55
        rings=((np.abs(radius-1)<.055)|(np.abs(radius-.64)<.045))&stitches
        rings&=~((angle>-.30)&(angle<.16))
        paint=np.array((197,174,119))[None,None,:]*(.83+.24*grain[:,:,None])
        alpha=rings.astype(float)*(.75+.20*medium)
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


ROBE=material('Cultist | repaired ash-linen robe','ACA894',cloth_texture('Cultist_Robe_BaseColor'))
HOOD=material('Cultist | charcoal-green cowl and mantle','4D5A53',cloth_texture('Cultist_Hood_BaseColor',True))
DARK=material('Cultist | shadow lining and leather','211E19')
ROPE=material('Cultist | old brown rope','32251A')
FIBER=material('Cultist | old ochre stitching','9A8052')
RED=material('Cultist | recessed red eyes','A62B21',emission=.45)
AMBER=material('Cultist | censer embers','D09B46',emission=.45)
IRON=material('Cultist | blackened iron fittings','414039')
IRON.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.65
IRON.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.7
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


def cloth_shell(name,rings,bind,steps=64,folds=.04,mat=None,split=False,asymmetric=False):
    verts=[];uv=[]
    for z,rx,ry in rings:
        for j in range(steps+1):
            if split:
                gap=math.radians(32)*max(0,min(1,(.72-z)/.59))**.8
                angle=gap+(math.tau-2*gap)*j/steps
            else:angle=-math.pi+math.tau*j/steps
            rip=1+folds*(.75*math.cos(angle*10)+.25*math.cos(angle*17))
            hem_weight=max(0,1-z/.73)
            zz=z+(.009*math.sin(angle*13) if z<.12 else 0)
            if asymmetric:
                zz+=hem_weight*(.10+.055*math.sin(angle)+.018*math.sin(angle*19))
            verts.append((rx*math.sin(angle)*rip,-ry*math.cos(angle)*rip,zz))
            uv.append(((angle+math.pi)/math.tau,max(0,min(1,zz/1.5))))
    faces=[]
    for i in range(len(rings)-1):
        for j in range(steps):
            a=i*(steps+1)+j;faces.append((a,a+1,a+steps+2,a+steps+1))
    obj=mesh(name,verts,faces,mat or ROBE,bind,uv)
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    bm.to_mesh(obj.data);bm.free();obj.data.update()
    solidify(obj,.009)
    return obj


def rope_ring(name,z,rx,ry,radius,phase=0):
    verts=[];uv=[];steps=88;sides=6
    for i in range(steps+1):
        t=math.tau*i/steps
        for j in range(sides):
            s=math.tau*j/sides
            r=radius*(1+.12*math.sin(t*27+s*2+phase))
            verts.append(((rx+r*math.cos(s))*math.sin(t),-(ry+r*math.cos(s))*math.cos(t),z+r*math.sin(s)+.003*math.sin(t*3+phase)))
            uv.append((i/steps,j/sides))
    faces=[]
    for i in range(steps):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    return mesh(name,verts,faces,ROPE,'Hips',uv)


# Humanoid proportions under the collapsed, asymmetric cowl.
bone('Root',(0,0,0),(0,0,.15))
bone('Hips',(0,0,.88),(0,0,1.04),'Root')
bone('Spine',(0,0,1.04),(0,0,1.20),'Hips')
bone('Chest',(0,0,1.20),(0,0,1.40),'Spine')
bone('Neck',(0,0,1.40),(0,0,1.55),'Chest')
bone('Head',(0,0,1.55),(0,0,1.95),'Neck')
for side,suffix in [(1,'L'),(-1,'R')]:
    bone('Clavicle.'+suffix,(0,0,1.365),(side*.29,0,1.365),'Chest')
    bone('UpperArm.'+suffix,(side*.30,0,1.37),(side*.47,0,1.10),'Clavicle.'+suffix)
    bone('Forearm.'+suffix,(side*.47,0,1.10),(side*.54,-.015,.85),'UpperArm.'+suffix)
    bone('Hand.'+suffix,(side*.54,-.015,.85),(side*.54,-.025,.72),'Forearm.'+suffix)
    bone('Thigh.'+suffix,(side*.13,0,.90),(side*.14,.01,.50),'Hips')
    bone('Shin.'+suffix,(side*.14,.01,.50),(side*.14,0,.10),'Thigh.'+suffix)
    bone('Foot.'+suffix,(side*.14,0,.10),(side*.14,-.18,.05),'Shin.'+suffix)
    for which,y in [('Front',-.09),('Back',.09)]:
        name='Skirt'+which+'.'+suffix
        bone(name,(side*.17,y,.96),(side*.20,y,.55),'Hips')
        bone(name+'.Tip',(side*.20,y,.55),(side*.25,y,.16),name)

# One continuous outer garment removes the former overlapping waist shells.
skirt=cloth_shell('Asymmetric split outer robe',[(.13,.445,.32),(.18,.435,.308),(.32,.407,.284),(.47,.38,.26),(.68,.335,.227),(.86,.279,.185),(.965,.255,.175),(1.12,.277,.185),(1.29,.31,.188),(1.40,.32,.18),(1.44,.24,.15)],'Hips',folds=.035,split=True,asymmetric=True)
under=cloth_shell('Dark inner tunic',[(.32,.35,.245),(.40,.34,.235),(.52,.32,.22),(.72,.285,.19),(.93,.224,.142)],'Hips',folds=.025,mat=HOOD)


def reset_weights(obj,initial):
    obj.vertex_groups[initial].remove(list(range(len(obj.data.vertices))))


def torso_weights(obj):
    reset_weights(obj,'Chest')
    for vertex in obj.data.vertices:
        chest=max(0,min(1,(vertex.co.z-1.07)/.27))
        hips=max(0,min(1,(1.075-vertex.co.z)/.11))
        for name,weight in [('Chest',chest),('Spine',(1-chest)*(1-hips)),('Hips',(1-chest)*hips)]:
            if weight>0:
                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                group.add([vertex.index],weight,'REPLACE')

for garment in (skirt,under):
    reset_weights(garment,'Hips')
    for v in garment.data.vertices:
        x,y,z=v.co
        if z>=.965:
            chest=max(0,min(1,(z-1.07)/.27))
            hips=max(0,min(1,(1.075-z)/.11))
            for name,weight in [('Chest',chest),('Spine',(1-chest)*(1-hips)),('Hips',(1-chest)*hips)]:
                if weight>0:
                    group=garment.vertex_groups.get(name) or garment.vertex_groups.new(name=name)
                    group.add([v.index],weight,'REPLACE')
            continue
        hip=max(0,min(1,(z-.72)/.245))
        lower=max(0,min(1,(.64-z)/.40))
        left=max(0,min(1,.5+x/.24));front=max(0,min(1,.5-y/.23))
        if hip>0:garment.vertex_groups['Hips'].add([v.index],hip,'REPLACE')
        for side,suffix,weight_side in [(1,'L',left),(-1,'R',1-left)]:
            for which,weight_front in [('Front',front),('Back',1-front)]:
                for tip,weight_tip in [(False,1-lower),(True,lower)]:
                    name='Skirt'+which+'.'+suffix+('.Tip' if tip else '')
                    weight=(1-hip)*weight_side*weight_front*weight_tip
                    if weight>0:
                        group=garment.vertex_groups.get(name) or garment.vertex_groups.new(name=name)
                        group.add([v.index],weight,'REPLACE')

# Mismatched sleeves: one dark fitted cuff, one ragged linen bell sleeve.
GLOVE=material('Cultist | worn work gloves','6B614A')
for side,suffix in [(1,'L'),(-1,'R')]:
    sleeve=tube('Bell sleeve '+suffix,[(side*.285,0,1.375),(side*.33,0,1.30),(side*.43,0,1.18),
        (side*.475,0,1.08),(side*.51,-.005,.96),(side*.54,-.015,.84)],
        [.12,.128,.132,.13,.122 if side>0 else .13,.13 if side>0 else .145],HOOD if side>0 else ROBE,'UpperArm.'+suffix,sides=24,cloth=True)
    reset_weights(sleeve,'UpperArm.'+suffix)
    for vertex in sleeve.data.vertices:
        upper_weight=max(0,min(1,(vertex.co.z-1.03)/.16))
        for name,weight in [('UpperArm.'+suffix,upper_weight),('Forearm.'+suffix,1-upper_weight)]:
            group=sleeve.vertex_groups.get(name) or sleeve.vertex_groups.new(name=name)
            if weight>0:group.add([vertex.index],weight,'REPLACE')
    ellipsoid('Gloved hand '+suffix,(side*.54,-.025,.79),(.067,.059,.09),GLOVE,'Hand.'+suffix)
    ellipsoid('Glove thumb '+suffix,(side*.49,-.047,.81),(.029,.038,.045),GLOVE,'Hand.'+suffix,12,6)
    ellipsoid('Boot toe '+suffix,(side*.14,-.16,.057),(.085,.20,.052),DARK,'Foot.'+suffix)
    ellipsoid('Boot ankle '+suffix,(side*.14,0,.105),(.076,.085,.095),DARK,'Foot.'+suffix)

# Elliptical cord wraps, crossed front strands, a knot, and hanging tails.
for i,z in enumerate((.91,.954,.998)):
    rope_ring('Waist rope wrap '+str(i),z,.305+i*.003,.229+i*.003,.018,i*.7)
tube('Crossed cord',[(.27,-.12,.99),(.15,-.224,.96),(-.06,-.25,.93),(-.24,-.17,.90)],[.020,.020,.020,.020],ROPE,'Hips',8)
tube('Crossed upper cord',[(-.25,-.15,1.00),(-.08,-.25,.985),(.13,-.237,.95),(.27,-.12,.94)],[.018,.018,.018,.018],ROPE,'Hips',8)
ellipsoid('Rope knot',(-.23,-.188,.958),(.050,.041,.047),ROPE,'Hips',12,6)
tube('Hanging rope A',[(-.23,-.20,.94),(-.30,-.25,.82),(-.34,-.28,.71)],[.017,.017,.010],ROPE,'Hips',8)
tube('Hanging rope B',[(-.21,-.215,.94),(-.31,-.24,.85),(-.34,-.26,.77)],[.015,.015,.009],ROPE,'Hips',8)
for i in range(3):
    tube('Cord fiber '+str(i),[(-.20+i*.008,-.215,.913),(-.07+i*.008,-.236,.924),(.13+i*.008,-.212,.948)],[.002,.002,.002],FIBER,'Hips',5)


def torus(name,location,radius,thickness,mat,bind,rotation=(math.pi/2,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=5,major_radius=radius,minor_radius=thickness,
        location=location,rotation=rotation)
    obj=bpy.context.object;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    vertices=[v.co.copy() for v in obj.data.vertices];faces=[tuple(p.vertices) for p in obj.data.polygons]
    bpy.data.objects.remove(obj,do_unlink=True)
    return mesh(name,vertices,faces,mat,bind)


# A broad diagonal harness and a suspended iron censer give the cult a practical,
# industrial ritual identity rather than the previous uniform priest's robe.
from mathutils.bvhtree import BVHTree
robe_tree=BVHTree.FromObject(skirt,bpy.context.evaluated_depsgraph_get())
for front,name in [(True,'Diagonal leather harness'),(False,'Rear harness')]:
    vertices=[];faces=[];sign=-1 if front else 1
    for i in range(25):
        t=.18+.82*i/24;z=1.43-.44*t;cx=-.22+.44*t
        for edge in (-1,1):
            x=cx+.030*edge
            hit,normal,_,_=robe_tree.ray_cast(Vector((x,sign*2,z)),Vector((0,-sign,0)))
            assert hit is not None
            vertices.append(hit+Vector((0,sign*.020,0)))
    for i in range(24):
        a=i*2;faces.append((a,a+1,a+3,a+2) if front else (a+2,a+3,a+1,a))
    strap=mesh(name,vertices,faces,ROPE,'Chest')
    solidify(strap,.009,False);torso_weights(strap)
for z in (.87,.915,.96):
    torus('Censer chain',(-.32,-.16,z),.021,.005,IRON,'Hips',rotation=(math.pi/2 if z==.915 else 0,0,0))
ellipsoid('Censer coal chamber',(-.32,-.16,.681),(.069,.059,.025),DARK,'Hips',16,8)
ellipsoid('Censer glowing coals',(-.32,-.17,.744),(.060,.052,.052),AMBER,'Hips',12,6)
ellipsoid('Censer domed lid',(-.32,-.16,.806),(.082,.070,.029),IRON,'Hips',16,6)
ellipsoid('Censer bowl',(-.32,-.16,.669),(.079,.068,.035),IRON,'Hips',16,6)
for i in range(8):
    t=math.tau*i/8
    x=-.32+.077*math.sin(t);y=-.16+.066*math.cos(t)
    tube('Censer iron cage',[(x,y,.68),(x,y,.795)],[.007,.007],IRON,'Hips',6)
torus('Censer rim',(-.32,-.16,.785),.077,.007,IRON,'Hips',rotation=(0,0,0))
# Move the entire rigid assembly clear of both the robe and the reaching arm.
for obj in parts:
    if obj.name.startswith('Censer'):
        for vertex in obj.data.vertices:vertex.co+=Vector((.12,-.19,0))
tube('Censer belt hanger',[(-.20,-.23,.99),(-.20,-.35,.96),(-.20,-.35,.94)],[.007,.007,.007],IRON,'Hips',8)
for z in (.90,.95):
    center=Vector((.54-.28*(z-.84),-.015+.06*(z-.84),z))
    direction=Vector((.28,-.06,-1)).normalized()
    u=direction.cross(Vector((0,1,0))).normalized();v=direction.cross(u).normalized()
    radius=.13-(z-.84)*.067+.008
    points=[center+radius*(u*math.cos(math.tau*i/32)+v*math.sin(math.tau*i/32)) for i in range(33)]
    tube('Fitted sleeve binding',points,[.003]*33,ROPE,'Forearm.L',6)

# A collapsed, hooked cowl replaces the full conical hood. Its opening is a
# pair of recessed red eyes, with a separately draped shoulder mantle.
hood_rings=[(1.53,.25,.205,0,0),(1.64,.283,.233,0,0),
    (1.735,.255,.215,-.01,0),(1.795,.25,.21,-.02,0),
    (1.85,.233,.195,-.04,.012),(1.94,.185,.16,-.085,.03),
    (2.04,.13,.122,-.15,.055),(2.11,.068,.082,-.225,.08),
    (2.12,.022,.039,-.305,.095)]
angles=sorted(set(list(range(-180,181,6))+[-28,-24,-18,-12,-8,8,12,18,24,28]))
def hood_point(z,degree):
    pair=(hood_rings[-2],hood_rings[-1])
    for first,second in zip(hood_rings,hood_rings[1:]):
        if first[0]<=z<=second[0]:pair=(first,second);break
    first,second=pair
    t=max(0,min(1,(z-first[0])/(second[0]-first[0])))
    rx,ry,cx,cy=[a+(b-a)*t for a,b in zip(first[1:],second[1:])]
    angle=math.radians(degree)
    wrinkle=.04*max(0,1-(z-1.48)/.65)*math.cos(angle*5)+.012*math.sin(angle*13)
    return Vector((cx+rx*math.sin(angle)*(1+wrinkle),cy-ry*math.cos(angle)*(1+wrinkle),z))
verts=[];uv=[];stride=len(angles)
for z,rx,ry,cx,cy in hood_rings:
    for degree in angles:
        verts.append(hood_point(z,degree));uv.append(((degree+180)/360,(z-1.44)/.73))
faces=[]
for i in range(len(hood_rings)-1):
    for j in range(stride-1):
        mid=(angles[j]+angles[j+1])/2
        eye_window=8<abs(mid)<28 and hood_rings[i][0]>=1.735 and hood_rings[i+1][0]<=1.795
        if eye_window:continue
        a=i*stride+j;faces.append((a,a+1,a+stride+1,a+stride))
apex=len(verts);verts.append((-.365,.102,2.145));uv.append((.5,.97))
for j in range(stride-1):faces.append(((len(hood_rings)-1)*stride+j,(len(hood_rings)-1)*stride+j+1,apex))
hood=mesh('Hooked collapsed cowl',verts,faces,HOOD,'Head',uv);solidify(hood,.012)
ellipsoid('Black cowl interior',(0,.045,1.65),(.18,.15,.23),DARK,'Head')
def eye_patch(name,center,width,low,high,mat,inset):
    degrees=[center-width+2*width*i/12 for i in range(13)]
    vertices=[]
    for z in (low,high):
        for degree in degrees:
            angle=math.radians(degree)
            normal=Vector((math.sin(angle),-math.cos(angle),.08)).normalized()
            vertices.append(hood_point(z,degree)-normal*inset)
    faces=[(i,i+1,i+14,i+13) for i in range(12)]
    return mesh(name,vertices,faces,mat,'Head')
for side in (-1,1):
    eye_patch('Recessed black eye socket '+str(side),side*18,11,1.733,1.797,DARK,.024)
    eye_patch('Dim red eye '+str(side),side*18,4,1.751,1.779,RED,.016)
for degree in (-36,36):
    points=[hood_point(z,degree)+Vector((0,-.006,0)) for z in (1.810,1.852)]
    tube('Cowl iron staple',points,[.004,.004],IRON,'Head',6)

verts=[];uv=[];faces=[];steps=48
mantle_rings=[(1.20,.61,.35),(1.28,.60,.34),(1.41,.52,.31),(1.49,.39,.27),(1.54,.28,.245)]
for i in range(len(mantle_rings)):
    for j in range(steps+1):
        degree=35+290*j/steps;angle=math.radians(degree)
        # Sample every row along the same angular rays. Rotating successive
        # rows twisted faces through one another at the rear shoulder folds.
        # The front edge rises into an open arm slit instead.
        nearest_front=min(degree,360-degree)
        low=1.20 if nearest_front>=120 else 1.43-.21*(nearest_front-35)/85
        z=low+(1.54-low)*i/(len(mantle_rings)-1)
        for first,second in zip(mantle_rings,mantle_rings[1:]):
            if first[0]<=z<=second[0]+1e-6:
                t=(z-first[0])/(second[0]-first[0])
                rx=first[1]+(second[1]-first[1])*t
                ry=first[2]+(second[2]-first[2])*t
                break
        weight=max(0,(1.54-z)/.34)
        hem=.10*math.sin(angle)+.024*math.sin(angle*11)+.016*math.sin(angle*17)
        verts.append((rx*math.sin(angle),-ry*math.cos(angle),z+weight*hem))
        uv.append((.15+.72*j/steps,(z-1.10)/.45))
# Ease the longer right shoulder panel outward by up to 45 mm. This preserves
# its uneven hem while clearing the upper sleeve in the bind and reach poses.
verts=[(x-.045*max(0,min(1,(1.54-z)/.25))*max(0,min(1,(-x-.22)/.18)),y,z) for x,y,z in verts]
for i in range(len(mantle_rings)-1):
    for j in range(steps):
        a=i*(steps+1)+j;faces.append((a,a+1,a+steps+2,a+steps+1))
mantle=mesh('Ragged asymmetric shoulder mantle',verts,faces,HOOD,'Chest',uv);solidify(mantle,.013)
def mantle_weights(obj):
    reset_weights(obj,'Chest')
    for vertex in obj.data.vertices:
        x,y,z=vertex.co
        arm=max(0,min(1,(abs(x)-.28)/.10))
        arm=arm*arm*(3-2*arm)
        suffix='L' if x>=0 else 'R'
        upper=max(0,min(1,(z-1.03)/.16))
        for name,weight in [('Chest',1-arm),('UpperArm.'+suffix,arm*upper),('Forearm.'+suffix,arm*(1-upper))]:
            if weight>0:
                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                group.add([vertex.index],weight,'REPLACE')
mantle_weights(mantle)
for j in range(0,steps,3):
    a=Vector(verts[j]);b=Vector(verts[j+1])
    for point in (a,b):
        outward=Vector((point.x/.60**2,point.y/.34**2,0)).normalized()
        point+=outward*.005;point.z+=.008
    stitch=tube('Mantle hem stitch',[a,b],[.002,.002],FIBER,'Chest',5)
    mantle_weights(stitch)

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
rig['description']='Rift Bellkeeper: hooked charcoal cowl, two recessed red eyes, ragged mantle, split repaired robe, circular stitching and iron censer.'
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


def solve_arm(suffix,wrist,pose,reach):
    # Keep the elbows outside the waist while the hands swing/reach forward.
    # Local Euler swings previously pulled the bell cuffs through the belt.
    first='UpperArm.'+suffix;second='Forearm.'+suffix;end='Hand.'+suffix
    head=pose[first].translation.copy();a=rig.data.bones[first].length;b=rig.data.bones[second].length
    delta=wrist-head;direction=delta.normalized();distance=min(delta.length,a+b-.0001)
    wrist=head+direction*distance
    along=(a*a-b*b+distance*distance)/(2*distance)
    side=1 if suffix=='L' else -1
    bend=Vector((side,0,.1));bend=(bend-direction*bend.dot(direction)).normalized()
    elbow=head+direction*along+bend*math.sqrt(max(0,a*a-along*along))
    set_pose_matrix(first,aim_matrix(first,head,elbow),pose)
    set_pose_matrix(second,aim_matrix(second,elbow,wrist),pose)
    set_pose_matrix(end,aim_matrix(end,wrist,wrist+Vector((0,-.02-.10*reach,-.12+.06*reach))),pose)


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
            reach=.60*attack*(1 if side<0 else .35)
            wrist=Vector((side*.58,-.42*reach+(.055*wave*side if clip=='Walk' else 0),.90+.12*reach))
            solve_arm(suffix,wrist,pose,reach)
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
if not NO_RENDER:bpy.ops.render.render(write_still=True)

# A second native Blender scene provides front, three-quarter and rear views.
rig.animation_data_clear()
# Keep the checked idle pose for the presentation scene as well.
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
    obj.location=camera.matrix_world@Vector((x,y,-6))
    mat=material('Type '+text,color);shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Emission Color'].default_value=mat.diffuse_color;shader.inputs['Emission Strength'].default_value=.7
    curve.materials.append(mat)
caption('R I F T   B E L L K E E P E R',0,1.62,.15,'DDD0B9')
caption('HOOKED COWL  /  RECESSED RED EYES  /  IRON CENSER',0,1.37,.052,'A6B2B5')
for x,label in [(-1.65,'FRONT'),(0,'THREE-QUARTER'),(1.65,'REAR')]:caption(label,x,-1.35,.08,'C5B299')
caption('BLENDER + GLB  /  RIGGED  /  ORIGINAL PAINTED TEXTURES',0,-1.61,.047,'A6B2B5')
scene.render.resolution_x=1800;scene.render.resolution_y=1200
scene.render.filepath=str(PREVIEW/'RiftCultist_Turnaround.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'RiftCultist_Turnaround.blend'),compress=True)
if not NO_RENDER:bpy.ops.render.render(write_still=True)
vertices=[v.co for v in body.data.vertices]
report={'name':'Rift Bellkeeper','design_revision':3,'generator':'Blender '+bpy.app.version_string,
    'triangles':len(body.data.polygons),'vertices_blender':len(body.data.vertices),'bones':len(data.bones),'materials':len(body.data.materials),
    'animations_seconds':{name:frames/24 for name,frames in clip_frames.items()},
    'looping_clips':['Idle','Walk'],'non_looping_clips':['Attack'],
    'bounds_blender_m':{'min':[min(v[i] for v in vertices) for i in range(3)],'max':[max(v[i] for v in vertices) for i in range(3)]},
    'texture_resolution':[512,512],'textures':['textures/Cultist_Robe_BaseColor.png','textures/Cultist_Hood_BaseColor.png'],
    'forward':'Blender -Y; glTF +Z','up':'Blender Z; glTF Y','units':'metres',
    'design':'Hooked charcoal-green cowl, two recessed red eyes, asymmetric ragged mantle, continuous split ash-linen robe over dark tunic, ochre stitch circles, leather harness and suspended iron censer.',
    'external_art_used':False,'runtime_roster_integration':False}
(EXPORT/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print('CULTIST_COMPLETE',json.dumps(report))
