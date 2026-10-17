"""Предметы M4. Запуск рядом с gen_art.py: python tools/gen_art_m4.py.

--preview out.png — лист всех спрайтов, масштаб x4 без сглаживания.
Выходная папка — ga.OUT; импорт этого модуля ничего не сохраняет.
"""

import argparse
import math
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as ga


STEEL = ga.ramp(ga.hexc("687478"), spread=0.65)
DARK_METAL = ga.ramp(ga.hexc("3e4849"), spread=0.7)
OLIVE = ga.ramp(ga.hexc("646b42"), spread=0.65)
ENAMEL = ga.ramp(ga.hexc("c7c8b4"), spread=0.45)
RED = ga.ramp(ga.hexc("b32c2d"), spread=0.6)
BLUE = ga.ramp(ga.hexc("4a8fe0"))
RUST = ga.ramp(ga.hexc("79503a"))


def plate(cv, x0, y0, x1, y1, rmp, seed, bevel=0.65):
    """Металлическая крышка: срезанные углы, фаска, свет LIGHT и зерно."""
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = (x1 - x0) / 2, (y1 - y0) / 2
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / cv.s, (ny + 0.5) / cv.s
            dx, dy = x - cx, y - cy
            ex, ey = rx - abs(dx), ry - abs(dy)
            if min(ex, ey) < 0 or ex + ey < bevel * 0.7:
                continue
            sh = 0.1 + ga.LIGHT[0] * dx / rx * 0.22 + ga.LIGHT[1] * dy / ry * 0.22
            if min(ex, ey) < bevel:
                light = ga.LIGHT[0] * (1 if dx > 0 else -1) if ex < ey else ga.LIGHT[1] * (1 if dy > 0 else -1)
                sh = light * 0.8 - 0.18
            cv.putn(nx, ny, ga.pick(rmp, sh + ga.hnoise(nx, ny, seed) * 0.12))


def rivet(cv, x, y):
    cv.dot(x + 0.45, y + 0.45, DARK_METAL[0])
    cv.dot(x, y, STEEL[4])


def medkit():
    """Светлая эмаль и крупный крест различимы среди крови."""
    rng = random.Random(4101)
    cv = ga.Canvas(10, 10)
    cv.line(3.4, 1.1, 6.0, 1.1, STEEL[4])
    cv.line(3.4, 1.1, 3.4, 2.5, STEEL[2])
    cv.line(6.0, 1.1, 6.0, 2.5, STEEL[1])
    plate(cv, 1.2, 2.3, 8.7, 8.8, ENAMEL, 4101)
    cv.line(1.6, 7.4, 8.1, 7.4, ENAMEL[1])
    cv.stain(rng, 2.0, 6.4, 0.65, ga.DRIED)
    cv.stain(rng, 7.7, 3.1, 0.55, ga.BLOOD)
    # Крест в родных пикселях: ровные плечи, без размытия на сетке S=1.5.
    for ny in range(5, 11):
        for nx in range(5, 11):
            if nx in (7, 8) or ny in (7, 8):
                cv.putn(nx, ny, RED[3])
    cv.dot(1.4, 4.0, STEEL[3])
    cv.dot(8.0, 6.6, STEEL[1])
    cv.outline(0.4)
    return cv


def weapon_crate():
    rng = random.Random(4102)
    cv = ga.Canvas(14, 14)
    plate(cv, 1.3, 1.8, 12.7, 12.2, OLIVE, 4102)
    plate(cv, 2.4, 3.0, 11.6, 10.8, OLIVE, 4152, bevel=0.45)
    # Приподнятые рёбра крышки, две защёлки и утопленная ручка.
    for x in (3.3, 10.7):
        cv.tube(x, 2.3, x, 11.5, 1.0, OLIVE, tex=0.12, seed=4102)
    cv.line(5.3, 3.4, 8.5, 3.4, DARK_METAL[0])
    cv.line(5.3, 4.0, 8.5, 4.0, STEEL[2])
    for x in (4.6, 8.5):
        plate(cv, x, 10.3, x + 1.2, 12.2, STEEL, 4112)
        cv.dot(x + 0.6, 11.1, DARK_METAL[0])
    for x, y in ((1.9, 2.5), (11.6, 2.5), (2.0, 11.4), (11.6, 11.4)):
        rivet(cv, x, y)
        cv.dot(x + 0.7, y, RUST[2])
    for x, length in ((5.0, 1.1), (7.0, 0.5), (8.3, 0.7)):
        cv.line(x, 6.3, x + length, 6.3, ENAMEL[2])
    cv.line(5.0, 7.6, 7.0, 7.6, ENAMEL[1])
    for _ in range(8):
        x = rng.choice((2.0, 11.5)) + rng.uniform(-0.3, 0.3)
        cv.dot(x, rng.uniform(3.3, 9.9), STEEL[3])
    cv.outline(0.35)
    return cv


