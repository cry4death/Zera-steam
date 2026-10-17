"""Арт M5. Запуск рядом с gen_art.py: python tools/gen_art_m5.py.

--out DIR перенаправляет ga.OUT; --preview PNG собирает лист x3 на двух фонах.
Импорт ничего не сохраняет. Зависимости: gen_art и Pillow, как в M4.
"""

import argparse
import math
import os
import random

from PIL import Image, ImageDraw

import gen_art as ga


METAL = ga.ramp(ga.hexc("525b49"), spread=0.7)
STEEL = ga.ramp(ga.hexc("859086"), spread=0.6)
STRAP = ga.ramp(ga.hexc("302c24"))
MEAT = ga.ramp(ga.hexc("ad4b49"), spread=0.75)
YELLOW = ga.ramp(ga.hexc("c5a64a"), spread=0.55)
TUBE = ga.ramp(ga.hexc("6c8c80"), spread=0.6)


def metal(cv, pts, seed):
    """Гнутая пластина: ломаный силуэт, светлая фаска слева, тёмная справа."""
    cx = sum(x for x, _ in pts) / len(pts)
    cy = sum(y for _, y in pts) / len(pts)
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / cv.s, (ny + 0.5) / cv.s
            inside = False
            dist = 999
            for (ax, ay), (bx, by) in zip(pts, pts[1:] + pts[:1]):
                if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
                    inside = not inside
                dx, dy = bx - ax, by - ay
                t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
                dist = min(dist, math.hypot(x - ax - t * dx, y - ay - t * dy))
            if inside:
                light = ((x - cx) * ga.LIGHT[0] + (y - cy) * ga.LIGHT[1]) / 12
                shade = 0.1 + light * 0.45 + ga.hnoise(nx, ny, seed) * 0.12
                if dist < 0.8:
                    shade = 0.65 if light > 0 else -0.8
                if abs(x - cx + (y - cy) * 0.25) < 0.65:
                    shade -= 0.3  # перегиб листа
                cv.putn(nx, ny, ga.pick(METAL, shade))
    for x, y in pts[::2]:
        x, y = x * 0.78 + cx * 0.22, y * 0.78 + cy * 0.22
        cv.ellipse(x, y, 0.7, 0.7, STRAP)
        cv.dot(x - 0.2, y - 0.2, STEEL[5])
    rng = random.Random(seed)
    for _ in range(5):
        x, y = cx + rng.uniform(-3, 3), cy + rng.uniform(-3, 3)
        cv.line(x, y, x + rng.uniform(1, 3), y - 0.7, STEEL[3],
                cond=lambda nx, ny: cv.getn(nx, ny) is not None)


def stencil(cv, x, y):
    # О-7, один родной пиксель на штрих; буква О одинакова в кириллице/латинице.
    for j, row in enumerate(("11100111", "10100001", "10111010", "10100010", "11100010")):
        for i, bit in enumerate(row):
            if bit == "1":
                cv.putn(round(x * cv.s) + i, round(y * cv.s) + j, ga.BONE[2])


def ribs(cv, x, y, scale=1):
    cv.ellipse(x, y, 7 * scale, 10 * scale, ga.BLOOD, bias=-0.6, tex=0.2)
    for k in range(5):
        yy = y + (k - 2) * 3.2 * scale
        cv.tube(x - 4 * scale, yy, x, yy - scale, scale, ga.BONE)
        cv.tube(x, yy - scale, x + 4.5 * scale, yy + scale, scale * 0.8, ga.BONE)
    cv.tube(x - 4.5 * scale, y - 7 * scale, x - 4.5 * scale, y + 7 * scale,
            1.5 * scale, ga.MUSCLE)


def boss_inside(pts):
    """Ломаный край поверх объёмной формы; координаты cond — логические."""
    def inside(x, y):
        hit = False
        for (ax, ay), (bx, by) in zip(pts, pts[1:] + pts[:1]):
            if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
                hit = not hit
        return hit
    return inside


def boss_surface(cv, pts, rmp, seed, bias=0):
    """Срезанный, неровный силуэт без круглых швов между мышцами."""
    x0, x1 = min(x for x, _ in pts), max(x for x, _ in pts)
    y0, y1 = min(y for _, y in pts), max(y for _, y in pts)
    inside = boss_inside(pts)
    cv.ellipse((x0 + x1) / 2, (y0 + y1) / 2,
               (x1 - x0) * 0.78, (y1 - y0) * 0.78, rmp,
               cond=inside, tex=0.25, seed=seed, bias=bias)
    return inside


