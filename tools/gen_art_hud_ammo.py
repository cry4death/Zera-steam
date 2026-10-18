"""Патроны боевого HUD (U3). Запуск: python tools/gen_art_hud_ammo.py [--out DIR] [--preview PNG].

Пишет в art/ hud_round_<вид>.png: по одному листу на вид патрона. В листе размеры
(ярусы) идут сверху вниз; внутри яруса слева — тело патрона в своих цветах, справа — маска
наконечника (белая, в HUD красится цветом типа патронов: обычные, экспансивные, зажигательные, крио,
редкие — с синим отливом). 1 пиксель арта = 1 «игровой» пиксель HUD.

Ярусы нужны для магазинов разной ёмкости: на 6 дробин — крупная гильза, на 71 патрон ППШ — тонкая
чёрточка. Таблица TIERS (w, h) должна совпадать с HudRounds.TIERS в scripts/hud_rounds.gd.
Зависимость: Pillow.
"""

import argparse
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(ROOT, "..", "art"))

# цвета тела; 'T' и 'u' — маска наконечника (светлая и затенённая), '.' — прозрачно
BODY = {
    "H": (238, 208, 132), "B": (208, 162, 80), "D": (142, 102, 48), "R": (96, 94, 98),
    "S": (226, 92, 74), "E": (192, 54, 46), "Q": (118, 30, 30),
    "G": (132, 140, 152), "K": (86, 94, 106), "Z": (48, 54, 64),
    "o": (134, 152, 88), "O": (100, 118, 66), "p": (62, 74, 42),
}
TIP = {"T": (255, 255, 255), "u": (168, 168, 168)}

# вид → ярусы от крупного к мелкому; каждый ярус — строки рисунка
ROUNDS = {
    "rifle": [
        [".T.", "TTu", "TTu", "HBD", "HBD", "HBD", "HBD", "HBD", "RRR"],
        [".T.", "TTu", "HBD", "HBD", "HBD", "HBD", "RRR"],
        ["Tu", "Tu", "HD", "HD", "HD", "RR"],
        ["T", "B", "B", "R"],
    ],
    "pistol": [
        [".TTT.", "TTTTu", "TTTTu", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "DDDDD", "RRRRR"],
        [".T.", "TTu", "HBD", "HBD", "HBD", "RRR"],
        ["Tu", "HD", "HD", "HD", "RR"],
        ["T", "B", "B", "R"],
        ["T", "B", "R"],
    ],
    "shell": [
        [".TTTT.", "TTTTTu", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "SEEEEQ", "HBBBBD", "HBBBBD", "HBBBBD", "HBBBBD", "RRRRRR"],
        [".TT.", "SEEQ", "SEEQ", "SEEQ", "SEEQ", "SEEQ", "HBBD", "HBBD", "RRRR"],
        [".T.", "SEQ", "SEQ", "SEQ", "HBD", "HBD", "RRR"],
        ["Tu", "SQ", "SQ", "HD", "RR"],
    ],
    "revolver": [
        [".TTT.", "TTTTu", "TTTTu", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "HBBBD", "DDDDD", "RRRRR"],
        [".TT.", "TTTu", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "RRRR"],
        [".T.", "TTu", "HBD", "HBD", "HBD", "RRR"],
    ],
    "sniper": [
        [".TT.", ".TT.", "TTTu", "TTTu", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "HBBD", "DDDD", "RRRR"],
        [".T.", ".T.", "TTu", "TTu", "HBD", "HBD", "HBD", "HBD", "HBD", "HBD", "HBD", "RRR"],
        ["Tu", "Tu", "HD", "HD", "HD", "HD", "HD", "RR"],
    ],
    "rail": [
        ["..RR..", ".RRRR.", "GKKKKZ", "GKKKKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKTuKZ", "GKKKKZ", "GKKKKZ", ".RRRR.", "..RR.."],
        [".RR.", "GKKZ", "GTuZ", "GTuZ", "GTuZ", "GTuZ", "GTuZ", "GKKZ", "GKKZ", ".RR."],
        [".R.", "GKZ", "GTZ", "GTZ", "GTZ", "GKZ", "GKZ", ".R."],
    ],
    "grenade": [
        ["..TT..", ".TTTT.", "TTTTTu", "TTTTTu", "TTTTTu", "oOOOOp", "oOOOOp", "oOOOOp", "ZZZZZZ", "oOOOOp", "oOOOOp", "oOOOOp", "HBBBBD", "HBBBBD", "DDDDDD", "RRRRRR"],
        [".TT.", "TTTu", "TTTu", "oOOp", "oOOp", "ZZZZ", "oOOp", "HBBD", "RRRR"],
        [".T.", "TTu", "TTu", "oOp", "ZZZ", "HBD", "RRR"],
    ],
}


def tier_size(rows):
    return len(rows[0]), len(rows)


def render(tiers):
    """Лист вида: ярусы друг под другом, тело слева, маска справа."""
    width = max(tier_size(t)[0] for t in tiers) * 2
    height = sum(tier_size(t)[1] for t in tiers)
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = img.load()
    y0 = 0
    for rows in tiers:
        w, h = tier_size(rows)
        for y, row in enumerate(rows):
            assert len(row) == w, row
            for x, ch in enumerate(row):
                if ch in BODY:
                    px[x, y0 + y] = BODY[ch] + (255,)
                elif ch in TIP:
                    px[w + x, y0 + y] = TIP[ch] + (255,)
        y0 += h
    return img


def preview(images, path):
    cell_w = 150
    sheet = Image.new("RGB", (cell_w * len(images), 150), (46, 48, 52))
    draw = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(images):
        draw.text((i * cell_w + 4, 2), name[10:], fill=(211, 213, 206))
        big = img.resize((img.width * 6, img.height * 6), Image.Resampling.NEAREST)
        sheet.paste(big, (i * cell_w + 8, 18), big)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", metavar="DIR", help="куда писать вместо art/")
    parser.add_argument("--preview", metavar="PNG", help="лист патронов на сером фоне")
    args = parser.parse_args(argv)
    out = os.path.abspath(args.out) if args.out else OUT
    os.makedirs(out, exist_ok=True)
    images = []
    for kind, tiers in ROUNDS.items():
        img = render(tiers)
        name = "hud_round_" + kind
        img.save(os.path.join(out, name + ".png"))
        images.append((name, img))
        print("%s.png: %dx%d RGBA, ярусов %d" % (name, *img.size, len(tiers)))
    print("art ->", out)
    if args.preview:
        preview(images, args.preview)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
