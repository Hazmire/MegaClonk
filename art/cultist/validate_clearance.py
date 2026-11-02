"""Check independently moving garment/prop layers at every half frame.
blender -b -t 8 --python-exit-code 1 --python art/cultist/validate_clearance.py

Armholes, knots, sewn trim, glove/thumb joins, and metal assembly joints are
intentional attachments. This checks clearance between the separate layers,
not whether a constructed joint contains overlapping attachment geometry.
"""
import bpy
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector
from mathutils.geometry import intersect_ray_tri
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'art/cultist/RiftCultist.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene
rig=bpy.data.objects['RiftCultist']
body=bpy.data.objects['RiftCultist_Mesh']
parts={}
for group in body.vertex_groups:
    if not group.name.startswith('PART | '):continue
    ids={v.index for v in body.data.vertices if any(g.group==group.index and g.weight>.5 for g in v.groups)}
    parts[group.name[7:]]=[tuple(p.vertices) for p in body.data.polygons if all(i in ids for i in p.vertices)]
outer='Asymmetric split outer robe';inner='Dark inner tunic'
mantle='Ragged asymmetric shoulder mantle';cowl='Hooked collapsed cowl'
parts['Censer assembly']=[face for name,faces in list(parts.items())
    if name.startswith('Censer') and name!='Censer belt hanger' for face in faces]
pairs=[]
def pair(a,b):
    assert parts[a] and parts[b],(a,b)
    if (a,b) not in pairs and (b,a) not in pairs:pairs.append((a,b))
pair(outer,inner);pair(outer,mantle);pair(cowl,mantle)
for side in ('L','R'):
    sleeve='Bell sleeve '+side
    # The closed torso intentionally continues inside the sewn armhole. Only
    # the upper attachment (rest z >= 1.15 m) is exempt from this specific pair.
    lower=sleeve+' below armhole'
    parts[lower]=[f for f in parts[sleeve] if max(body.data.vertices[i].co.z for i in f)<1.15]
    pair(outer,lower)
    for other in (mantle,'Mantle hem stitch','Censer assembly','Diagonal leather harness','Rear harness'):
        pair(sleeve,other)
    for hand in ('Gloved hand '+side,'Glove thumb '+side):
        for other in (mantle,outer,'Censer assembly'):pair(hand,other)
    for boot in ('Boot toe '+side,'Boot ankle '+side):
        pair(outer,boot);pair(inner,boot)
    for belt in ['Waist rope wrap '+str(i) for i in range(3)]+['Crossed cord','Crossed upper cord','Rope knot','Hanging rope A','Hanging rope B']:
        pair(sleeve,belt)
for belt in ['Waist rope wrap '+str(i) for i in range(3)]+['Crossed cord','Crossed upper cord','Rope knot','Hanging rope A','Hanging rope B']:
    pair(outer,belt)
for garment in (outer,inner):pair('Censer assembly',garment)
for tail in ('Hanging rope A','Hanging rope B'):pair('Censer assembly',tail)
for strap in ('Diagonal leather harness','Rear harness'):pair(outer,strap)
for eye in ('Dim red eye -1','Dim red eye 1'):pair(cowl,eye)
used={name for p in pairs for name in p}
regions={}
for name in used:
    faces=parts[name];ids=sorted({v for f in faces for v in f});mapping={v:i for i,v in enumerate(ids)}
    regions[name]=(ids,[tuple(mapping[v] for v in f) for f in faces])
self_regions={}
outside={tuple(p.vertices) for p in body.data.polygons
    if body.data.materials[p.material_index].name.startswith(('Cultist | repaired','Cultist | charcoal'))}
for name in (outer,inner,mantle,cowl,'Bell sleeve L','Bell sleeve R'):
    faces=[f for f in parts[name] if f in outside]
    ids=sorted({v for f in faces for v in f});mapping={};positions={};representatives=[]
    for i in ids:
        key=tuple(round(c,6) for c in body.data.vertices[i].co)
        if key not in positions:
            positions[key]=len(representatives);representatives.append(i)
        mapping[i]=positions[key]
    self_regions[name]=(representatives,[tuple(mapping[v] for v in f) for f in faces])

def crosses(first,second,points):
    # Reject boundary touches and coincident UV seams; detect strict crossings
    # of non-adjacent exterior triangles in the posed cloth.
    for source,target in ((first,second),(second,first)):
        tri=[points[i] for i in target]
        for j in range(3):
            start=points[source[j]];delta=points[source[(j+1)%3]]-start
            if delta.length_squared<1e-16:continue
            hit=intersect_ray_tri(*tri,delta,start,True)
            if hit is None:continue
            t=(hit-start).dot(delta)/delta.length_squared
            if not .00001<t<.99999:continue
            a=tri[1]-tri[0];b=tri[2]-tri[0];c=hit-tri[0]
            aa=a.dot(a);ab=a.dot(b);bb=b.dot(b);ca=c.dot(a);cb=c.dot(b)
            denominator=aa*bb-ab*ab
            if abs(denominator)<1e-18:continue
            u=(bb*ca-ab*cb)/denominator;v=(aa*cb-ab*ca)/denominator
            if u>1e-5 and v>1e-5 and u+v<.99999:return True
    return False