def rare_part():
    cv = ga.Canvas(10, 10)
    rng = random.Random(4103)

    def teeth(x, y):
        dx, dy = x - 5, y - 5
        return math.hypot(dx, dy) < 2.65 or min(abs(dx), abs(dy)) < 0.85 or abs(abs(dx) - abs(dy)) < 0.5

    cv.ellipse(5, 5, 3.3, 3.3, STEEL, cond=teeth, tex=0.15, seed=4103)
    cv.ellipse(5, 5, 2.15, 2.15, DARK_METAL, bias=-0.35)
    cv.ellipse(5, 5, 1.55, 1.55, BLUE, tex=0.12, seed=4103)
    cv.line(4.4, 4.3, 5.4, 4.3, BLUE[5])
    for x, y in ((3.1, 5), (6.7, 5), (5, 3.1), (5, 6.7)):
        cv.dot(x, y, BLUE[rng.randrange(3, 5)])
    cv.outline(0.4)
    # Два родных пикселя ореола вокруг металла, без непрозрачной подложки.
    body = [(x, y) for y in range(cv.h) for x in range(cv.w) if cv.getn(x, y)]
    for ny in range(cv.h):
        for nx in range(cv.w):
            if cv.getn(nx, ny) is not None:
                continue
            d = min(max(abs(nx - x), abs(ny - y)) for x, y in body)
            if d <= 2:
                cv.putn(nx, ny, BLUE[3], 70 if d == 1 else 28)
    return cv


def blood_container():
    rng = random.Random(4104)
    cv = ga.Canvas(28, 20)
    plate(cv, 1.5, 2.0, 26.2, 17.7, DARK_METAL, 4104, bevel=1.0)
    plate(cv, 3.4, 3.2, 24.2, 16.2, DARK_METAL, 4124)
    for x in (3.2, 24.3):
        cv.tube(x, 3.5, x, 15.6, 1.4, STEEL, bias=-0.2, tex=0.18, seed=4104)
    for y in (5.0, 13.2):
        cv.line(0.8, y, 2.2, y, STEEL[3])
        cv.line(25.2, y, 26.7, y, STEEL[1])
    for x in (6.4, 20.6):
        cv.tube(x, 3.5, x + 1.9, 5.0, 1.1, ga.BLOOD, tex=0.18, seed=4114)
        cv.tube(x, 14.3, x + 1.9, 15.7, 1.1, ga.BLOOD, bias=-0.2)
    # Вмятины: тень и освещённая кромка на одной поверхности крышки.
    for x, y in ((8.1, 7.8), (21.6, 11.7), (7.7, 13.3)):
        cv.shade_area(x, y, 1.6, 0.9, k=0.42)
        cv.line(x - 0.7, y + 0.5, x + 0.6, y + 0.5, STEEL[2])
    cv.stain(rng, 18.8, 15.6, 1.5, ga.BLOOD)
    cv.tube(19.2, 15.5, 19.5, 18.2, 0.9, ga.BLOOD, w1=0.5, bias=-0.2)
    cv.tube(21.1, 16.0, 21.2, 17.6, 0.65, ga.DRIED)
    # Круглый герметичный иллюминатор с образцом крови.
    cv.ellipse(14.0, 9.9, 4.9, 4.9, STEEL, tex=0.13, seed=4104)
    cv.ellipse(14.0, 9.9, 3.9, 3.9, DARK_METAL, bias=-0.65)
    cv.ellipse(14.0, 9.9, 3.15, 3.15, ga.BLOOD, bias=0.18, tex=0.18, seed=4134)
    cv.ellipse(13.2, 9.0, 1.5, 1.0, RED, bias=-0.15, tex=0.12, seed=4104)
    cv.line(12.0, 7.8, 13.2, 7.3, ga.mix(STEEL[4], RED[2], 0.4))
    for x, y in ((14, 5.6), (18.3, 9.9), (14, 14.2), (9.7, 9.9)):
        rivet(cv, x, y)
    for x in (6.5, 21.2):
        cv.ellipse(x, 6.1, 1.15, 1.0, DARK_METAL, bias=-0.6)
        cv.ellipse(x, 6.1, 0.65, 0.6, RED, bias=-0.4)
        cv.dot(x - 0.25, 5.8, RED[4])
    for x, y in ((4.1, 3.4), (23.6, 3.4), (4.1, 15.7), (23.6, 15.7)):
        rivet(cv, x, y)
    for _ in range(12):
        x, y = rng.uniform(4.8, 23), rng.choice((3.5, 15.7))
        cv.dot(x, y, rng.choice((STEEL[2], RUST[2], DARK_METAL[0])))
    cv.line(5.5, 9.3, 7.1, 9.3, ENAMEL[1])
    cv.line(5.5, 10.6, 6.2, 10.6, ENAMEL[1])
    cv.outline(0.35)
    return cv


