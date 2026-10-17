"""Арт M6 (экран базы). Запуск рядом с gen_art.py: python tools/gen_art_m6.py.

Пишет в art/:
  base_bg.png                 1920x1080, фон казармы (бетон, койки, шкафы, ящики, кровь, свет ламп)
  (иконки стволов gun_<model>.png теперь рисует gen_art_guns.py, G7)
  base_crate_body/lid.png     оружейный ящик (вид спереди), крышка отдельно для анимации вскрытия
  base_crate_mil_body/lid.png военный ящик

--out DIR перенаправляет ga.OUT; --preview PNG собирает лист на сером фоне.
Импорт ничего не сохраняет. Зависимости: gen_art, gen_art_m4 (фаска plate), Pillow, numpy.
"""

import argparse
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import gen_art as ga
from gen_art_m4 import DARK_METAL, ENAMEL, OLIVE, RUST, STEEL, plate

BLACK = ga.ramp(ga.hexc("33373c"), spread=0.7)
WOOD = ga.ramp(ga.hexc("8a5a34"), spread=0.7)
DARK_WOOD = ga.ramp(ga.hexc("5c3a22"), spread=0.7)
BRASS = ga.ramp(ga.hexc("b8923f"), spread=0.7)
BLUE = ga.ramp(ga.hexc("4a8fe0"), spread=0.8)
ORANGE = ga.ramp(ga.hexc("e8832a"), spread=0.8)
HONEY = ga.ramp(ga.hexc("e0b030"), spread=0.7)
DRAB = ga.ramp(ga.hexc("5d6540"), spread=0.7)
MIL_STEEL = ga.ramp(ga.hexc("4d5560"), spread=0.7)
GOLD = ga.ramp(ga.hexc("e8b84a"), spread=0.75)
WARN_RED = ga.ramp(ga.hexc("a82a28"), spread=0.7)


# --- примитивы стволов --------------------------------------------------------------------

def box(cv, x0, y0, x1, y1, rmp, seed=1, bevel=0.5):
    plate(cv, x0, y0, x1, y1, rmp, seed, bevel=bevel)


