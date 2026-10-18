"""Пиктограммы деталей для карточек Level Up и снабжения (U1-14).
Запуск: python tools/gen_art_icons.py [--out DIR] [--preview PNG].

Пишет в art/:
  card_mod_<0..5>.png   рикошет, пробивание, сплит, детонатор, сдвоенный ствол, цепь (порядок WeaponDefs.Module)
  card_ammo_<0..3>.png  стандартные, экспансивные, зажигательные, крио (порядок WeaponDefs.Ammo)
  card_pas_<0..5>.png   пассивки (порядок WeaponDefs.Passive)

Иконка 26x26 px = 26 «игровых» пикселей интерфейса (×3 на 1080p): рисуется в сетке 24x24 без
сглаживания, вокруг добавляется чёрная обводка в 1 px, как у hud_*.png. Зависимость: Pillow.
"""

import argparse
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(ROOT, "..", "art"))

SIZE = 24
STEEL = (170, 178, 186, 255)
STEEL_D = (96, 104, 114, 255)
BRASS = (226, 178, 66, 255)
BRASS_D = (160, 112, 38, 255)
COPPER = (196, 108, 62, 255)
ORANGE = (244, 134, 40, 255)
YELLOW = (255, 218, 92, 255)
RED = (214, 66, 56, 255)
RED_D = (140, 38, 36, 255)
ICE = (196, 238, 255, 255)
BLUE = (96, 170, 240, 255)
GREEN = (126, 220, 132, 255)
OLIVE = (112, 124, 78, 255)
WHITE = (240, 238, 230, 255)


class Canvas:
    def __init__(self):
        self.img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def line(self, pts, color, width=1):
        self.d.line(pts, fill=color, width=width)

    def poly(self, pts, color):
        self.d.polygon(pts, fill=color)

    def rect(self, x0, y0, x1, y1, color):
        self.d.rectangle((x0, y0, x1, y1), fill=color)

    def ellipse(self, x0, y0, x1, y1, color, outline=None, width=1):
        self.d.ellipse((x0, y0, x1, y1), fill=color, outline=outline, width=width)

    def arc(self, box, a0, a1, color, width=1):
        self.d.arc(box, a0, a1, fill=color, width=width)

    def arrow(self, a, b, color, width=2, head=4):
        """Линия a→b с наконечником на b."""
        self.line([a, b], color, width)
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        pts = [b]
        for s in (-1, 1):
            pts.append((b[0] - head * math.cos(ang) + s * head * 0.7 * -math.sin(ang),
                        b[1] - head * math.sin(ang) + s * head * 0.7 * math.cos(ang)))
        self.poly(pts, color)


