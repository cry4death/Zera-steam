"""A4 QA: метрики, спектры, стык лупов, картинки, сцена, сверка с main и детерминированность.

Запуск из корня worktree:
  PYTHONDONTWRITEBYTECODE=1 python design/tasks/reports/a4_verify.py [--sfx sfx] [--repeat <dir>] [--scene] [--plots-only]
  --sfx <папка>   что проверять (по умолчанию sfx/)
  --repeat <dir>  вторая сборка (prep_sfx.py --out <dir>) для побайтового сравнения
  --scene         склеить design/tasks/reports/a4_scene.wav (20 с, в git не коммитится)
  --plots-only    только картинки
"""
from pathlib import Path
import argparse
import ast
import csv
import hashlib
import json
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools"))
import prep_sfx as p

GROUPS = ("zombies", "ambience", "gore", "player", "ui")
MIN_COUNT = {"zombies/groan": 8, "zombies/attack": 4, "zombies/death": 6, "zombies/runner": 4, "zombies/fat": 3,
             "zombies/spit": 3, "zombies/boss_roar": 2, "ambience/horde": 2, "gore/hit": 8, "gore/splat": 6,
             "gore/gib": 4, "gore/bone": 4, "player/hurt": 4, "player/heartbeat": 1, "ui/click": 1,
             "ui/confirm": 1, "ui/deny": 1}
LOOPS = ("ambience/horde", "player/heartbeat")
FONT = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
SMALL = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_imports(sfx):
    """PCM сохраняет короткие шумовые атаки; importer 2 = Forward, 1 = Disabled."""
    for path in new_files(sfx):
        id_, rel = ident(path, sfx)
        sidecar = path.with_suffix(".wav.import")
        if sidecar.exists():
            continue
        resource = "res://sfx/" + rel
        dest = "res://.godot/imported/" + path.name + "-" + hashlib.md5(resource.encode()).hexdigest() + ".sample"
        sidecar.write_text(f'''[remap]

importer="wav"
type="AudioStreamWAV"
path="{dest}"

[deps]

source_file="{resource}"
dest_files=["{dest}"]

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode={2 if id_ in LOOPS else 1}
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
''', encoding="utf-8")


def db(x):
    return float(20 * np.log10(max(float(x), 1e-12)))


def new_files(sfx):
    return sorted(f for f in sfx.rglob("*.wav") if f.relative_to(sfx).parts[0] in GROUPS)


def ident(path, sfx):
    rel = path.relative_to(sfx).as_posix()
    return rel.rsplit("_", 1)[0], rel


def tonality(x, rate=48000):
    """Выступание спектральных пиков над локальной медианой (дБ), 300–9000 Гц, по громким кадрам.

    Шум даёт ≈ 9–11 дБ; чистый тон — 30+ дБ. Возвращает (p95 по кадрам, максимум)."""
    n, hop = 1024, 256
    if len(x) < n:
        x = np.pad(x, (0, n - len(x)))
    window = np.hanning(n)
    starts = range(0, len(x) - n + 1, hop)
    frames = np.stack([x[s:s + n] * window for s in starts])
    level = np.sqrt((frames ** 2).mean(axis=1))
    keep = level > level.max() * 10 ** (-20 / 20)
    mag = 20 * np.log10(np.abs(np.fft.rfft(frames[keep], axis=1)) + 1e-9)
    lo, hi = int(300 / (rate / n)), int(9000 / (rate / n))
    band = mag[:, lo:hi]
    stack = np.lib.stride_tricks.sliding_window_view(np.pad(mag, ((0, 0), (20, 20)), mode="edge"), 41, axis=1)[:, lo:hi]
    median = np.median(stack, axis=2)
    prom = (band - median).max(axis=1)
    return float(np.percentile(prom, 95)), float(prom.max())


def spectral(x, rate=48000):
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x)))) ** 2
    f = np.fft.rfftfreq(len(x), 1 / rate)
    centroid = float((spec * f).sum() / spec.sum())
    roll = float(f[np.searchsorted(np.cumsum(spec) / spec.sum(), .85)])
    band = spec[(f > 200) & (f < 10000)] + 1e-18
    flat = float(np.exp(np.mean(np.log(band))) / np.mean(band))
    return centroid, roll, flat


