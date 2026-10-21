"""R1c: куски кишок, органы, лоскуты мяса и кости в крови. Детерминированно, стиль gen_art.py.

python -I tools/gen_art_r1c.py
Пишет только новые файлы в art/ (старые gib_* не трогает):
  gib_gut_0..5      петли кишечника разной длины (ключевые: 0-1 длинные, 2-3 средние, 4-5 обрывки)
  gib_organ_heart_0/1, gib_organ_liver_0/1, gib_organ_lung_0/1, gib_organ_stomach_0/1
  gib_scrap_0..3    лоскуты мяса и кожи
  bbone_<вид>_<0..3> кости в крови: 0, 1 — свежая кровь, 2, 3 — подсохшая (вид: rib, spine, long, arm, skull)
"""
import math
import os
import random
import struct
import sys
import zlib

# -I убирает каталог скрипта из sys.path. Общие примитивы — рядом с этим файлом.
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gen_art as ga
from gen_art import Canvas, ramp, hexc, pick, darker, mix, hnoise, BONE, FLESH, MUSCLE, FAT, VEIN, TEETH

# Бордовая палитра R1c: тонкий слой ≈ #6E0A0E, толстый ≈ #2A0306.
WET = ramp(hexc("5e0a10"), spread=1.0)
CLOT = ramp(hexc("2e0508"), spread=0.8)
CRUST = ramp(hexc("3a1a10"), spread=0.7)
GUT_A = ramp(hexc("a5545e"))
GUT_B = ramp(hexc("8c4650"))
LIVER = ramp(hexc("62201e"), spread=0.9)
HEART = ramp(hexc("8e2430"), spread=0.9)
LUNG = ramp(hexc("b86f78"))
STOMACH = ramp(hexc("c28c88"), spread=0.7)
SKIN = ramp(hexc("7d8a6b"), spread=0.7)
PALE = ramp(hexc("c9b9a0"), spread=0.6)
FATY = ramp(hexc("d9c27e"), spread=0.5)
SOCKET = ramp(hexc("1e0e0e"), spread=0.4)


def _blood_on(cv, rng, count, rmp, rmin=0.8, rmax=1.9):
    """Пятна поверх уже нарисованного: только на непрозрачных пикселях."""
    w, h = cv.w / cv.s, cv.h / cv.s
    for _ in range(count):
        cv.stain(rng, rng.uniform(1, w - 1), rng.uniform(1, h - 1), rng.uniform(rmin, rmax), rmp)


def _wet(cv, rng, pts, n):
    """Влажные блики: светлые родные пиксели вдоль пути."""
    for _ in range(n):
        x, y = rng.choice(pts)
        cv.dot(x + rng.uniform(-0.4, 0.4), y - 0.6, (238, 206, 206))


def _path(rng, w, h, n, wave, phase):
    pts = []
    for i in range(n):
        t = i / (n - 1)
        x = 1.6 + t * (w - 3.2)
        y = h / 2 + math.sin(t * math.pi * wave + phase) * (h / 2 - 2.2) * (0.5 + 0.5 * math.sin(t * 3.0 + phase))
        pts.append((x, y + rng.uniform(-0.3, 0.3)))
    return pts


def gut_loop(k):
    """Петля кишечника: хвост разной длины, перетяжки, кровь на разрывах и по длине."""
    rng = random.Random(9100 + k)
    length = (30, 26, 19, 16, 11, 8)[k]
    h = (12, 11, 9, 9, 7, 6)[k]
    cv = Canvas(length, h)
    pts = _path(rng, length, h, max(5, int(length / 2.2)), 1.3 + 0.5 * (k % 2), k * 1.7)
    rmp = GUT_A if k % 2 == 0 else GUT_B
    width = 2.4 + (k % 3) * 0.3
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        cv.tube(x0, y0, x1, y1, width, rmp, tex=0.28, seed=k)
    # перетяжки: тёмные поперечные штрихи
    for i in range(1, len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i - 1], pts[i + 1]
        dx, dy = y1 - y0, -(x1 - x0)
        ln = math.hypot(dx, dy) or 1.0
        px, py = pts[i]
        for j in (-1, 0, 1):
            cv.dot(px + dx / ln * j * 0.75, py + dy / ln * j * 0.75, darker(rmp[1], 0.78))
    _wet(cv, rng, pts, 4 + int(length / 5))
    _blood_on(cv, rng, 2 + int(length / 8), WET, 0.8, 1.6)
    # разорванный конец: тёмная кровь и жир
    cv.dot(pts[0][0], pts[0][1], CLOT[2])
    cv.dot(pts[0][0] + 0.7, pts[0][1] + 0.3, WET[2])
    cv.dot(pts[-1][0], pts[-1][1], CLOT[3])
    if k < 4:
        for _ in range(3):
            x, y = rng.choice(pts)
            cv.dot(x + rng.uniform(-0.6, 0.6), y + rng.uniform(0.4, 1.0), FATY[3])
    cv.outline(0.4)
    return cv


