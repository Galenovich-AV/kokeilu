// Finds Wiktionary multiword terms (tools/wiktionary_fi_multiword_terms.txt) in the site texts, by surface form or base form.
// Run: node tools/find_expressions.js   — then add real hits to lexicon.txt as "@ phrase | перевод | regex".
const fs=require('fs');const s=fs.readFileSync(require('path').join(__dirname,'..','index.html'),'utf8');
const a=s.indexOf('const TOPICS = ['), b=s.indexOf('\n];', a)+3; eval(s.slice(a,b).replace('const TOPICS','global.TOPICS'));
const L=s.match(/const LEX = (\{.*?\});\/\*LEX-END/s)[1]; const LEX=JSON.parse(L);
const texts=[];const push=x=>{if(typeof x==='string'&&!/[а-яё]/i.test(x))texts.push(x)};
TOPICS.forEach(t=>t.blocks.forEach(b=>b.exercises.forEach(ex=>{(ex.items||[]).forEach(it=>{push(it.t);push(it.box)});(ex.texts||[]).forEach(tx=>{push(tx.title);tx.body.forEach(push);tx.questions.forEach(q=>{push(q.q);(q.options||[]).forEach(push)})});(ex.tasks||[]).forEach(tk=>{push(tk.text);tk.points.forEach(push)});(ex.groups||[]).forEach(g=>g.cards.forEach(c=>push(c[2])))})));
const sents=texts.map(t=>(t.match(/[\p{L}]+(?:-[\p{L}]+)*/gu)||[]).map(w=>{const k=w.toLowerCase();const h=LEX.forms[k];return {w:k,l:h?h[0].toLowerCase():k}}));
const mwe=fs.readFileSync(require('path').join(__dirname,'wiktionary_fi_multiword_terms.txt'),'utf8').split('\n').filter(x=>/^[\p{L} -]+$/u.test(x)&&x.includes(' '));
const found=new Map();
for(const m of mwe){const toks=m.toLowerCase().split(/\s+/);if(toks.length<2)continue;
 for(const [si,S] of sents.entries()){for(let i=0;i<S.length;i++){let j=i,k=0,gaps=0;
  while(k<toks.length&&j<S.length){if(S[j].w===toks[k]||S[j].l===toks[k]){k++;j++}else if(k>0&&gaps<1){gaps++;j++}else break}
  if(k===toks.length){const key=m;if(!found.has(key))found.set(key,[]);found.get(key).push(S.slice(i,j).map(x=>x.w).join(' '));}}}}
for(const [k,v] of found) console.log(k,'  ⇐  ',[...new Set(v)].join(' | '));