def outlined(img):
    """Чёрная обводка в 1 px вокруг непрозрачных пикселей; холст растёт на 1 px с каждой стороны."""
    w, h = img.size
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    src = img.load()
    dst = out.load()

    def solid(x, y):
        return 0 <= x < w and 0 <= y < h and src[x, y][3] > 0

    for y in range(-1, h + 1):
        for x in range(-1, w + 1):
            if solid(x, y):
                dst[x + 1, y + 1] = src[x, y]
            elif any(solid(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                dst[x + 1, y + 1] = (0, 0, 0, 215)
    return out


# --- модули -------------------------------------------------------------------------------

def ricochet():
    c = Canvas()
    c.rect(19, 3, 21, 20, STEEL)
    c.rect(19, 3, 19, 20, WHITE)
    c.line([(3, 20), (17, 12)], ORANGE, 2)
    c.arrow((17, 12), (6, 4), YELLOW, 2, 5)
    c.ellipse(1, 18, 5, 22, BRASS)
    return c.img


def pierce():
    c = Canvas()
    for x in (6, 12, 18):
        c.rect(x, 3, x + 2, 9, STEEL)
        c.rect(x, 14, x + 2, 20, STEEL)
        c.rect(x, 3, x, 9, WHITE)
        c.rect(x, 14, x, 20, WHITE)
    c.arrow((0, 11), (23, 11), ORANGE, 2, 5)
    return c.img


def split():
    c = Canvas()
    c.line([(1, 12), (9, 12)], BRASS, 2)
    c.ellipse(8, 10, 12, 14, YELLOW)
    for end in ((20, 3), (22, 12), (20, 21)):
        c.arrow((11, 12), end, ORANGE, 2, 4)
    return c.img


def detonator():
    c = Canvas()
    c.ellipse(3, 8, 16, 21, STEEL_D)
    c.ellipse(5, 10, 9, 13, STEEL)
    c.rect(8, 5, 11, 8, BRASS_D)
    c.line([(11, 5), (14, 3), (17, 4)], BRASS, 1)
    # искра на конце фитиля
    c.poly([(19, 1), (20, 3), (22, 4), (20, 5), (19, 7), (18, 5), (16, 4), (18, 3)], YELLOW)
    c.poly([(19, 3), (20, 4), (19, 5), (18, 4)], ORANGE)
    return c.img


def twin():
    c = Canvas()
    for x in (4, 14):
        c.rect(x, 11, x + 5, 21, BRASS)
        c.rect(x, 11, x + 1, 21, YELLOW)
        c.rect(x, 20, x + 5, 21, BRASS_D)
        c.poly([(x, 11), (x + 5, 11), (x + 4, 6), (x + 2.5, 3), (x + 1, 6)], COPPER)
    c.line([(11, 6), (11, 14)], STEEL_D, 1)
    return c.img


def chain():
    c = Canvas()
    c.arc((1, 8, 11, 16), 0, 360, STEEL, 2)
    c.arc((8, 5, 16, 19), 0, 360, STEEL_D, 2)
    c.arc((13, 8, 23, 16), 0, 360, STEEL, 2)
    return c.img


# --- патроны ------------------------------------------------------------------------------

def ammo_standard():
    c = Canvas()
    c.rect(8, 12, 15, 21, BRASS)
    c.rect(8, 12, 9, 21, YELLOW)
    c.rect(8, 20, 15, 21, BRASS_D)
    c.rect(7, 21, 16, 22, BRASS_D)
    c.poly([(8, 12), (15, 12), (14, 7), (11.5, 3), (9, 7)], COPPER)
    c.line([(9, 7), (9, 11)], ORANGE, 1)
    return c.img


def ammo_expansive():
    c = Canvas()
    c.rect(8, 13, 15, 21, BRASS)
    c.rect(8, 13, 9, 21, YELLOW)
    c.rect(8, 20, 15, 21, BRASS_D)
    c.rect(7, 21, 16, 22, BRASS_D)
    # пуля с «раскрывшейся» вершиной
    c.poly([(8, 13), (15, 13), (18, 6), (15, 8), (13, 3), (11, 8), (9, 3), (8, 8), (5, 6)], COPPER)
    c.poly([(10, 8), (13, 8), (12, 12), (11, 12)], RED)
    return c.img


def ammo_incendiary():
    c = Canvas()
    c.poly([(12, 1), (15, 6), (19, 11), (19, 17), (15, 22), (9, 22), (5, 17), (5, 12), (8, 8), (9, 12), (11, 8)], ORANGE)
    c.poly([(12, 10), (15, 14), (15, 19), (12, 21), (9, 19), (9, 14)], YELLOW)
    c.poly([(12, 15), (13, 18), (12, 20), (11, 18)], WHITE)
    return c.img


def ammo_cryo():
    c = Canvas()
    cx, cy = 11.5, 11.5
    for k in range(3):
        a = k * math.pi / 3
        dx, dy = math.cos(a) * 10.5, math.sin(a) * 10.5
        c.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], ICE, 2)
        for s in (-1, 1):
            bx, by = cx + dx * 0.55 * s, cy + dy * 0.55 * s
            for t in (-1, 1):
                ba = a + t * math.pi / 3
                c.line([(bx, by), (bx + math.cos(ba) * 3.5 * s, by + math.sin(ba) * 3.5 * s)], BLUE, 1)
    c.ellipse(9, 9, 14, 14, WHITE)
    return c.img


# --- пассивки -----------------------------------------------------------------------------

