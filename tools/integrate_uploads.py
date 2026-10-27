"""Extract supplied runtime assets without importing their standalone demo projects."""
from pathlib import Path
import zipfile,json,re,ctypes as c
root=Path(__file__).resolve().parents[1]
def put(path,data):
 p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
for archive,category,prefix in [('Free-Undead-Skill-Pixel-Art-Icons.zip','weapons','PNG/'),('free-undead-loot-pixel-art-icons.zip','items','PNG/Transperent/')]:
 z=zipfile.ZipFile(root/archive)
 for n in z.namelist():
  m=re.fullmatch(re.escape(prefix)+r'Icon(\d+)\.png',n)
  if m:put(Path('assets/vendor')/category/('Icon'+m[1]+'.png'),z.read(n))
 put(Path('assets/vendor')/category/'License.txt',z.read('License.txt'))
z=zipfile.ZipFile(root/'psx-fx-free-assets.zip')
for n in z.namelist():
 if '/sheets/' in n and not n.endswith('/'):
  put(Path('assets/vendor/psx_fx/sheets')/n.split('/sheets/',1)[1],z.read(n))
put(Path('assets/vendor/psx_fx/LICENSE.txt'),z.read('psx-fx-free/LICENSE.txt'))
z=zipfile.ZipFile(root/'ElectricFXFree.zip')
for n in z.namelist():
 if '/shader/' in n and n.endswith('.gdshader'):
  put(Path('assets/vendor/electric')/Path(n).name,z.read(n))
 if n.endswith('/license.txt'):put(Path('assets/vendor/electric/license.txt'),z.read(n))
z=zipfile.ZipFile(root/'Ancient Reliques.zip')
for n in z.namelist():
 if n.endswith(('.obj','.mtl','.png')):put(Path('assets/vendor/relics')/Path(n).name,z.read(n))
z=zipfile.ZipFile(root/'150+ Free RPG Sounds .zip');sounds=[]
for n in sorted(z.namelist()):
 if n.startswith('__MACOSX/') or not n.endswith('.mp3'):continue
 name=re.sub('[^a-zA-Z0-9_]+','_',Path(n).stem)+'.mp3'
 put(Path('assets/vendor/audio')/name,z.read(n));sounds.append({'path':'res://assets/vendor/audio/'+name,'original':n})
put(Path('assets/vendor/audio/manifest.json'),json.dumps(sounds,indent=2).encode())
# libarchive supports the supplied RAR without installing an external extractor.
a=c.CDLL('libarchive.so.13');a.archive_read_new.restype=c.c_void_p
for f in ['archive_read_support_filter_all','archive_read_support_format_all','archive_read_free']:getattr(a,f).argtypes=[c.c_void_p]
a.archive_read_open_filename.argtypes=[c.c_void_p,c.c_char_p,c.c_size_t];a.archive_read_next_header.argtypes=[c.c_void_p,c.POINTER(c.c_void_p)];a.archive_entry_pathname.argtypes=[c.c_void_p];a.archive_entry_pathname.restype=c.c_char_p
a.archive_read_data.argtypes=[c.c_void_p,c.c_void_p,c.c_size_t];a.archive_read_data.restype=c.c_ssize_t
p=a.archive_read_new();a.archive_read_support_filter_all(p);a.archive_read_support_format_all(p)
assert a.archive_read_open_filename(p,str(root/'LowPoly Environment Pack.rar').encode(),10240)==0
e=c.c_void_p();count=0
while a.archive_read_next_header(p,c.byref(e))==0:
 name=Path(a.archive_entry_pathname(e).decode()).name
 data=bytearray();b=c.create_string_buffer(65536)
 while True:
  size=a.archive_read_data(p,b,len(b))
  if size==0:break
  if size<0:raise RuntimeError('RAR read failed: '+name)
  data.extend(b.raw[:size])
 if name.endswith('.fbx'):put(Path('assets/vendor/environment')/name,bytes(data));count+=1
a.archive_read_free(p)
print('Extracted icons, PSX sheets, Electric shaders, relics,',len(sounds),'sounds and',count,'environment models')
