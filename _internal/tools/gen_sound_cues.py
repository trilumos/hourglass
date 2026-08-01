#!/usr/bin/env python3
"""Synthesizes Sustain's bundled CUE-SOUND OPTIONS (alternates to the default
Pixabay bell). Each is a single, complete, premium cue played at every session
transition; the user picks one in Settings.

Original works, synthesized from scratch (CC0). All are de-clicked (tail fade to
true zero) and loudness-matched by the loudest window. Retune + re-run:

    python tools/gen_sound_cues.py

Outputs: assets/audio/cue_chime.wav, assets/audio/cue_tingsha.wav
(The default sound, assets/audio/cue_bell.mp3, is a Pixabay asset — see CREDITS.md.)
"""
import math
import os
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

# Warm bell (soft chime) and a brighter bell (tingsha) partial sets.
_WARM = ((1.0, 1.0), (2.01, 0.28), (2.99, 0.10), (4.20, 0.04))
_BRIGHT = ((1.0, 1.0), (2.0, 0.55), (3.0, 0.28), (4.2, 0.16), (5.4, 0.08))


def buf(seconds):
    return [0.0] * int(SR * seconds)


def add_note(b, freq, t0, dur, gain, tau, attack, partials):
    n0 = int(t0 * SR)
    n = min(int(dur * SR), len(b) - n0)
    for i in range(n):
        t = i / SR
        atk = t / attack if t < attack else 1.0
        s = 0.0
        for ratio, amp in partials:
            s += amp * math.exp(-t / (tau / math.sqrt(ratio))) * \
                math.sin(2 * math.pi * freq * ratio * t)
        b[n0 + i] += gain * atk * s


def _max_window_rms(b, win=0.30):
    n = len(b)
    w = min(int(SR * win), n)
    ps = [0.0] * (n + 1)
    for i in range(n):
        ps[i + 1] = ps[i] + b[i] * b[i]
    best = 0.0
    for s in range(0, max(1, n - w + 1), max(1, w // 8)):
        rms = ((ps[s + w] - ps[s]) / w) ** 0.5
        best = max(best, rms)
    return best


def save(b, name, target=0.20, ceiling=0.9):
    f = int(SR * 0.025)  # 25 ms de-click fade to true zero
    for i in range(f):
        b[-1 - i] *= i / f
    loud = _max_window_rms(b)
    if loud > 1e-9:
        k = target / loud
        for i in range(len(b)):
            b[i] *= k
    peak = max(1e-9, max(abs(x) for x in b))
    if peak > ceiling:
        k = ceiling / peak
        for i in range(len(b)):
            b[i] *= k
    path = os.path.join(OUT, name)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1.0, min(1.0, x)) * 32767)) for x in b))
    print('wrote', path)


os.makedirs(OUT, exist_ok=True)

# Soft Chime — a single warm bell (C5), gentle and minimal.
b = buf(2.6)
add_note(b, 523.25, 0.0, 2.6, gain=0.42, tau=0.55, attack=0.012, partials=_WARM)
save(b, 'cue_chime.wav')

# Tingsha — a bright meditation-bell ting (A5) + a faint detuned shimmer voice.
b = buf(2.8)
add_note(b, 880.00, 0.0, 2.8, gain=0.40, tau=0.80, attack=0.006, partials=_BRIGHT)
add_note(b, 880.00 * 1.0032, 0.0, 2.8, gain=0.17, tau=0.72, attack=0.006,
         partials=_BRIGHT)
save(b, 'cue_tingsha.wav')

print('done')