errors={};counts={};minimum_z=math.inf
for clip,length in [('Rest',0),('Idle',72),('Walk',40),('Attack',30)]:
    rig.animation_data.action=None if clip=='Rest' else bpy.data.actions[clip]
    if clip=='Rest':
        for pb in rig.pose.bones:
            pb.rotation_quaternion=(1,0,0,0);pb.location=(0,0,0)
    frames=[1+i*.5 for i in range(length*2+1)];counts[clip]=len(frames)
    for frame in frames:
        scene.frame_set(int(frame),subframe=frame-int(frame));bpy.context.view_layer.update()
        evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
        vertices=[evaluated.matrix_world@v.co for v in mesh.vertices]
        minimum_z=min(minimum_z,min(v.z for v in vertices))
        trees={name:BVHTree.FromPolygons([vertices[i] for i in ids],faces,all_triangles=True)
            for name,(ids,faces) in regions.items()}
        for a,b in pairs:
            overlaps=trees[a].overlap(trees[b])
            if overlaps:
                key=a+' / '+b
                item=errors.setdefault(key,{'samples':0,'first_clip':clip,'first_frame':frame,'max_triangle_contacts':0})
                item['samples']+=1;item['max_triangle_contacts']=max(item['max_triangle_contacts'],len(overlaps))
        for name,(ids,faces) in self_regions.items():
            points=[vertices[i] for i in ids]
            tree=BVHTree.FromPolygons(points,faces,all_triangles=True)
            contacts=sum(1 for a,b in tree.overlap(tree) if a<b
                and not (set(faces[a])&set(faces[b])) and crosses(faces[a],faces[b],points))
            if contacts:
                item=errors.setdefault(name+' exterior self-crossing',{'samples':0,'first_clip':clip,'first_frame':frame,'max_triangle_contacts':0})
                item['samples']+=1;item['max_triangle_contacts']=max(item['max_triangle_contacts'],contacts)
        # Both pupils must be visible through actual hood apertures. Check a
        # frontal viewing cone rather than only the hero camera's one angle.
        for name in ('Dim red eye -1','Dim red eye 1'):
            ids=regions[name][0];center=sum((vertices[i] for i in ids),Vector())/len(ids)
            orientation=(rig.pose.bones['Head'].matrix@rig.data.bones['Head'].matrix_local.inverted()).to_3x3()
            for degree in (-20,0,20):
                direction=(orientation@Vector((math.sin(math.radians(degree)),-math.cos(math.radians(degree)),.05))).normalized()
                hit,_,_,_=trees[cowl].ray_cast(center+direction*.001,direction,.5)
                if hit is not None:
                    key=name+' visibility'
                    item=errors.setdefault(key,{'samples':0,'first_clip':clip,'first_frame':frame})
                    item['samples']+=1
        evaluated.to_mesh_clear()
    print('CLEARANCE_CLIP_SAMPLED',clip,len(frames),flush=True)
if minimum_z<-.001:errors['ground']={'minimum_z_m':minimum_z}
report={'checks':'passed' if not errors else 'failed','design_revision':3,
    'method':'triangle intersections on evaluated skinned mesh; every half frame',
    'sampled_poses':counts,'total_sampled_poses':sum(counts.values()),
    'separate_layer_pairs':len(pairs),'pairs':[list(p) for p in pairs],
    'exterior_self_checked_parts':list(self_regions),
    'eye_visibility':'two red pupils clear through apertures across frontal +/-20 degree cone' if not any('visibility' in k for k in errors) else 'failed',
    'minimum_ground_clearance_m':round(minimum_z,6),
    'intentional_attachments':'Sewn upper armholes above rest z=1.15 m, knots and cord crossings, embedded hem stitches, glove/thumb joins, and censer metal assembly joints are not separate clearance layers.',
    'limitations':'Checks cover the supplied clips and sampled poses, not arbitrary future retargeting or runtime cloth simulation.',
    'source_blend_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
    'failures':errors}
output=ROOT/'assets/characters/cultist/clearance_validation.json'
output.write_text(json.dumps(report,indent=2)+'\n')
print('CULTIST_CLEARANCE_VALIDATED',json.dumps({k:v for k,v in report.items() if k!='pairs'}))
assert not errors,errors