def passive_damage():
    c = Canvas()
    # шприц со стимулятором, по диагонали
    c.poly([(5, 16), (8, 19), (17, 10), (14, 7)], STEEL)
    c.poly([(7, 16), (9, 18), (16, 11), (14, 9)], RED)
    c.line([(16, 8), (20, 4)], STEEL_D, 2)
    c.line([(18, 3), (22, 7)], STEEL, 2)
    c.line([(5, 19), (1, 23)], WHITE, 1)
    c.line([(12, 6), (18, 12)], STEEL_D, 1)
    return c.img


def passive_fire_rate():
    c = Canvas()
    for x in (2, 8, 14):
        c.line([(x, 4), (x + 6, 11), (x, 19)], ORANGE if x != 14 else YELLOW, 3)
    return c.img


def passive_reload():
    c = Canvas()
    c.arc((2, 2, 21, 21), 40, 330, GREEN, 3)
    c.poly([(21, 3), (22, 11), (14, 8)], GREEN)
    c.rect(9, 7, 14, 16, BRASS)
    c.rect(9, 7, 10, 16, YELLOW)
    c.rect(9, 15, 14, 16, BRASS_D)
    return c.img


def passive_speed():
    c = Canvas()
    c.line([(1, 6), (10, 6)], STEEL, 2)
    c.line([(3, 12), (13, 12)], STEEL_D, 2)
    c.line([(1, 18), (10, 18)], STEEL, 2)
    c.poly([(12, 4), (23, 12), (12, 20), (15, 12)], GREEN)
    return c.img


def passive_hp():
    c = Canvas()
    c.poly([(12, 1), (21, 4), (20, 14), (12, 23), (4, 14), (3, 4)], OLIVE)
    c.poly([(12, 4), (18, 6), (17, 13), (12, 19), (7, 13), (6, 6)], STEEL_D)
    c.rect(10, 7, 13, 16, RED)
    c.rect(7, 10, 16, 13, RED)
    return c.img


def passive_pickup():
    c = Canvas()
    c.arc((3, 3, 20, 20), 180, 360, RED, 4)
    c.rect(3, 11, 6, 19, RED)
    c.rect(17, 11, 20, 19, RED)
    c.rect(3, 16, 6, 20, STEEL)
    c.rect(17, 16, 20, 20, STEEL)
    return c.img


ICONS = {
    # WeaponDefs.Module: RICOCHET, PIERCE, SPLIT, DETONATOR, TWIN, CHAIN
    "card_mod_0": ricochet,
    "card_mod_1": pierce,
    "card_mod_2": split,
    "card_mod_3": detonator,
    "card_mod_4": twin,
    "card_mod_5": chain,
    # WeaponDefs.Ammo: STANDARD, EXPANSIVE, INCENDIARY, CRYO
    "card_ammo_0": ammo_standard,
    "card_ammo_1": ammo_expansive,
    "card_ammo_2": ammo_incendiary,
    "card_ammo_3": ammo_cryo,
    # WeaponDefs.Passive: DAMAGE, FIRE_RATE, RELOAD, SPEED, HP, PICKUP
    "card_pas_0": passive_damage,
    "card_pas_1": passive_fire_rate,
    "card_pas_2": passive_reload,
    "card_pas_3": passive_speed,
    "card_pas_4": passive_hp,
    "card_pas_5": passive_pickup,
}


def preview(images, path):
    cell = 26 * 4 + 16
    cols = 6
    sheet = Image.new("RGB", (cols * cell, ((len(images) + cols - 1) // cols) * (cell + 12)), (28, 26, 26))
    draw = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(images):
        x, y = (i % cols) * cell, (i // cols) * (cell + 12)
        draw.text((x + 4, y + 1), name[5:], fill=(211, 213, 206))
        big = img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST)
        sheet.paste(big, (x + 8, y + 12), big)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", metavar="DIR", help="куда писать вместо art/")
    parser.add_argument("--preview", metavar="PNG", help="лист иконок на тёмном фоне")
    args = parser.parse_args(argv)
    out = os.path.abspath(args.out) if args.out else OUT
    os.makedirs(out, exist_ok=True)
    images = []
    for name, fn in ICONS.items():
        img = outlined(fn())
        img.save(os.path.join(out, name + ".png"))
        images.append((name, img))
        print("%s.png: %dx%d RGBA" % (name, *img.size))
    print("art ->", out)
    if args.preview:
        preview(images, args.preview)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
