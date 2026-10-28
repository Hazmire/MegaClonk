#!/usr/bin/env python3
"""Generates the small retro SFX for vases, power-ups, imbue stations and status effects, and registers them in events.json."""
import json, wave, struct, sys
import numpy as np
SR = 22050
OUT = "assets/audio/sfx/sockets/"
rng = np.random.default_rng(1234)

def env(n, a=0.005, d=0.5):
    t = np.arange(n) / SR
    return np.minimum(t / a, 1.0) * np.exp(-t / d)

def tone(f0, dur, f1=None, kind="sq", d=0.2):
    n = int(SR * dur); f1 = f0 if f1 is None else f1
    f = np.linspace(f0, f1, n); ph = np.cumsum(f) / SR
    w = np.sign(np.sin(2 * np.pi * ph)) if kind == "sq" else np.sin(2 * np.pi * ph)
    return w * env(n, 0.003, d)

def noise(dur, d=0.1, lp=0.5):
    n = int(SR * dur); x = rng.uniform(-1, 1, n)
    for i in range(1, n): x[i] = x[i - 1] * lp + x[i] * (1 - lp)
    return x * env(n, 0.001, d)

def cat(*a): return np.concatenate(a)
def mix(*a):
    n = max(len(x) for x in a); o = np.zeros(n)
    for x in a: o[:len(x)] += x
    return o

def save(name, x, i):
    x = x / max(1e-6, np.max(np.abs(x))) * 0.8
    x = (x * 32767).astype("<i2")
    with wave.open(f"{OUT}{name}_{i:02d}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(x.tobytes())

def gen(name, fn, variants=3):
    for i in range(variants): save(name, fn(i), i)

def vase(i): return mix(noise(0.35, 0.09, 0.3 + 0.1 * i), tone(180 + 40 * i, 0.12, 90, "sq", 0.05) * 0.5)
def gold(i): return cat(tone(1200 + 100 * i, 0.05, kind="sq", d=0.03), tone(1700 + 100 * i, 0.12, kind="sq", d=0.08))
def gem(i): return cat(tone(880 + 60 * i, 0.06, d=0.04, kind="sin"), tone(1320 + 60 * i, 0.12, d=0.08, kind="sin"))
def heart(i): return cat(tone(440, 0.08, d=0.06, kind="sin"), tone(554, 0.08, d=0.06, kind="sin"), tone(659, 0.18, d=0.14, kind="sin"))
def magnet(i): return mix(tone(200, 0.45, 900, "sq", 0.3) * 0.5, tone(300, 0.45, 1200, "sin", 0.3))
def stopwatch(i): return cat(tone(900, 0.04, d=0.02), np.zeros(int(SR * 0.05)), tone(700, 0.04, d=0.02), tone(300, 0.5, 80, "sin", 0.35))
def imbue_interact(i): return cat(tone(150, 0.1, 220, "sq", 0.08), tone(220, 0.15, 330, "sin", 0.1))
def imbue_install(i): return mix(noise(0.25, 0.1, 0.7) * 0.6, cat(tone(330, 0.1, d=0.08), tone(495, 0.1, d=0.08), tone(660, 0.3, d=0.25, kind="sin")))
def poison(i): return mix(noise(0.2, 0.08, 0.85) * 0.7, tone(220 + 30 * i, 0.2, 120, "sin", 0.12))
def shatter(i): return mix(noise(0.3, 0.06, 0.1), tone(2200, 0.15, 900, "sq", 0.05) * 0.4)
def ignite(i): return mix(noise(0.4, 0.2, 0.6), tone(110, 0.3, 260, "sq", 0.2) * 0.4)
def stun(i): return mix(noise(0.18, 0.05, 0.2), tone(1500, 0.18, 400, "sq", 0.07) * 0.6)
def combo(i): return mix(noise(0.3, 0.12, 0.3) * 0.5, cat(tone(220, 0.12, 440, "sq", 0.1), tone(440, 0.3, 880, "sin", 0.2)))

# event -> (generator, files, cooldown, priority, max_voices, gain_db, pitch)
EV = {
 "vase.break": (vase, 3, 0.04, 2, 4, -12, 0.06),
 "pickup.gold": (gold, 3, 0.03, 1, 3, -16, 0.04),
 "gem.pickup": (gem, 3, 0.03, 1, 3, -17, 0.04),
 "powerup.heart": (heart, 1, 0.2, 4, 2, -10, 0.0),
 "powerup.magnet": (magnet, 1, 0.3, 4, 2, -10, 0.0),
 "powerup.stopwatch": (stopwatch, 1, 0.3, 4, 2, -9, 0.0),
 "imbue.interact": (imbue_interact, 1, 0.1, 3, 2, -11, 0.0),
 "imbue.install": (imbue_install, 1, 0.2, 4, 2, -9, 0.0),
 "status.poison": (poison, 3, 0.25, 1, 2, -20, 0.06),
 "status.ice_shatter": (shatter, 3, 0.1, 2, 3, -16, 0.06),
 "status.ignite": (ignite, 3, 0.2, 1, 2, -18, 0.05),
 "status.stun": (stun, 3, 0.15, 2, 3, -16, 0.05),
 "status.combo": (combo, 2, 0.15, 3, 3, -13, 0.04),
}
reg = json.load(open("assets/audio/events.json"))
for ev, (fn, n, cd, pr, mv, gain, pitch) in EV.items():
    base = ev.replace(".", "_")
    gen(base, fn, n)
    reg["events"][ev] = {"files": [f"res://assets/audio/sfx/sockets/{base}_{i:02d}.wav" for i in range(n)],
        "bus": "SFX", "cooldown": cd, "priority": pr, "max_voices": mv, "gain_db": gain, "pitch": pitch, "base_pitch": 1.0}
json.dump(reg, open("assets/audio/events.json", "w"), indent=2)
print("events:", len(reg["events"]))