def envelope_stats(x, rate=48000):
    win = max(1, round(.002 * rate))
    env = np.sqrt(np.convolve(x ** 2, np.ones(win) / win, "same"))
    top = int(np.argmax(env))
    above = np.flatnonzero(env[top:] > env[top] * 10 ** (-30 / 20))
    return top / rate * 1000, (above[-1] / rate if len(above) else 0.0)


def metrics(sfx):
    rows = []
    for path in new_files(sfx):
        ident_, rel = ident(path, sfx)
        x, rate = p.read_pcm(path)
        with wave.open(str(path)) as w:
            channels, width = w.getnchannels(), w.getsampwidth()
        assert width == 2 and rate == 48000, rel
        mono = x.mean(axis=1)
        peak = db(np.abs(x).max())
        assert peak <= -1 and np.sum(np.abs(x) >= 32767 / 32768) == 0, rel
        loop = ident_ in LOOPS
        centroid, roll, flat = spectral(mono)
        prom95, promax = tonality(mono)
        attack_ms, t30 = envelope_stats(mono)
        row = {"file": rel, "channels": channels, "seconds": round(len(x) / rate, 4), "peak_dbfs": round(peak, 2),
               "rms_dbfs": round(db(np.sqrt(np.mean(x ** 2))), 2), "centroid_hz": round(centroid), "rolloff85_hz": round(roll),
               "flatness": round(flat, 3), "tonal_prom95_db": round(prom95, 1), "tonal_prom_max_db": round(promax, 1),
               "attack_ms": round(attack_ms, 1), "t_minus30_s": round(t30, 3), "dc": float(abs(x.mean(axis=0)).max()),
               "endpoints": float(np.abs(x[[0, -1]]).max()), "sha256": sha(path)}
        if not loop:
            assert row["endpoints"] == 0, rel
        assert row["dc"] < 2e-6, rel
        rows.append(row)
    return rows


def check_counts_and_limits(rows):
    counts = {}
    for r in rows:
        counts[r["file"].rsplit("_", 1)[0]] = counts.get(r["file"].rsplit("_", 1)[0], 0) + 1
    for id_, need in MIN_COUNT.items():
        assert counts.get(id_, 0) >= need, f"{id_}: {counts.get(id_, 0)} < {need}"
    by = {r["file"]: r for r in rows}
    for r in rows:
        id_ = r["file"].rsplit("_", 1)[0]
        if id_ == "gore/hit":
            assert r["seconds"] <= .15, r["file"]
        if id_.startswith("gore/"):
            assert r["tonal_prom95_db"] < 24 and r["tonal_prom_max_db"] < 30, r["file"]
        if id_ == "zombies/boss_roar":
            assert 1.5 <= r["seconds"] <= 2.5, r["file"]
        if id_ == "ambience/horde":
            assert 8 <= r["seconds"] <= 12, r["file"]
        if id_ == "player/heartbeat":
            assert r["seconds"] == 1.0, r["file"]
        assert r["channels"] == 1, r["file"]
    return counts