def boss_armor(cv, pts, seed):
    """Только броня босса: выпуклый металл, швы, сколы и грязь."""
    inside = boss_surface(cv, pts, METAL, seed, bias=-0.12)
    rng = random.Random(seed)
    cx = sum(x for x, _ in pts) / len(pts)
    cy = sum(y for _, y in pts) / len(pts)
    # Фаски ориентированы относительно источника света проекта.
    for (ax, ay), (bx, by) in zip(pts, pts[1:] + pts[:1]):
        mx, my = (ax + bx) / 2 - cx, (ay + by) / 2 - cy
        col = STEEL[3] if mx * ga.LIGHT[0] + my * ga.LIGHT[1] > 0 else METAL[0]
        cv.line(ax, ay, bx, by, col)
    rust = ga.ramp(ga.hexc("624330"))
    for _ in range(5):
        x, y = rng.choice(pts)
        x, y = x * 0.83 + cx * 0.17, y * 0.83 + cy * 0.17
        cv.stain(rng, x, y, rng.uniform(0.6, 1.5), rust, cond=inside)
    for _ in range(9):
        x, y = cx + rng.uniform(-7, 7), cy + rng.uniform(-6, 6)
        cv.line(x, y, x + rng.uniform(1, 3), y - rng.uniform(0.3, 1), STEEL[2],
                cond=lambda nx, ny: inside((nx + 0.5) / cv.s, (ny + 0.5) / cv.s))
    for x, y in pts[::2]:
        x, y = x * 0.73 + cx * 0.27, y * 0.73 + cy * 0.27
        cv.ellipse(x, y, 0.85, 0.85, STRAP, bias=-0.2)
        cv.dot(x - 0.3, y - 0.3, STEEL[5])
        cv.dot(x + 0.4, y + 0.4, METAL[0])
    cv.stain(rng, cx + 3, cy + 4, 1.4, ga.BLOOD, cond=inside)


def boss_fibers(cv, x0, y0, x1, y1, width, seed):
    """Короткие неодинаковые волокна вдоль мышцы, без полос поперёк всей руки."""
    rng = random.Random(seed)
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy) or 1
    ux, uy = dx / ln, dy / ln
    for _ in range(round(ln * width * 0.12)):
        t, off = rng.uniform(0.1, 0.85), rng.uniform(-0.38, 0.38) * width
        x, y = x0 + dx * t - uy * off, y0 + dy * t + ux * off
        length = rng.uniform(1, 3.5)
        cv.line(x, y, x + ux * length, y + uy * length, ga.MUSCLE[rng.choice((0, 1, 2))],
                cond=lambda nx, ny: cv.getn(nx, ny) is not None)
        if rng.random() < 0.3:
            cv.dot(x - uy * 0.65, y + ux * 0.65, ga.darker(ga.FLESH[3], 0.8))


def boss_wound(cv, x, y, seed, size=1):
    """Неровная полость: лоскуты кожи, жёлтый жир по краю, сломанные рёбра."""
    rng = random.Random(seed)
    skin = ga.ramp(ga.VARIANTS[0]["skin"])
    pts = [(x + xx * size, y + yy * size) for xx, yy in
           ((-5, -7), (-1, -9), (2, -6), (5, -5), (4, -1), (6, 3),
            (2, 8), (-2, 7), (-5, 9), (-6, 3), (-4, -1), (-6, -4))]
    inside = boss_surface(cv, pts, ga.BLOOD, seed, bias=-0.55)
    for i, (px, py) in enumerate(pts):
        cv.tube(px, py, px + size, py - size, 1.3 * size,
                ga.FAT if i % 3 else skin, w1=0.4 * size, tex=0.25, seed=i)
    for k in range(4):
        yy = y + (k - 1.5) * 3.1 * size
        cv.tube(x - 3.8 * size, yy, x + 0.4 * size, yy - 1.1 * size,
                0.9 * size, ga.BONE, w1=0.7 * size)
        cv.tube(x + 0.4 * size, yy - 1.1 * size, x + 2.7 * size, yy + 0.4 * size,
                0.7 * size, ga.BONE, w1=0.3 * size)
        cv.dot(x + 2.7 * size, yy + 0.4 * size, ga.TEETH)
    cv.stain(rng, x + 3 * size, y + 5 * size, 1.7 * size, ga.BLOOD, cond=inside)
    cv.tube(x + 2 * size, y + 7 * size, x - size, y + 12 * size,
            1.4 * size, ga.BLOOD, w1=0.35)
    cv.dot(x - size, y + 10 * size, ga.FLESH[4])


