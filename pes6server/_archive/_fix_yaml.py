# -*- coding: utf-8 -*-
import re
p = r'D:\Games\friendPES6\pes6server\fiveserver\etc\conf\sixserver.yaml'
lines = open(p, encoding='utf-8').read().split('\n')
BAD_PREFIXES = (
    'Welcome to Fiveserver',
    'independent community server',
    'supporting PES6/WE2007',
    'Have a good time, play some nice',
    'football and try to score goals',
    'Credits:',
    'Protocol analysis:',
    'Server programming: juce',
)
out = []
for ln in lines:
    st = ln.strip()
    if st == '\\n\\' or any(st.startswith(b) for b in BAD_PREFIXES):
        continue
    out.append(ln)
s = '\n'.join(out)
s = re.sub(r'\n{3,}', '\n\n', s)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('cleaned, tail:')
print(s[-300:])
