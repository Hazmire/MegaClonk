#!/usr/bin/env python3
"""Generate original applause-like noise claps and a Legendary reward flourish."""
import math
from pathlib import Path
import random
import struct
import wave

rng = random.Random(9182)
rate = 22050
length = rate * 2
samples = [0.0] * length
for start, gain in [(rng.uniform(0, 1.8), rng.uniform(.15, .7)) for _ in range(75)]:
    for offset in range(int(rate * .08)):
        index = int(start * rate) + offset
        if index < length:
            samples[index] += (rng.random() * 2 - 1) * gain * math.exp(-offset / (rate * .012))
samples = [math.tanh(value * .6) * min(1, index / (rate * .1)) * min(1, (length - index) / (rate * .35)) * .65 for index, value in enumerate(samples)]
flourish = [sum(math.sin(index / rate * frequency * math.tau) * math.exp(-index / rate * 1.5) for frequency in [523.25, 659.25, 783.99, 1046.5]) * .13 for index in range(length)]
output = Path(__file__).resolve().parents[1] / 'assets/audio'
output.mkdir(parents=True, exist_ok=True)
for name, values in [('reward_applause', samples), ('reward_legendary', flourish)]:
    with wave.open(str(output / (name + '.wav')), 'wb') as stream:
        stream.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        stream.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, value)) * 32767)) for value in values))