def boss(phase, frame):
    cv = ga.Canvas(96, 96)
    rng = random.Random(5700)  # локальные seed сохраняют раны при движении
    rush = frame == 4
    swing = (0, 3.8, 0, -3.8, 0)[frame]
    cx = 43 + (3 if rush else 0)
    cy = 48 + (0, -1, 0.7, 1, 0)[frame]
    skin = ga.ramp(ga.VARIANTS[0]["skin"])
    raw = [ga.mix(ga.darker(c, 0.8), ga.BLOOD[3], 0.25) for c in ga.MUSCLE]
    tissue = raw if phase == 2 else skin
    # Колени и тяжёлые ступни выступают из-под суженной задней части туши.
    for side in (-1, 1):
        step = -swing * side
        kx, ky = cx - 15 + step * 0.35, cy + side * 17
        fx, fy = cx - 23 + step, cy + side * 21
        cv.tube(cx - 7, cy + side * 11, kx, ky, 13, tissue, w1=9, tex=0.28, seed=5680)
        cv.tube(kx, ky, fx + 2, fy, 8, tissue, w1=5.5, tex=0.28, seed=5681)
        cv.tear(rng, kx - 1, ky - 2, 1.2, 4, ga.FLESH)
        cv.tube(fx - 3, fy, fx + 4, fy - side, 7, ga.SHOES, w1=8, tex=0.3)
        cv.line(fx - 2, fy - 2, fx + 4, fy - 2.5, METAL[2])
    # Один клиновидный объём: затылочный горб широк спереди, поясница узкая.
    pts = [(cx + x, cy + y) for x, y in
           ((-25, -3), (-22, -10), (-15, -14), (-10, -22), (0, -28),
            (10, -27), (18, -21), (23, -10), (25, 1), (21, 14),
            (13, 22), (2, 25), (-10, 19), (-18, 11), (-24, 7))]
    if rush:
        pts = [(x + (x - cx) * 0.12, cy + (y - cy) * 0.87) for x, y in pts]
    inside = boss_surface(cv, pts, tissue, 5700, bias=-0.17 if phase == 2 else -0.08)
    # Направленные бугры трапеций, ограниченные общим силуэтом.
    for side in (-1, 1):
        cv.tube(cx - 15, cy + side * 4, cx + 12, cy + side * 15,
                17, tissue, w1=23 if side < 0 else 18, tex=0.28,
                seed=5702 + side, bias=-0.12, cond=inside)
        cv.shade_area(cx + 10, cy + side * 18, 12, 7, 0.52)
    for _ in range(30):
        x, y = cx + rng.uniform(-20, 18), cy + rng.uniform(-23, 21)
        if inside(x, y):
            cv.ellipse(x, y, rng.uniform(0.6, 1.8), rng.uniform(0.4, 1.1),
                       ga.ramp(ga.BRUISE), tex=0.3, cond=inside, bias=-0.1)
    for side in (-1, 1):
        cv.walk(rng, cx - 12, cy + side * 10, side * 0.3, 27, ga.VEIN, 0.4)
        cv.tear(rng, cx - 13, cy + side * 7, -side * 0.35, 12,
                ga.BLOOD if phase == 2 else ga.MUSCLE, cond=inside)
    if phase == 2:
        boss_fibers(cv, cx - 18, cy, cx + 11, cy - 17, 18, 5705)
        boss_fibers(cv, cx - 17, cy + 6, cx + 14, cy + 15, 16, 5706)
        boss_wound(cv, cx - 5, cy + 2, 5750)
        boss_wound(cv, cx + 12, cy - 16, 5751, 0.55)
        boss_wound(cv, cx + 8, cy + 18, 5752, 0.48)
    # Лопатки и предплечья разной толщины, локоть образует перелом контура.
    for side in (-1, 1):
        ext = swing * side
        sx = cx + 8 + (4 if rush else ext * 0.22)
        sy = cy + side * (19 if rush else (24 if side < 0 else 22))
        ex = cx + (9 if rush else 19 + ext * 0.65)
        ey = cy + side * (27 if rush else 31)
        hx = cx + (12 if rush else 31 + ext)
        hy = cy + side * (23 if rush else 27) + ext * 0.3
        shoulder = [(sx - 12, sy - side * 5), (sx - 9, sy + side * 6),
                    (sx - 2, sy + side * 10), (ex + 1, ey + side * 6),
                    (ex + 6, ey + side * 3), (ex + 7, ey - side * 3),
                    (sx + 9, sy - side * 5), (sx, sy - side * 9)]
        shoulder_inside = boss_surface(cv, shoulder, tissue, 5710 + side, bias=-0.15)
        cv.tube(sx - 8, sy + side, ex, ey, 22 if side < 0 else 18,
                tissue, w1=12, tex=0.28, seed=5710 + side, bias=-0.1, cond=shoulder_inside)
        cv.tube(ex, ey, hx - 2, hy, 13, tissue, w1=8, tex=0.28, seed=5713 + side)
        cv.shade_area(ex - 3, ey - side * 2, 6, 4, 0.48)
        cv.line(ex - 2, ey + side * 2, ex + 2, ey + side * 3, ga.MUSCLE[1])
        palm = [(hx + x, hy + y) for x, y in
                ((-5, -3), (-1, -5), (3, -4), (5, -1), (4, 4), (0, 5), (-4, 3))]
        boss_surface(cv, palm, tissue, 5717)
        for k in range(3):
            yy = hy - 3 + k * 2.8
            cv.tube(hx + 2, yy, hx + 6, yy + 0.5, 2.3, tissue, w1=1.5, tex=0.25)
            cv.tube(hx + 5.8, yy + 0.5, hx + 8 - abs(k - 1), yy + 1.3,
                    1.0, ga.BONE, w1=0.3, bias=-0.3)
            cv.dot(hx + 3, yy - 0.5, ga.BLOOD[1])
        cv.stain(rng, hx + 2, hy, 2.5, ga.BLOOD)
        cv.walk(rng, ex + 1, ey - side * 2, math.atan2(hy - ey, hx - ex),
                17, ga.VEIN, 0.4)
        cv.dot(ex, ey, ga.BRUISE)
        cv.tear(rng, sx, sy - 3, 0.6 * side, 7, ga.BLOOD if phase == 2 else ga.FLESH)
        if phase == 2:
            boss_fibers(cv, sx - 5, sy, ex, ey, 14, 5720 + side)
            boss_fibers(cv, ex, ey, hx, hy, 8, 5723 + side)
            cv.stain(rng, ex - 1, ey + side * 2, 2, ga.BLOOD)
            # Рваный остаток мёртвой кожи с жёлтой подкожной кромкой.
            cv.tube(ex - 3, ey + side * 4, hx - 4, hy + side * 4,
                    2, skin, w1=0.6, tex=0.3)
            cv.line(ex - 1, ey + side * 3.5, ex + 2, ey + side * 3, ga.FAT[2])
        else:
            cv.ellipse(ex - 2, ey, 2.4, 1.6, ga.ramp(ga.BRUISE), tex=0.3)
            # Большая левая наплечная пластина, меньшая правая.
            size = 1.05 if side < 0 else 0.79
            plate = [(sx + x * size, sy + y * size) for x, y in
                     ((-12, -5), (-6, -10), (3, -9), (10, -3), (8, 5), (-2, 8), (-10, 5))]
            cv.shade_area(sx + 2, sy + 4, 15, 12, 0.4)
            boss_armor(cv, plate, 5730 + side)
    if phase == 1:
        for side in (-1, 1):
            cv.tube(cx - 18, cy + side * 9, cx + 11, cy + side * 15,
                    3.1, STRAP, tex=0.2)
        # Две перекрывающиеся выпуклые плиты вместо плоского щита.
        cv.shade_area(cx - 1, cy + 2, 22, 23, 0.42)
        boss_armor(cv, [(cx - 20, cy - 6), (cx - 12, cy - 15), (cx, cy - 18),
                       (cx + 9, cy - 9), (cx + 6, cy + 7), (cx - 12, cy + 11),
                       (cx - 21, cy + 5)], 5740)
        boss_armor(cv, [(cx + 1, cy - 16), (cx + 10, cy - 22), (cx + 19, cy - 13),
                       (cx + 20, cy + 5), (cx + 13, cy + 14), (cx + 3, cy + 8)], 5741)
        stencil(cv, cx - 13, cy - 5)
        for side in (-1, 1):
            yy = cy + side * 10
            cv.tube(cx - 15, yy, cx - 24, yy + side * 4, 1.7, TUBE, tex=0.2)
            cv.tube(cx - 24, yy + side * 4, cx - 23, yy + side * 9, 1.5, TUBE)
            cv.dot(cx - 23, yy + side * 9, ga.BLOOD[1])
            cv.ellipse(cx - 15, yy, 1.1, 1.1, YELLOW, bias=-0.2)
    else:
        # Два обломка, висящие отдельно от обнажённого горба.
        for side, dx in ((-1, -15), (1, 4)):
            xx, yy = cx + dx, cy + side * 17
            cv.tube(xx, yy - side * 4, xx - 2, yy + side * 7, 1.7, STRAP)
            boss_armor(cv, [(xx - 4, yy + side * 4), (xx + 1, yy + side * 3),
                           (xx + 3, yy + side * 8), (xx - 3, yy + side * 10)], 5760 + side)
    # Маленькое лицо погружено в горб; костяной клин не закрывает челюсть и глаза.
    hx, hy = cx + (27 if rush else 21), cy + (1.5 if rush else 0)
    cv.shade_area(hx - 5, hy, 12, 10, 0.35)
    head = [(hx + x, hy + y) for x, y in
            ((-6, -3), (-3, -7), (1, -6), (5, -4), (7, 0), (5, 5), (0, 6), (-4, 4))]
    head_ramp = [ga.darker(c, 0.72) for c in tissue]
    boss_surface(cv, head, head_ramp, 5770, bias=-0.2)
    horn = [(hx + x, hy + y) for x, y in
            ((-4, -1), (-1, -2.1), (3, -1.6), (5, -1.3), (9, -0.8),
             (7, 0.1), (8, 0.8), (4, 1.1), (2, 1.8), (-2, 1.2), (-5, 0))]
    horn_ramp = [ga.darker(c, 0.7) for c in ga.BONE]
    boss_surface(cv, horn, horn_ramp, 5771, bias=-0.45)
    cv.line(hx - 3, hy - 2, hx + 1, hy - 0.3, ga.BONE[1])
    cv.line(hx + 1, hy - 0.3, hx, hy + 1.5, ga.BONE[0])
    cv.line(hx + 1, hy - 0.3, hx + 4, hy - 0.8, ga.BONE[0])
    cv.dot(hx + 5, hy - 1.5, ga.BONE[4])
    # Пасть открыта с нижней стороны костяного клина, её не перекрывает лоб.
    cv.tube(hx + 2, hy + 5, hx + 7, hy + 3, 2.2, horn_ramp, w1=1.0, bias=-0.4)
    cv.tube(hx + 4, hy + 3, hx + 7, hy + 1, 2.4, ga.BLOOD, w1=1.8, bias=-0.8)
    for k in range(5):
        xx, yy = hx + 3.7 + k * 0.75, hy + 3.7 - k * 0.55
        cv.dot(xx, yy, ga.TEETH)
        if k % 2:
            cv.dot(xx + 0.5, yy + 1.0, ga.darker(ga.TEETH, 0.8))
    for side in (-1, 1):
        socket = [ga.darker(c, 0.35) for c in ga.BLOOD]
        cv.ellipse(hx + 3.6, hy + side * 3.5, 2, 1.5, socket, bias=-0.85)
        cv.dot(hx + 4.1, hy + side * 3.5, ga.EYE_GLOW)
        cv.dot(hx + 4.7, hy + side * 3.5, ga.EYE_GLOW)
    cv.tube(hx + 4, hy + 4.5, hx + 1, hy + 8, 1.1, ga.BLOOD, w1=0.3)
    cv.outline(0.36)
    return cv.image()