def organ_heart(k):
    rng = random.Random(9200 + k)
    cv = Canvas(10, 10)
    cx, cy = 5.0, 5.8
    cv.ellipse(cx - 0.6, cy, 3.2, 3.5, HEART, tex=0.3, seed=k)
    cv.ellipse(cx + 1.2, cy + 0.5, 2.5, 3.0, HEART, bias=-0.1, tex=0.3, seed=k + 2)
    # сосуды сверху
    cv.tube(3.6, 3.0, 3.0, 0.8, 1.3, ramp(hexc("7a4a5c")), tex=0.2)
    cv.tube(5.2, 2.8, 5.8, 0.6, 1.1, ramp(hexc("9a3040")), tex=0.2)
    cv.tube(6.3, 3.4, 7.6, 1.8, 0.9, ramp(hexc("7a4a5c")), tex=0.2)
    for _ in range(4):  # жировые прожилки
        cv.dot(cx + rng.uniform(-2.5, 2.5), cy - 1.8 + rng.uniform(0, 1.2), FATY[3])
    cv.walk(rng, cx - 1.5, cy - 1.0, 1.0, 5, darker(HEART[1], 0.7), 0.5)
    _blood_on(cv, rng, 2, WET, 0.9, 1.7)
    _wet(cv, rng, [(cx - 1, cy - 1), (cx + 1.5, cy)], 3)
    cv.outline(0.4)
    return cv


def organ_liver(k):
    rng = random.Random(9300 + k)
    cv = Canvas(13, 9)
    cv.ellipse(5.5, 4.8, 5.0, 3.4, LIVER, tex=0.26, seed=k)
    cv.ellipse(9.4, 5.6, 3.0, 2.6, LIVER, bias=-0.08, tex=0.26, seed=k + 3)
    cv.ellipse(3.0, 3.8, 2.4, 2.2, LIVER, bias=0.1, tex=0.26, seed=k + 5)
    # жёлчный пузырь
    cv.ellipse(8.6, 7.4, 0.9, 0.8, ramp(hexc("486a34")), bias=0.1)
    cv.line(4.0, 2.0, 7.0, 3.4, darker(LIVER[1], 0.75))
    _wet(cv, rng, [(4.5, 3.4), (8.0, 4.4), (6.0, 5.2)], 4)
    _blood_on(cv, rng, 3, CLOT, 1.0, 1.9)
    cv.outline(0.4)
    return cv


def organ_lung(k):
    rng = random.Random(9400 + k)
    cv = Canvas(11, 11)
    cv.ellipse(3.6, 6.2, 2.7, 4.0, LUNG, tex=0.3, seed=k)
    cv.ellipse(7.4, 6.2, 2.7, 3.8, LUNG, bias=-0.08, tex=0.3, seed=k + 2)
    # трахея с кольцами
    cv.tube(5.5, 0.6, 5.5, 4.4, 1.4, ramp(hexc("cfc4b4"), spread=0.5), tex=0.1)
    for y in (1.4, 2.4, 3.4):
        cv.line(4.8, y, 6.2, y, (150, 138, 128))
    for _ in range(5):  # бронхиальные прожилки
        cv.walk(rng, 3.6 + rng.choice((0, 3.8)), 4.0 + rng.uniform(0, 3), rng.uniform(0.5, 2.5), 5, darker(LUNG[1], 0.8), 0.5)
    _blood_on(cv, rng, 3, WET, 0.9, 1.7)
    _wet(cv, rng, [(3.0, 5.0), (8.0, 5.0)], 3)
    cv.outline(0.4)
    return cv


