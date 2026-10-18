"""Иконки боевого HUD (H1). Запуск: python tools/gen_art_hud.py [--out DIR] [--preview PNG].

Пишет в art/ hud_*.png: белые силуэты с чёрной обводкой в 1 px. В HUD они красятся
через modulate; 1 пиксель арта = 1 «игровой» пиксель HUD (×3 на 1080p, ×2 на 720p).
Зависимость: Pillow.
"""

import argparse
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(ROOT, "..", "art"))

# '#' — белый пиксель, '.' — прозрачный; обводка добавляется автоматически.
ICONS = {
    "hud_star": [
        "..#..",
        "#####",
        ".###.",
        ".#.#.",
        "#...#",
    ],
    "hud_dash": [
        "##..##......",
        ".##..##.....",
        "..##..##....",
        "...##..##...",
        "....##..##..",
        "....##..##..",
        "...##..##...",
        "..##..##....",
        ".##..##.....",
        "##..##......",
    ],
    "hud_vest": [
        "##.....##",
        "###...###",
        "####.####",
        "#########",
        "#########",
        "#########",
        ".#######.",
        ".#######.",
        "..#####..",
    ],
    "hud_dna": [
        "##...##",
        ".##.##.",
        "..###..",
        "...#...",
        "..###..",
        ".##.##.",
        "##...##",
        ".##.##.",
        "..###..",
    ],
    "hud_arrow": [
        "#........",
        "###......",
        "#####....",
        "#######..",
        "#########",
        "#######..",
        "#####....",
        "###......",
        "#........",
    ],
    "hud_skull": [
        ".#######.",
        "#########",
        "#########",
        "##.###.##",
        "##.###.##",
        "#########",
        ".#######.",
        "..#.#.#..",
        "..#####..",
    ],
    "hud_container": [
        "#########",
        "#.......#",
        "#.#...#.#",
        "#..#.#..#",
        "#...#...#",
        "#..#.#..#",
        "#.#...#.#",
        "#.......#",
        "#########",
    ],
    "hud_crate": [
        "#########",
        "#########",
        ".........",
        "#########",
        "#########",
        "#########",
        "#########",
        "#########",
    ],
    "hud_part": [
        "....#....",
        "...###...",
        "..#####..",
        ".#######.",
        "#########",
        ".#######.",
        "..#####..",
        "...###...",
        "....#....",
    ],
    "hud_med": [
        "...###...",
        "...###...",
        "...###...",
        "#########",
        "#########",
        "#########",
        "...###...",
        "...###...",
        "...###...",
    ],
    "hud_coin": [
        "..###..",
        ".#####.",
        "#######",
        "#######",
        "#######",
        ".#####.",
        "..###..",
    ],
    "hud_bolt": [
        "....###",
        "...###.",
        "..###..",
        ".#####.",
        "...##..",
        "..##...",
        ".#.....",
    ],
    # U3: значки вместо слов — пассивки, модификаторы операции, события, серия
    "hud_drop": [
        "...#...",
        "...#...",
        "..###..",
        "..###..",
        ".#####.",
        "#######",
        "#######",
        ".#####.",
        "..###..",
    ],
    "hud_alarm": [
        "....#....",
        ".#..#..#.",
        "..#####..",
        ".#######.",
        ".#######.",
        "#########",
        "#########",
    ],
    "hud_flame": [
        "...#...",
        "...##..",
        "..###.#",
        ".#####.",
        "#######",
        "#######",
        ".#####.",
    ],
    "hud_clock": [
        "..###..",
        ".#...#.",
        "#..#..#",
        "#..#..#",
        "#..##.#",
        ".#...#.",
        "..###..",
    ],
    "hud_pas_damage": [
        "#..#..#",
        ".#.#.#.",
        "..###..",
        "#######",
        "..###..",
        ".#.#.#.",
        "#..#..#",
    ],
    "hud_pas_rate": [
        ".....#.",
        "...#.#.",
        ".#.#.#.",
        ".#.#.#.",
        ".#.#.#.",
        ".#.#.#.",
    ],
    "hud_pas_reload": [
        "..###..",
        ".#...#.",
        "#....##",
        "#...###",
        "#....#.",
        ".#.....",
        "..###..",
    ],
    "hud_pas_speed": [
        "...#...",
        "....#..",
        "#######",
        "....#..",
        "...#...",
    ],
    "hud_pas_pickup": [
        "..###..",
        ".#...#.",
        "#..#..#",
        "#.###.#",
        "#..#..#",
        ".#...#.",
        "..###..",
    ],
}


def render(rows):
    h, w = len(rows), len(rows[0])
    fill = [[rows[y][x] == "#" for x in range(w)] for y in range(h)]
    img = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    px = img.load()

    def solid(x, y):
        return 0 <= x < w and 0 <= y < h and fill[y][x]

    for y in range(-1, h + 1):
        for x in range(-1, w + 1):
            if solid(x, y):
                px[x + 1, y + 1] = (255, 255, 255, 255)
            elif any(solid(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                px[x + 1, y + 1] = (0, 0, 0, 215)
    return img


def preview(images, path):
    cell = 90
    sheet = Image.new("RGB", (6 * cell, ((len(images) + 5) // 6) * cell), (46, 48, 52))
    draw = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(images):
        x, y = (i % 6) * cell, (i // 6) * cell
        draw.text((x + 4, y + 2), name[4:], fill=(211, 213, 206))
        big = img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST)
        sheet.paste(big, (x + 8, y + 18), big)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", metavar="DIR", help="куда писать вместо art/")
    parser.add_argument("--preview", metavar="PNG", help="лист иконок на сером фоне")
    args = parser.parse_args(argv)
    out = os.path.abspath(args.out) if args.out else OUT
    os.makedirs(out, exist_ok=True)
    images = []
    for name, rows in ICONS.items():
        img = render(rows)
        img.save(os.path.join(out, name + ".png"))
        images.append((name, img))
        print("%s.png: %dx%d RGBA" % (name, *img.size))
    print("art ->", out)
    if args.preview:
        preview(images, args.preview)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
