"""Render the six requested clips as lightweight review frames.
blender -b -t 8 --python art/protagonist/preview_animations.py [-- --poses-only]
The render frames go to /tmp/investigator_animation_frames.
"""
import bpy
import sys
import json
import tempfile
from pathlib import Path
from mathutils import Vector

SOURCE=Path(__file__).resolve().parent
sys.path.insert(0,str(SOURCE))
from animation_clips import CLIPS
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'Investigator.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['Investigator']
scene.render.engine='BLENDER_WORKBENCH'
scene.display.shading.light='STUDIO'
scene.display.shading.color_type='MATERIAL'
scene.display.shading.show_shadows=True
scene.display.shading.show_specular_highlight=False
scene.display.shading.show_cavity=True
scene.display.shading.cavity_type='BOTH'
scene.display.shading.curvature_ridge_factor=1.15
scene.display.shading.curvature_valley_factor=1.0
scene.display.shading.background_type='WORLD'
scene.display.render_aa='8'
scene.world.color=(.035,.042,.047)
scene.view_settings.exposure=1.3
scene.render.resolution_x=480;scene.render.resolution_y=600;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.camera.data.ortho_scale=3.0
scene.camera.location=(3,-6.5,2.8)
scene.camera.rotation_euler=(Vector((0,0,1.05))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
out=Path(tempfile.gettempdir())/'investigator_animation_frames';out.mkdir(exist_ok=True)
requested=['Idle','Walk','Jump','Crouch','Slide','CriticalWalk']
index=[]
for clip in requested:
    selected=next((arg.split('=',1)[1] for arg in sys.argv if arg.startswith('--clip=')),None)
    if selected and clip!=selected:continue
    rig.animation_data.action=bpy.data.actions[clip]
    folder=out/clip;folder.mkdir(exist_ok=True)
    frames=([1] if clip in ('Idle','Crouch') else [max(1,CLIPS[clip]['frames']//2)] if clip in ('Jump','Slide') else [9]) if '--poses-only' in sys.argv else list(range(1,CLIPS[clip]['frames']+1,2))
    for frame in frames:
        scene.frame_set(frame)
        scene.render.filepath=str(folder/('%04d.png'%frame))
        bpy.ops.render.render(write_still=True)
    index.append({'clip':clip,'frames':frames,'fps':12})
path=out/'index.json'
existing={item['clip']:item for item in json.loads(path.read_text())} if path.exists() else {}
existing.update({item['clip']:item for item in index})
path.write_text(json.dumps([existing[clip] for clip in requested if clip in existing],indent=2))
print('ANIMATION_PREVIEW_RENDERED',str(out))