def organ_stomach(k):
    rng = random.Random(9500 + k)
    cv = Canvas(12, 9)
    cv.ellipse(6.0, 4.8, 4.6, 3.3, STOMACH, tex=0.22, seed=k)
    cv.ellipse(9.4, 4.0, 2.2, 1.9, STOMACH, bias=0.05, tex=0.22, seed=k + 2)
    cv.tube(1.2, 3.2, 2.4, 4.2, 1.5, GUT_A, tex=0.25)  # пищевод
    cv.tube(10.6, 4.0, 12.0, 4.6, 1.4, GUT_B, tex=0.25)  # переход в кишку
    for _ in range(5):
        cv.walk(rng, 4.0 + rng.uniform(0, 4), 3.2 + rng.uniform(0, 2.4), rng.uniform(0, 6.0), 4, darker(STOMACH[1], 0.8), 0.7)
    _blood_on(cv, rng, 3, WET, 1.0, 2.0)
    _wet(cv, rng, [(5.0, 3.2), (7.4, 4.4)], 3)
    cv.outline(0.4)
    return cv


def scrap(k):
    """Лоскут мяса: плоский, с кожей по краю, бахромой и сгустком."""
    rng = random.Random(9600 + k)
    s = (9, 7, 10, 8)[k]
    cv = Canvas(s, s - 1)
    for _ in range(4):
        cv.ellipse(s / 2 + rng.uniform(-1.6, 1.6), (s - 1) / 2 + rng.uniform(-1.0, 1.0), rng.uniform(s * 0.2, s * 0.34),
                   rng.uniform(s * 0.14, s * 0.26), FLESH if k % 2 else MUSCLE, tex=0.4, seed=k)
    if k in (0, 2):  # кожа с одной стороны
        for x in range(int(cv.w)):
            for y in range(int(cv.h)):
                c = cv.getn(x, y)
                if c is not None and (x < 3 or y < 2) and rng.random() < 0.55:
                    cv.putn(x, y, pick(SKIN, 0.0 + hnoise(x, y, k) * 0.4))
    for _ in range(3):
        cv.dot(s / 2 + rng.uniform(-2, 2), (s - 1) / 2 + rng.uniform(-1.5, 1.5), FATY[3])
    cv.walk(rng, s / 2, (s - 1) / 2, rng.uniform(0, 6), 5, ga.VEIN, 0.8)
    for _ in range(3):  # бахрома
        a = rng.uniform(0, math.tau)
        cv.walk(rng, s / 2 + math.cos(a) * s * 0.3, (s - 1) / 2 + math.sin(a) * s * 0.25, a, 4, MUSCLE[1], 0.5, on_body=False)
    _blood_on(cv, rng, 2, WET, 0.8, 1.6)
    cv.outline(0.4)
    return cv


# --- кости в крови ---------------------------------------------------------------------

def _soak(cv, rng, fresh, cover, ends):
    """Кровь на кости: пятна по длине, мясо на концах. fresh — мокрая бордовая, иначе подсохшая бурая."""
    rmp = WET if fresh else CRUST
    deep = CLOT if fresh else ramp(hexc("2a1610"), spread=0.7)
    w, h = cv.w, cv.h
    for ny in range(h):
        for nx in range(w):
            c = cv.getn(nx, ny)
            if c is None or c[3] < 128:
                continue
            near_end = min((abs(nx - ex) for ex in ends), default=99) / max(1.0, w / 2.0)
            p = cover * 0.5 + max(0.0, 0.75 - near_end * 1.9)
            n = hnoise(nx, ny, 77) * 0.5 + 0.5
            if n < p:
                # внутри пятна — тёмнее, у кромки — светлее
                depth = (p - n) / max(p, 0.01)
                col = pick(deep, -0.2) if depth > 0.7 else pick(rmp, 0.1 - depth * 0.7 + hnoise(nx, ny, 5) * 0.25)
                cv.putn(nx, ny, col)
    if fresh:
        for _ in range(3):  # влажный блик
            x, y = rng.randint(1, w - 2), rng.randint(1, h - 2)
            c = cv.getn(x, y)
            if c is not None and c[0] > c[1] * 2:
                cv.putn(x, y, (216, 120, 120))


