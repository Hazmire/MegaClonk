"""Package the editable character and game export for download.
python art/cultist/package_cultist.py
"""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import json

ROOT=Path(__file__).resolve().parents[2]
output=ROOT/'art/cultist/RiftCultist_Model_Pack.zip'
manifest=json.loads((ROOT/'assets/characters/cultist/manifest.json').read_text())
reports=[json.loads((ROOT/'assets/characters/cultist'/name).read_text())
    for name in ('glb_validation.json','godot_validation.json')]
for report in reports:
    assert report['checks']=='passed'
    assert all(report[key]==manifest[key] for key in ('triangles','bones','materials'))
files=sorted(p for folder in ('art/cultist','assets/characters/cultist','docs/images/cultist')
    for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix not in ('.zip','.pyc')
    and not p.name.endswith('.blend1') and '__pycache__' not in p.parts)
with ZipFile(output,'w',ZIP_DEFLATED,compresslevel=6) as archive:
    for p in files:archive.write(p,p.relative_to(ROOT))
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert len([p for p in archive.namelist() if p.endswith('.blend')])==2
    assert len([p for p in archive.namelist() if p.endswith('.glb')])==1
    assert len([p for p in archive.namelist() if '/textures/' in p and p.endswith('.png')])==2
print('CULTIST_PACK_VALIDATED',output,'files',len(files),'bytes',output.stat().st_size)
