#!/usr/bin/env python
"""Checks the web falling-sand against the APP's, lib/hourglass/hourglass_painter.dart.

The ALGORITHM must match — same acceleration curve, same radius/alpha shaping, same
ballistic scatter. That is what makes the two products feel like one thing, and a
divergence there is a bug.

The CONSTANTS are the founder's to tune per surface and are reported as a diff, not
a failure: the web is a big hero render, the app is a phone widget, and they were
deliberately retuned on 2026-07-19."""
import re, io, sys

dart = io.open('../lib/hourglass/hourglass_painter.dart', encoding='utf-8').read()
web  = io.open('hybrid.html', encoding='utf-8').read()
fail = []

def dartnum(pat, label):
    m = re.search(pat, dart)
    if not m: fail.append(f'could not read {label} from the app'); return None
    return float(m.group(1))
def webnum(key):
    m = re.search(r'\b%s:\s*([\d.]+)' % key, web)
    if not m: fail.append(f'{key} missing from S'); return None
    return float(m.group(1))

checks = [
    ('grain count',  r'grainCount\s*=\s*(\d+)',              'streamN'),
    ('fall period',  r'ambient \? 0\.78 : ([\d.]+)',         'streamPer'),
    ('exit speed',   r'v0Frac\s*=\s*([\d.]+)',               'streamV0'),
    ('column width', r'colHalf = neckHalf \* ([\d.]+)',      'streamCol'),
]
print(f'{"":14} {"app":>8} {"web":>8}   (constants are tuned per surface)')
for label, pat, key in checks:
    a, b = dartnum(pat, label), webnum(key)
    if a is None or b is None: continue
    ok = abs(a-b) < 1e-9
    print(f'{label:14} {a:8} {b:8}   {"same" if ok else "tuned"}')

# the two formulas that shape the spray must be identical
shapes = [
    ('grain radius', r'\(1\.05 - 0\.4 \* fall\) \* \(0\.55 \+ 0\.4 \* sizeR\)',
                     r'\(1\.05-0\.4\*fall\)\*\(0\.55\+0\.4\*sizeR\)'),
    ('grain alpha',  r'\(1\.0 - 0\.16 \* fall\) \* \(0\.82 \+ 0\.18 \* laneR\)',
                     r'\(1\.0-0\.16\*fall\)\*\(0\.82\+0\.18\*laneR\)'),
    ('scatter count',r'3 \+ 13 \* fill',  r'3\+13\*fill'),
    ('ballistic arc',r'vsin \* p \* \(1 - p\)', r'Math\.sin\(ang\)\*p\*\(1-p\)'),
]
for label, dp, wp in shapes:
    da, wa = re.search(dp, dart), re.search(wp, web)
    print(f'{label:14} {"in app" if da else "MISSING":>8} {"in web" if wa else "MISSING":>8}'
          f'   {"match" if da and wa else "DIFFERS"}')
    if not (da and wa): fail.append(f'{label} formula differs between app and web')

# and it must still be discrete grains, not the continuous column that was cut
if 'fillRect(cx-w' in web:
    fail.append('web is drawing a continuous column again - the app uses grains')

print('\nFAIL:\n  ' + '\n  '.join(fail) if fail else '\nOK - web falling sand matches the app.')
sys.exit(1 if fail else 0)