def _meat_cap(cv, x, y, r, fresh):
    cv.ellipse(x, y, r, r * 0.85, MUSCLE if fresh else ramp(hexc("5a2a2a")), bias=-0.1, tex=0.3)
    cv.dot(x, y, WET[3] if fresh else CRUST[3])


def _long_bone(variant, fresh):
    rng = random.Random(9700 + variant * 10 + int(fresh))
    ln = (13, 11)[variant % 2]
    cv = Canvas(ln, 7)
    ang = (0.0, 0.12)[variant % 2]
    x0, y0, x1, y1 = 2.5, 3.5, ln - 2.5, 3.5 + math.sin(ang) * ln * 0.5
    cv.tube(x0, y0, x1, y1, 1.6, BONE)
    for x, y in ((x0 - 0.4, y0), (x1 + 0.4, y1)):
        cv.ellipse(x, y - 0.8, 1.3, 1.1, BONE)
        cv.ellipse(x, y + 0.9, 1.3, 1.1, BONE)
    if variant % 2 == 1:  # слом: скос и щепа
        cv.dot(x1 - 1.0, y1 - 0.7, (0, 0, 0, 0))
        cv.erasen(*cv.n(x1 + 0.9, y1 - 0.3))
    _meat_cap(cv, x0 - 0.2, y0, 1.4, fresh)
    _soak(cv, rng, fresh, 0.34 if fresh else 0.4, (cv.n(x0, 0)[0], cv.n(x1, 0)[0]))
    cv.outline(0.38)
    return cv


def _arm_bone(variant, fresh):
    """Две кости предплечья рядом и клочья мяса на месте локтя."""
    rng = random.Random(9800 + variant * 10 + int(fresh))
    cv = Canvas(15, 7)
    cv.tube(2.5, 2.6, 12.0, 2.6 + variant * 0.5, 1.2, BONE)
    cv.tube(2.5, 4.4, 12.5, 4.4 - variant * 0.4, 1.4, BONE)
    for x, y in ((2.0, 2.6), (2.0, 4.4), (12.8, 3.0)):
        cv.ellipse(x, y, 1.0, 1.0, BONE)
    _meat_cap(cv, 1.6, 3.5, 1.8, fresh)
    cv.tube(11.5, 3.4, 14.0, 3.5, 1.5, MUSCLE if fresh else ramp(hexc("5a2a2a")), tex=0.3)
    _soak(cv, rng, fresh, 0.34 if fresh else 0.42, (cv.n(1.5, 0)[0], cv.n(13.5, 0)[0]))
    cv.outline(0.38)
    return cv


def _rib(variant, fresh):
    rng = random.Random(9900 + variant * 10 + int(fresh))
    cv = Canvas(15, 11)
    n = 4 if variant % 2 == 0 else 3
    for k in range(n):
        pts = [(2.6 + t, 2.2 + k * 2.2 + math.sin(t * 0.38 + variant) * 1.2) for t in range(10)]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            cv.tube(x0, y0, x1, y1, 0.9, BONE)
    cv.tube(1.8, 1.4, 1.8, 2.0 + n * 2.2, 1.7, ramp(hexc("5a2a2a")) if not fresh else MUSCLE, tex=0.3)
    _soak(cv, rng, fresh, 0.34 if fresh else 0.42, (cv.n(2.0, 0)[0], cv.n(12.0, 0)[0]))
    cv.outline(0.38)
    return cv