def check_sources_and_code(sfx):
    manifest = json.loads((sfx / "manifest.json").read_text(encoding="utf-8"))
    original_manifest = json.loads(subprocess.run(["git", "show", "main:sfx/manifest.json"], cwd=ROOT,
                                                 capture_output=True, check=True).stdout.decode("utf-8"))
    assert manifest["files"][:len(original_manifest["files"])] == original_manifest["files"]
    for key, value in original_manifest["source_files"].items():
        assert manifest["source_files"][key] == value, key
    for path in new_files(sfx):
        id_, rel = ident(path, sfx)
        settings = path.with_suffix(".wav.import").read_text(encoding="utf-8")
        assert f"edit/loop_mode={2 if id_ in LOOPS else 1}" in settings, rel
        assert "compress/mode=0" in settings and "edit/normalize=false" in settings, rel
    sources = [(k, v) for k, v in manifest["source_files"].items() if k.startswith("zombies_cc0/")]
    assert len(sources) == 42, len(sources)
    for name, info in sources:
        path = p.DEFAULT_ZSRC / name.removeprefix("zombies_cc0/")
        assert sha(path) == info["sha256"], name
        with wave.open(str(path)) as w:
            assert (w.getsampwidth(), w.getframerate(), w.getnchannels()) == (3, 44100, 2), name
    original = ast.parse(subprocess.run(["git", "show", "main:tools/prep_sfx.py"], cwd=ROOT,
                                        capture_output=True, check=True).stdout.decode("utf-8"))
    current = ast.parse((ROOT / "tools/prep_sfx.py").read_text(encoding="utf-8"))
    definitions = {node.name: node for node in current.body if isinstance(node, ast.FunctionDef)}
    for node in original.body:
        if isinstance(node, ast.FunctionDef) and node.name not in ("metadata", "main"):
            assert ast.dump(node) == ast.dump(definitions[node.name]), node.name
    # Контроль чувствительности метрики: шум и чистая синусоида с одной огибающей.
    t = np.arange(12000) / p.RATE
    envelope = np.sin(np.pi * np.arange(len(t)) / len(t)) ** 2
    noise_p95, _ = tonality(np.random.default_rng(4).standard_normal(len(t)) * envelope)
    sine_p95, _ = tonality(np.sin(2 * np.pi * 2000 * t) * envelope)
    assert noise_p95 < 20 and sine_p95 > 40, (noise_p95, sine_p95)
    print(f"SOURCES/CODE: PASS; 24 zombies + 18 monsters, PCM24 stereo 44100 Hz, SHA256 correct; old generator functions unchanged")
    print(f"TONALITY: reference noise={noise_p95:.1f} dB, sine={sine_p95:.1f} dB; all gore p95<24 dB, max<30 dB")


def seam(sfx):
    """Стык лупа: RMS последних/первых 50 мс, скачок на шве против обычных соседних отсчётов, ВЧ-энергия шва."""
    out = []
    for path in new_files(sfx):
        ident_, rel = ident(path, sfx)
        if ident_ not in LOOPS:
            continue
        x, _ = p.read_pcm(path)
        m = x.mean(axis=1)
        n50 = 2400
        step = np.abs(np.diff(x, axis=0)).max(axis=1)
        jump = float(np.abs(x[0] - x[-1]).max())
        # ВЧ (>3 кГц) разность: энергия в ±2 мс вокруг шва против среднего по файлу
        loop2 = np.concatenate([m[-4800:], m[:4800]])
        hf = loop2 - np.convolve(loop2, np.ones(16) / 16, "same")        # грубый ФВЧ
        hf_full = m - np.convolve(m, np.ones(16) / 16, "same")
        seam_rms = float(np.sqrt(np.mean(hf[4800 - 96:4800 + 96] ** 2)))
        avg_rms = float(np.sqrt(np.mean(hf_full ** 2)))
        assert jump <= max(float(np.percentile(step, 99)) * 1.5, 1 / 32768), rel
        out.append({"file": rel, "rms_last50_db": round(db(np.sqrt(np.mean(m[-n50:] ** 2))), 2),
                    "rms_first50_db": round(db(np.sqrt(np.mean(m[:n50] ** 2))), 2),
                    "jump_last_to_first": round(jump, 6), "median_step": round(float(np.median(step)), 6),
                    "p99_step": round(float(np.percentile(step, 99)), 6), "max_step": round(float(step.max()), 6),
                    "jump_over_p99": round(jump / max(float(np.percentile(step, 99)), 1e-9), 2),
                    "hf_seam_db_vs_avg": round(db(seam_rms / avg_rms), 2)})
    return out


