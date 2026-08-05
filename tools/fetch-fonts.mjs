import fs from 'node:fs/promises';
const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
const URL_CSS = 'https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@500;700;800&family=IBM+Plex+Mono:wght@400;500;600&display=swap';
const OUT = process.argv[2];
const css = await (await fetch(URL_CSS, { headers: { 'User-Agent': UA } })).text();
const blocks = css.split('@font-face').slice(1).map(b => '@font-face' + b.split('}\n').slice(0, 1).join('}\n') + '}');
// re-split properly
const re = /\/\*\s*([a-z0-9\-\[\]]+)\s*\*\/\s*@font-face\s*\{([^}]+)\}/g;
let m, out = [], n = 0;
while ((m = re.exec(css))) {
  const subset = m[1], body = m[2];
  if (!['latin', 'latin-ext'].includes(subset)) continue;
  const fam = /font-family:\s*'([^']+)'/.exec(body)[1];
  const wt = /font-weight:\s*([^;]+);/.exec(body)[1].trim();
  const st = /font-style:\s*([^;]+);/.exec(body)[1].trim();
  const ur = /src:\s*url\(([^)]+)\)/.exec(body)[1];
  const ur2 = /unicode-range:\s*([^;]+);/.exec(body)?.[1].trim();
  const slug = fam.toLowerCase().replace(/\s+/g, '-') + '-' + wt + '-' + subset + '.woff2';
  const buf = Buffer.from(await (await fetch(ur, { headers: { 'User-Agent': UA } })).arrayBuffer());
  await fs.writeFile(OUT + '/assets/fonts/' + slug, buf);
  n++;
  out.push(`@font-face{font-family:'${fam}';font-style:${st};font-weight:${wt};font-display:swap;src:url(fonts/${slug}) format('woff2');unicode-range:${ur2}}`);
  console.log(slug, (buf.length / 1024).toFixed(1) + 'kB');
}
await fs.writeFile(OUT + '/assets/fonts.css', out.join('\n') + '\n');
console.log('faces:', n);
