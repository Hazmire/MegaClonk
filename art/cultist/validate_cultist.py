"""Audit the exported GLB using the Python standard library.
python art/cultist/validate_cultist.py
"""
import json
import math
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
EXPORT=ROOT/'assets/characters/cultist'
path=EXPORT/'RiftCultist.glb';raw=path.read_bytes()
magic,version,length=struct.unpack_from('<4sII',raw)
assert magic==b'glTF' and version==2 and length==len(raw)
n,kind=struct.unpack_from('<I4s',raw,12);assert kind==b'JSON'
g=json.loads(raw[20:20+n]);size,kind=struct.unpack_from('<I4s',raw,20+n)
assert kind==b'BIN\x00';binary=raw[28+n:28+n+size]
components={5121:('B',1),5123:('H',2),5125:('I',4),5126:('f',4)}
widths={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
def read(index):
    a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
    code,width=components[a['componentType']];count=widths[a['type']]
    offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',width*count)
    assert offset+(a['count']-1)*stride+width*count<=len(binary)
    values=[struct.unpack_from('<'+code*count,binary,offset+i*stride) for i in range(a['count'])]
    assert all(math.isfinite(x) for row in values for x in row)
    return values
assert len(g['meshes'])==1 and len(g['skins'])==1
assert len(g['skins'][0]['joints'])==28
assert len(read(g['skins'][0]['inverseBindMatrices']))==28
assert not g.get('cameras')
assert len(g['images'])==2
for img in g['images']:
    assert 'uri' not in img and img['mimeType']=='image/png'
    view=g['bufferViews'][img['bufferView']]
    data=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
    assert data[:8]==b'\x89PNG\r\n\x1a\n'
    assert struct.unpack_from('>II',data,16)==(512,512)
assert all(s.get('magFilter')==9728 for s in g['samplers'])
triangles=0
for primitive in g['meshes'][0]['primitives']:
    assert primitive.get('mode',4)==4
    a=primitive['attributes']
    positions=read(a['POSITION']);normals=read(a['NORMAL']);uvs=read(a['TEXCOORD_0'])
    weights=read(a['WEIGHTS_0']);joints=read(a['JOINTS_0'])
    assert len(positions)==len(normals)==len(uvs)==len(weights)==len(joints)
    assert all(abs(sum(row)-1)<.0001 for row in weights)
    assert all(0<=x<28 for row in joints for x in row)
    assert all(abs(sum(x*x for x in row)-1)<.002 for row in normals)
    ids=[x[0] for x in read(primitive['indices'])]
    assert len(ids)%3==0 and all(0<=i<len(positions) for i in ids)
    triangles+=len(ids)//3
clips={}
for animation in g['animations']:
    name=animation['name'];end=0
    for sampler in animation['samplers']:
        times=[x[0] for x in read(sampler['input'])];values=read(sampler['output'])
        assert len(times)==len(values) and abs(times[0])<.00001
        assert all(a<b for a,b in zip(times,times[1:]))
        end=max(end,times[-1])
        if name in ('Idle','Walk'):assert all(abs(a-b)<.0001 for a,b in zip(values[0],values[-1]))
    assert abs(end-{'Idle':3,'Walk':40/24,'Attack':30/24}[name])<.0001
    clips[name]=end
assert set(clips)=={'Idle','Walk','Attack'}
report={'checks':'passed','triangles':triangles,'materials':len(g['materials']),'bones':28,
    'embedded_textures':2,'texture_resolution':[512,512],'nearest_texture_sampling':True,
    'animations_seconds':clips,'idle_walk_loop_endpoints':'match','external_files_required_by_glb':False,
    'skin_weights_and_normals':'normalized','glb_bytes':len(raw)}
(EXPORT/'glb_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('CULTIST_GLB_VALIDATED',json.dumps(report))