# ---- картинки -----------------------------------------------------------------
def spectrogram(x, width, height, rate=48000, top_hz=12000):
    n = 1024 if len(x) > 20000 else 512
    hop = max(16, len(x) // width)
    window = np.hanning(n)
    pad = np.pad(x, (n // 2, n))
    frames = np.stack([pad[i:i + n] * window for i in range(0, max(1, len(x) - 1), hop)][:width])
    mag = np.abs(np.fft.rfft(frames, axis=1)).T
    bins = int(top_hz / (rate / n))
    mag = 20 * np.log10(mag[:bins] + 1e-9)
    mag = np.clip((mag - (mag.max() - 70)) / 70, 0, 1)[::-1]
    img = Image.fromarray((mag * 255).astype("uint8")).resize((width, height), Image.BILINEAR)
    return Image.merge("RGB", (img.point(lambda v: min(255, v * 2)),
                               img.point(lambda v: max(0, min(255, (v - 60) * 2))),
                               img.point(lambda v: 40 + v // 2)))


def draw_cell(image, draw, x, y, w, path, sfx, label=None, wave_h=60, spec_h=100):
    data, rate = p.read_pcm(path)
    mono = data.mean(axis=1)
    draw.text((x + 8, y + 3), label or path.relative_to(sfx).as_posix(), fill="#182b3d", font=FONT)
    draw.text((x + 8, y + 22), f"{len(data) / rate:.3f} s  peak {db(np.abs(data).max()):.1f} dBFS", fill="#485c6c", font=SMALL)
    a = mono / max(np.abs(mono).max(), 1e-9)
    inner = w - 20
    mid = y + 48 + wave_h // 2
    for j, block in enumerate(np.array_split(a, inner)):
        draw.line((x + 10 + j, mid - block.max() * wave_h / 2, x + 10 + j, mid - block.min() * wave_h / 2), fill="#156b9b")
    image.paste(spectrogram(mono, inner, spec_h), (x + 10, y + 52 + wave_h))
    draw.text((x + 10, y + 53 + wave_h + spec_h), f"0..{len(data)/rate:.3f}s | 0..12kHz bottom->top", fill="#485c6c", font=SMALL)
    return y + 52 + wave_h + spec_h + 6


def sheet(files, sfx, out, cols, cw, wave_h=60, spec_h=100, labels=None):
    ch = 52 + wave_h + spec_h + 16
    image = Image.new("RGB", (cols * cw, ((len(files) + cols - 1) // cols) * ch), "#f7f9fc")
    draw = ImageDraw.Draw(image)
    for i, path in enumerate(files):
        draw_cell(image, draw, (i % cols) * cw, (i // cols) * ch, cw, path, sfx, labels[i] if labels else None, wave_h, spec_h)
    image.save(out)


def plots(sfx):
    files = new_files(sfx)
    firsts = [f for f in files if f.name.endswith("_0.wav") and f.parts[-2] != "ambience"]
    sheet([f for f in firsts if f.relative_to(sfx).parts[0] == "zombies"], sfx, REPORT / "a4_voices.png", 3, 600)
    sheet([f for f in files if f.relative_to(sfx).parts[0] == "gore"], sfx, REPORT / "a4_gore.png", 4, 470,
          spec_h=120)
    rest = [f for f in firsts if f.relative_to(sfx).parts[0] in ("player", "ui")]
    sheet(rest, sfx, REPORT / "a4_player_ui.png", 3, 600)
    # лупы: форма + спектр + стык (последние 100 мс + первые 100 мс, стык по центру)
    loops = [f for f in files if ident(f, sfx)[0] in LOOPS]
    image = Image.new("RGB", (1400, len(loops) * 330), "#f7f9fc")
    draw = ImageDraw.Draw(image)
    for i, path in enumerate(loops):
        y = i * 330
        data, rate = p.read_pcm(path)
        mono = data.mean(axis=1)
        draw.text((20, y + 4), f"{path.relative_to(sfx).as_posix()}  {len(data) / rate:.3f} s", fill="#182b3d", font=FONT)
        a = mono / np.abs(mono).max()
        for j, block in enumerate(np.array_split(a, 880)):
            draw.line((20 + j, y + 70 - block.max() * 40, 20 + j, y + 70 - block.min() * 40), fill="#156b9b")
        image.paste(spectrogram(mono, 880, 110, top_hz=8000), (20, y + 120))
        # шов
        join = np.concatenate([mono[-4800:], mono[:4800]])
        draw.text((930, y + 4), "стык: последние 100 мс | первые 100 мс", fill="#182b3d", font=SMALL)
        b = join / max(np.abs(join).max(), 1e-9)
        for j, block in enumerate(np.array_split(b, 440)):
            draw.line((930 + j, y + 70 - block.max() * 40, 930 + j, y + 70 - block.min() * 40), fill="#156b9b")
        draw.line((930 + 220, y + 20, 930 + 220, y + 110), fill="#c43c3c")
        image.paste(spectrogram(join, 440, 110, top_hz=8000), (930, y + 120))
        draw.text((20, y + 240), "0 .. %.1f s; слева спектрограмма всего лупа до 8 кГц" % (len(data) / rate), fill="#485c6c", font=SMALL)
    image.save(REPORT / "a4_loops.png")
    sheet(firsts + [f for f in loops if f.name != "heartbeat_0.wav"], sfx,
          REPORT / "a4_waveforms.png", 4, 470, spec_h=120)


def compare_hashes(sfx):
    """Прежние файлы sfx/ (всё, что было в main) — байт-в-байт, кроме CREDITS.md и manifest.json."""
    listing = subprocess.run(["git", "ls-tree", "-r", "--name-only", "main", "sfx"], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout.split()
    changed = []
    for name in listing:
        if name in ("sfx/CREDITS.md", "sfx/manifest.json"):
            continue
        blob = subprocess.run(["git", "show", f"main:{name}"], cwd=ROOT, capture_output=True, check=True).stdout
        if hashlib.sha256(blob).digest() != hashlib.sha256((sfx / Path(name).relative_to("sfx")).read_bytes()).digest():
            changed.append(name)
    return listing, changed


def build_scene(sfx, out):
    """20 с: луп орды + 30 стонов + очередь АК + 25 попаданий + 8 смертей + 2 гиба + сердцебиение."""
    rng = np.random.default_rng(404)
    rate, n = 48000, 20 * 48000
    mix = np.zeros((n, 2))

    def load(name):
        x, _ = p.read_pcm(sfx / name)
        return x

    def put(x, t, gain_db=0.0, pan=0.0):
        a = (pan + 1) * np.pi / 4
        g = 10 ** (gain_db / 20)
        start = int(t * rate)
        size = min(len(x), n - start)
        if size > 0:
            if x.shape[1] == 2:
                mix[start:start + size] += g * x[:size]
            else:
                mix[start:start + size, 0] += g * np.cos(a) * x[:size, 0]
                mix[start:start + size, 1] += g * np.sin(a) * x[:size, 0]

    # орда (плотная) на весь отрезок: луп 12 с, дважды с обрезкой
    horde = load("ambience/horde_1.wav")
    loop = np.concatenate([horde, horde])[:n]
    mix += loop
    heart = load("player/heartbeat_0.wav")[:, 0]
    for k in range(20):
        put(heart[:, None], k * 1.0, -2 if k >= 10 else -12, 0.0)    # со 2-й половины громче: низкое HP
    kinds = ["groan_%d" % i for i in range(14)]
    for k in range(30):
        name = f"zombies/{kinds[rng.integers(len(kinds))]}.wav"
        put(load(name), rng.uniform(.3, 18.5), rng.uniform(-8, -1), rng.uniform(-.9, .9))
    for k in range(3):
        put(load(f"zombies/attack_{k}.wav"), 4 + 4 * k + rng.uniform(0, 1), -4, rng.uniform(-.7, .7))
        put(load(f"zombies/runner_{k}.wav"), 6 + 3 * k, -5, rng.uniform(-.7, .7))
    put(load("zombies/fat_0.wav"), 9.0, -4, -.3)
    put(load("zombies/spit_1.wav"), 11.3, -5, .5)
    put(load("zombies/boss_roar_0.wav"), 14.0, -3, 0)
    # очередь АК: 14 выстрелов за 2.3 с, c 7.0 с, +25 попаданий, +смерти
    t0 = 7.0
    for k in range(14):
        t = t0 + k * .165
        put(load(f"weapons/rifle/shot_{k % 4}.wav"), t, 0, 0)
        put(load(f"gore/hit_{rng.integers(10)}.wav"), t + rng.uniform(.02, .09), -3, rng.uniform(-.8, .8))
    put(load("weapons/rifle/tail_0.wav"), t0 + 14 * .165, -3, 0)
    for k in range(11):
        put(load(f"gore/hit_{rng.integers(10)}.wav"), rng.uniform(1.0, 6.5) if k < 6 else rng.uniform(10, 16),
            -3, rng.uniform(-.8, .8))
    for k in range(8):
        t = 7.6 + k * .55 + rng.uniform(0, .2)
        put(load(f"gore/splat_{k % 8}.wav"), t, -2, rng.uniform(-.8, .8))
        put(load(f"zombies/death_{k % 8}.wav"), t - .03, -5, rng.uniform(-.8, .8))
    put(load("gore/bone_0.wav"), 12.4, -3, .3)
    put(load("gore/gib_0.wav"), 12.0, -1, -.4)
    put(load("gore/gib_3.wav"), 16.2, -1, .4)
    put(load("player/hurt_1.wav"), 13.4, -2, 0)
    put(load("player/hurt_2.wav"), 17.2, -2, 0)
    mix = p.finish(mix, .08)
    peak = np.abs(mix).max()
    mix *= 10 ** (-1.5 / 20) / peak
    quant = np.rint(mix * 32768).astype("<i2")
    with wave.open(str(out), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(quant.tobytes())
    return peak


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sfx", type=Path, default=ROOT / "sfx")
    parser.add_argument("--plots-only", action="store_true")
    parser.add_argument("--repeat", type=Path)
    parser.add_argument("--scene", action="store_true")
    parser.add_argument("--write-imports", action="store_true")
    args = parser.parse_args()
    sfx = args.sfx
    if args.write_imports:
        write_imports(sfx)
    rows = metrics(sfx)
    counts = check_counts_and_limits(rows)
    print(f"FORMAT/COUNTS: PASS; {len(rows)} new WAV (PCM16/48 kHz; all mono); "
          f"peak {min(r['peak_dbfs'] for r in rows)}..{max(r['peak_dbfs'] for r in rows)} dBFS; no clipping; non-loop endpoints=0")
    print("COUNTS " + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    if not args.plots_only:
        check_sources_and_code(sfx)
        with (REPORT / "a4_metrics.csv").open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        seams = seam(sfx)
        (REPORT / "a4_seams.json").write_text(json.dumps(seams, indent=2) + "\n", encoding="utf-8")
        for s in seams:
            print("SEAM", json.dumps(s, ensure_ascii=False))
        listing, changed = compare_hashes(sfx)
        assert not changed, changed
        print(f"MAIN HASHES: {'PASS' if not changed else 'FAIL ' + str(changed)}; {len(listing) - 2} files of main (WAV + .import) "
              "byte-identical; only CREDITS.md and manifest.json extended")
        total = sum(f.stat().st_size for f in sfx.rglob("*") if f.is_file())
        print(f"SIZE: sfx/ = {total / 1e6:.1f} MB (limit 40)")
        assert total < 40e6
        if args.repeat:
            names = [e["file"] for e in json.loads((sfx / "manifest.json").read_text(encoding="utf-8"))["files"]]
            assert set(names) == {f.relative_to(sfx).as_posix() for f in sfx.rglob("*.wav")}
            assert set(names) == {f.relative_to(args.repeat).as_posix() for f in args.repeat.rglob("*.wav")}
            bad = [n for n in names if sha(sfx / n) != sha(args.repeat / n)]
            for extra in ("manifest.json", "CREDITS.md"):
                if sha(sfx / extra) != sha(args.repeat / extra):
                    bad.append(extra)
            assert not bad, bad
            print(f"DETERMINISM: {'PASS' if not bad else 'FAIL ' + str(bad)}; {len(names)} WAV + manifest.json + CREDITS.md "
                  "equal to a second build (--out)")
    plots(sfx)
    print("VISUALS: a4_waveforms.png, a4_voices.png, a4_gore.png, a4_player_ui.png, a4_loops.png")
    if args.scene:
        peak = build_scene(sfx, REPORT / "a4_scene.wav")
        print(f"SCENE: a4_scene.wav 20 s stereo, pre-normalization peak {db(peak):.1f} dBFS, normalized to -1.5 dBFS")


if __name__ == "__main__":
    main()