def grenade(hud=False):
    size = 8 if hud else 6
    cv = ga.Canvas(size, size)
    scale = 1.05 if hud else 1.0

    def pt(x, y):
        return size / 2 + (x - 3) * scale, size / 2 + (y - 3) * scale

    cx, cy = pt(2.7, 3.5)
    cv.ellipse(cx, cy, 1.65 * scale, 1.8 * scale, OLIVE, tex=0.13, seed=4105)
    for y in (2.9, 4.0):
        cv.line(*pt(1.4, y), *pt(3.7, y), OLIVE[0])
    cv.line(*pt(2.6, 2.1), *pt(2.6, 4.8), OLIVE[1])
    cv.tube(*pt(3.3, 2.0), *pt(4.0, 4.4), 0.65 * scale, STEEL, bias=-0.3)
    cv.line(*pt(2.5, 1.6), *pt(3.8, 1.6), STEEL[4])
    cv.ellipse(*pt(4.1, 1.1), 0.75 * scale, 0.75 * scale, STEEL)
    cv.outline(0.3 if hud else 0.4)
    if hud:
        cv.outline(0.4)  # Два родных пикселя контура для тёмного HUD.
    # Отверстие кольца открывается после обводки, чтобы она его не затянула.
    cv.erasen(*cv.n(*pt(4.1, 1.1)))
    return cv


def spit(frame):
    rng = random.Random(4110 + frame)
    cv = ga.Canvas(6, 6)
    cy = (3.0, 2.8, 3.1)[frame]
    cv.tube(1.0, cy + 0.25, 3.9, cy, 0.7, ga.ACID, w1=3.0, tex=0.18, seed=4110 + frame)
    cv.ellipse(3.7, cy, 1.45, (1.55, 1.3, 1.65)[frame], ga.ACID, tex=0.13, seed=4120 + frame)
    cv.ellipse(3.7, cy - 0.35, 0.65, 0.7, ga.PUS, bias=0.2)
    cv.dot(1.2, cy - 1.0, ga.ACID[3])
    cv.dot(2.2, cy + rng.choice((-1.2, 1.2)), ga.PUS[3])
    cv.dot(3.2, cy - 0.7, ga.PUS[5])
    cv.outline(0.4)
    return cv


