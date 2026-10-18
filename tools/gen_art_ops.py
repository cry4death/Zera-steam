"""Пиксельные знаки и снимки разведки C5. Только локальный арт, постоянный seed.

Запуск: python tools/gen_art_ops.py. Лист пиктограмм — reports/c5b_icons.png (×4).
"""
from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageFont
import gen_art as ga

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art"
INK = (13, 17, 18)
STEEL = ga.hexc("a3aca7")
SHADOW = ga.hexc("48524e")
LIGHT = ga.hexc("d3d0b7")
OLIVE = ga.hexc("778061")
RUST = ga.hexc("aa6653")
PURPLE = ga.hexc("845065")


def canvas(size=(24, 24)):
    im = Image.new("RGBA", size)
    return im, ImageDraw.Draw(im)


def clearance():
    im, d = canvas()
    # Череп заражённого в четырёх раздельных скобах прицела.
    for pts in [[(1, 7), (1, 1), (7, 1)], [(17, 1), (22, 1), (22, 7)],
                [(1, 17), (1, 22), (7, 22)], [(17, 22), (22, 22), (22, 17)]]:
        d.line(pts, STEEL, 2)
    d.polygon([(8, 5), (15, 5), (18, 8), (18, 13), (15, 15), (15, 19),
               (8, 19), (8, 15), (5, 13), (5, 9)], fill=OLIVE)
    d.line([(6, 10), (7, 7), (9, 6), (14, 6)], LIGHT, 1)
    d.rectangle((7, 10, 10, 12), fill=INK)
    d.rectangle((13, 10, 16, 12), fill=INK)
    d.polygon([(11, 13), (10, 15), (12, 15)], fill=INK)
    d.line((10, 17, 10, 19), INK)
    d.line((13, 17, 13, 19), INK)
    return im


def journal():
    im, d = canvas()
    d.polygon([(4, 2), (19, 2), (21, 4), (21, 22), (4, 22), (2, 20), (2, 4)], fill=SHADOW)
    d.rectangle((5, 2, 18, 20), fill=OLIVE)
    d.line((6, 3, 17, 3), LIGHT)
    d.line((5, 4, 5, 19), STEEL)
    d.line((7, 21, 19, 21), STEEL)
    for y in (7, 11, 15):
        d.line((9, y, 15 if y == 15 else 17, y), LIGHT)
    for y in (5, 12, 18):
        d.line((1, y, 5, y), STEEL)
    return im


def hive():
    im, d = canvas()
    # Рваная органическая масса и три открытые камеры.
    d.polygon([(2, 19), (4, 9), (8, 7), (10, 2), (15, 4), (17, 9), (21, 12), (22, 21), (14, 23), (7, 21)], fill=ga.hexc("49303d"))
    d.line([(3, 17), (5, 9), (9, 8), (11, 3), (14, 5)], fill=PURPLE, width=2)
    for x, y in [(10, 9), (6, 16), (16, 17)]:
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=INK, outline=PURPLE)
        d.point((x - 1, y - 2), fill=LIGHT)
    return im


def enemy(variant):
    # Тот же кадр, что у врага в игре; не новый условный человечек.
    atlas = Image.open(OUT / "zombie_atlas.png").convert("RGBA")
    sprite = atlas.crop((0, variant * 4 * 48, 48, (variant * 4 + 1) * 48))
    bbox = sprite.getbbox()
    if bbox:
        sprite = sprite.crop(bbox)
    sprite.thumbnail((20, 20), Image.Resampling.NEAREST)
    im, d = canvas()
    im.alpha_composite(sprite, (2, 2))
    if variant == 4:
        d.line([(0, 17), (4, 17)], STEEL, 1)
        d.line([(0, 20), (7, 20)], STEEL, 1)
    elif variant == 6:
        d.polygon([(18, 16), (21, 11), (23, 17), (22, 20), (19, 20)], fill=OLIVE)
    else:
        d.polygon([(18, 1), (23, 1), (22, 8), (20, 10), (18, 7)], fill=LIGHT)
    return im


