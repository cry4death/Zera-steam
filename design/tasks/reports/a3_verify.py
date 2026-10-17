"""A3 QA: метрики, побайтовая сверка с main, детерминированность, осциллограммы.

Запуск из корня worktree: PYTHONDONTWRITEBYTECODE=1 python design/tasks/reports/a3_verify.py
  --sfx <папка>  что проверять (по умолчанию sfx/)
  --plots-only   только картинки
  --repeat <dir> готовая вторая сборка (prep_sfx.py --out <dir>) для сравнения
"""
from pathlib import Path
import argparse
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

NEW_GUNS = ("m4", "shkval", "guard", "cowboy", "osa", "winchester", "spear", "hive")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(x):
    return float(20 * np.log10(max(float(x), 1e-12)))


def max_rms(x):
    power = np.pad(x[:, 0] ** 2, (0, max(0, 4800 - len(x))))
    e = np.concatenate(([0.], np.cumsum(power)))
    return np.sqrt(np.max(e[4800:] - e[:-4800]) / 4800)


def new_files(sfx):
    return sorted(f for f in sfx.rglob("*.wav")
                  if f.relative_to(sfx).parts[0] == "weapons" and f.relative_to(sfx).parts[1] in NEW_GUNS)


def metrics(sfx):
    rows = []
    for path in new_files(sfx):
        rel = path.relative_to(sfx).as_posix()
        x, rate = p.read_pcm(path)
        with wave.open(str(path)) as w:
            channels, width = w.getnchannels(), w.getsampwidth()
        assert width == 2 and rate == 48000, rel
        event = path.name.rsplit("_", 1)[0]
        shot = event == "shot"
        assert channels == (2 if shot else 1), rel
        mono = x.mean(axis=1, keepdims=True) if channels == 2 else x
        row = {"file": rel, "channels": channels, "seconds": round(len(x) / rate, 4),
               "peak_dbfs": round(db(np.abs(x).max()), 2),
               "rms_dbfs": round(db(np.sqrt(np.mean(mono ** 2))), 2),
               "rms100_start_dbfs": round(db(np.sqrt(np.mean(x[:4800] ** 2))), 2),
               "rmsmax100_dbfs": round(db(max_rms(x)), 2),
               "dc": float(abs(x.mean())), "endpoints": float(np.abs(x[[0, -1]]).max()),
               "tail1ms_dbfs": round(db(np.sqrt(np.mean(x[-48:] ** 2))), 2),
               "clipped": int(np.sum(np.abs(x) >= 32767 / 32768)), "sha256": sha(path)}
        assert row["peak_dbfs"] <= -1 and row["clipped"] == 0, rel
        assert row["dc"] < 2e-6 and row["endpoints"] == 0, rel
        assert row["tail1ms_dbfs"] < -60, rel
        gun = path.parent.name
        if gun in p.SHOT_LEVELS and not shot and gun in NEW_GUNS and gun not in ("spear", "hive"):
            assert abs(row["rmsmax100_dbfs"] - (p.SHOT_LEVELS[gun] - 12)) < .02, rel
        if shot and gun in p.SHOT_LEVELS:
            assert abs(row["rms100_start_dbfs"] - p.SHOT_LEVELS[gun]) < .02, rel
        if shot and gun not in ("spear", "hive"):
            assert row["seconds"] <= 1.2, rel
        if event == "rack" and gun in p.MODEL_RACK_LIMIT:
            assert row["seconds"] <= p.MODEL_RACK_LIMIT[gun], rel
        rows.append(row)
    return rows


