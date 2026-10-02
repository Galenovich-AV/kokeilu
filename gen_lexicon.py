"""Embed lexicon.txt into index.html (between the LEX markers) as a compact JS object."""
import json, pathlib, re
root = pathlib.Path(__file__).parent
forms, exprs = {}, []
for line in (root / 'lexicon.txt').read_text(encoding='utf-8').splitlines():
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    if line.startswith('@'):
        lemma, ru, rx = [x.strip() for x in line[1:].split('|', 2)]
        exprs.append([lemma, ru, rx])
        continue
    lemma, ru, fs = [x.strip() for x in line.split('|')]
    for f in fs.split():
        forms[f.lower()] = [lemma, ru]
js = 'const LEX = ' + json.dumps({'forms': forms, 'exprs': exprs}, ensure_ascii=False, separators=(',', ':')) + ';'
page = (root / 'index.html').read_text(encoding='utf-8')
page = re.sub(r'/\*LEX-START\*/.*?/\*LEX-END\*/', lambda m: '/*LEX-START*/' + js + '/*LEX-END*/', page, flags=re.S)
(root / 'index.html').write_text(page, encoding='utf-8')
print(len(forms), 'forms,', len(exprs), 'expressions')