def acid(frame):
    """Слитые лопасти одной лужи; кайма и альфа без Canvas.outline."""
    rng = random.Random(4120 + frame)
    cv = ga.Canvas(40, 40)
    lobes = [(19.5, 20.0, 10.0, 9.0)]
    for i in range(7):
        angle = i * math.tau / 7 + rng.uniform(-0.3, 0.3)
        d = rng.uniform(6.0, 11.0)
        lobes.append((20 + math.cos(angle) * d, 20 + math.sin(angle) * d,
                      rng.uniform(5.0, 8.0), rng.uniform(4.5, 7.0)))

    def depth(x, y):
        return 1 - min(math.hypot((x - cx) / rx, (y - cy) / ry) for cx, cy, rx, ry in lobes)

    # Объём и текстура сначала рисуются штатными эллипсами генератора.
    for i, (cx, cy, rx, ry) in enumerate(lobes):
        cv.ellipse(cx, cy, rx, ry, ga.ACID, bias=-0.18, tex=0.16, seed=4120 + frame * 10 + i)
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / cv.s, (ny + 0.5) / cv.s
            d = depth(x, y)
            if -0.065 < d < 0:
                cv.putn(nx, ny, ga.mix(DARK_METAL[0], ga.ACID[0], 0.15), 110)
            elif d >= 0:
                c = cv.getn(nx, ny)
                if c is not None:
                    # Внешние 1–2 пикселя прозрачнее; центр около 200.
                    alpha = round(100 + 100 * min(1.0, d / 0.4))
                    light = ((x - 20) * ga.LIGHT[0] + (y - 20) * ga.LIGHT[1]) / 18
                    sh = -0.25 + min(d, 0.45) * 0.8 + light * 0.22
                    sh += ga.hnoise(nx // 2, ny // 2, 4120 + frame) * 0.1
                    # Общее освещение поверхности убирает швы полусфер.
                    col = ga.mix(c, ga.pick(ga.ACID, sh), 0.9)
                    cv.putn(nx, ny, col, alpha)
    # Пузырьки внутри плотного участка, с тёмным ободком и бликом слева.
    for _ in range(20):
        x, y = rng.uniform(5, 35), rng.uniform(5, 35)
        r = rng.uniform(0.55, 1.25)
        if depth(x, y) < 0.23:
            continue
        cv.ellipse(x, y, r, r * 0.8, ga.ACID, bias=-0.65)
        cv.ellipse(x, y, r * 0.6, r * 0.5, ga.PUS, bias=-0.2)
        cv.dot(x - r * 0.35, y - r * 0.3, ga.PUS[5])
    # Сохраняем полупрозрачность и у пузырей, не создаём твёрдых точек декали.
    for ny in range(cv.h):
        for nx in range(cv.w):
            c = cv.getn(nx, ny)
            if c is not None and c[3] > 200:
                cv.putn(nx, ny, c[:3], 200)
    return cv


def sprites():
    return [
        ("medkit", medkit()),
        ("weapon_crate", weapon_crate()),
        ("rare_part", rare_part()),
        ("blood_container", blood_container()),
        ("grenade", grenade()),
        ("icon_grenade", grenade(hud=True)),
        *[("spit_%d" % i, spit(i)) for i in range(3)],
        *[("acid_%d" % i, acid(i)) for i in range(3)],
    ]


def preview(images, path):
    """Одинаковые ячейки, честный масштаб x4, серый фон из ТЗ."""
    cols, cell_w, cell_h, pad = 3, 264, 280, 12
    rows = math.ceil(len(images) / cols)
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (61, 63, 67))
    draw = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(images):
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        draw.text((x + pad, y + pad), "%s  %dx%d" % (name, *img.size), fill=(211, 213, 206))
        enlarged = img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST)
        sheet.paste(enlarged, (x + (cell_w - enlarged.width) // 2,
                               y + 30 + (cell_h - 30 - enlarged.height) // 2), enlarged)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", metavar="PNG", help="лист спрайтов x4 на сером фоне")
    args = parser.parse_args(argv)
    os.makedirs(ga.OUT, exist_ok=True)
    images = []
    for name, cv in sprites():
        img = cv.image()
        ga.save(img, name)
        images.append((name, img))
        print("%s.png: %dx%d RGBA" % (name, *img.size))
    print("art ->", ga.OUT)
    if args.preview:
        preview(images, args.preview)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