def spectrogram(x, width, height, rate=48000, top_hz=16000):
    n, hop = 1024, max(32, len(x) // width)
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


def waves(sfx):
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 17)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 14)
    files = [f for f in new_files(sfx) if f.name.endswith("_0.wav")]
    cols, cw, ch = 3, 600, 250
    image = Image.new("RGB", (cols * cw, ((len(files) + cols - 1) // cols) * ch), "#f7f9fc")
    draw = ImageDraw.Draw(image)
    for i, path in enumerate(files):
        x, rate = p.read_pcm(path)
        left, top = (i % cols) * cw, (i // cols) * ch
        mono = x.mean(axis=1)
        draw.text((left + 10, top + 4), path.relative_to(sfx / "weapons").as_posix(), fill="#182b3d", font=font)
        draw.text((left + 10, top + 25), f"{len(x)/rate:.3f} s   peak {db(np.abs(x).max()):.1f} dBFS", fill="#485c6c", font=small)
        a = mono / max(abs(mono).max(), 1e-9)
        w = cw - 40
        for j, block in enumerate(np.array_split(a, w)):
            draw.line((left + 20 + j, top + 84 - block.max() * 40, left + 20 + j, top + 84 - block.min() * 40), fill="#156b9b")
        image.paste(spectrogram(mono, w, 80), (left + 20, top + 132))
        for frac in (0, .25, .5, .75, 1):
            xx = left + 20 + frac * w
            draw.text((xx - 14 if frac < 1 else xx - 36, top + 216), f"{frac*len(x)/rate:.2f}", fill="#485c6c", font=small)
    image.save(REPORT / "a3_waveforms.png")
    # Крупно: составные движения, оба варианта.
    pick = [f for f in new_files(sfx) if (f.parent.name, f.name.rsplit("_", 1)[0]) in
            (("winchester", "rack"), ("shkval", "rack"), ("cowboy", "eject"), ("cowboy", "load"),
             ("cowboy", "hammer"), ("osa", "rack"), ("m4", "mag_out"))]
    im = Image.new("RGB", (1600, len(pick) * 215), "white")
    d = ImageDraw.Draw(im)
    for i, path in enumerate(pick):
        x, rate = p.read_pcm(path)
        y = i * 215
        d.text((20, y + 6), f"{path.relative_to(sfx / 'weapons').as_posix()}   {len(x)/rate:.3f} s", fill="black", font=font)
        a = x[:, 0] / max(abs(x).max(), 1e-9)
        for j, block in enumerate(np.array_split(a, 1500)):
            d.line((40 + j, y + 100 - block.max() * 62, 40 + j, y + 100 - block.min() * 62), fill="#156b9b")
        for frac in np.linspace(0, 1, 11):
            d.text((40 + 1500 * frac - 14, y + 180), f"{frac*len(x)/rate:.3f}", fill="black", font=small)
    im.save(REPORT / "a3_detail.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sfx", type=Path, default=ROOT / "sfx")
    parser.add_argument("--plots-only", action="store_true")
    parser.add_argument("--repeat", type=Path)
    args = parser.parse_args()
    sfx = args.sfx
    rows = metrics(sfx)
    print(f"FORMAT/LEVELS: PASS; {len(rows)} new WAV; PCM16/48 kHz; shots stereo, rest mono; "
          f"peak {min(r['peak_dbfs'] for r in rows)}..{max(r['peak_dbfs'] for r in rows)} dBFS; clipped=0; "
          "endpoints=0; DC<2e-6; tail<-60 dBFS; shot RMS100 and mech RMSmax100 match table")
    if not args.plots_only:
        with (REPORT / "a3_metrics.csv").open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]))
            writer.writeheader(); writer.writerows(rows)
        # Старые файлы: хэши из main (git), без новых каталогов и без CREDITS/manifest.
        listing = subprocess.run(["git", "ls-tree", "-r", "--name-only", "main", "sfx"], cwd=ROOT,
                                 capture_output=True, text=True, check=True).stdout.split()
        changed = []
        for name in listing:
            blob = subprocess.run(["git", "show", f"main:{name}"], cwd=ROOT, capture_output=True, check=True).stdout
            if name in ("sfx/CREDITS.md", "sfx/manifest.json"):
                continue
            if hashlib.sha256(blob).digest() != hashlib.sha256((ROOT / name).read_bytes()).digest():
                changed.append(name)
        print(f"MAIN HASHES: {'PASS' if not changed else 'FAIL ' + str(changed)}; "
              f"{len(listing) - 2} files of main (WAV + .import) byte-identical; only CREDITS.md and manifest.json extended")
        if args.repeat:
            names = [e["file"] for e in json.loads((sfx / "manifest.json").read_text(encoding="utf-8"))["files"]]
            bad = [n for n in names if sha(sfx / n) != sha(args.repeat / n)]
            for extra in ("manifest.json", "CREDITS.md"):
                if sha(sfx / extra) != sha(args.repeat / extra):
                    bad.append(extra)
            print(f"DETERMINISM: {'PASS' if not bad else 'FAIL ' + str(bad)}; {len(names)} WAV + manifest.json + CREDITS.md "
                  "equal to a second build (--out)")
    waves(sfx)
    print("VISUALS: a3_waveforms.png (33 new _0, waveform + spectrogram), a3_detail.png (compound moves)")


if __name__ == "__main__":
    main()