def boss_plate(k):
    cv = ga.Canvas(20, 20)
    cv.tube(10, 12, 5 + k, 18, 2.5, STRAP)
    cv.ellipse(10, 13, 4, 3, ga.MUSCLE, tex=0.25, seed=k)
    shapes = [ [(3, 4), (13, 2), (17, 8), (14, 14), (4, 13)],
               [(5, 2), (15, 4), (16, 15), (9, 13), (3, 10)],
               [(2, 6), (11, 3), (17, 5), (14, 11), (17, 15), (4, 14)],
               [(4, 3), (15, 3), (17, 12), (10, 16), (3, 10)] ]
    metal(cv, shapes[k], 5800 + k)
    if k == 0:
        stencil(cv, 6, 6)
    cv.line(8, 7, 11, 10, METAL[0])
    cv.line(8, 6.3, 11, 9.3, STEEL[3])
    cv.outline(0.36)
    return cv.image()


def boss_gib(k):
    rng = random.Random(5900 + k)
    cv = ga.Canvas(24, 24)
    cv.ellipse(12, 12, 9, 8, MEAT, tex=0.25, seed=k)
    cv.stain(rng, 13, 15, 4, ga.BLOOD)
    if k == 0:
        metal(cv, [(6, 5), (14, 3), (19, 9), (15, 12), (6, 10)], 5900)
        cv.tube(8, 15, 4, 20, 2.5, ga.GUTS)
    elif k == 1:
        ribs(cv, 12, 11, 0.8)
    elif k == 2:
        for j in range(5):
            y = 6 + j * 2.8
            cv.tube(6, y, 17, y + 1, 2.6, ga.GUTS, tex=0.2, seed=j)
            cv.ellipse(17 if j % 2 else 6, y + 1, 2.2, 1.8, ga.GUTS)
            cv.line(8, y - 0.7, 13, y - 0.7, ga.GUTS[5])
    else:
        cv.ellipse(12, 10, 8, 6, ga.BONE, tex=0.2)
        cv.tube(16, 6, 19, 14, 3, ga.BONE)
        cv.line(8, 6, 12, 10, ga.BONE[0])
        cv.line(12, 10, 10, 14, ga.BONE[0])
        cv.ellipse(7, 15, 3, 2, ga.BRAIN)
    for _ in range(5):
        cv.dot(rng.uniform(8, 16), rng.uniform(14, 19), ga.FAT[3])
    cv.outline(0.4)
    return cv.image()


