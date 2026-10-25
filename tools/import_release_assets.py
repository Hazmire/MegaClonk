"""Select runtime-only glTF assets from the four verified assets-v1 archives."""
from pathlib import Path
import zipfile,json
root=Path(__file__).resolve().parents[1];target=root/'assets/quaternius';target.mkdir(exist_ok=True)
def put(p,b):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
def gltf(z,n,out):
 d=json.loads(z.read(n));put(out/Path(n).name,z.read(n))
 for entry in d.get('images',[])+d.get('buffers',[]):
  if 'uri' in entry and not entry['uri'].startswith('data:'):put(out/entry['uri'],z.read(str(Path(n).parent/entry['uri'])))
archive=root/'builds/assets-v1'
z=zipfile.ZipFile(archive/'Modular.Character.Outfits.-.Fantasy.Standard.zip')
n=next(n for n in z.namelist() if n.endswith('Outfits/Male_Ranger.gltf'));gltf(z,n,target/'ranger')
put(target/'ranger/LICENSE.txt',z.read(next(n for n in z.namelist() if n.endswith('License_Standard.txt'))))
z=zipfile.ZipFile(archive/'Universal.Animation.Library.2.Standard.zip')
n=next(n for n in z.namelist() if n.endswith('/UAL2_Standard.glb'));put(target/'animations/UAL2_Standard.glb',z.read(n));put(target/'animations/LICENSE.txt',z.read(next(n for n in z.namelist() if n.endswith('/License.txt'))))
z=zipfile.ZipFile(archive/'Bestiary.-.Dungeon.Monsters.Kit.Standard.zip')
for model in ['Imp','Puglin']:
 n=next(n for n in z.namelist() if n.endswith('/'+model+'.glb'));put(target/'bestiary'/(model+'.glb'),z.read(n))
put(target/'bestiary/LICENSE.txt',z.read(next(n for n in z.namelist() if n.endswith('License_Standard.txt'))))
z=zipfile.ZipFile(archive/'Stylized.Nature.MegaKit.Standard.zip')
for model in ['CommonTree_1','CommonTree_3','CommonTree_5','Bush_Common','Bush_Common_Flowers','Grass_Common_Short','Fern_1','Flower_3_Group','Rock_Medium_1']:
 matches=[n for n in z.namelist() if n=='glTF/'+model+'.gltf']
 if not matches:
  print('Unavailable nature selection:',model);continue
 gltf(z,matches[0],target/'nature')
put(target/'nature/LICENSE.txt',z.read('License_Standard.txt'))
print('Imported selected runtime assets. Nature alternatives:',[Path(n).stem for n in z.namelist() if n.endswith('.gltf') and ('Rock' in n or 'Log' in n)])
