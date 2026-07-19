#!/usr/bin/env python
"""Guards hybrid.html's slider plumbing. Three classes of silent breakage came from
here, all of which blank the canvas with no clue:
  1. an S key read but never defined -> addColorStop(NaN) -> drawSand throws
  2. a slider wired to nothing, so moving it does nothing
  3. a BACKTICK inside the shader source, which ends the template literal and
     truncates the entire module (hit three times in one session)
Run after editing hybrid.html."""
import re, io, sys

s = io.open('hybrid.html', encoding='utf-8').read()
s2 = s
script = re.search(r'<script type="module">(.*?)</script>', s, re.S).group(1)
ids = set(re.findall(r'id="([^"]+)"', s))
lit = re.search(r'const S = \{(.*?)\n?\};', script, re.S).group(1)
lit = re.sub(r'//.*', '', lit)                       # strip comments
defined = set(re.findall(r'(\w+)\s*:', lit))
used = set(re.findall(r'\bS\.(\w+)\b', script))
# Some keys are reached dynamically (S[m.h] via the HALF table, S[f] over the sun
# field list), which dotted-access matching cannot see. A quoted string equal to an
# S key counts as a read, otherwise those sliders look dead when they are live.
quoted = set(re.findall(r"['\"](\w+)['\"]", script))

binds = re.findall(r"bind\('([^']+)','([^']+)','([^']+)'", script)
# colour pickers use their own binder; same contract, no readout element
for el, key in re.findall(r"bindCol\('([^']+)','([^']+)'\)", script):
    binds.append((el, None, key))

fail = []

# The shaders must stay in <script> DATA BLOCKS, not template literals.
# MDN: a <script> whose type is not a JavaScript MIME type "is treated as a data
# block, and won't be processed by the browser", and its content reads back via
# textContent. That makes a backtick in a GLSL comment an ordinary character.
# While the shaders lived in template literals a stray backtick silently truncated
# the whole module and blanked the page - three times. The old guard here searched
# for a backtick INSIDE a non-greedy backtick-delimited match, which by construction
# can never match: it was incapable of ever firing.
for kind in ('vert', 'frag'):
    if f'id="{kind}Shader"' not in s2:
        fail.append(f'{kind} shader is not a <script id="{kind}Shader"> data block')
if re.search(r'(?:vertex|fragment)Shader:\s*`', s2):
    fail.append('a shader is back in a template literal - one stray backtick will '
                'truncate the module and blank the page')

# TEMPORAL DEAD ZONE. `const` is not hoisted (MDN: "can only be accessed after the
# place of declaration is reached"), so a top-level statement that uses a const
# declared further down throws ReferenceError at load and the whole module dies —
# a blank page with a working UI panel. node --check CANNOT see this: it is a
# runtime error, not a syntax error. This shipped once as bind(...F2) placed above
# `const F2 = ...`.
# Only top-level statements are checked (column 0). A const referenced inside a
# function body declared earlier is fine, because the body runs later.
lines = script.split('\n')
declared_at = {}
for i, ln in enumerate(lines):
    m = re.match(r'const\s+(\w+)\s*=', ln)
    if m:
        declared_at.setdefault(m.group(1), i)
    for nm in re.findall(r'const\s+(\w+)\s*=[^,;]*,\s*(\w+)\s*=', ln):
        for n in nm:
            declared_at.setdefault(n, i)
for i, ln in enumerate(lines):
    if not ln or ln[0].isspace() or ln.lstrip().startswith('//'):
        continue                                   # not a top-level statement
    if re.match(r'(?:const|let|var|function|class)\b', ln):
        continue                                   # a declaration, not a use
    for name in re.findall(r'\b([A-Za-z_]\w*)\b', ln):
        d = declared_at.get(name)
        if d is not None and d > i:
            fail.append(f"line {i+1} uses '{name}' but it is declared on line {d+1} "
                        f"- temporal dead zone, throws at load and blanks the page")

for k in sorted(used - defined):
    fail.append(f"S.{k} is READ but has no default in the S literal")
# a slider the user can move that changes nothing is a silent time-waster
for el, out, key in binds:
    if key not in used and key not in quoted:
        fail.append(f"slider '{el}' writes S.{key} which is never read - dead control")
for k in sorted(defined - used - quoted):
    fail.append(f"S.{k} is defined but never read - dead default, remove it")
# An <input> in the panel with NO bind() at all is a dead control the user can
# move to no effect. The read/defined checks miss it entirely — coneLift shipped
# that way for exactly this reason.
bound = {el for el, _, _ in binds}
# Not everything goes through bind(): colour pickers use their own binders, and the
# per-phase grade controls attach listeners directly. Both are genuinely wired.
bound |= set(re.findall(r"bind(?:Col|MoonCol)\('([^']+)'", script))
bound |= set(re.findall(r"\$\('(\w+)'\)\.addEventListener\('input'", script))
# Scan the whole file rather than trying to bound the panel: an earlier version
# anchored on '<div id="ui">...</div><canvas', that pattern stopped matching, and
# the check silently passed everything. A check that cannot fire is worse than none.
inputs = re.findall(r'<input[^>]*id="(\w+)"', s2)
if not inputs:
    fail.append("found no <input> elements at all - this check is not looking where it should")
for el in inputs:
    if el not in bound:
        fail.append(f"<input id=\"{el}\"> has no bind() - moving it does nothing")

for el, out, key in binds:
    if el not in ids:
        fail.append(f"bind('{el}') has no <input id=\"{el}\">")
    if out is not None and out not in ids:
        fail.append(f"bind -> <b id=\"{out}\"> missing (slider {el})")
    if key not in defined:
        fail.append(f"bind('{el}') writes S.{key}, absent from S literal")

print(f"S keys defined: {len(defined)}   read: {len(used)}   binds: {len(binds)}")
if fail:
    print("\nFAIL:")
    for f in fail:
        print("  -", f)
    sys.exit(1)
print("OK - every S key has a default and every bind is wired.")