def crushed(k):
    cv = ga.Canvas(32, 32)
    rng = random.Random(6000 + k)
    # Плоский мазок по +X: полупрозрачный рваный край без обводки.
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / cv.s, (ny + 0.5) / cv.s
            d = math.hypot((x - 16) / 14, (y - 16) / 6.5)
            d += ga.hnoise(nx // 2, ny // 2, 6000 + k) * 0.11
            if d < 1:
                cv.putn(nx, ny, ga.pick(ga.BLOOD, -0.3 + ga.hnoise(nx, ny, k) * 0.2),
                        round(65 + 145 * min(1, (1 - d) * 4)))
    cloth = ga.ramp(ga.VARIANTS[k]["shirt"])
    cv.tube(6, 15, 17, 16, 6, cloth, w1=4, tex=0.22, seed=k)
    cv.tear(rng, 8, 14, 0.2, 7, ga.MUSCLE)
    cv.ellipse(19, 16, 6, 4, ga.MUSCLE, tex=0.3)
    for j in range(4):
        cv.tube(16 + j * 2, 13, 17 + j * 2, 17, 0.7, ga.BONE)
    for j in range(6):
        cv.tube(21 + j, 16 + math.sin(j) * 2, 22 + j, 16 + math.sin(j + 1) * 2,
                1.4, ga.GUTS)
    cv.tube(7, 17, 3, 19, 1.3, ga.BONE)
    for _ in range(12):
        x, y = rng.uniform(3, 30), rng.uniform(9, 23)
        cv.dot(x, y, ga.BLOOD[1] + (rng.randrange(70, 170),))
    return cv.image()


def military_crate():
    cv = ga.Canvas(18, 18)
    metal(cv, [(2, 2), (15, 2), (16, 4), (16, 15), (3, 16), (1, 14)], 6100)
    cv.tube(4, 4, 4, 14, 1.8, STRAP)
    cv.tube(13, 4, 13, 14, 1.8, STRAP)
    for x in (5.5, 11):
        cv.tube(x, 3, x, 14.5, 1.3, YELLOW)
    cv.line(7, 5, 10, 5, STRAP[0])
    cv.line(7, 5.7, 10, 5.7, STEEL[3])
    for x in (4, 13):
        cv.tube(x, 13, x, 15.5, 1.2, STEEL)
    cv.line(8, 9, 9, 13, STEEL[2])
    cv.ellipse(9, 12, 1.7, 1.5, ga.FLESH, bias=-0.2)
    cv.dot(8.5, 11.5, (224, 96, 75))
    cv.line(7.5, 8, 10, 8, ga.BONE[2])
    cv.outline(0.35)
    return cv.image()


def sprites():
    atlas = Image.new("RGBA", (720, 288))
    for phase in (1, 2):
        for frame in range(5):
            atlas.paste(boss(phase, frame), (frame * 144, (phase - 1) * 144))
    return [("boss", atlas),
            *[("boss_plate_%d" % k, boss_plate(k)) for k in range(4)],
            *[("boss_gib_%d" % k, boss_gib(k)) for k in range(4)],
            *[("crushed_%d" % k, crushed(k)) for k in range(3)],
            ("military_crate", military_crate())]


def preview(images, path, reference):
    atlas = images[0][1]
    panel_h = 1650
    sheet = Image.new("RGB", (2400, panel_h * 2))
    draw = ImageDraw.Draw(sheet)
    for panel, bg in enumerate(((61, 63, 67), (60, 12, 14))):
        top = panel * panel_h
        draw.rectangle((0, top, 2399, top + panel_h - 1), fill=bg)
        draw.text((16, top + 10), "ASPHALT / x3" if panel == 0 else "BLOOD / x3", fill=(220, 217, 201))
        for phase in range(2):
            for frame in range(5):
                x, y = frame * 480, top + 35 + phase * 450
                draw.text((x + 12, y), "phase %d / %s" % (phase + 1, "CHARGE" if frame == 4 else "walk %d" % frame), fill=(220, 217, 201))
                tile = atlas.crop((frame * 144, phase * 144, frame * 144 + 144, phase * 144 + 144))
                tile = tile.resize((432, 432), Image.Resampling.NEAREST)
                sheet.paste(tile, (x + 16, y + 17), tile)
        for i, (name, img) in enumerate(images[1:]):
            x, y = (i % 8) * 192 + 12, top + 950 + (i // 8) * 115
            draw.text((x, y), name, fill=(220, 217, 201))
            enlarged = img.resize((img.width * 3, img.height * 3), Image.Resampling.NEAREST)
            sheet.paste(enlarged, (x, y + 16), enlarged)
        if reference:
            draw.text((16, top + 1186), "SCALE COMPARISON: boss / zombie 0 / zombie 3 / zombie 5 / boss phase 2 (all x3)", fill=(220, 217, 201))
            for phase, left in ((0, 16), (1, 1050)):
                tile = atlas.crop((0, phase * 144, 144, phase * 144 + 144))
                tile = tile.resize((432, 432), Image.Resampling.NEAREST)
                sheet.paste(tile, (left, top + 1210), tile)
            with Image.open(reference) as source:
                for j, variant in enumerate((0, 3, 5)):
                    zombie = source.crop((0, variant * 4 * 48, 48, variant * 4 * 48 + 48)).convert("RGBA")
                    zombie = zombie.resize((144, 144), Image.Resampling.NEAREST)
                    x = 1740 + j * 210
                    draw.text((x, top + 956), "zombie %d / x3" % variant, fill=(220, 217, 201))
                    sheet.paste(zombie, (x, top + 985), zombie)
                    sheet.paste(zombie, (480 + j * 175, top + 1354), zombie)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", help="папка PNG вместо ga.OUT")
    parser.add_argument("--preview", metavar="PNG")
    parser.add_argument("--reference", help="zombie_atlas.png для сравнения масштаба")
    args = parser.parse_args(argv)
    if args.out:
        ga.OUT = os.path.abspath(args.out)
    os.makedirs(ga.OUT, exist_ok=True)
    images = sprites()
    for name, img in images:
        ga.save(img, name)
        print("%s.png: %dx%d RGBA" % (name, *img.size))
    print("art ->", ga.OUT)
    if args.preview:
        reference = args.reference or os.path.join(os.path.dirname(ga.__file__), "..", "art", "zombie_atlas.png")
        preview(images, args.preview, reference)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
