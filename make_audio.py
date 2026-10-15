#!/usr/bin/env python3
"""Synthesize the full audio bed for THE ASCENT (Snowmoon Ch. 6).

Deterministic (numpy seed fixed). No stock music, no voiceover, no foley.
Output: build/seg/audio.wav — 83 s, 48 kHz, stereo, 16-bit.

Layers:
  wind  — lowpassed white noise + slow tremolo gusts; envelope rises during
          the staircase/climb (shots 3-4), drops near-silence at the tower
          and during the dialogue.
  drone — three layered sine waves (55 / 82.41 / 110 Hz), very low; fades in
          after the opening, out during the dialogue, returns softly, fades
          with the picture.
  chime — two sine partials (880 / 1318.51 Hz) with exponential decay,
          struck once at the device confirmation (~73.5 s).
"""
import numpy as np
import wave

SR = 48000
DUR = 83.0
N = int(SR * DUR)
t = np.arange(N) / SR
rng = np.random.default_rng(7)

def env(points):
    xs = np.array([p[0] for p in points]); ys = np.array([p[1] for p in points])
    return np.interp(t, xs, ys)

# --- wind: two decorrelated noise channels, one-pole lowpass, slow gusts ---
def pinkish(n):
    w = rng.standard_normal(n)
    y = np.zeros(n); a = 0.985
    for i in range(1, n):
        y[i] = a * y[i-1] + (1 - a) * w[i]
    y /= (np.abs(y).max() + 1e-9)
    return y
gust = 0.75 + 0.25 * np.sin(2*np.pi*0.13*t) * np.sin(2*np.pi*0.071*t + 1.3)
wind_env = env([(0,0.12),(16,0.12),(18,0.25),(42,0.25),(45,0.15),(50,0.15),
                (54,0.06),(57,0.04),(72,0.04),(75,0.10),(83,0.10)])
wind_l = pinkish(N) * gust * wind_env * 0.9
wind_r = pinkish(N) * gust[::-1] * wind_env * 0.9

# --- drone score ---
drone_env = env([(0,0),(8,0),(12,0.06),(52,0.06),(56,0),(71,0),
                 (75,0.035),(80,0.035),(83,0)])
drone = (np.sin(2*np.pi*55*t) + np.sin(2*np.pi*82.41*t)
         + np.sin(2*np.pi*110*t)) / 3.0 * drone_env

# --- confirmation chime ---
ch = np.zeros(N); m = t >= 73.5
ch[m] = 0.10 * np.exp(-(t[m]-73.5)/1.4) * (np.sin(2*np.pi*880*t[m])
                                          + np.sin(2*np.pi*1318.51*t[m])) / 2.0

L = np.tanh(wind_l + drone + ch)
R = np.tanh(wind_r + drone + ch)
stereo = np.stack([L, R], axis=1)
pcm = (np.clip(stereo, -1, 1) * 32767).astype(np.int16)

with wave.open("/home/hatch/workspace/snowmoon-keeper/build/seg/audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("audio.wav written:", N/SR, "s")
