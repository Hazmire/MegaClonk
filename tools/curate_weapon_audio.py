#!/usr/bin/env python3
"""Weapon Overhaul 2.0 audio curation. Usage: curate_weapon_audio.py <pixel-combat wav dir> <project root>
Reuses the dark pass of curate_retro_audio.py (5 kHz low-pass, soft saturation, 10-bit grain, 32 kHz mono).
Writes assets/audio/sfx/weapon/<weapon>/<name>_NN.wav, rewrites the weapon.* entries of assets/audio/events.json and
records provenance in docs/audio/WEAPON_CURATION.json. Clips are chosen by transient/silence/crest screening; nothing here has been auditioned by ear."""
from pathlib import Path
import argparse, json, subprocess, wave, hashlib
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('library',type=Path);ap.add_argument('root',type=Path);a=ap.parse_args()
RATE=32000
axis=np.arange(63)-31;K=np.sinc(2*5000/RATE*axis)*np.hamming(63);K/=K.sum()
def darken(c):
 x=(c*32767).astype('<i2').astype(np.float64)/32768;pk=float(abs(x).max());x=np.convolve(x,K,'same');x=.65*np.tanh(x*2)/2+.35*x;x=np.round(x*1024)/1024
 x*=min(1.35,pk/max(float(abs(x).max()),1e-8));return np.clip(x,-.5,.5)
