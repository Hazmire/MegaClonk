#!/usr/bin/env python3
"""Original short revolver transient; no external recording or sample."""
import math
from pathlib import Path
import random
import struct
import wave
rng=random.Random(64187)
rate=22050
samples=[]
previous=0.0
for index in range(int(rate*0.18)):
    time=index/rate
    noise=rng.uniform(-1,1)
    high=noise-previous*0.8
    previous=noise
    sample=high*math.exp(-time*65)*0.55+math.sin(time*math.tau*(100-100*time))*math.exp(-time*35)*0.25
    samples.append(int(max(-1,min(1,sample))*32767))
path=Path(__file__).resolve().parents[1]/'assets/audio/revolver.wav'
with wave.open(str(path),'wb') as stream:
    stream.setparams((1,2,rate,0,'NONE','not compressed'))
    stream.writeframes(b''.join(struct.pack('<h',sample) for sample in samples))
