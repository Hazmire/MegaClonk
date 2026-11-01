"""Encode review renders with Python/Pillow and ffmpeg (no Blender needed).
python art/protagonist/encode_previews.py
"""
from pathlib import Path
import json
import subprocess
import tempfile
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
FRAMES=Path(tempfile.gettempdir())/'investigator_animation_frames'
OUT=ROOT/'docs/images/protagonist/animations';OUT.mkdir(parents=True,exist_ok=True)
TIMELINE=Path(tempfile.gettempdir())/'investigator_preview_timeline';TIMELINE.mkdir(exist_ok=True)
for old in TIMELINE.glob('*.png'):old.unlink()
font_path=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
def font(size):
    return ImageFont.truetype(str(font_path),size) if font_path.exists() else ImageFont.load_default()
labels={'Idle':('IDLE','BREATHING / LOOP'), 'Walk':('WALK','GROUNDED STEPS / LOOP'),
        'Jump':('JUMP','TAKEOFF / AIRTIME / LANDING'), 'Crouch':('CROUCH','HELD LOW STANCE / LOOP'),
        'Slide':('CROUCH / SLIDE','LOW SLIDE POSE / IN PLACE'),
        'CriticalWalk':('CRITICAL HP WALK','HUNCHED / ABDOMEN BRACE / LIMP')}
index=json.loads((FRAMES/'index.json').read_text())
timeline=[];tiles=[]
for i,item in enumerate(index):
    clip=item['clip'];sequence=[]
    for frame in item['frames']:
        image=Image.open(FRAMES/clip/('%04d.png'%frame)).convert('RGB')
        canvas=Image.new('RGB',(480,680),(16,22,27));canvas.paste(image,(0,64))
        draw=ImageDraw.Draw(canvas)
        draw.text((16,8),labels[clip][0],font=font(23),fill=(224,211,188))
        draw.text((16,40),labels[clip][1],font=font(12),fill=(153,177,184))
        draw.text((16,661),'THE INVESTIGATOR  /  ANIMATION STUDY',font=font(11),fill=(153,177,184))
        sequence.append(canvas)
    pick=0 if clip in ('Idle','Crouch') else len(sequence)//2 if clip in ('Jump','Slide') else len(sequence)//4
    tiles.append(sequence[pick])
    timeline.extend(sequence*(2 if clip in ('Walk','CriticalWalk','Slide') else 1))
for i,canvas in enumerate(timeline):canvas.save(TIMELINE/('%04d.png'%i))
sheet=Image.new('RGB',(1440,1360),(16,22,27))
for i,tile in enumerate(tiles):sheet.paste(tile,((i%3)*480,(i//3)*680))
sheet.save(OUT/'Investigator_Animation_Poses.png')
base=['ffmpeg','-hide_banner','-loglevel','error','-y','-framerate','12','-i',str(TIMELINE/'%04d.png')]
subprocess.run(base+['-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'Investigator_Animations.mp4')],check=True)
subprocess.run(base+['-filter_complex','[0:v]split[x][y];[x]palettegen=max_colors=128:stats_mode=diff[p];[y][p]paletteuse=dither=sierra2_4a','-loop','0',str(OUT/'Investigator_Animations.gif')],check=True)
print('PREVIEW_ENCODED',len(timeline),'frames',str(OUT))