# event: (sources, clips, max seconds, cooldown, max_voices, gain_db, base_pitch, pitch_jitter, priority)
NEW={
 'weapon.sword.hit':(['FGHTImpt_HIT-Smack','FGHTImpt_MELEE-Swish Hit'],4,.3,.07,3,-15,.95,.07,2),
 'weapon.sword.crit':(['DSGNTonl_MELEE-Sword Critical'],3,.5,.12,2,-12,.9,.04,3),
 'weapon.firestaff.impact':(['DSGNImpt_EXPLOSION-Fire Hit','DSGNImpt_EXPLOSION-Small Flare'],4,.5,.08,3,-14,.85,.06,2),
 'weapon.firestaff.crit':(['DSGNImpt_EXPLOSION-Pyro Burst'],3,.6,.14,2,-12,.9,.04,3),
 'weapon.lightning.thunder':(['DSGNImpt_EXPLOSION-Thud','DSGNImpt_EXPLOSION-Voltaic Blast'],3,.9,.18,2,-13,.8,.05,2),
 'weapon.lightning.chain':(['MAGSpel_CAST-Wet Electricity','DSGNMisc_HIT-Zap Clap'],4,.35,.11,2,-18,1.0,.08,1),
 'weapon.lightning.crit':(['DSGNMisc_SKILL IMPACT-Jacobs Ladder'],3,.7,.15,2,-12,.95,.04,3),
 'weapon.bow.hit':(['DSGNMisc_HIT-Gore Pierce','FGHTImpt_HIT-Strong Smack'],4,.3,.06,3,-16,1.0,.07,2),
 'weapon.bow.crit':(['DSGNMisc_SKILL IMPACT-Critical Strike'],3,.5,.12,2,-13,.95,.04,3),
 'weapon.revolver.hit':(['DSGNMisc_HIT-Mecha Armor Piercer','DSGNMisc_HIT-Hit Rattle'],4,.3,.06,3,-16,1.0,.07,2),
 'weapon.revolver.ricochet':(['DSGNTonl_SKILL RELEASE-Ricochet 1','DSGNTonl_SKILL RELEASE-Ricochet 2'],4,.5,.09,2,-16,1.0,.08,2),
 'weapon.revolver.crit':(['FGHTImpt_MELEE-Kick Critical'],3,.5,.12,2,-12,.95,.04,3),
 'weapon.aura.hum':(['MAGSpel_CAST-Underwater'],2,1.6,2.0,1,-24,.8,.02,1),
 'weapon.aura.crit':(['MAGSpel_CAST-Weirdness'],2,.6,.2,1,-16,.9,.03,2),
 'weapon.scythes.hit':(['DSGNMisc_HIT-Sweep Hit','DSGNMisc_HIT-Swish Clap'],4,.35,.07,3,-15,.9,.07,2),
 'weapon.scythes.catch':(['DSGNMisc_HIT-Fleeting Hit'],3,.3,.1,2,-17,.9,.06,1),
 'weapon.scythes.crit':(['DSGNImpt_MELEE-Homerunner'],3,.6,.12,2,-12,.9,.04,3),
 'weapon.shotgun.fire':(['DSGNImpt_EXPLOSION-Mecha Engine Blast','DSGNImpt_EXPLOSION-Eruption'],5,.9,.3,2,-8,.72,.04,4),
 'weapon.shotgun.hit':(['DSGNImpt_EXPLOSION-Crunchy Burst','FGHTImpt_HIT-Strong Punch'],4,.3,.05,3,-17,.9,.08,2),
 'weapon.shotgun.crit':(['DSGNImpt_EXPLOSION-Mecha Piercing Punch'],3,.5,.1,2,-13,.85,.04,3),
}
# existing curated files kept (renamed folders): event -> (folder, stem, count, cooldown, voices, gain, base_pitch, jitter, priority)
KEEP={
 'weapon.sword.swing':('sword','swing',4,.09,3,-14,.9,.06,2),
 'weapon.firestaff.cast':('firestaff','cast',4,.1,3,-14,.85,.06,2),
 'weapon.lightning.strike':('lightning','strike',5,.12,3,-13,.9,.06,3),
 'weapon.bow.fire':('bow','fire',3,.08,3,-15,.9,.06,2),
 'weapon.revolver.fire':('revolver','fire',6,.07,3,-13,.92,.05,2),
 'weapon.aura.pulse':('aura','pulse',3,.25,2,-15,.8,.04,2),
 'weapon.scythes.throw':('scythes','throw',3,.12,3,-15,.9,.07,2),
}
cache={};report=[];events={}
sfx=a.root/'assets/audio/sfx/weapon'
for ev,(src,n,lim,cd,vo,g,bp,pj,pr) in NEW.items():
 cands=[]
 for s in src:
  path=a.library/(s+'_HY_PC.wav')
  if s not in cache:
   d=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar',str(RATE),'-ac','1','-']),dtype='<f4').copy()
   B=320;t=d[:len(d)//B*B].reshape(-1,B);en=np.sqrt(np.mean(t**2,axis=1));th=max(float(en.max())*.018,.0005);act=np.flatnonzero(en>th);sp=[]
   if len(act):
    st=la=int(act[0])
    for i in act[1:]:
     if i-la>22:sp.append((max(0,st*B-160),min(len(d),(la+1)*B+1600)));st=int(i)
     la=int(i)
    sp.append((max(0,st*B-160),min(len(d),(la+1)*B+1600)))
   cache[s]=(d,sp)
  d,sp=cache[s]
  for st,en_ in sp:
   en_=min(en_,st+int(lim*RATE));c=d[st:en_].copy()
   if len(c)<RATE*.035:continue
   pk=float(abs(c).max());rms=float(np.sqrt(np.mean(c**2)))
   if pk<.005 or rms<.0001:continue
   cands.append((min(pk/rms,12)+min(rms*10,2),s,st,en_,c))
 cands.sort(key=lambda x:x[0],reverse=True);files=[]
 for i,(_,s,st,en_,c) in enumerate(cands[:n]):
  c*=min(3,.5/max(float(abs(c).max()),1e-8));f=min(160,len(c)//4);t=min(960,len(c)//4);c[:f]*=np.linspace(0,1,f);c[-t:]*=np.linspace(1,0,t)
  w_,name=ev.split('.')[1:]
  rel='%s/%s_%02d.wav'%(w_,name,i);dest=sfx/rel;dest.parent.mkdir(parents=True,exist_ok=True);c=darken(c)
  with wave.open(str(dest),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((c*32767).astype('<i2').tobytes())
  files.append('res://assets/audio/sfx/weapon/'+rel)
  report.append({'event':ev,'file':rel,'source':s+'_HY_PC.wav','source_start':round(st/RATE,3),'source_end':round(en_/RATE,3),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
 assert files,ev
 events[ev]={'files':files,'bus':'SFX','cooldown':cd,'priority':pr,'max_voices':vo,'gain_db':g,'pitch':pj,'base_pitch':bp}
for ev,(fo,stem,n,cd,vo,g,bp,pj,pr) in KEEP.items():
 files=['res://assets/audio/sfx/weapon/%s/%s_%02d.wav'%(fo,stem,i) for i in range(n)]
 for f in files:assert (a.root/f.replace('res://','')).exists(),f
 events[ev]={'files':files,'bus':'SFX','cooldown':cd,'priority':pr,'max_voices':vo,'gain_db':g,'pitch':pj,'base_pitch':bp}
ej=a.root/'assets/audio/events.json';cur=json.loads(ej.read_text())
cur['events']={k:v for k,v in cur['events'].items() if not k.startswith('weapon.')};cur['events'].update(events);ej.write_text(json.dumps(cur,indent=2)+'\n')
(a.root/'docs/audio/WEAPON_CURATION.json').write_text(json.dumps({'auditioned':False,'note':'selected by waveform screening only; not listened to','kept_from_earlier_curation':list(KEEP),'new_clips':report},indent=2)+'\n')
print('weapon events',len(events),'new clips',len(report))