def poly(cv, pts, rmp, seed=1, bias=0.0, tex=0.1):
    """Закрашенный многоугольник: свет сверху-слева, тёмный низ, зерно."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    y0, y1 = min(ys), max(ys)
    x0, x1 = min(xs), max(xs)
    for ny in range(int(y0 * cv.s) - 1, int(y1 * cv.s) + 2):
        for nx in range(int(x0 * cv.s) - 1, int(x1 * cv.s) + 2):
            x, y = (nx + 0.5) / cv.s, (ny + 0.5) / cv.s
            inside = False
            for (ax, ay), (bx, by) in zip(pts, pts[1:] + pts[:1]):
                if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
                    inside = not inside
            if not inside:
                continue
            v = (y - y0) / max(0.01, y1 - y0)
            u = (x - x0) / max(0.01, x1 - x0)
            sh = 0.5 - v * 0.95 - u * 0.12 + bias + ga.hnoise(nx, ny, seed) * tex
            cv.putn(nx, ny, ga.pick(rmp, sh))


def ring(cv, cx, cy, ro, ri, rmp, seed=1):
    cv.ellipse(cx, cy, ro, ro, rmp, tex=0.1, seed=seed,
               cond=lambda x, y: math.hypot(x - cx, y - cy) >= ri)


def holes(cv, x0, x1, y, dy, n, col=None):
    col = col or DARK_METAL[0]
    for i in range(n):
        cv.dot(x0 + (x1 - x0) * i / max(1, n - 1), y + dy * (i % 2) * 0.0, col)


def grip(cv, pts, rmp, seed):
    poly(cv, pts, rmp, seed)
    # насечка на рукояти
    (x0, y0), (x1, y1) = pts[0], pts[3]
    for k in range(3):
        t = 0.3 + k * 0.2
        ax, ay = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        cv.line(ax + 0.2, ay, ax + 2.6, ay, rmpdark(rmp))


def rmpdark(rmp):
    return rmp[0]


def finish(cv, k=0.3):
    cv.outline(k)
    img = cv.image()
    bbox = img.getbbox()
    return img.crop((max(0, bbox[0] - 1), max(0, bbox[1] - 1), min(img.width, bbox[2] + 1), min(img.height, bbox[3] + 1)))


def new():
    return ga.Canvas(62, 26)


# Спрайты стволов (gun_<model>.png) рисует tools/gen_art_guns.py (задача G7).


# --- ящики -------------------------------------------------------------------------------------

def crate_parts(military):
    """Тело и крышка ящика, вид спереди. Возвращает (body, lid) — RGBA-изображения."""
    shell = MIL_STEEL if military else OLIVE
    strap = BLACK if military else DARK_METAL
    body = ga.Canvas(66, 30)
    box(body, 1, 0.4, 65, 29.4, shell, 201, 0.9)
    for y in (7, 14, 21):
        body.line(2, y, 64, y, ga.darker(shell[1], 0.8))
        body.line(2, y + 0.6, 64, y + 0.6, shell[4])
    for x in (9, 56):
        box(body, x, 0.4, x + 3.2, 29.4, strap, 202 + x, 0.4)
        for y in (3, 15, 26.6):
            body.dot(x + 0.9, y, STEEL[4])
            body.dot(x + 2.4, y, STEEL[2])
    # трафарет: три патрона, у военного — звезда на жёлтой полосе
    if military:
        box(body, 14, 11.5, 52, 18.5, ga.ramp(ga.hexc("c9a33a"), spread=0.5), 210, 0.4)
        for i in range(10):
            x = 15 + i * 3.8
            poly(body, [(x, 18.4), (x + 1.9, 11.6), (x + 3.8, 11.6), (x + 1.9, 18.4)], BLACK, 211 + i, tex=0.02)
        star = []
        for k in range(10):
            r = 5.2 if k % 2 == 0 else 2.2
            a = -math.pi / 2 + k * math.pi / 5
            star.append((33 + math.cos(a) * r, 15 + math.sin(a) * r))
        poly(body, star, WARN_RED, 230, tex=0.04)
        box(body, 14, 23.4, 52, 25.4, ENAMEL, 231, 0.2)
    else:
        for i in range(3):
            x = 27 + i * 5
            box(body, x, 11, x + 3, 22, ENAMEL, 215 + i, 0.5)
            poly(body, [(x, 11), (x + 1.5, 8.6), (x + 3, 11)], BRASS, 218 + i, tex=0.02)
        box(body, 18, 24.6, 48, 26.0, ENAMEL, 221, 0.2)
    rng = random.Random(777 + military)
    for _ in range(14):
        body.dot(rng.uniform(3, 63), rng.uniform(2, 28), ga.darker(shell[2], 0.7))
    body.outline(0.32)
    lid = ga.Canvas(68, 12)
    box(lid, 0.4, 3.4, 67.6, 11.4, shell, 241, 0.9)
    box(lid, 1.6, 0.6, 66.4, 4.2, shell, 242, 0.7)
    for x in (9, 56):
        box(lid, x, 0.6, x + 3.2, 11.4, strap, 243 + x, 0.4)
    box(lid, 29, 8.4, 39, 12, STEEL, 244, 0.3)
    lid.dot(34, 10.4, DARK_METAL[0])
    for x in (4, 63):
        lid.dot(x, 7.4, STEEL[4])
        lid.dot(x + 0.5, 7.9, DARK_METAL[1])
    lid.outline(0.32)
    return finish_pad(body), finish_pad(lid)


def finish_pad(cv):
    return cv.image()


# --- фон ---------------------------------------------------------------------------------------

W, H = 1920, 1080


def fbm(rng, w, h, scales):
    out = np.zeros((h, w), dtype=np.float32)
    for sc, amp in scales:
        gw, gh = max(2, w // sc + 2), max(2, h // sc + 2)
        g = rng.standard_normal((gh, gw)).astype(np.float32)
        img = Image.fromarray(g).resize((w, h), Image.Resampling.BICUBIC)
        out += np.asarray(img, dtype=np.float32) * amp
    return out


def shadow(layer, box_, off=(14, 16), blur=9, alpha=0.55):
    """Тень прямоугольника/эллипса на отдельный слой L."""
    sh = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(sh)
    x0, y0, x1, y1 = box_
    d.rounded_rectangle((x0 + off[0], y0 + off[1], x1 + off[0], y1 + off[1]), 8, fill=int(255 * alpha))
    return sh.filter(ImageFilter.GaussianBlur(blur))


def background():
    rng = np.random.default_rng(6001)
    # бетонные плиты 192x192 со швами, у каждой свой тон
    slab = 192
    yy, xx = np.mgrid[0:H, 0:W]
    sx, sy = xx // slab, yy // slab
    tone = (np.sin(sx * 12.9898 + sy * 78.233) * 43758.5453) % 1.0
    base = np.array([64, 63, 62], dtype=np.float32)
    img = np.zeros((H, W, 3), dtype=np.float32) + base
    img *= (0.88 + tone[..., None] * 0.2)
    img *= 1.0 + fbm(rng, W, H, [(220, 0.035), (60, 0.03), (14, 0.02)])[..., None]
    img *= 1.0 + (rng.random((H, W), dtype=np.float32)[..., None] - 0.5) * 0.07
    # швы
    ex, ey = xx % slab, yy % slab
    seam = (ex < 3) | (ey < 3)
    hi = (ex == 3) | (ey == 3)
    img[seam] *= 0.5
    img[hi] *= 1.12
    # трещины и пятна
    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert("RGB")
    d = ImageDraw.Draw(pil)
    r = random.Random(60)
    for _ in range(22):
        x, y, a = r.uniform(0, W), r.uniform(0, H), r.uniform(0, math.tau)
        pts = [(x, y)]
        for _ in range(r.randint(14, 40)):
            a += r.uniform(-0.55, 0.55)
            x += math.cos(a) * r.uniform(4, 11)
            y += math.sin(a) * r.uniform(4, 11)
            pts.append((x, y))
        d.line(pts, fill=(28, 28, 29), width=2)
    pil = pil.convert("RGBA")

    # объекты сверху вниз: койки слева, шкафы сверху, ящики справа, бочки, стол
    layers = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadows = Image.new("L", (W, H), 0)

    def put(box_, draw_fn, off=(14, 16), blur=9, alpha=0.6):
        nonlocal shadows
        sh = shadow(None, box_, off, blur, alpha)
        shadows = Image.fromarray(np.maximum(np.asarray(shadows), np.asarray(sh)))
        draw_fn(ImageDraw.Draw(layers))

    # койки (вид сверху): рама, матрас, подушка, одеяло
    for i, y in enumerate((84, 248, 412, 576)):
        b = (24, y, 330, y + 140)

        def bunk(dr, b=b, i=i):
            x0, y0, x1, y1 = b
            dr.rectangle(b, fill=(46, 48, 50))
            dr.rectangle((x0 + 6, y0 + 6, x1 - 6, y1 - 6), fill=(74, 76, 70))
            dr.rectangle((x0 + 12, y0 + 12, x0 + 82, y1 - 12), fill=(138, 134, 118))
            dr.rectangle((x0 + 92, y0 + 10, x1 - 10, y1 - 10), fill=(84, 92, 62) if i % 2 == 0 else (92, 76, 62))
            for k in range(5):
                dr.line((x0 + 100 + k * 40, y0 + 12, x0 + 100 + k * 40, y1 - 12), fill=(0, 0, 0, 40), width=2)
            dr.line((x0 + 92, y0 + 10, x0 + 92, y1 - 10), fill=(40, 42, 30), width=3)
        put(b, bunk)
    # шкафы у верхней кромки: вид сверху — крышки с отбортовкой
    for i in range(9):
        x0 = 420 + i * 134
        b = (x0, 14, x0 + 118, 74)

        def locker(dr, b=b, i=i):
            dr.rectangle(b, fill=(62, 70, 74))
            dr.rectangle((b[0] + 4, b[1] + 4, b[2] - 4, b[3] - 4), fill=(78, 87, 91))
            dr.line((b[0] + 59, b[1] + 4, b[0] + 59, b[3] - 4), fill=(40, 46, 49), width=2)
            dr.rectangle((b[0] + 4, b[1] + 4, b[2] - 4, b[1] + 10), fill=(92, 102, 106))
        put(b, locker, off=(8, 14), blur=7)
    # ящики справа внизу
    for (x0, y0, w, h, col) in ((1660, 640, 190, 124, (88, 94, 60)), (1700, 790, 150, 110, (74, 80, 52)),
                                (1530, 760, 120, 120, (96, 76, 52)), (1740, 140, 150, 130, (80, 88, 58))):
        b = (x0, y0, x0 + w, y0 + h)

        def crate(dr, b=b, col=col):
            dr.rectangle(b, fill=tuple(int(c * 0.7) for c in col))
            dr.rectangle((b[0] + 6, b[1] + 6, b[2] - 6, b[3] - 6), fill=col)
            dr.line((b[0] + 6, b[1] + 6, b[2] - 6, b[3] - 6), fill=tuple(int(c * 0.6) for c in col), width=4)
            dr.line((b[0] + 6, b[3] - 6, b[2] - 6, b[1] + 6), fill=tuple(int(c * 0.6) for c in col), width=4)
        put(b, crate)
    # бочки
    for cx, cy in ((90, 930), (190, 990), (1610, 960), (1470, 640)):
        b = (cx - 46, cy - 46, cx + 46, cy + 46)

        def barrel(dr, cx=cx, cy=cy):
            dr.ellipse((cx - 46, cy - 46, cx + 46, cy + 46), fill=(52, 56, 60))
            dr.ellipse((cx - 40, cy - 40, cx + 40, cy + 40), fill=(72, 82, 66))
            dr.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), outline=(50, 58, 46), width=3)
            dr.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(40, 44, 38))
        put(b, barrel, off=(10, 12), blur=8)
    # стол с картой
    tb = (330, 900, 700, 1010)

    def table(dr):
        dr.rectangle(tb, fill=(70, 52, 38))
        dr.rectangle((tb[0] + 8, tb[1] + 8, tb[2] - 8, tb[3] - 8), fill=(96, 74, 52))
        dr.rectangle((tb[0] + 40, tb[1] + 18, tb[2] - 90, tb[3] - 20), fill=(170, 160, 128))
        dr.line((tb[0] + 60, tb[1] + 30, tb[2] - 120, tb[3] - 40), fill=(150, 40, 36), width=3)
        dr.ellipse((tb[2] - 70, tb[1] + 22, tb[2] - 30, tb[1] + 62), fill=(60, 60, 56))
    put(tb, table)

    sh_arr = np.asarray(shadows, dtype=np.float32)[..., None] / 255.0
    arr = np.asarray(pil, dtype=np.float32)[..., :3]
    arr = arr * (1.0 - sh_arr)
    lay = np.asarray(layers, dtype=np.float32)
    a = lay[..., 3:4] / 255.0
    # объекты чуть затемняются, чтобы не спорить с UI
    arr = arr * (1.0 - a) + lay[..., :3] * 0.82 * a
    # светлая кромка по верху объектов
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("RGBA")

    # опасная полоса у нижней кромки и вдоль левой стены
    st = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(st)
    for x in range(-40, W + 40, 48):
        sd.polygon([(x, 1060), (x + 24, 1060), (x + 4, 1080), (x - 20, 1080)], fill=(168, 134, 36, 150))
    sd.rectangle((0, 1056, W, 1060), fill=(20, 20, 20, 160))
    img = Image.alpha_composite(img, st)

    # кровь: лужи, брызги и дорожка следов
    blood = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    def stamp(mask, cx, cy, scale, ang, strength):
        m = mask.resize((int(mask.width * scale), int(mask.height * scale)), Image.Resampling.NEAREST)
        m = m.rotate(ang, expand=True, resample=Image.Resampling.NEAREST)
        g = np.asarray(m.convert("RGBA"), dtype=np.float32)
        thick = g[..., 0] / 255.0
        al = (g[..., 3] > 0)
        col = np.zeros(g.shape, dtype=np.float32)
        col[..., 0] = 40 + thick * 52
        col[..., 1] = 4 + thick * 6
        col[..., 2] = 8 + thick * 8
        col[..., 3] = np.where(al, 255 * strength * (0.55 + thick * 0.45), 0)
        tile = Image.fromarray(col.astype(np.uint8), "RGBA")
        blood.alpha_composite(tile, (int(cx - tile.width / 2), int(cy - tile.height / 2)))
    r2 = random.Random(9)
    pools = [(800, 560, 2.6, 0.9), (1230, 400, 2.2, 0.8), (520, 780, 2.0, 0.85), (1450, 820, 2.8, 0.8),
             (260, 60, 2.2, 0.7), (1100, 980, 2.4, 0.85), (1750, 520, 2.0, 0.75), (700, 240, 2.0, 0.6)]
    for i, (cx, cy, sc, st_) in enumerate(pools):
        stamp(ga.splat(100 + i % 8, 66), cx, cy, sc, r2.uniform(0, 360), st_)
    for i in range(5):
        stamp(ga.splat(200 + i % 4, 60, 2.3), r2.uniform(300, 1700), r2.uniform(120, 980), 2.0, r2.uniform(0, 360), 0.7)
    # следы босых ног и ботинок к двери
    foot = ga.footprint()
    for k in range(26):
        t = k / 25
        cx = 340 + t * 1150 + math.sin(t * 9) * 40
        cy = 1000 - t * 760 + math.cos(t * 7) * 30
        ang = -math.degrees(math.atan2(-760, 1150)) + (6 if k % 2 else -6)
        f = foot.resize((foot.width * 4, foot.height * 4), Image.Resampling.NEAREST).rotate(90 + ang + 90, expand=True)
        arrf = np.asarray(f, dtype=np.float32)
        col = np.zeros(arrf.shape, dtype=np.float32)
        col[..., 0], col[..., 1], col[..., 2] = 78, 8, 12
        col[..., 3] = arrf[..., 3] * (0.55 - t * 0.4)
        blood.alpha_composite(Image.fromarray(col.astype(np.uint8), "RGBA"),
                              (int(cx + (14 if k % 2 else -14)), int(cy)))
    img = Image.alpha_composite(img, blood)

    # свет: тёплые пятна ламп, тёмные углы
    arr = np.asarray(img, dtype=np.float32)[..., :3]
    light = np.zeros((H, W), dtype=np.float32)
    for lx, ly, lr, ls in ((420, 300, 520, 0.55), (1500, 280, 560, 0.5), (960, 800, 640, 0.6), (200, 900, 380, 0.3)):
        d2 = ((xx - lx) ** 2 + (yy - ly) ** 2) / (lr * lr)
        light += ls * np.exp(-d2 * 2.2)
    vign = ((xx - W / 2) / (W * 0.62)) ** 2 + ((yy - H / 2) / (H * 0.66)) ** 2
    shade = 0.34 + light * 0.7 - vign * 0.28
    shade = np.clip(shade, 0.12, 1.1)[..., None]
    warm = np.array([1.0, 0.94, 0.8], dtype=np.float32)
    arr = arr * shade * (1.0 + (warm - 1.0) * np.clip(light[..., None], 0, 1))
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("RGB")


# --- сборка ------------------------------------------------------------------------------------

def sprites():
    out = []
    for military in (False, True):
        body, lid = crate_parts(military)
        tag = "base_crate_mil" if military else "base_crate"
        out.append((tag + "_body", body))
        out.append((tag + "_lid", lid))
    return out


def preview(images, path):
    cols, cell_w, cell_h = 4, 420, 200
    rows = math.ceil(len(images) / cols)
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (61, 63, 67))
    draw = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(images):
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        draw.text((x + 8, y + 6), "%s  %dx%d" % (name, *img.size), fill=(211, 213, 206))
        k = 3 if img.width < 130 else 2
        big = img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)
        sheet.paste(big, (x + 8, y + 24), big)
    sheet.save(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", metavar="DIR", help="куда писать вместо art/")
    parser.add_argument("--preview", metavar="PNG", help="лист спрайтов на сером фоне")
    parser.add_argument("--no-bg", action="store_true", help="не пересобирать фон (долго)")
    args = parser.parse_args(argv)
    if args.out:
        ga.OUT = os.path.abspath(args.out)
    os.makedirs(ga.OUT, exist_ok=True)
    images = []
    for name, img in sprites():
        ga.save(img, name)
        images.append((name, img))
        print("%s.png: %dx%d RGBA" % (name, *img.size))
    if not args.no_bg:
        bg = background()
        bg.save(os.path.join(ga.OUT, "base_bg.png"))
        print("base_bg.png: %dx%d RGB" % bg.size)
    print("art ->", ga.OUT)
    if args.preview:
        preview(images, args.preview)
        print("preview ->", args.preview)


if __name__ == "__main__":
    main()
