"""Reproducible A1 numeric/visual QA (numpy + Pillow, no scipy/matplotlib).

Run after prep_sfx.py --out tmp/repeat. Burst WAVs are temporary; PNG/JSON/CSV
and this script remain as review evidence. Does not modify generated assets.
"""
import csv
import hashlib
import json
from pathlib import Path
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import prep_sfx as prep

REPORT = Path(__file__).resolve().parent
FONT_PATH = Path("C:/Windows/Fonts/consola.ttf")
FONT = ImageFont.truetype(str(FONT_PATH), 16)
SMALL = ImageFont.truetype(str(FONT_PATH), 13)


def db(value):
    return float(20 * np.log10(max(float(value), 1e-12)))


def spectrum(audio):
    # Mean channel powers: stereo phase cancellation cannot hide energy.
    padded = np.pad(audio, ((512, 512), (0, 0)))
    frames = np.lib.stride_tricks.sliding_window_view(padded, 1024, axis=0)[::128]
    fft = np.fft.rfft(frames * np.hanning(1024), axis=-1)
    return np.mean(np.abs(fft) ** 2, axis=1).T


def metrics(path):
    x, rate = prep.read_pcm(path)
    assert rate == 48000
    with wave.open(str(path)) as stream:
        assert stream.getsampwidth() == 2
    power = spectrum(x).sum(axis=1)
    frequencies = np.fft.rfftfreq(1024, 1 / rate)
    full = x * 32768
    row = {"file": path.relative_to(ROOT / "sfx").as_posix(), "duration_s": round(len(x) / rate, 6),
           "channels": x.shape[1], "peak_dbfs": round(db(np.abs(x).max()), 3),
           "rms100_dbfs": round(db(np.sqrt(np.mean(x[:4800] ** 2))), 3),
           "centroid_hz": round(float(np.sum(frequencies * power) / power.sum()), 1),
           "clipped_samples": int(np.sum(np.abs(full) >= 32767)),
           "dc_max": float(np.max(np.abs(x.mean(axis=0)))),
           "endpoints_max": float(np.max(np.abs(x[[0, -1]]))),
           "tail1ms_dbfs": round(db(np.sqrt(np.mean(x[-48:] ** 2))), 2)}
    assert row["peak_dbfs"] <= -1
    assert row["clipped_samples"] == 0
    assert row["dc_max"] < 2e-6
    assert row["endpoints_max"] == 0
    assert row["tail1ms_dbfs"] < -60
    assert x.shape[1] == (2 if row["file"].startswith("weapons/") else 1)
    if row["file"].startswith("weapons/"):
        gun = path.parent.name
        assert len(x) / rate <= (2.5 if gun in ("sniper", "shotgun", "revolver") else 1.2)
    return row


