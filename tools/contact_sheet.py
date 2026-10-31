#!/usr/bin/env python3
"""Build a contact sheet from weapon-lab captures: contact_sheet.py out.png frame1.png frame2.png ... [--crop x0,y0,x1,y1] [--cols N] [--scale S]"""
import sys
from PIL import Image
args=sys.argv[1:];out=args.pop(0);crop=None;cols=3;scale=0.5
files=[]
while args:
    a=args.pop(0)
    if a=='--crop':crop=tuple(int(v) for v in args.pop(0).split(','))
    elif a=='--cols':cols=int(args.pop(0))
    elif a=='--scale':scale=float(args.pop(0))
    else:files.append(a)
ims=[]
for f in files:
    im=Image.open(f).convert('RGB')
    if crop:im=im.crop(crop)
    ims.append(im.resize((int(im.width*scale),int(im.height*scale)),Image.NEAREST))
w,h=ims[0].size;rows=(len(ims)+cols-1)//cols
sheet=Image.new('RGB',(w*cols,h*rows))
for i,im in enumerate(ims):sheet.paste(im,((i%cols)*w,(i//cols)*h))
sheet.save(out)
