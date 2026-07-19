#!/usr/bin/env python
"""Guards the LOCKED sun. Two things must not regress:

  1. The body is a MIX, not an additive. When it was additive its apparent size
     depended on the plate behind it — 120% of frame width on the sunrise plate
     (whose sky is already 0.99 in red) versus 1.4% on midnight. As a mix, size is
     a pure function of radius and cannot track the sky.
  2. The founder's three keys are intact, including nearA/farA = 0. The near and
     far glow layers are deliberately OFF; the locked look is one steep bright
     core whose colour shifts through the day. Do not "restore" them.

Run from web-prototype/ after editing hybrid.html."""
import re, io, sys

s = io.open('hybrid.html', encoding='utf-8').read()
fail = []

# --- 1. blend operator
sun = s[s.index('float disc ='):s.index('// --- far glow')]
if 'mix(col, sunC, sunA' not in sun:
    fail.append('sun body is no longer a mix — its size will track the plate again')
if 'clamp(disc + near' in sun:
    fail.append('sunA is clamped again — that plateau is what created a visible border')
if '1.0 - exp(-(disc + near))' not in sun:
    fail.append('sunA is not the asymptotic form; a hard shoulder will show as an edge')
far = s[s.index('// --- far glow'):s.index('// --- far glow')+400]
if 'exp(-uFarCol' not in far:
    fail.append('far glow is no longer screened — it will bloom into a blob')

# --- 2. locked keys
keys = re.search(r'const SUNKEY = \[(.*?)\n\];', s, re.S).group(1)
LOCKED = {'sunSize': '0.09', 'coreW': '8', 'coreA': '6',
          'nearW': '3', 'nearA': '0', 'farW': '0.01', 'farA': '0'}
names = re.findall(r"name:'(\w+)'", keys)
if names != ['sunrise', 'midday', 'sunset']:
    fail.append(f'sun keys are {names}, expected sunrise/midday/sunset')
for blk in re.findall(r'\{ name:.*?\}', keys, re.S):
    nm = re.search(r"name:'(\w+)'", blk).group(1)
    for k, v in LOCKED.items():
        got = re.search(r'\b%s:\s*([\d.]+)' % k, blk)
        if not got:
            fail.append(f'{nm}: {k} missing')
        elif abs(float(got.group(1)) - float(v)) > 1e-9:
            fail.append(f'{nm}: {k}={got.group(1)}, founder locked {v}')

# every key must reach a uniform
fields = re.search(r'const SUN_FIELDS = \[(.*?)\];', s, re.S).group(1)
cols   = re.search(r'const SUN_COLS   = \[(.*?)\];', s, re.S).group(1)
U = re.search(r'const U = \{(.*?)\n\};', s, re.S).group(1)
for f in re.findall(r"'(\w+)'", fields + cols):
    if 'u' + f[0].upper() + f[1:] not in U:
        fail.append(f'sun param {f} is not wired to a uniform')

print('sun: body=mix, 3 keys, glow layers deliberately off')
if fail:
    print('\nFAIL:')
    for f in fail:
        print('  -', f)
    sys.exit(1)
print('OK - locked sun intact.')
