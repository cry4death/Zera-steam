"""A2 build and QA. Run from worktree root with PYTHONDONTWRITEBYTECODE=1.

--build generates only mechanics and appends credits, preserving A1 manifest.
The full prep_sfx.py CLI still builds A1+A2 into a fresh output directory.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools"))
import prep_sfx as p


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(x):
    return float(20 * np.log10(max(float(x), 1e-12)))


def max_rms(x):
    power = np.pad(x[:, 0] ** 2, (0, max(0, 4800 - len(x))))
    e = np.concatenate(([0.], np.cumsum(power)))
    return np.sqrt(np.max(e[4800:] - e[:-4800]) / 4800)


def build():
    b = p.Builder(p.DEFAULT_SRC, ROOT / "sfx")
    p.mechanics(b)
    (REPORT / "a2_manifest.json").write_text(json.dumps(
        {"sources": b.source_info, "files": b.entries}, indent=2) + "\n", encoding="utf-8")
    credits = ROOT / "sfx/CREDITS.md"
    prefix = credits.read_text(encoding="utf-8").split("\n## A2 Raw mechanics")[0]
    lines = [prefix.rstrip(), "", "## A2 Raw mechanics", "",
             "The A1 table above uses Prepared recordings. A2 uses Raw Master Tracks from the same CC0 library and authors.",
             "A2 edits and additional procedural brass contacts are dedicated to CC0 1.0.",
             "Exact source SHA256, disjoint crop segments, playback ratios and scatter seeds: `../design/tasks/reports/a2_manifest.json`.",
             "Times below are seconds in the original Raw track, before playback-rate changes.", "",
             "| Output file | Raw source | Original segments (s) | Playback ratio |",
             "|---|---|---|---|"]
    for e in b.entries:
        segments = "; ".join(f"{a:.6f}–{z:.6f}" for a, z in e["segments_s"])
        extra = f" + synthesized brass (seed {e['scatter_seed']}..{e['scatter_seed'] + 4})" if e["scatter_seed"] else ""
        lines.append(f"| `{e['file']}` | {e['source']}{extra} | {segments} | {e['pitch_ratio']:.9f} |")
    credits.write_text("\n".join(lines) + "\n", encoding="utf-8")
    configure_imports(b.entries)
    print(f"BUILD: {len(b.entries)} A2 WAVs; 24 ids x 2 variants; A1 manifest preserved")


def configure_imports(entries):
    for e in entries:
        resource = "res://sfx/" + e["file"]
        path = ROOT / "sfx" / (e["file"] + ".import")
        if path.exists():
            text = path.read_text(encoding="utf-8")
            text = text.replace("edit/loop_mode=0", "edit/loop_mode=1")
            text = text.replace("compress/mode=2", "compress/mode=0")
        else:
            imported = f'res://.godot/imported/{Path(e["file"]).name}-{hashlib.md5(resource.encode()).hexdigest()}.sample'
            text = (f'[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\npath="{imported}"\n\n'
                    f'[deps]\n\nsource_file="{resource}"\ndest_files=["{imported}"]\n\n'
                    '[params]\n\nforce/8_bit=false\nforce/mono=false\nforce/max_rate=false\n'
                    'force/max_rate_hz=44100\nedit/trim=false\nedit/normalize=false\n'
                    'edit/loop_mode=1\nedit/loop_begin=0\nedit/loop_end=-1\ncompress/mode=0\n')
        path.write_text(text, encoding="utf-8")


def verify():
    m = json.loads((REPORT / "a2_manifest.json").read_text())
    repeat = p.Builder(p.DEFAULT_SRC, ROOT / "tmp/a2_repeat")
    p.mechanics(repeat)
    assert repeat.entries == m["files"] and repeat.source_info == m["sources"]
    rows = []
    for e in m["files"]:
        path = ROOT / "sfx" / e["file"]
        assert sha(path) == sha(repeat.out / e["file"]), e["file"]
        x, rate = p.read_pcm(path)
        with wave.open(str(path)) as w:
            assert w.getsampwidth() == 2 and w.getnchannels() == 1 and rate == 48000
        gun = path.parent.name
        row = {"file": e["file"], "seconds": round(len(x) / rate, 6),
               "peak_dbfs": round(db(np.abs(x).max()), 3),
               "rmsmax100_dbfs": round(db(max_rms(x)), 3),
               "shot_delta_db": round(db(max_rms(x)) - p.SHOT_LEVELS[gun], 3),
               "dc": float(abs(x.mean())), "endpoints": float(np.abs(x[[0, -1]]).max()),
               "tail1ms_dbfs": round(db(np.sqrt(np.mean(x[-48:] ** 2))), 3),
               "clipped": int(np.sum(np.abs(x) >= 32767 / 32768)), "sha256": sha(path)}
        assert row["peak_dbfs"] <= -1 and row["clipped"] == 0
        assert row["dc"] < 2e-6 and row["endpoints"] == 0
        assert row["tail1ms_dbfs"] < -60
        assert abs(row["shot_delta_db"] + 12) < .02
        if path.name.startswith("rack_") and gun in ("sniper", "shotgun"):
            assert row["seconds"] <= (.6 if gun == "sniper" else .5)
        rows.append(row)
    with (REPORT / "a2_metrics.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    before = json.loads((REPORT / "a2_a1_before.json").read_text())
    changed = [name for name, digest in before.items()
               if sha(ROOT / name) != digest and name != "sfx/CREDITS.md"]
    assert not changed, changed
    print(f"A1 HASHES: PASS; {len(before)-1} protected files unchanged; only permitted CREDITS.md extended")
    print(f"DETERMINISM: PASS; {len(rows)} WAV hashes and all provenance match second build")
    print("FORMAT: PASS; PCM16 / 48000 Hz / mono; endpoints zero; DC < 2e-6; final 1 ms < -60 dBFS")
    print(f"LEVELS: peak {min(r['peak_dbfs'] for r in rows):.3f}..{max(r['peak_dbfs'] for r in rows):.3f} dBFS; loudest RMS100 minus shot RMS100: {min(r['shot_delta_db'] for r in rows):.3f}..{max(r['shot_delta_db'] for r in rows):.3f} dB; clipped=0")
    for gun in ("sniper", "shotgun"):
        times = [r["seconds"] for r in rows if f"/{gun}/rack_" in r["file"]]
        print(f"RACK {gun}: {times} s")
    print(f"SIZE: A2 WAVs {sum((ROOT/'sfx'/r['file']).stat().st_size for r in rows)} bytes; sfx total {sum(f.stat().st_size for f in (ROOT/'sfx').rglob('*') if f.is_file())} bytes")
    waves(m)


def waves(m):
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 19)
    small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
    entries = [e for e in m["files"] if e["file"].endswith("_0.wav")]
    image = Image.new("RGB", (1800, 8 * 235), "#f7f9fc")
    draw = ImageDraw.Draw(image)
    for i, e in enumerate(entries):
        x, rate = p.read_pcm(ROOT / "sfx" / e["file"])
        left, top = (i % 3) * 600, (i // 3) * 235
        draw.text((left + 12, top + 6), e["file"].replace("weapons/", ""), fill="#182b3d", font=font)
        draw.text((left + 12, top + 32), f'{e["source"].split("/")[-1]}  {len(x)/rate:.3f}s; normalized y', fill="#485c6c", font=small)
        a = x[:, 0] / abs(x).max()
        for j, block in enumerate(np.array_split(a, 560)):
            draw.line((left + 20 + j, top + 133 - block.max() * 65,
                       left + 20 + j, top + 133 - block.min() * 65), fill="#156b9b")
        for frac in (0, .25, .5, .75, 1):
            xx = left + 20 + frac * 560
            draw.text((xx - 10, top + 205), f'{frac*len(x)/rate:.2f}', fill="#485c6c", font=small)
    image.save(REPORT / "a2_waveforms.png")
    # Larger views of both variants of the three compound mechanics.
    selected = [e for e in m["files"] if any(f"/{g}/{event}_" in e["file"]
                for g, event in (("sniper", "rack"), ("shotgun", "rack"), ("revolver", "eject")))]
    im = Image.new("RGB", (1600, len(selected) * 250), "white")
    d = ImageDraw.Draw(im)
    for i, e in enumerate(selected):
        x, rate = p.read_pcm(ROOT / "sfx" / e["file"])
        y = i * 250
        d.text((20, y + 8), f'{e["file"]}    {len(x)/rate:.6f}s; playback x{e["pitch_ratio"]:.6f}', fill="black", font=font)
        for j, block in enumerate(np.array_split(x[:, 0] / abs(x).max(), 1500)):
            d.line((40+j, y+135-block.max()*75, 40+j, y+135-block.min()*75), fill="#156b9b")
        for frac in np.linspace(0, 1, 11):
            d.text((40+1500*frac-10, y+220), f'{frac*len(x)/rate:.3f}', fill="black", font=small)
    im.save(REPORT / "a2_detail.png")
    print("VISUALS: a2_waveforms.png (all 24 _0); a2_detail.png (both Mosin/pump/eject variants)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true")
    args = parser.parse_args()
    if args.build:
        build()
    verify()