def waveform(draw, x, box, label):
    left, top, right, bottom = box
    w, h = right - left, bottom - top
    draw.rectangle(box, fill="#f5f8fc", outline="#9cabbc")
    draw.line((left, (top + bottom) // 2, right, (top + bottom) // 2), fill="#abb5c1")
    for channel, color in enumerate(["#1773ae", "#e48523"][:x.shape[1]]):
        for i in range(w):
            lo = int(i * len(x) / w)
            hi = max(lo + 1, int((i + 1) * len(x) / w))
            values = x[lo:hi, channel]
            draw.line((left + i, top + h / 2 - float(values.max()) * h * .47,
                       left + i, top + h / 2 - float(values.min()) * h * .47), fill=color)
    draw.text((left, bottom + 3), label, font=SMALL, fill="#26364a")


def heatmap(x, size):
    power = spectrum(x)
    level = 10 * np.log10(np.maximum(power, 1e-15) / max(power.max(), 1e-15))
    v = np.clip((level + 80) / 80, 0, 1)[::-1]
    anchors = np.array([[7, 7, 27], [47, 16, 83], [114, 31, 107], [185, 55, 84], [238, 112, 49], [252, 193, 74], [252, 255, 164]])
    pos = v * (len(anchors) - 1)
    lower = np.minimum(pos.astype(int), len(anchors) - 2)
    frac = pos - lower
    rgb = anchors[lower] * (1 - frac[..., None]) + anchors[lower + 1] * frac[..., None]
    return Image.fromarray(rgb.astype(np.uint8)).resize(size)


def make_sheet(paths, target):
    width, row_h = 1840, 238
    im = Image.new("RGB", (width, 85 + row_h * len(paths)), "white")
    draw = ImageDraw.Draw(im)
    draw.text((20, 12), "A1 | PCM16 48 kHz | L blue / R orange | waveform scale +/-1 FS", font=FONT, fill="black")
    draw.text((20, 38), "STFT: Hann 1024 / hop 128; channel-mean power; each image 0 ... -80 dB relative to its maximum", font=SMALL, fill="black")
    for row, path in enumerate(paths):
        x, _ = prep.read_pcm(path)
        top = 85 + row * row_h
        draw.text((20, top), path.relative_to(ROOT).as_posix(), font=FONT, fill="black")
        waveform(draw, x[:960], (25, top + 31, 435, top + 181), "0              onset 0-20 ms             20")
        waveform(draw, x, (470, top + 31, 1090, top + 181), f"0               full waveform          {len(x)/48000:.3f} s")
        im.paste(heatmap(x, (650, 150)), (1150, top + 31))
        draw.text((1107, top + 30), "24k", font=SMALL, fill="black")
        draw.text((1107, top + 100), "12k", font=SMALL, fill="black")
        draw.text((1130, top + 166), "0", font=SMALL, fill="black")
        draw.text((1150, top + 184), f"0                 spectrogram          {len(x)/48000:.3f} s", font=SMALL, fill="black")
        draw.line((15, top + 225, width - 15, top + 225), fill="#d7dee7")
    im.save(target)


def main():
    files = sorted((ROOT / "sfx").rglob("*.wav"))
    rows = [metrics(path) for path in files]
    assert len(files) == 59
    for gun, count in {"pistol": 4, "revolver": 4, "smg": 5, "rifle": 4, "sniper": 4, "shotgun": 4, "launcher": 3, "rail": 3}.items():
        assert sorted(p.name for p in (ROOT / "sfx/weapons" / gun).glob("*.wav")) == [f"shot_{i}.wav" for i in range(count)]
    for kind in ("brass_small", "brass_rifle", "shell", "mag_drop"):
        assert len(list((ROOT / "sfx/casings").glob(kind + "_*.wav"))) == 6
    for row in rows:
        file = row["file"]
        if file.startswith("weapons/") and file.split("/")[1] in prep.SHOT_LEVELS:
            assert abs(row["rms100_dbfs"] - prep.SHOT_LEVELS[file.split("/")[1]]) < .01
            x, _ = prep.read_pcm(ROOT / "sfx" / file)
            envelope = np.max(np.abs(x), axis=1)
            onset_ms = np.flatnonzero(envelope > .18 * envelope.max())[0] / 48
            assert .5 <= onset_ms <= 2.0, (file, onset_ms)
    for path in files:
        settings = Path(str(path) + ".import").read_text(encoding="utf-8")
        assert "edit/loop_mode=1" in settings
        assert "edit/trim=false" in settings and "edit/normalize=false" in settings
        assert "force/max_rate=false" in settings and "force/mono=false" in settings
        assert f"compress/mode={0 if path.parent.name == 'casings' else 2}" in settings
    print("file,duration_s,channels,peak_dbfs,rms100_dbfs,centroid_hz,clipped_samples,dc_max,endpoints_max,tail1ms_dbfs")
    with (REPORT / "a1_metrics.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    for row in rows:
        print(",".join(str(value) for value in row.values()))
    print(f"ASSET CHECK: PASS; {len(rows)} WAV; PCM16/48000; channel counts, names, durations, levels, zero endpoints, DC and tails")

    entries = json.loads((ROOT / "sfx/manifest.json").read_text(encoding="utf-8"))["files"]
    generated = [e["file"] for e in entries] + ["CREDITS.md", "manifest.json"]
    for name in generated:
        a = (ROOT / "sfx" / name).read_bytes()
        b = (ROOT / "tmp/repeat" / name).read_bytes()
        assert a == b, name
    print(f"DETERMINISM: PASS; {len(generated)} generated files byte-identical to tmp/repeat")
    print("IMPORT SIDECARS: PASS; 35 QOA shots/explosions, 24 PCM casings; explicit loop=Disabled; no trim/normalize/downsample")
    manifest = json.loads((ROOT / "sfx/manifest.json").read_text(encoding="utf-8"))
    for name, info in manifest["source_files"].items():
        assert hashlib.sha256((prep.DEFAULT_SRC / name).read_bytes()).hexdigest() == info["sha256"]
    print("SOURCE HASHES: PASS; six originals match recorded SHA256")
    # Verify the actual FIR/downsampling path against passband and aliased tones.
    t = np.arange(96000) / 96000
    rms = []
    for frequency in (10000, 30000):
        tone = np.sin(2 * np.pi * frequency * t)[:, None]
        result = prep.resample_48k(tone, 96000)[1000:-1000]
        rms.append(np.sqrt(np.mean(result ** 2)))
    rejection = db(rms[1] / rms[0])
    assert rejection < -80
    print(f"FIR: PASS; 30 kHz alias vs 10 kHz passband={rejection:.2f} dB")

    bursts = []
    burst_paths = []
    for gun in ("smg", "rifle"):
        variants = [prep.read_pcm(path)[0] for path in files if path.parent.name == gun]
        for hz in (10, 15):
            mix = np.zeros((48000, 2))
            for i in range(hz):
                start = round(i * 48000 / hz)
                clip = variants[i % len(variants)]
                n = min(len(clip), len(mix) - start)
                mix[start:start + n] += clip[:n]
            # No limiter or gain reduction; a fade only at the end of the test.
            mix[-480:] *= np.linspace(1, 0, 480)[:, None]
            peak = db(np.abs(mix).max())
            assert peak < -1
            cycle_rms = [db(np.sqrt(np.mean(mix[round(i*48000/hz):round((i+1)*48000/hz)] ** 2))) for i in range(2, hz - 1)]
            spread = max(cycle_rms) - min(cycle_rms)
            assert spread < 2.5
            path = ROOT / f"tmp/{gun}_{hz}hz.wav"
            prep.write_pcm(path, mix)
            bursts.append({"gun": gun, "hz": hz, "peak_dbfs": round(peak, 3), "cycle_rms_spread_db": round(spread, 3), "clipped_samples": 0})
            burst_paths.append(path)
            print(f"BURST: {gun} {hz} Hz; duration=1.000 s; peak={peak:.3f} dBFS; clipped=0; cycle_RMS_spread={spread:.3f} dB; gain=1.0")
    (REPORT / "a1_bursts.json").write_text(json.dumps(bursts, indent=2) + "\n", encoding="utf-8")
    representatives = sorted((ROOT / "sfx/weapons").glob("*/shot_0.wav"))
    representatives += [ROOT / f"sfx/casings/{kind}_0.wav" for kind in ("brass_small", "brass_rifle", "shell", "mag_drop")]
    representatives += [ROOT / "sfx/explosions/grenade_0.wav"]
    make_sheet(representatives, REPORT / "a1_waveforms.png")
    make_sheet(burst_paths, REPORT / "a1_burst_waveforms.png")
    # Full-resolution detail pages make the required image easy to inspect.
    with Image.open(REPORT / "a1_waveforms.png") as sheet:
        for page, start in enumerate(range(0, len(representatives), 4)):
            sheet.crop((0, 85 + start * 238, 1840, min(sheet.height, 85 + (start + 4) * 238))).save(REPORT / f"a1_detail_{page}.png")
    size = sum(path.stat().st_size for path in (ROOT / "sfx").rglob("*") if path.is_file())
    assert size <= 25000000
    print(f"SIZE: {size} bytes in sfx/ including import sidecars; limit=25000000; PASS")
    print("VISUALS: a1_waveforms.png (13 rows), a1_detail_0..3.png, a1_burst_waveforms.png")


if __name__ == "__main__":
    main()
