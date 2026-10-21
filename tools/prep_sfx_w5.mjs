// Детерминированная сборка W5 из тех же CC0-записей, что у prep_sfx.py.
// node tools/prep_sfx_w5.mjs [каталог Prepared SFX Library]
// Node используется, потому что Python из AGENTS.md недоступен в песочнице.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CHECK = process.argv.includes('--check');
const SRC = process.argv.slice(2).find(a => a !== '--check') || 'C:/Users/Dev/Desktop/zera-assets/firearm_cc0/extracted/Prepared SFX Library';
const RATE = 48000;
const specs = {
  pistol: ['1911/A_42P.wav', .75, 118, .035, .55, ['1911/A_34P.wav', [0, 6]]],
  revolver: ['Smith & Wesson 642/V_27P.wav', .90, 91, .050, .60, ['Smith & Wesson 642/V_22P.wav', [0, 6]]],
  smg: ['PPSh/P_30P.wav', .18, 140, .020, .35],
  rifle: ['AK-47/C_28P.wav', .18, 106, .032, .45],
  shotgun: ['Nova/O_21P.wav', 1.10, 74, .060, .65, ['Nova/O_17P.wav', [0, 5]]],
  sniper: ['Mosin Nagant/M_21P.wav', 1.20, 62, .070, .70],
};
const provenance = [];
let currentSource = '', currentTake = -1;
function read(file) {
  const b = fs.readFileSync(file); let off = 12, channels, rate, width, pcm;
  while (off + 8 <= b.length) {
    const id = b.toString('ascii', off, off + 4), size = b.readUInt32LE(off + 4), s = off + 8;
    if (id === 'fmt ') { channels = b.readUInt16LE(s + 2); rate = b.readUInt32LE(s + 4); width = b.readUInt16LE(s + 14) / 8; }
    if (id === 'data') pcm = b.subarray(s, s + size);
    off = s + size + size % 2;
  }
  if (![2, 3].includes(width) || !pcm) throw Error(`PCM16/24 required: ${file}`);
  const x = Array.from({length: channels}, () => new Float64Array(pcm.length / width / channels));
  for (let i = 0; i < x[0].length; i++) for (let c = 0; c < channels; c++) {
    const o = (i * channels + c) * width;
    x[c][i] = width === 2 ? pcm.readInt16LE(o) / 32768 : pcm.readIntLE(o, 3) / 8388608;
  }
  return {x, rate};
}
function filter(x, kind, hz, rate = RATE) {
  const w = 2 * Math.PI * hz / rate, co = Math.cos(w), a = Math.sin(w) / Math.SQRT2;
  const b0 = (1 + (kind === 'hp' ? co : -co)) / 2 / (1 + a);
  const b1 = (kind === 'hp' ? -(1 + co) : 1 - co) / (1 + a);
  const a1 = -2 * co / (1 + a), a2 = (1 - a) / (1 + a);
  let z1 = 0, z2 = 0; const y = new Float64Array(x.length);
  for (let i = 0; i < x.length; i++) { const v = x[i] * b0 + z1; z1 = x[i] * b1 - a1 * v + z2; z2 = x[i] * b0 - a2 * v; y[i] = v; }
  return y;
}
function source(rel) {
  const file = path.join(SRC, rel), b = fs.readFileSync(file), {x, rate} = read(file);
  provenance.push({source: rel, sha256: crypto.createHash('sha256').update(b).digest('hex')});
  if (rate !== 96000 || x.length !== 2) throw Error('Expected stereo 96 kHz CC0 source');
  // ФНЧ Blackman-sinc перед децимацией; задержка компенсирована.
  const h = new Float64Array(193); let sum = 0;
  for (let j = 0; j < h.length; j++) { const n = j - 96, v = 2 * 21500 / rate * n; h[j] = (v === 0 ? 1 : Math.sin(Math.PI * v) / (Math.PI * v)) * 2 * 21500 / rate * (.42 - .5 * Math.cos(2 * Math.PI * j / 192) + .08 * Math.cos(4 * Math.PI * j / 192)); sum += h[j]; }
  return x.map(a => { const y = new Float64Array(Math.ceil(a.length / 2)); for (let i = 0; i < y.length; i++) for (let j = 0; j < h.length; j++) { const k = 2 * i + j - 96; if (k >= 0 && k < a.length) y[i] += a[k] * h[j] / sum; } return y; });
}
function attacks(x) {
  let peak = 0; const env = x[0].map((v, i) => Math.max(Math.abs(v), Math.abs(x[1][i])));
  for (const v of env) peak = Math.max(peak, v);
  const groups = []; let last = -1e9;
  for (let i = 0; i < env.length; i += 24) {
    let m = 0; for (let j = i; j < Math.min(i + 24, env.length); j++) m = Math.max(m, env[j]);
    if (m <= peak * .18) continue;
    if (i - last > .035 * RATE) { let k = Math.max(0, i - 192); while (k < i + 24 && env[k] <= peak * .05) k++; groups.push(k); }
    last = i;
  }
  return groups;
}
function rms(x, n = x.length) { let sum = 0; n = Math.min(n, x.length); for (let i = 0; i < n; i++) sum += x[i] ** 2; return Math.sqrt(sum / Math.max(n, 1)); }
function peak(x) { let p = 0; for (const a of x) for (const v of a) p = Math.max(p, Math.abs(v)); return p; }
function guardTruePeak(x, ceiling) {
  // У электрического crack межсемпловый пик выше отсчётного; запас создаётся до Master.
  const h = []; let sum = 0;
  for (let j = -64; j <= 64; j++) {
    const t = j / 4, w = .42 - .5 * Math.cos(2 * Math.PI * (j + 64) / 128) + .08 * Math.cos(4 * Math.PI * (j + 64) / 128);
    h.push((t === 0 ? 1 : Math.sin(Math.PI * t) / (Math.PI * t)) * w); sum += h.at(-1);
  }
  let p = peak(x);
  for (const a of x) for (let phase = 1; phase < 4; phase++) for (let i = 0; i < a.length; i++) {
    let value = 0;
    for (let j = -16; j <= 16; j++) {
      const k = 64 + phase - j * 4, s = i + j;
      if (k >= 0 && k < h.length && s >= 0 && s < a.length) value += a[s] * h[k] * 4 / sum;
    }
    p = Math.max(p, Math.abs(value));
  }
  const gain = Math.min(1, 10 ** (ceiling / 20) / p);
  return x.map(a => a.map(v => v * gain));
}
function finish(x, ceiling = -.9, fade = .08) {
  for (const a of x) {
    let mean = 0; for (const v of a) mean += v / a.length;
    for (let i = 0; i < a.length; i++) { const t = i / RATE, end = (a.length - 1 - i) / RATE; a[i] = (a[i] - mean * 2 * Math.sin(Math.PI * i / (a.length - 1)) ** 2) * Math.min(1, t / .00025) * Math.min(1, end / fade); }
  }
  // Запас для межсемплового пика, повторная проверка x4 в w5_analyze.mjs.
  const gain = 10 ** (ceiling / 20) / Math.max(peak(x), 1e-9);
  return x.map(a => a.map(v => v * gain));
}
function write(gun, action, variant, x) {
  const file = path.join(ROOT, 'sfx/weapons', gun, `${action}_${variant}.wav`), ch = x.length, n = x[0].length;
  const b = Buffer.alloc(44 + n * ch * 2);
  b.write('RIFF'); b.writeUInt32LE(b.length - 8, 4); b.write('WAVEfmt ', 8); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(ch, 22); b.writeUInt32LE(RATE, 24); b.writeUInt32LE(RATE * ch * 2, 28); b.writeUInt16LE(ch * 2, 32); b.writeUInt16LE(16, 34); b.write('data', 36); b.writeUInt32LE(n * ch * 2, 40);
  for (let i = 0; i < n; i++) for (let c = 0; c < ch; c++) b.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(x[c][i] * 32768))), 44 + (i * ch + c) * 2);
  if (CHECK) {
    if (!fs.existsSync(file) || !fs.readFileSync(file).equals(b)) throw Error(`Non-deterministic output: ${file}`);
  } else if (!fs.existsSync(file) || !fs.readFileSync(file).equals(b)) fs.writeFileSync(file, b);
  provenance.push({file: `sfx/weapons/${gun}/${action}_${variant}.wav`, source: currentSource, take: currentTake,
    recipe: 'CC0 direct + parallel saturation + mono recorded body + damped pressure pulse + controlled street decay',
    sha256: crypto.createHash('sha256').update(b).digest('hex')});
}
function layer(x, freq, decay, weight, variant) {
  const n = x[0].length, mono = x[0].map((v, i) => (v + x[1][i]) * .5);
  // Низ делается моно до сатурации: противофаза стереозаписи не съедает удар.
  const body = filter(filter(mono, 'hp', 48), 'lp', 180), br = rms(body, 4800), sr = Math.max(rms(mono, 4800), .00001);
  const directGain = .25 / sr;
  for (let i = 0; i < n; i++) {
    const t = Math.max(0, i / RATE - .0015), env = (1 - Math.exp(-t / .0008)) * Math.exp(-t / decay);
    const recorded = body[i] / Math.max(br, 1e-9) * .09 * Math.exp(-t / .12);
    const thump = Math.sin(2 * Math.PI * (freq * t + .6 * (1 - Math.exp(-t / .018)))) * env * weight;
    for (let c = 0; c < 2; c++) {
      const dry = x[c][i] * directGain;
      // Параллельная сатурация добавляет плотность; исходный crack остаётся спереди.
      const tail = Math.exp(-Math.max(0, t - .08) / (decay * 3.5 + .06));
      const attack = (.15 * dry + .85 * Math.tanh(dry * 3.0) / 1.6) * tail;
      x[c][i] = attack + recorded + thump;
    }
  }
  return finish(x);
}
const shots = {};
for (const [gun, [rel, duration, freq, decay, weight, extra]] of Object.entries(specs)) {
  let variant = 0;
  for (const [file, chosen] of [[rel, null], ...(extra ? [extra] : [])]) {
    const src = source(file), at = attacks(src), indices = chosen || at.map((_, i) => i);
    for (const k of indices) {
      currentSource = file; currentTake = k + 1;
      if (at[k] === undefined) throw Error(`Missing take ${file}:${k}`);
      const start = Math.max(0, at[k] - 72), x = src.map(a => a.slice(start, start + Math.round(duration * RATE)));
      const y = layer(x, freq, decay, weight, variant); write(gun, 'shot', variant, y);
      if (!shots[gun]) shots[gun] = y;
      if (['smg', 'rifle'].includes(gun) && variant < 3) {
        // Последние отражения отдельно; внутри очереди звучит только короткий near-выстрел.
        const n = Math.round((gun === 'smg' ? .65 : .85) * RATE), tail = src.map(a => a.slice(at[k] + 5280, at[k] + 5280 + n));
        for (const a of tail) for (let i = 0; i < a.length; i++) a[i] *= Math.min(1, i / 1440) * Math.exp(-i / RATE / .20);
        write(gun, 'tail', variant, finish(tail, -23, .12));
      }
      variant++;
    }
  }
  console.log(`W5 BUILD ${gun} takes=${variant}`);
}
for (const gun of ['rail', 'launcher']) for (let variant = 0; variant < 3; variant++) {
  currentSource = `CC0 synthesis: ${gun}, seed=${104729 + variant * 7919}`; currentTake = variant + 1;
  const n = Math.round((gun === 'rail' ? .9 : 1.05) * RATE), x = [new Float64Array(n), new Float64Array(n)];
  let seed = 104729 + variant * 7919; const rand = () => { seed = (1664525 * seed + 1013904223) >>> 0; return seed / 2147483648 - 1; };
  const noise = new Float64Array(n); for (let i = 0; i < n; i++) noise[i] = rand();
  const low = filter(noise, 'lp', gun === 'rail' ? 3500 : 850);
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    const crack = gun === 'rail' ? (noise[i] - low[i] * .5) * Math.exp(-t / .009) + .30 * Math.sin(2 * Math.PI * (480 * t + 4800 * .012 * (1 - Math.exp(-t / .012)))) * Math.exp(-t / .038) : low[i] * 3.5 * Math.exp(-t / .045);
    for (let c = 0; c < 2; c++) x[c][i] = crack * (1 - Math.exp(-t / .0003)) * (1 - c * .03);
  }
  const direct = x.map(a => a.slice());
  for (const [delay, gain] of [[.075,.16],[.15,.10],[.29,.06]]) {
    const start = Math.round(delay * RATE); for (let c = 0; c < 2; c++) for (let i = start; i < n; i++) x[c][i] += direct[c][i - start] * gain;
  }
  let clip = layer(x, gun === 'rail' ? 132 : 57, gun === 'rail' ? .025 : .075, gun === 'rail' ? .28 : .55, variant);
  if (gun === 'rail') clip = guardTruePeak(clip, -.9);
  write(gun, 'shot', variant, clip);
}
if (!CHECK) fs.writeFileSync(path.join(ROOT, 'design/tasks/reports/w5_sources.json'), JSON.stringify(provenance, null, 2) + '\n');
console.log(`W5 BUILD PCM16 stereo 48000Hz verified=${CHECK} deterministic=true`);
