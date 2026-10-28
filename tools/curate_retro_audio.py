#!/usr/bin/env python3
"""NOTE: weapon.* events are owned by tools/curate_weapon_audio.py (Weapon Overhaul 2.0); running this script no longer writes them.
Curate supplied long variation reels OUTSIDE project first; optional --install.
No synthesis or bulk library import. Requires ffmpeg/numpy for offline analysis.
"""
from pathlib import Path
import argparse, json, subprocess, wave, hashlib
import numpy as np
p=argparse.ArgumentParser();p.add_argument('library',type=Path);p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
RATE=32000
DARK_PASS={"lowpass_hz":5000,"soft_saturation":True,"quantization_bits":10}
axis=np.arange(63)-31;dark_kernel=np.sinc(2*5000/RATE*axis)*np.hamming(63);dark_kernel/=dark_kernel.sum()
def darken(clip):
 x=(clip*32767).astype('<i2').astype(np.float64)/32768;peak=float(abs(x).max());x=np.convolve(x,dark_kernel,'same');x=.65*np.tanh(x*2)/2+.35*x;x=np.round(x*1024)/1024
 x*=min(1.35,peak/max(float(abs(x).max()),1e-8));return np.clip(x,-.5,.5)
# Semantic shortlist; waveform scoring rejects silence/weak snippets. Listening is not claimed.
groups={
 'combat.explosion':(['DSGNImpt_EXPLOSION-Bit Bomb','DSGNImpt_EXPLOSION-Pyro Burst'],5,.9),
 'player.damage':(['DSGNMisc_MELEE-Sword Slash'],4,.4),
 'player.footstep.grass':(['FEETMisc_STEP-Boots on Grass'],8,.25),
 'player.footstep.rock':(['FEETMisc_STEP-Boots on Concrete'],8,.25),
 'player.slide':(['WHSH_MOVEMENT-Sand Swipe','DSGNMisc_MOVEMENT-Noise Sweeper'],4,.85),
 'player.land':(['FEETMisc_STEP-Hard Step'],3,.35),
 'pickup.xp':(['DSGNTonl_USABLE-Metallic Item','DSGNTonl_USABLE-Coin Toss'],5,.35),
 'ui.hover':(['UIClick_INTERFACE-Positive Click'],3,.13),
 'ui.confirm':(['UIClick_INTERFACE-Strong Click 1'],3,.2),
 'ui.open':(['DSGNTonl_USABLE-Scifi Select'],3,.35),
 'ui.close':(['UIMisc_INTERFACE-Lock'],3,.25),
 'ui.purchase':(['DSGNTonl_USABLE-Coin Spend'],3,.45),
 'reward.level_up':(['DSGNSynth_BUFF-Mecha Level Up'],3,1.5),
 'reward.chest.tick':(['UIClick_INTERFACE-Rattling Click'],3,.1),
 'reward.chest.reveal':(['MAGAngl_BUFF-Effect Success'],3,1.4),
 'reward.chest.legendary':(['DSGNSynth_BUFF-Mecha Guarantee Hit'],3,1.8),
 'boss.warning':(['MAGSpel_CAST-High Powering Up'],3,.85),
}
cache={};report=[];events={}
for event,(sources,count,limit) in groups.items():
 candidates=[]
 for source in sources:
  path=a.library/(source+'_HY_PC.wav')
  if not path.exists():raise FileNotFoundError(path)
  if source not in cache:
   raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar',str(RATE),'-ac','1','-']);data=np.frombuffer(raw,dtype='<f4').copy()
   block=320;trim=data[:len(data)//block*block].reshape(-1,block);energy=np.sqrt(np.mean(trim**2,axis=1));threshold=max(float(energy.max())*.018,.0005)
   active=np.flatnonzero(energy>threshold);spans=[]
   if len(active):
    start=last=int(active[0])
    for index in active[1:]:
     if index-last>22:spans.append((max(0,start*block-160),min(len(data),(last+1)*block+1600)));start=int(index)
     last=int(index)
    spans.append((max(0,start*block-160),min(len(data),(last+1)*block+1600)))
   cache[source]=(data,spans)
  data,spans=cache[source]
  for start,end in spans:
   end=min(end,start+int(limit*RATE));clip=data[start:end].copy()
   if len(clip)<RATE*.035:continue
   peak=float(abs(clip).max());rms=float(np.sqrt(np.mean(clip**2)))
   if peak<.005 or rms<.0001:continue
   spectrum=abs(np.fft.rfft(clip));freq=np.fft.rfftfreq(len(clip),1/RATE);centroid=float(np.sum(spectrum*freq)/max(np.sum(spectrum),1e-9));crest=peak/rms
   candidates.append((min(crest,12)+min(rms*10,2),source,start,end,clip,centroid,crest))
 candidates.sort(key=lambda x:x[0],reverse=True);selected=candidates[:count]
 files=[]
 for i,(_,source,start,end,clip,centroid,crest) in enumerate(selected):
  peak=float(abs(clip).max());clip*=min(3,.5/max(peak,1e-8));fade=min(160,len(clip)//4);tail=min(960,len(clip)//4);clip[:fade]*=np.linspace(0,1,fade);clip[-tail:]*=np.linspace(1,0,tail)
  relative=event.replace('.','/')+'_%02d.wav'%i;dest=a.output/relative;dest.parent.mkdir(parents=True,exist_ok=True)
  clip=darken(clip);pcm=(clip*32767).astype('<i2')
  with wave.open(str(dest),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
  files.append('res://assets/audio/sfx/'+relative)
  report.append({'event':event,'file':relative,'source':source+'_HY_PC.wav','source_start':start/RATE,'source_end':end/RATE,'duration':len(clip)/RATE,'centroid_hz':round(centroid,1),'crest':round(crest,2),'peak_dbfs':round(float(20*np.log10(max(abs(clip).max(),1e-8))),2),'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
 priority=5 if event in ['player.damage','boss.warning'] else 4 if event.startswith('reward.') else 2 if event.startswith('weapon.') else 1
 cooldown=.09 if event.startswith('weapon.') else .055 if event in ['pickup.xp','reward.chest.tick'] else .12 if event.startswith('ui.') else .15
 events[event]={'base_pitch':.92 if event=='weapon.revolver.fire' else .88 if event.startswith(('weapon.','combat.','player.')) else .82,'files':files,'bus':'UI' if event.startswith(('ui.','reward.')) else 'SFX','cooldown':cooldown,'priority':priority,'max_voices':2 if event in ['pickup.xp','player.slide'] else 3,'gain_db':-18 if event.startswith(('ui.','player.footstep')) else -11 if priority>=4 else -14,'pitch':.035 if event.startswith('reward.') else .055}
 assert files,event
(a.output/'events.json').write_text(json.dumps({'events':events},indent=2)+'\n');(a.output/'curation.json').write_text(json.dumps({'dark_pass':DARK_PASS,'auditioned':False,'selection':'semantic shortlist plus transient/silence/crest/spectrum screening; manual listening remains required','files':report,'bytes':sum(r['bytes'] for r in report)},indent=2)+'\n');print('Curated',len(report),'clips,',sum(r['bytes'] for r in report),'bytes;', {k:len(v['files']) for k,v in events.items()})
