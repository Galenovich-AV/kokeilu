"""Build the Netlify site (site/) from index.html, the claude.ai page source."""
import pathlib, shutil, subprocess, sys
root = pathlib.Path(__file__).parent
subprocess.run([sys.executable, str(root / 'gen_lexicon.py')], check=True)
page = (root / 'index.html').read_text(encoding='utf-8')
head = ('<!doctype html>\n<html lang="ru">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n</head>\n<body>\n')
page = page.replace('<script>', '<script src="config.js"></script>\n<script>', 1)
out = root / 'site'
out.mkdir(exist_ok=True)
(out / 'index.html').write_text(head + page + '\n</body>\n</html>\n', encoding='utf-8')
shutil.copy(root / 'config.js', out / 'config.js')
print('built', out / 'index.html')