def boss():
    src = Image.open(OUT / "boss.png").convert("RGBA")
    src = src.crop((0, 0, src.width // 5, src.height // 2))
    if src.getbbox():
        src = src.crop(src.getbbox())
    src.thumbnail((22, 21), Image.Resampling.NEAREST)
    im, d = canvas()
    im.alpha_composite(src, ((24 - src.width) // 2, 1))
    d.polygon([(15, 12), (22, 12), (22, 19), (19, 23), (15, 20)], fill=SHADOW, outline=STEEL)
    return im


def frenzy():
    im, d = canvas()
    d.polygon([(12, 1), (3, 14), (3, 19), (8, 23), (16, 23), (21, 19), (21, 14)], fill=RUST)
    d.line([(8, 10), (5, 15), (5, 18)], fill=LIGHT, width=2)
    d.line((12, 9, 12, 16), fill=INK, width=2)
    d.rectangle((11, 19, 13, 20), fill=INK)
    return im


def supply():
    src = Image.open(OUT / "military_crate.png").convert("RGBA") if (OUT / "military_crate.png").exists() else Image.open(OUT / "hud_crate.png").convert("RGBA")
    src.thumbnail((22, 19), Image.Resampling.NEAREST)
    im, _ = canvas()
    im.alpha_composite(src, ((24 - src.width) // 2, (24 - src.height) // 2))
    return im


def arrow(up=False, neighbors=False):
    im, d = canvas()
    if neighbors:
        for x, y in [(3, 5), (19, 4), (4, 19), (20, 19)]:
            d.line((12, 12, x, y), SHADOW, 1)
            d.rectangle((x - 2, y - 2, x + 2, y + 2), outline=STEEL)
    pts = [(9, 3), (15, 3), (15, 13), (20, 13), (12, 22), (4, 13), (9, 13)]
    if up:
        pts = [(x, 24 - y) for x, y in pts]
    d.polygon(pts, fill=RUST if up else OLIVE)
    d.line([(9, 4 if not up else 20), (9, 13 if not up else 11)], fill=LIGHT, width=1)
    return im


def threat():
    im, d = canvas((10, 12))
    d.polygon([(2, 0), (7, 0), (9, 3), (9, 7), (7, 8), (7, 11), (2, 11), (2, 8), (0, 7), (0, 3)], fill=LIGHT)
    d.rectangle((1, 3, 3, 5), fill=INK)
    d.rectangle((6, 3, 8, 5), fill=INK)
    d.point((4, 7), INK)
    d.line((4, 9, 4, 11), INK)
    return im


def dispatcher():
    im, d = canvas((32, 32))
    d.polygon([(3, 32), (5, 26), (12, 23), (21, 23), (27, 27), (29, 32)], fill=SHADOW)
    d.polygon([(11, 7), (23, 7), (24, 17), (21, 24), (14, 24), (10, 18)], fill=ga.hexc("9d8b73"))
    d.polygon([(11, 8), (14, 5), (23, 7), (24, 18), (21, 22), (20, 12)], fill=ga.hexc("695e50"))
    d.polygon([(8, 8), (10, 3), (21, 2), (26, 7), (25, 10), (9, 10)], fill=OLIVE)
    d.line((10, 5, 21, 4), fill=STEEL)
    d.line((13, 13, 16, 13), INK)
    d.line((20, 13, 22, 13), INK)
    d.line((16, 20, 20, 20), INK)
    d.line([(7, 15), (7, 7), (12, 3), (22, 3), (27, 8), (27, 16)], fill=STEEL, width=2)
    d.rectangle((6, 12, 9, 19), fill=INK)
    d.rectangle((25, 12, 28, 19), fill=INK)
    d.line([(27, 19), (24, 23), (20, 23)], fill=STEEL)
    d.rectangle((18, 22, 21, 24), fill=INK)
    d.line((12, 26, 16, 31), fill=OLIVE, width=2)
    return im


REGIONS = ["east_europe", "west_europe", "siberia", "middle_east", "north_africa", "east_asia", "north_america", "south_asia"]


def reconnaissance(region):
    """Три тональных плана; детали привязаны к месту, а не к шумовому ковру."""
    rng = random.Random(20261018 + REGIONS.index(region) * 101)
    im, d = canvas((160, 64))
    sky = ga.hexc("343e40")
    far = ga.hexc("424c4b")
    ground = ga.hexc("353c35")
    dark = ga.hexc("1d2726")
    if region in ("middle_east", "north_africa"):
        sky, far, ground = map(ga.hexc, ("454744", "56564b", "5d5745"))
    elif region == "siberia":
        sky, far, ground = map(ga.hexc, ("424f54", "5b6869", "77847f"))
    d.rectangle((0, 0, 159, 63), fill=sky)
    # Рваная дальняя гряда уходит в воздушную перспективу.
    ridge = [(x, rng.randint(22, 30)) for x in range(-8, 170, 7)]
    d.polygon(ridge + [(169, 64), (-8, 64)], fill=far)
    if region not in ("north_africa", "siberia"):
        for x in range(-6, 165, 9):
            h = rng.randint(4, 17)
            d.rectangle((x, 30-h, x+rng.randint(4, 8), 35), fill=ga.mix(far, sky, .28))
    d.polygon([(0, 39), (27, 37), (48, 39), (87, 35), (119, 38), (159, 34),
               (159, 63), (0, 63)], fill=ground)

    def building(x, y, w, h, tone=SHADOW, roof=False):
        # Обвал угла, уступы крыши и затенённый торец.
        top = [(x, y+2), (x+3, y+2), (x+3, y), (x+w-7, y),
               (x+w-7, y+3), (x+w-4, y+1), (x+w, y+4)]
        d.polygon(top + [(x+w, y+h), (x, y+h)], fill=tone)
        d.polygon([(x+w-4, y+4), (x+w, y+4), (x+w, y+h), (x+w-4, y+h)], fill=ga.darker(tone, .66))
        d.line(top[:4], ga.mix(tone, STEEL, .32))
        for xx in range(x+4, x+w-4, 6):
            for yy in range(y+7, y+h-2, 7):
                if rng.random() < .78:
                    d.rectangle((xx, yy, xx+1, yy+2), fill=ga.hexc("8b8264") if rng.random() < .09 else ga.darker(tone, .47))
        if w > 19 and rng.random() < .65:
            cx, cy = x+rng.randint(8, w-7), y+rng.randint(5, 9)
            d.polygon([(cx, cy), (cx+3, cy+3), (cx+1, cy+7),
                       (cx+2, min(y+h, cy+12)), (cx-2, min(y+h, cy+10)),
                       (cx-1, cy+5)], fill=ga.darker(tone, .55))
        if roof:
            d.polygon([(x-2, y+2), (x+w//2-3, y-6), (x+w+1, y+4),
                       (x+w-7, y+3), (x+w-11, y+1)], fill=ga.hexc("5d5148"))

    def smoke(x, y, h=23, distant=False):
        # Ветер сносит ступенчатые пятна дыма вправо, без blur/glow.
        tone = ga.mix(sky, dark, .27 if distant else .55)
        pts = [(x-2, y), (x-3, y-6), (x+1, y-10), (x, y-15),
               (x+5, y-h), (x+12, y-h-2), (x+17, y-h+1),
               (x+11, y-h+4), (x+8, y-12), (x+5, y-8), (x+3, y)]
        d.polygon(pts, fill=tone)
        d.polygon([(x+1, y-10), (x+5, y-h+1), (x+12, y-h-1),
                   (x+8, y-h+5), (x+5, y-9)], fill=ga.mix(tone, sky, .4))

    def fire(x, y, small=False):
        d.line((x-4, y+1, x+6, y+1), dark, 2)
        d.polygon([(x-3, y), (x-2, y-4), (x, y-3), (x+1, y-7 if not small else y-4),
                   (x+3, y-2), (x+5, y-4), (x+4, y)], fill=ga.hexc("935d40"))
        d.line((x, y-2, x+2, y), fill=ga.hexc("bd9460"))

    def wreck(x, y, truck=False):
        d.polygon([(x-3, y+2), (x+21, y+2), (x+28, y+5), (x+3, y+5)], fill=ga.darker(ground, .65))
        d.polygon([(x, y-1), (x+3, y-6), (x+10, y-7), (x+15, y-3),
                   (x+21, y-2), (x+20, y+2), (x, y+2)], fill=ga.hexc("50574a"))
        if truck:
            d.polygon([(x+11, y-3), (x+11, y-10), (x+23, y-9), (x+24, y+1), (x+16, y+1)], fill=ga.hexc("4b4c3c"))
            d.line((x+12, y-10, x+21, y-9), ga.hexc("78745b"))
        d.polygon([(x+4, y-5), (x+8, y-6), (x+10, y-3), (x+3, y-3)], fill=dark)
        d.line((x+1, y-1, x+10, y-1), ga.hexc("777b64"))
        for xx in (x+4, x+17):
            d.rectangle((xx, y+1, xx+3, y+3), fill=INK)
        d.line((x+13, y-2, x+16, y), ga.hexc("805744"))
        d.line((x+20, y-2, x+24, y-4), dark)

    def horde(x, y, count=9):
        xx = x
        for i in range(count):
            xx += rng.choice((3, 4, 6))
            yy = y+rng.randint(-2, 2)
            d.rectangle((xx, yy-7, xx+1, yy-6), fill=dark)
            d.line((xx, yy-5, xx-1, yy-2), dark, 2)
            d.line((xx, yy-4, xx+2, yy-3), dark)
            d.line((xx-1, yy-2, xx-2, yy), dark)
            d.line((xx, yy-2, xx+1, yy+1), dark)

    if region in ("west_europe", "east_asia"):
        smoke(105, 29, 24, True)
        if region == "west_europe":
            blocks = [(-5, 20, 27, 28), (27, 24, 21, 21), (51, 15, 25, 31),
                      (100, 21, 23, 26), (132, 10, 31, 44)]
        else:
            blocks = [(-6, 12, 26, 37), (24, 5, 18, 38), (47, 19, 23, 25),
                      (105, 10, 19, 37), (132, 2, 30, 53)]
        for x, y, w, h in blocks:
            building(x, y, w, h, ga.hexc("4c5550"), region == "west_europe")
        d.polygon([(77, 39), (91, 39), (133, 63), (32, 63)], fill=ga.hexc("272f2d"))
        for yy, xx in [(45, 82), (52, 80), (61, 76)]:
            d.line((xx, yy, xx-1, yy+2), ga.hexc("777864"))
        horde(74, 44, 7)
        wreck(106, 55)
        smoke(113, 49, 28)
        fire(113, 49)
        d.polygon([(0, 57), (9, 54), (16, 55), (19, 60), (31, 60), (34, 64), (0, 64)], fill=dark)
    elif region == "siberia":
        d.polygon([(0, 28), (24, 10), (31, 14), (37, 12), (58, 31), (93, 18),
                   (104, 24), (121, 21), (159, 34)], fill=ga.hexc("6a797b"))
        smoke(98, 32, 24, True)
        building(34, 27, 73, 20, ga.hexc("5d6a65"))
        d.line([(35, 27), (51, 27), (52, 25), (77, 26), (79, 28), (99, 27)], ga.hexc("a6ada0"), 2)
        building(109, 34, 25, 17, ga.hexc("4a5955"))
        d.rectangle((63, 36, 70, 48), fill=dark)
        d.line((116, 15, 116, 35), SHADOW)
        d.line((111, 19, 120, 19), SHADOW)
        for x, y, h in [(4, 44, 25), (17, 47, 18), (146, 51, 24), (155, 55, 29)]:
            d.polygon([(x, y-h), (x-2, y-h+9), (x-1, y-h+9), (x-5, y-5),
                       (x-3, y-6), (x-7, y), (x+6, y), (x+3, y-8)], fill=dark)
        horde(73, 49, 7)
        wreck(24, 55, True)
        fire(105, 45, True)
        smoke(105, 42, 20)
    elif region == "middle_east":
        smoke(43, 31, 24, True)
        building(6, 32, 75, 18, ga.hexc("57594c"))
        for x, y, h in [(18, 16, 21), (38, 6, 29), (68, 23, 13)]:
            d.rectangle((x, y, x+5, y+h), fill=ga.hexc("424a44"))
            d.line((x, y, x+4, y), ga.hexc("777e6e"))
        for x, y in [(96, 34), (127, 31)]:
            d.ellipse((x, y-4, x+22, y+3), fill=ga.hexc("7f8270"))
            d.rectangle((x, y, x+22, y+17), fill=ga.hexc("606758"))
            d.rectangle((x+17, y+1, x+22, y+17), fill=ga.hexc("404c42"))
            d.line((x+2, y+2, x+2, y+14), ga.hexc("8b8e77"))
        d.line([(0, 57), (84, 57), (84, 49), (159, 49)], dark, 3)
        d.line([(0, 55), (82, 55), (82, 47), (159, 47)], ga.hexc("767c60"))
        horde(64, 46, 8)
        wreck(111, 59, True)
        smoke(123, 34, 30)
        fire(123, 35)
    elif region == "north_africa":
        d.polygon([(0, 39), (32, 29), (58, 34), (79, 32), (120, 42), (159, 36),
                   (159, 64), (0, 64)], fill=ga.hexc("776c52"))
        building(86, 30, 28, 17, ga.hexc("81775b"))
        building(116, 19, 10, 29, ga.hexc("5b6051"))
        d.polygon([(112, 19), (113, 16), (129, 16), (130, 20)], fill=ga.hexc("858770"))
        smoke(68, 39, 22, True)
        fire(68, 40, True)
        horde(43, 44, 8)
        # Провисшая сетка и разрыв периметра.
        for x in (3, 26, 51, 99, 128, 154):
            d.line((x, 40 if x < 60 else 43, x-1, 62), dark)
        for y in (45, 51):
            d.line([(0, y-2), (26, y), (50, y-1), (63, y+5)], SHADOW)
            d.line([(95, y+3), (101, y), (128, y+2), (159, y)], SHADOW)
        wreck(76, 58)
        d.polygon([(0, 61), (20, 58), (36, 60), (47, 64), (0, 64)], fill=ga.hexc("434638"))
    elif region == "north_america":
        smoke(121, 31, 24, True)
        d.polygon([(73, 30), (88, 30), (150, 64), (8, 64)], fill=ga.hexc("293130"))
        for yy in (39, 46, 57):
            d.line((79-(yy-34)//2, yy, 78-(yy-32)//2, yy+3), ga.hexc("8a8972"))
        d.line([(12, 26), (69, 26), (73, 29), (89, 29), (93, 25), (150, 25)], SHADOW, 4)
        d.line((13, 24, 67, 24), ga.hexc("70786a"))
        for x in (24, 127):
            d.polygon([(x, 28), (x+4, 28), (x+3, 47), (x-2, 49)], fill=dark)
        d.rectangle((94, 16, 117, 25), fill=ga.hexc("56654b"))
        d.line((97, 18, 109, 18), ga.hexc("93957a"))
        d.line((97, 21, 106, 21), ga.hexc("93957a"))
        building(141, 34, 23, 20, ga.hexc("4c554b"))
        horde(76, 38, 6)
        wreck(42, 57, True)
        wreck(101, 49)
        smoke(111, 47, 23)
        fire(111, 48)
        d.line([(3, 62), (22, 57), (31, 59), (29, 63)], dark, 2)
    elif region == "south_asia":
        smoke(124, 28, 24, True)
        building(16, 24, 100, 17, ga.hexc("606558"))
        d.polygon([(11, 26), (30, 18), (70, 17), (87, 21), (105, 20), (121, 27)], fill=ga.hexc("48564e"))
        d.line([(14, 25), (30, 18), (69, 17)], ga.hexc("798171"))
        d.polygon([(59, 38), (73, 38), (104, 64), (35, 64)], fill=ga.hexc("272f2c"))
        for x, end in [(60, 40), (71, 98)]:
            d.line((x, 40, end, 63), ga.hexc("848c7b"))
        for yy in (44, 49, 56, 63):
            d.line((59-(yy-40)//2, yy, 74+(yy-40), yy), ga.hexc("4d5344"))
        for x, y in [(2, 48), (17, 51), (114, 47), (137, 51)]:
            building(x, y-8, 18, 11, ga.hexc("59604b"))
            d.line((x+4, y-7, x+4, y+2), SHADOW)
        horde(72, 44, 8)
        wreck(104, 59, True)
        smoke(127, 46, 28)
        fire(127, 47)
    else:
        smoke(108, 34, 26, True)
        building(105, 27, 37, 20, ga.hexc("515a4c"), True)
        # Дальний лес и рваная насыпь за укреплениями.
        d.polygon([(0, 39), (13, 34), (21, 37), (34, 33), (47, 38), (60, 36),
                   (82, 43), (81, 50), (0, 50)], fill=ga.hexc("3d493c"))
        horde(65, 41, 10)
        fire(103, 44)
        smoke(103, 42, 27)
        wreck(116, 56, True)
        # Чехский ёж: три объёмные балки вокруг узла, третья уходит в глубину.
        for x, y, size in [(14, 54, 12), (40, 49, 9), (62, 47, 6)]:
            d.polygon([(x-size, y+3), (x-size+2, y+1), (x+size+8, y+5),
                       (x+size+4, y+7)], fill=ga.darker(ground, .65))
            d.line((x-3, y-4, x+size, y-9), dark, 3)
            d.line((x-3, y-5, x+size, y-10), SHADOW)
            d.line((x-size//2, y-size, x+size//2, y+3), dark, 4)
            d.line((x-size//2-1, y-size, x+size//2-1, y+2), ga.hexc("697466"))
            d.line((x+size//2, y-size+2, x-size//2, y+4), dark, 3)
            d.line((x+size//2-1, y-size+2, x-size//2-1, y+3), SHADOW)
            d.rectangle((x-2, y-5, x+1, y-2), fill=ga.hexc("737a65"))
            d.point((x, y-3), INK)
        # Мешки с неровными краями и смещёнными швами.
        for row, yy in enumerate((55, 60)):
            for x in range(73-row*5, 110, 9):
                d.polygon([(x, yy+1), (x+2, yy), (x+8, yy+1), (x+9, yy+4),
                           (x+1, yy+4)], fill=ga.hexc("616a4d"))
                d.line((x+2, yy, x+7, yy), ga.hexc("92967a"))
    # Направленные сколы на переднем плане, без общего зерна.
    for i in range(18):
        x, y = rng.randint(0, 157), rng.randint(51, 63)
        d.line((x, y, x+rng.randint(1, 4), y), ga.darker(ground, .77))
    return im


def generate():
    icons = {"clearance": clearance(), "journal": journal(), "nest": hive(), "runner_surge": enemy(4),
             "elite_hunt": enemy(2), "acid_rain": enemy(6), "hardened_boss": boss(),
             "blood_frenzy": frenzy(), "resource_cache": supply(),
             "infection_down": arrow(), "infection_up": arrow(True), "neighbors": arrow(neighbors=True),
             "threat": threat(), "dispatcher": dispatcher()}
    for name, im in icons.items():
        im.save(OUT / f"ops_{name}.png")
    for region in REGIONS:
        reconnaissance(region).save(OUT / f"ops_region_{region}.png")
    # Лист ×4: отдельно видны и знак, и характер каждого разведывательного кадра.
    sheet = Image.new("RGB", (768, 648), INK)
    sd = ImageDraw.Draw(sheet)
    samples = dict(icons)
    for name in ("hud_dna", "hud_crate"):
        samples[name] = Image.open(OUT / f"{name}.png").convert("RGBA")
    for i, (name, im) in enumerate(samples.items()):
        x, y = 16 + i % 4 * 192, 12 + i // 4 * 158
        sheet.paste(im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST), (x, y), im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST))
        sd.text((x, y + (132 if name == "dispatcher" else 99)), name, fill=STEEL, font=ImageFont.load_default(size=10))
    sheet.save(ROOT / "design/tasks/reports/c5b_icons.png")
    # Полные кадры ×4, без уменьшения для листа.
    frames = Image.new("RGB", (1280, 4 * 280), INK)
    fd = ImageDraw.Draw(frames)
    for i, region in enumerate(REGIONS):
        x, y = i % 2 * 640, i // 2 * 280
        frames.paste(reconnaissance(region).resize((640, 256), Image.Resampling.NEAREST), (x, y))
        fd.text((x + 8, y + 259), region, fill=STEEL)
    frames.save(ROOT / "design/tasks/reports/c5b_recon.png")
    print(f"OPSART icons={len(icons)} regions={len(REGIONS)} seed=20261018 preview=c5b_icons.png x4")


if __name__ == "__main__":
    generate()