def _spine(variant, fresh):
    rng = random.Random(10000 + variant * 10 + int(fresh))
    cv = Canvas(19, 7)
    n = 6 if variant % 2 == 0 else 5
    for k in range(n):
        y = 3.5 + math.sin(k * 0.8 + variant) * 0.6
        cv.ellipse(2.6 + k * 2.6, y, 1.3, 1.7, BONE)
        cv.ellipse(2.6 + k * 2.6, y, 0.4, 2.4, BONE, bias=0.2)
    cv.tube(1.0, 3.5, 3.0, 3.6, 1.3, MUSCLE if fresh else ramp(hexc("5a2a2a")), tex=0.3)
    _soak(cv, rng, fresh, 0.34 if fresh else 0.42, (cv.n(1.0, 0)[0], cv.n(17.0, 0)[0]))
    cv.outline(0.38)
    return cv


def _skull(variant, fresh):
    rng = random.Random(10100 + variant * 10 + int(fresh))
    cv = Canvas(9, 9)
    cv.ellipse(4.5, 4.5, 3.3, 3.0, BONE)
    cv.ellipse(5.4, 4.5, 2.6, 2.4, BONE, bias=0.05)
    cv.ellipse(3.0, 4.2, 0.9, 0.8, SOCKET)  # глазница
    cv.ellipse(3.2, 5.8, 0.8, 0.7, SOCKET)
    cv.walk(rng, 5.0, 2.6, 1.0, 4, (140, 128, 110), 0.5)  # трещина
    if variant % 2 == 0:  # проломленный затылок: мясо и кровь
        cv.ellipse(6.4, 4.5, 1.9, 2.0, MUSCLE if fresh else ramp(hexc("5a2a2a")), bias=-0.1, tex=0.35)
    cv.dot(4.6, 3.8, TEETH)
    _soak(cv, rng, fresh, 0.4 if fresh else 0.5, (cv.n(8.0, 0)[0],))
    cv.outline(0.38)
    return cv


BBONES = {"rib": _rib, "spine": _spine, "long": _long_bone, "arm": _arm_bone, "skull": _skull}


def _png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def _save(cv, name):
    # Вскрытая ткань тёмная и мокрая; жир и кость сохраняют исходный свет.
    tissue = name.startswith(("gib_gut_", "gib_organ_", "gib_scrap_"))
    raw = bytearray()
    for row in cv.c:
        raw.append(0)  # PNG filter None, RGBA8 без изменения прозрачных пикселей.
        for pixel in row:
            r, g, b, a = pixel or (0, 0, 0, 0)
            if tissue and a and r > g * 1.12:
                r, g, b = int(r * 0.78), int(g * 0.60), int(b * 0.65)
            raw.extend((r, g, b, a))
    # Stored DEFLATE: байты не зависят от версий Pillow, GDI+ и компрессора zlib.
    # Эти небольшие спрайты помещаются в один блок (максимум 65535 байт).
    if len(raw) > 65535:
        raise ValueError("R1c sprite exceeds one DEFLATE block")
    packed = b"\x78\x01\x01" + struct.pack("<HH", len(raw), len(raw) ^ 65535) + raw
    packed += struct.pack(">I", zlib.adler32(raw))
    png = b"\x89PNG\r\n\x1a\n"
    png += _png_chunk(b"IHDR", struct.pack(">IIBBBBB", cv.w, cv.h, 8, 6, 0, 0, 0))
    png += _png_chunk(b"IDAT", packed) + _png_chunk(b"IEND", b"")
    with open(os.path.join(ga.OUT, name + ".png"), "wb") as output:
        output.write(png)


def main():
    os.makedirs(ga.OUT, exist_ok=True)
    for k in range(6):
        _save(gut_loop(k), "gib_gut_%d" % k)
    for k in range(2):
        _save(organ_heart(k), "gib_organ_heart_%d" % k)
        _save(organ_liver(k), "gib_organ_liver_%d" % k)
        _save(organ_lung(k), "gib_organ_lung_%d" % k)
        _save(organ_stomach(k), "gib_organ_stomach_%d" % k)
    for k in range(4):
        _save(scrap(k), "gib_scrap_%d" % k)
    for name, fn in BBONES.items():
        for v in range(2):
            _save(fn(v, True), "bbone_%s_%d" % (name, v))
            _save(fn(v, False), "bbone_%s_%d" % (name, v + 2))


if __name__ == "__main__":
    main()
