"""Пиксельные знаки и снимки разведки C5. Только локальный арт, постоянный seed.

Запуск: python tools/gen_art_ops.py. Лист пиктограмм — reports/c5_icons.png (×4).
"""
from pathlib import Path

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
    # Прицел и пересекающий его штурмовой ствол.
    d.rectangle((5, 3, 18, 18), outline=SHADOW, width=2)
    d.line((12, 0, 12, 7), STEEL, 2)
    d.line((12, 16, 12, 23), STEEL, 2)
    d.line((0, 11, 7, 11), STEEL, 2)
    d.line((17, 11, 23, 11), STEEL, 2)
    d.polygon([(4, 19), (6, 21), (19, 8), (17, 6)], fill=LIGHT)
    d.polygon([(10, 15), (13, 18), (15, 16), (12, 13)], fill=OLIVE)
    d.rectangle((4, 19, 7, 22), fill=SHADOW)
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
    im, d = canvas((160, 64))
    d.rectangle((0, 0, 159, 63), fill=ga.hexc("222b2e"))
    # Крупные спокойные пятна. Свет сверху-слева, никакого шумового ковра.
    d.rectangle((0, 31, 159, 63), fill=ga.hexc("3f4640"))
    d.polygon([(0, 32), (20, 21), (42, 29), (73, 19), (103, 29), (127, 23), (159, 32)], fill=ga.hexc("303a3b"))

    def building(x, y, w, h, tone=SHADOW, windows=True):
        d.rectangle((x, y, x + w, y + h), fill=tone)
        d.rectangle((x, y, x + w, y + 2), fill=ga.mix(tone, STEEL, .35))
        d.rectangle((x + w - 3, y + 2, x + w, y + h), fill=ga.darker(tone, .65))
        if windows:
            for xx in range(x + 4, x + w - 4, 8):
                for yy in range(y + 6, y + h - 2, 8):
                    d.rectangle((xx, yy, xx + 2, yy + 2), fill=ga.hexc("929079") if (xx + yy) % 5 == 0 else INK)

    if region in ("west_europe", "east_asia"):
        if region == "east_asia":
            for x, y, w, h in [(2, 12, 22, 28), (26, 4, 20, 38), (48, 15, 28, 31), (80, 7, 20, 35), (104, 17, 26, 31), (136, 2, 24, 44)]:
                building(x, y, w, h)
            d.rectangle((2, 23, 15, 26), fill=RUST)
        else:
            for x, y, w, h in [(-3, 14, 30, 32), (31, 19, 27, 27), (65, 9, 34, 38), (110, 18, 27, 30), (142, 10, 23, 38)]:
                building(x, y, w, h)
                d.polygon([(x - 2, y), (x + w // 2, y - 9), (x + w + 2, y)], fill=ga.hexc("5d4e48"))
        d.polygon([(67, 43), (90, 43), (119, 63), (34, 63)], fill=INK)
        d.line((77, 48, 74, 63), fill=OLIVE, width=2)
    elif region == "siberia":
        d.polygon([(0, 22), (31, 5), (53, 27), (89, 11), (126, 29), (159, 14), (159, 64), (0, 64)], fill=ga.hexc("8a9694"))
        building(21, 23, 99, 27, ga.hexc("64716f"))
        building(119, 31, 22, 23, SHADOW, False)
        d.rectangle((24, 21, 122, 24), fill=LIGHT)
        d.rectangle((53, 31, 61, 46), fill=INK)
        d.line((138, 8, 138, 36), STEEL)
        d.line((132, 15, 144, 15), STEEL)
        for x in [4, 12, 149]:
            d.polygon([(x, 24), (x - 5, 44), (x + 5, 44)], fill=SHADOW)
    elif region == "middle_east":
        building(12, 32, 73, 20, ga.hexc("615b4d"), False)
        for x, h in [(23, 25), (47, 36), (70, 19)]:
            building(x, 32 - h, 7, h, SHADOW, False)
        for x in [101, 126]:
            d.ellipse((x, 31, x + 20, 39), fill=STEEL)
            d.rectangle((x, 35, x + 20, 52), fill=ga.hexc("63675e"))
            d.line((x + 2, 36, x + 2, 49), fill=STEEL)
        d.line([(4, 55), (94, 55), (94, 46), (157, 46)], OLIVE, 3)
    elif region == "north_africa":
        d.rectangle((0, 30, 159, 63), fill=ga.hexc("82745b"))
        d.polygon([(0, 38), (38, 27), (90, 36), (159, 29), (159, 44), (0, 52)], fill=ga.hexc("6b624f"))
        building(85, 27, 31, 19, ga.hexc("9e8e70"), False)
        building(113, 14, 10, 32, SHADOW, False)
        d.rectangle((111, 12, 126, 16), fill=STEEL)
        for x in range(7, 160, 17):
            d.line((x, 38, x, 61), fill=INK)
        d.line((0, 43, 159, 43), SHADOW)
        d.line((0, 51, 159, 51), SHADOW)
    elif region == "north_america":
        d.polygon([(71, 29), (88, 29), (149, 63), (7, 63)], fill=ga.hexc("252a2a"))
        d.line((77, 36, 60, 63), LIGHT, 1)
        d.line((84, 36, 105, 63), LIGHT, 1)
        d.rectangle((13, 24, 137, 28), fill=SHADOW)
        for x in [25, 123]:
            d.rectangle((x, 28, x + 4, 47), fill=SHADOW)
        d.rectangle((86, 15, 111, 26), fill=OLIVE)
        d.line((89, 18, 106, 18), STEEL)
        building(130, 33, 28, 17, SHADOW, False)
    elif region == "south_asia":
        building(11, 14, 104, 24, ga.hexc("626357"))
        d.polygon([(7, 13), (61, 5), (120, 13)], fill=SHADOW)
        d.polygon([(54, 37), (72, 37), (103, 64), (35, 64)], fill=INK)
        for x in [54, 70]:
            d.line((x, 39, x + (-10 if x == 54 else 18), 63), STEEL)
        for x in [9, 122, 141]:
            d.rectangle((x, 43, x + 14, 56), fill=OLIVE)
            d.line((x + 2, 45, x + 12, 45), STEEL)
    else:
        building(104, 25, 35, 24, SHADOW, False)
        d.polygon([(102, 25), (121, 16), (142, 25)], fill=ga.hexc("56594b"))
        for x in [10, 28, 47]:
            d.line((x, 22, x + 8, 47), INK, 2)
            d.line((x + 11, 22, x - 3, 47), INK, 2)
        for y in [46, 53]:
            for x in range(60 - (y - 46), 153, 12):
                d.rectangle((x, y, x + 11, y + 5), fill=OLIVE)
                d.line((x + 1, y, x + 10, y), STEEL)
        d.line((1, 32, 59, 30), SHADOW)
    # Несколько выбоин вместо равномерного процедурного зерна.
    for i in range(18):
        x = int((ga.hnoise(i, 5, 51) + 1) * 79)
        y = 49 + i % 14
        d.line((x, y, x + 2 + i % 3, y), fill=ga.hexc("303831"))
    return im


def generate():
    icons = {"clearance": clearance(), "nest": hive(), "runner_surge": enemy(4),
             "elite_hunt": enemy(2), "acid_rain": enemy(6), "hardened_boss": boss(),
             "blood_frenzy": frenzy(), "resource_cache": supply(),
             "infection_down": arrow(), "infection_up": arrow(True), "neighbors": arrow(neighbors=True),
             "threat": threat(), "dispatcher": dispatcher()}
    for name, im in icons.items():
        im.save(OUT / f"ops_{name}.png")
    for region in REGIONS:
        reconnaissance(region).save(OUT / f"ops_region_{region}.png")
    # Лист ×4: отдельно видны и знак, и характер каждого разведывательного кадра.
    sheet = Image.new("RGB", (768, 418), INK)
    sd = ImageDraw.Draw(sheet)
    samples = dict(icons)
    for name in ("hud_dna", "hud_crate"):
        samples[name] = Image.open(OUT / f"{name}.png").convert("RGBA")
    for i, (name, im) in enumerate(samples.items()):
        x, y = 16 + i % 6 * 126, 16 + i // 6 * 116
        sheet.paste(im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST), (x, y), im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST))
        sd.text((x, y + (132 if name == "dispatcher" else 99)), name, fill=STEEL, font=ImageFont.load_default(size=10))
    sheet.save(ROOT / "design/tasks/reports/c5_icons.png")
    # Полные кадры ×4, без уменьшения для листа.
    frames = Image.new("RGB", (1280, 4 * 280), INK)
    fd = ImageDraw.Draw(frames)
    for i, region in enumerate(REGIONS):
        x, y = i % 2 * 640, i // 2 * 280
        frames.paste(reconnaissance(region).resize((640, 256), Image.Resampling.NEAREST), (x, y))
        fd.text((x + 8, y + 259), region, fill=STEEL)
    frames.save(ROOT / "design/tasks/reports/c5_recon.png")
    print(f"OPSART icons={len(icons)} regions={len(REGIONS)} seed=20261018 preview=c5_icons.png x4")


if __name__ == "__main__":
    generate()
