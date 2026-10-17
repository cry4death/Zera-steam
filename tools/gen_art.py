"""Генератор пиксель-арта Zera: рисует все спрайты в PNG (папка art/).

Запуск из корня проекта:  python tools/gen_art.py
После генерации: godot --headless --path . --import

Всё рисуется «вид сверху», персонажи смотрят вправо (+X). Свет — сверху-слева.
Координаты в коде — логические (сетка 32×32 на персонажа), холст рисует их
в S раз плотнее: при S = 1.5 спрайт персонажа — 48×48 пикселей,
в игре это 16 игровых единиц (3 пикселя арта на единицу).
Мелкие детали (зрачки, зубы, вены, когти) ставятся в «родные» пиксели — они тоньше логических.
Файлы можно дорабатывать руками (Aseprite), но повторный запуск их перезапишет.
"""

import colorsys
import math
import os
import random
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(ROOT, "..", "art"))
S = 1.5  # плотность: родных пикселей на логический

_l = (-0.5, -0.7, 0.55)
_n = math.sqrt(sum(c * c for c in _l))
LIGHT = tuple(c / _n for c in _l)

# биты ран (совпадают с PixelArt.WOUND_* в Godot)
ARM_L, ARM_R, CHEST, HEAD = 1, 2, 4, 8


def hexc(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def ramp(base, n=6, spread=0.85):
    """Рампа от тени к свету: тени холоднее и насыщеннее, свет теплее."""
    r, g, b = (c / 255 for c in base)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    out = []
    for k in range(n):
        t = k / (n - 1) - 0.5
        hh = (h - t * 0.05) % 1.0
        ss = min(1.0, max(0.0, s * (1.0 - t * 0.45)))
        vv = min(1.0, max(0.0, v * (1.0 + t * spread)))
        rr, gg, bb = colorsys.hsv_to_rgb(hh, ss, vv)
        out.append((round(rr * 255), round(gg * 255), round(bb * 255)))
    return out


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def darker(c, k):
    return tuple(max(0, round(v * k)) for v in c[:3])


def pick(rmp, shade):
    v = (shade + 1.0) * 0.5
    return rmp[max(0, min(len(rmp) - 1, int(v * len(rmp))))]


def hnoise(x, y, seed=0):
    """Детерминированный шум −1..1 по пикселю."""
    n = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 32767.5 - 1.0


BLOOD = ramp(hexc("6a0c10"))
DRIED = ramp(hexc("4a1a12"))
FLESH = ramp(hexc("a2363c"))
MUSCLE = ramp(hexc("7e2a34"))
BONE = ramp(hexc("d4c9ad"), spread=0.5)
BRAIN = ramp(hexc("bd7f86"))
GUTS = ramp(hexc("b0646e"))
FAT = ramp(hexc("d6c28c"), spread=0.5)
SHOES = ramp(hexc("2c2824"))
ICE = ramp(hexc("8cc8dc"), spread=0.6)
VEIN = (104, 92, 104)
BRUISE = (96, 70, 92)
EYE_GLOW = (232, 222, 150)
TEETH = (214, 204, 170)


class Canvas:
    """Холст в логических координатах; рисует в S раз плотнее."""

    def __init__(self, w, h, s=S):
        self.s = s
        self.w, self.h = round(w * s), round(h * s)
        self.c = [[None] * self.w for _ in range(self.h)]

    # --- родные пиксели ---
    def inb(self, nx, ny):
        return 0 <= nx < self.w and 0 <= ny < self.h

    def getn(self, nx, ny):
        return self.c[ny][nx] if self.inb(nx, ny) else None

    def putn(self, nx, ny, col, a=255):
        if self.inb(nx, ny):
            self.c[ny][nx] = (col[0], col[1], col[2], col[3] if len(col) > 3 else a)

    def erasen(self, nx, ny):
        if self.inb(nx, ny):
            self.c[ny][nx] = None

    # --- логические ---
    def n(self, x, y):
        return int(math.floor(x * self.s)), int(math.floor(y * self.s))

    def dot(self, x, y, col):
        """Один родной пиксель в логической точке — для мелких деталей."""
        self.putn(*self.n(x, y), col)

    def get(self, x, y):
        return self.getn(*self.n(x, y))

    def filled(self, x, y):
        return self.get(x, y) is not None

    def _shade_px(self, nx, ny, sh, rmp, tex, seed):
        if tex:
            sh += hnoise(nx, ny, seed) * tex
        self.putn(nx, ny, pick(rmp, sh))

    def ellipse(self, cx, cy, rx, ry, rmp, bias=0.0, cond=None, tex=0.0, seed=0):
        """Залитый эллипс с объёмом (полусфера под светом LIGHT); tex — пятнистость."""
        s = self.s
        for ny in range(int((cy - ry) * s) - 1, int((cy + ry) * s) + 2):
            for nx in range(int((cx - rx) * s) - 1, int((cx + rx) * s) + 2):
                x, y = (nx + 0.5) / s, (ny + 0.5) / s
                dx, dy = (x - cx) / rx, (y - cy) / ry
                d2 = dx * dx + dy * dy
                if d2 > 1.0 or (cond and not cond(x, y)):
                    continue
                nz = math.sqrt(1.0 - d2)
                self._shade_px(nx, ny, dx * LIGHT[0] + dy * LIGHT[1] + nz * LIGHT[2] + bias, rmp, tex, seed)

    def tube(self, x0, y0, x1, y1, w, rmp, bias=0.0, w1=None, tex=0.0, seed=0, cond=None):
        """Толстая «трубка» (конечность, кишка) с объёмом поперёк; w → w1 — сужение."""
        w1 = w if w1 is None else w1
        s = self.s
        dx, dy = x1 - x0, y1 - y0
        ln = math.hypot(dx, dy) or 1.0
        ux, uy = dx / ln, dy / ln
        nx_, ny_ = -uy, ux
        r = max(w, w1) / 2 + 0.5
        for py in range(int((min(y0, y1) - r) * s) - 1, int((max(y0, y1) + r) * s) + 2):
            for px in range(int((min(x0, x1) - r) * s) - 1, int((max(x0, x1) + r) * s) + 2):
                x, y = (px + 0.5) / s, (py + 0.5) / s
                qx0, qy0 = x - x0, y - y0
                t = max(0.0, min(1.0, (qx0 * ux + qy0 * uy) / ln))
                rad = (w + (w1 - w) * t) / 2
                qx, qy = qx0 - ux * t * ln, qy0 - uy * t * ln
                d = math.hypot(qx, qy)
                if d > rad or (cond and not cond(x, y)):
                    continue
                side = (qx * nx_ + qy * ny_) / rad
                along = (qx * ux + qy * uy) / rad
                nz = math.sqrt(max(0.0, 1.0 - side * side - along * along * 0.3))
                sh = (nx_ * side + ux * along * 0.5) * LIGHT[0] + (ny_ * side + uy * along * 0.5) * LIGHT[1] + nz * LIGHT[2] + bias
                self._shade_px(px, py, sh, rmp, tex, seed)

    def line(self, x0, y0, x1, y1, col, cond=None):
        """Тонкая линия в родных пикселях (сухожилия, швы). cond(nx, ny) — в родных."""
        a, b = self.n(x0, y0), self.n(x1, y1)
        steps = max(abs(b[0] - a[0]), abs(b[1] - a[1]), 1)
        for i in range(steps + 1):
            nx = round(a[0] + (b[0] - a[0]) * i / steps)
            ny = round(a[1] + (b[1] - a[1]) * i / steps)
            if cond is None or cond(nx, ny):
                self.putn(nx, ny, col)

    def walk(self, rng, x, y, angle, steps, col, wiggle=0.6, on_body=True):
        """Извилистая линия в родных пикселях: вены, трещины, извилины."""
        nx, ny = self.n(x, y)
        fx, fy = float(nx), float(ny)
        for _ in range(steps):
            if not on_body or self.getn(int(fx), int(fy)) is not None:
                self.putn(int(fx), int(fy), col)
            angle += rng.uniform(-wiggle, wiggle)
            fx += math.cos(angle)
            fy += math.sin(angle)

    def stain(self, rng, cx, cy, r, rmp, cond=None):
        """Пятно крови поверх нарисованного (только на непрозрачных пикселях)."""
        def ok(x, y):
            return self.filled(x, y) and (cond is None or cond(x, y))
        self.ellipse(cx, cy, r, r * rng.uniform(0.55, 1.0), rmp, bias=-0.35, cond=ok, tex=0.25, seed=rng.randint(0, 999))
        for _ in range(int(r * 3)):
            a = rng.uniform(0, math.tau)
            d = r + rng.uniform(0.2, 1.4)
            x, y = cx + math.cos(a) * d, cy + math.sin(a) * d
            if self.filled(x, y):
                self.dot(x, y, rmp[1])

    def tear(self, rng, x, y, angle, length, inner, cond=None):
        """Разрыв ткани: тёмный рваный край, внутри кожа или мясо."""
        for i in range(int(length * self.s)):
            t = i / self.s
            px = x + math.cos(angle) * t + rng.uniform(-0.3, 0.3)
            py = y + math.sin(angle) * t + rng.uniform(-0.3, 0.3)
            if cond and not cond(px, py):
                continue
            w = 0.5 + math.sin(t / length * math.pi) * 0.9
            for k in range(-int(w * self.s), int(w * self.s) + 1):
                qx = px - math.sin(angle) * k / self.s
                qy = py + math.cos(angle) * k / self.s
                if self.filled(qx, qy):
                    edge = abs(k) >= int(w * self.s)
                    self.dot(qx, qy, darker(inner[1], 0.6) if edge else pick(inner, -0.1 + hnoise(int(qx * 9), int(qy * 9)) * 0.4))

    def shade_area(self, cx, cy, rx, ry, k=0.55):
        """Затемнить уже нарисованное (тень/AO) с мягким спадом к краю эллипса."""
        s = self.s
        for ny in range(int((cy - ry) * s), int((cy + ry) * s) + 1):
            for nx in range(int((cx - rx) * s), int((cx + rx) * s) + 1):
                c = self.getn(nx, ny)
                if c is None:
                    continue
                x, y = (nx + 0.5) / s, (ny + 0.5) / s
                d = math.hypot((x - cx) / rx, (y - cy) / ry)
                if d < 1.0:
                    f = k + (1.0 - k) * d * d
                    self.c[ny][nx] = darker(c, f) + (c[3],)

    def outline(self, k=0.32):
        """Выборочная обводка: цвет — затемнённый цвет соседа."""
        add = []
        for ny in range(self.h):
            for nx in range(self.w):
                if self.c[ny][nx] is not None:
                    continue
                best = None
                for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nb = self.getn(nx + ddx, ny + ddy)
                    if nb is not None and nb[3] > 128 and (best is None or sum(nb[:3]) < sum(best[:3])):
                        best = nb
                if best is not None:
                    add.append((nx, ny, darker(best, k)))
        for nx, ny, col in add:
            self.putn(nx, ny, col)

    def image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        px = img.load()
        for y in range(self.h):
            for x in range(self.w):
                if self.c[y][x] is not None:
                    px[x, y] = self.c[y][x]
        return img


# --- виды зомби -------------------------------------------------------------------------

VARIANTS = [
    {"name": "civilian", "shirt": hexc("49596a"), "pants": hexc("323c52"), "skin": hexc("7d8a6b"), "hair": hexc("2a1e16"), "build": 1.0},
    {"name": "scientist", "shirt": hexc("abada2"), "pants": hexc("3a3a40"), "skin": hexc("858c76"), "hair": hexc("5e5953"), "build": 0.92},
    {"name": "soldier", "shirt": hexc("4c5537"), "pants": hexc("454d33"), "skin": hexc("76826a"), "helmet": hexc("5e5a44"),
     "vest": hexc("373d27"), "build": 1.1},
    {"name": "worker", "shirt": hexc("3f4249"), "pants": hexc("383b42"), "skin": hexc("7c8866"), "hardhat": hexc("c09c34"),
     "vest": hexc("c4651f"), "build": 1.05},
    # особые заражённые (M4): бегун, толстяк, плевальщик
    {"name": "runner", "kind": "runner", "shirt": hexc("4a4038"), "pants": hexc("2f2a26"), "skin": hexc("8a8a70"),
     "hair": hexc("1e1814"), "build": 0.82},
    {"name": "fat", "kind": "fat", "shirt": hexc("6d685a"), "pants": hexc("3b3a40"), "skin": hexc("9c907e"),
     "hair": hexc("3a3028"), "build": 1.38},
    {"name": "spitter", "kind": "spitter", "shirt": hexc("3b4636"), "pants": hexc("33382e"), "skin": hexc("8e9758"),
     "hair": hexc("2a2a1a"), "build": 0.95},
]
ACID = ramp(hexc("8fd12e"), spread=0.7)
PUS = ramp(hexc("d9cf5a"), spread=0.5)


def body_cond(cx, cy, rx, ry, k=0.92):
    return lambda x, y: ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= k


def draw_torso(cv, d, v, cx, cy, rng, bits):
    """Сгорбленная спина и плечи; плечи несимметричные."""
    b = d["build"]
    shirt = ramp(d["shirt"])
    rx, ry = 6.0 * b, 10.2 * b
    cv.ellipse(cx, cy, rx, ry, shirt, tex=0.18, seed=v)
    cv.ellipse(cx + 1.2, cy - 7.6 * b, 3.4 * b, 3.0 * b, shirt, bias=0.08, tex=0.18, seed=v + 1)   # левое плечо выше
    cv.ellipse(cx + 1.8, cy + 7.9 * b, 3.6 * b, 3.1 * b, shirt, bias=-0.05, tex=0.18, seed=v + 2)  # правое ниже
    inside = body_cond(cx, cy, rx + 0.6, ry + 0.6)
    skin = ramp(d["skin"])
    if v == 2:  # солдат: плитник, подсумки, лямки
        vest = ramp(d["vest"])
        cv.ellipse(cx - 0.4, cy, rx - 1.5, ry - 2.2, vest, bias=-0.05, tex=0.12, seed=7)
        for py in (cy - 5.5, cy - 2.4, cy + 1.0, cy + 4.2):
            cv.ellipse(cx - 3.0, py + 0.9, 1.3, 1.25, vest, bias=0.15)
            cv.dot(cx - 3.0, py + 0.2, vest[5])
        sx = int((cx + 2.2) * S)
        for py in range(int((cy - ry + 2) * S), int((cy + ry - 1) * S)):
            if cv.getn(sx, py) is not None:
                cv.putn(sx, py, vest[1])
    elif v == 3:  # рабочий: грязный светоотражающий жилет
        vest = ramp(d["vest"])
        cv.ellipse(cx, cy, rx - 0.3, ry - 0.3, vest, tex=0.22, seed=11)
        stripe = ramp(hexc("cfcbb4"), spread=0.4)
        for sx in (cx - 2.8, cx + 1.2):
            for py in range(int((cy - ry) * S), int((cy + ry) * S) + 1):
                y = py / S
                if inside(sx, y):
                    cv.dot(sx, y, pick(stripe, 0.5 - abs(y - cy) / ry * 0.9 + hnoise(py, 3) * 0.3))
                    cv.dot(sx + 0.67, y, pick(stripe, 0.2 - abs(y - cy) / ry * 0.9))
    elif v == 1:  # учёный: халат, воротник
        for py in range(int((cy - ry + 3) * S), int((cy + ry - 2) * S)):
            cv.putn(int((cx + 3.8) * S), py, shirt[2])
    kind = d.get("kind", "")
    if kind == "fat":
        # раздутое тело: майка лопнула, голое пузо с венами и гнойниками
        cv.ellipse(cx + 1.0, cy, rx - 1.6, ry - 3.0, skin, tex=0.3, seed=51)
        for _ in range(6):
            cv.walk(rng, cx + rng.uniform(-3, 3), cy + rng.uniform(-7, 7), rng.uniform(0, math.tau), 7, (112, 80, 104), 0.7)
        for _ in range(9):
            px, py = cx + rng.uniform(-4, 4), cy + rng.uniform(-9, 9)
            if inside(px, py):
                cv.ellipse(px, py, 0.7, 0.7, PUS, bias=0.2)
        for k in range(3):  # складки
            cv.line(cx - 2.5 + k * 2.0, cy - 6, cx - 2.0 + k * 2.0, cy + 6, darker(skin[1], 0.8), cond=lambda nx, ny: cv.getn(nx, ny) is not None)
    elif kind == "runner":
        # тощий: сквозь лохмотья видны рёбра
        for k in range(4):
            y = cy - 4.0 + k * 2.2
            cv.line(cx - 2.5, y, cx + 1.8, y + 0.4, darker(skin[2], 0.75), cond=lambda nx, ny: cv.getn(nx, ny) is not None)
    elif kind == "spitter":
        # раздутые кислотные железы на спине
        for _ in range(3):
            cv.ellipse(cx - 2.5 + rng.uniform(-1, 1), cy + rng.uniform(-6, 6), 1.3, 1.6, ACID, bias=0.1)
    # разрывы одежды: под ними гнилая кожа или мясо
    for _ in range(3 if v != 2 else 1):
        a = rng.uniform(-1.2, 1.2) + (math.pi / 2 if rng.random() < 0.5 else 0)
        cv.tear(rng, cx + rng.uniform(-4, 1), cy + rng.uniform(-7, 7), a, rng.uniform(2.5, 4.5),
                skin if rng.random() < 0.6 else MUSCLE, cond=inside)
    # бугры позвоночника сквозь порванную ткань
    if v in (0, 1) and not bits & CHEST:
        for k in range(4):
            y = cy - 3.0 + k * 2.0
            cv.dot(cx - 3.6, y, BONE[2])
            cv.dot(cx - 3.6, y + 0.67, darker(BONE[1], 0.8))
    # кровь: пропитанная одежда, у учёного — особенно заметно
    for _ in range(4 + (4 if v == 1 else 0)):
        cv.stain(rng, cx + rng.uniform(-3, 4), cy + rng.uniform(-8, 8), rng.uniform(0.9, 2.2),
                 BLOOD if rng.random() < 0.6 else DRIED, cond=inside)
    # потёк крови изо рта на грудь (спереди)
    cv.tube(cx + 4.5, cy - 0.6, cx + 2.5, cy + 2.4, 1.1, BLOOD, w1=0.6)
    return rx, ry


def draw_arm(cv, d, v, sx, sy, hx, hy, rng, side, bare_from=0.38):
    """Костлявая рука: рукав, тонкое предплечье с венами, кисть с когтями."""
    shirt, skin = ramp(d["shirt"]), ramp(d["skin"])
    ex = sx + (hx - sx) * 0.5 + rng.uniform(-0.3, 0.3)
    ey = sy + (hy - sy) * 0.5 + side * 0.6
    mx, my = sx + (ex - sx) * bare_from / 0.5, sy + (ey - sy) * bare_from / 0.5
    cv.tube(sx, sy, mx, my, 4.0, shirt, w1=3.5, tex=0.15, seed=21)
    cv.tube(mx, my, ex, ey, 2.9, skin, w1=2.5, tex=0.3, seed=22)
    cv.ellipse(ex, ey, 1.35, 1.35, skin, bias=0.05)  # локоть
    cv.tube(ex, ey, hx, hy, 2.4, skin, w1=1.9, tex=0.3, seed=23)
    # кисть и когти
    ax, ay = hx - ex, hy - ey
    ln = math.hypot(ax, ay) or 1
    ux, uy = ax / ln, ay / ln
    cv.ellipse(hx + ux * 0.8, hy + uy * 0.8, 1.6, 1.4, skin, bias=-0.05, tex=0.3, seed=24)
    for k, spread in enumerate((-0.55, -0.15, 0.3)):
        fx0, fy0 = hx + ux * 1.6, hy + uy * 1.6 + spread * 1.6
        fa = math.atan2(uy, ux) + spread * 0.5
        flen = 2.6 if k == 1 else 2.1
        fx1, fy1 = fx0 + math.cos(fa) * flen, fy0 + math.sin(fa) * flen
        cv.tube(fx0, fy0, fx1, fy1, 0.8, skin, w1=0.55)
        cv.dot(fx1, fy1, (40, 32, 26))  # грязные когти
    # вены и кровь
    t = rng.uniform(0.2, 0.7)  # вена
    cv.walk(rng, mx + (hx - mx) * t, my + (hy - my) * t, math.atan2(uy, ux) + rng.uniform(-0.4, 0.4), 5, VEIN, 0.7)
    cv.dot(hx + ux * 1.8, hy + uy * 1.8, BLOOD[1])
    cv.dot(hx, hy + 0.5, BLOOD[0])
    if rng.random() < 0.6:
        cv.dot(ex + 0.5, ey, BRUISE)


def draw_stump(cv, d, sx, sy, side):
    shirt = ramp(d["shirt"])
    cv.ellipse(sx + 0.4, sy, 2.7, 2.5, shirt, tex=0.2)
    for k in range(5):  # рваный край рукава
        a = -1.2 + k * 0.6
        cv.dot(sx + 2.4 + math.cos(a) * 0.6, sy + math.sin(a) * 2.2, darker(shirt[1], 0.7))
    cv.ellipse(sx + 1.9, sy + side * 0.2, 1.8, 1.7, FLESH, tex=0.3)
    cv.ellipse(sx + 2.2, sy, 0.75, 0.75, BONE)
    cv.line(sx + 2.6, sy - 0.6, sx + 4.4, sy - 1.4 * side, (198, 150, 150))  # сухожилия
    cv.line(sx + 2.6, sy + 0.5, sx + 3.8, sy + 1.6 * side, FLESH[1])
    cv.dot(sx + 1.0, sy + side * 2.4, BLOOD[0])


def draw_face(cv, x, y, rng, dead=False):
    """Лицо спереди головы: провалы глазниц со светящимися зрачками, дыра носа, пасть с зубами."""
    socket = [(18, 10, 12), (22, 12, 14), (30, 16, 18), (40, 22, 22), (46, 26, 26), (52, 30, 30)]
    glow = (120, 116, 96) if dead else EYE_GLOW
    for sy in (-1.75, 1.75):
        cv.ellipse(x + 2.7, y + sy, 1.25, 1.3, socket, bias=-0.3)
        ex, ey = cv.n(x + 2.9, y + sy - 0.3)
        for ddx, ddy in ((0, 0), (1, 0), (0, 1), (1, 1)):  # зрачок 2×2
            cv.putn(ex + ddx, ey + ddy, glow if (ddx, ddy) != (1, 1) else darker(glow, 0.75))
    cv.dot(x + 4.0, y - 0.3, socket[0])  # дыра носа
    cv.dot(x + 4.0, y + 0.4, socket[0])
    # пасть: тёмный провал, два ряда зубов, кровь
    cv.ellipse(x + 5.0, y, 0.85, 2.2, [(28, 6, 8), (34, 8, 10), (46, 10, 12), (58, 14, 14), (70, 18, 18), (80, 22, 22)])
    for k in range(-4, 5):
        yy = y + k * 0.48
        if k % 2 == 0 and abs(k) < 4:
            cv.dot(x + 4.45, yy, TEETH)
        if k % 2 and abs(k) < 4:
            cv.dot(x + 5.6, yy, darker(TEETH, 0.9))
    cv.dot(x + 5.9, y + 0.9, BLOOD[2])
    cv.dot(x + 6.2, y + 1.3, BLOOD[1])


def draw_head(cv, d, v, x, y, broken, rng, face_up=False):
    skin = ramp(d["skin"])
    if "helmet" in d:
        cv.ellipse(x + 0.6, y, 4.4, 4.3, skin, tex=0.3, seed=31)
        draw_face(cv, x, y, rng, dead=face_up)
        hel = ramp(d["helmet"])
        cv.ellipse(x - 1.5, y, 4.4, 5.2, hel, tex=0.12, seed=32)
        cv.ellipse(x + 2.4, y, 0.8, 3.9, hel, bias=-0.4)  # козырёк-кромка над лицом
        cv.walk(rng, x - 3.0, y - 2.0, 0.6, 7, darker(hel[0], 0.7), 0.8)  # трещина
        cv.dot(x - 3.2, y - 2.8, hel[5])
    elif "hardhat" in d:
        cv.ellipse(x + 0.6, y, 4.4, 4.3, skin, tex=0.3, seed=33)
        draw_face(cv, x, y, rng, dead=face_up)
        hat = ramp(d["hardhat"])
        cv.ellipse(x - 2.0, y, 3.9, 4.8, hat, bias=-0.25, tex=0.15, seed=34)  # поля
        cv.ellipse(x - 2.2, y, 3.0, 3.6, hat, bias=0.1, tex=0.15, seed=35)
        cv.line(x - 5.0, y, x + 0.6, y, hat[5])  # гребень
        cv.line(x - 5.0, y + 0.67, x + 0.6, y + 0.67, hat[2])
        cv.walk(rng, x - 3.5, y + 2.0, -0.3, 6, darker(hat[0], 0.6), 0.7)
        for _ in range(3):
            cv.stain(rng, x + rng.uniform(-3, 1), y + rng.uniform(-3, 3), 0.8, DRIED)
    else:
        cv.ellipse(x, y, 4.8, 4.5, skin, tex=0.35, seed=36)
        # уши, одно надорвано
        cv.ellipse(x - 0.6, y - 4.5, 1.25, 0.95, skin, bias=-0.1)
        cv.ellipse(x - 0.6, y + 4.5, 1.25, 0.95, skin, bias=-0.2)
        cv.dot(x - 0.2, y + 5.2, FLESH[2])
        cv.erasen(*cv.n(x + 0.3, y + 5.3))
        # клочья волос и проплешины
        hair = ramp(d["hair"])
        for _ in range(5 if v == 0 else 3):
            a = rng.uniform(math.pi * 0.55, math.pi * 1.45)
            r = rng.uniform(1.5, 3.6)
            cv.ellipse(x + math.cos(a) * r, y + math.sin(a) * r * 1.1, rng.uniform(1.0, 1.9), rng.uniform(1.0, 1.7), hair,
                       tex=0.45, seed=rng.randint(0, 99), cond=lambda px, py: math.hypot(px - x, py - y) < 4.6)
        for _ in range(4):  # пряди
            a = rng.uniform(math.pi * 0.6, math.pi * 1.4)
            cv.walk(rng, x + math.cos(a) * 3.5, y + math.sin(a) * 3.5, a, 3, hair[0], 0.4, on_body=False)
        # синяки, струпья, вены на черепе
        for _ in range(2):
            cv.dot(x + rng.uniform(-2.5, 1.5), y + rng.uniform(-3, 3), BRUISE)
        cv.walk(rng, x - 1.0, y - 2.0, -1.2, 5, VEIN, 0.6)
        cv.dot(x + rng.uniform(-2, 1), y + rng.uniform(-2.5, 2.5), DRIED[2])
        draw_face(cv, x, y, rng, dead=face_up)
        if v == 1:  # треснувшие очки учёного
            for sy in (-1.65, 1.65):
                cv.dot(x + 3.4, y + sy - 0.6, (170, 210, 225))
            cv.dot(x + 3.4, y, (90, 90, 96))
    if broken:
        def cracked(px, py):
            return (px - x) < 1.4 and (py - y) < 0.5 and math.hypot(px - x, py - y) < 4.5
        cv.ellipse(x - 0.5, y - 1.0, 3.8, 3.4, BRAIN, bias=-0.1, cond=cracked, tex=0.35, seed=41)
        for _ in range(4):  # извилины
            cv.walk(rng, x + rng.uniform(-3, 0.5), y + rng.uniform(-3.5, -0.5), rng.uniform(0, math.tau), 4, BRAIN[0], 0.9)
        for a in range(140, 300, 9):  # обломки черепа по краю
            ar = math.radians(a)
            cv.dot(x + math.cos(ar) * 4.3, y + math.sin(ar) * 4.1, BONE[4 if a % 2 else 3])
        cv.dot(x - 1, y + 1.5, BLOOD[1])
        cv.tube(x - 2.0, y + 1.0, x - 3.0, y + 3.6, 0.8, BLOOD)


def draw_neck_stump(cv, x, y):
    cv.ellipse(x, y, 2.9, 3.1, FLESH, tex=0.3)
    cv.ellipse(x + 0.3, y, 1.6, 1.8, BLOOD, bias=-0.5)
    cv.ellipse(x - 0.2, y, 0.8, 0.8, BONE)
    cv.line(x + 1.5, y - 1.5, x + 3.0, y - 2.6, (198, 150, 150))
    cv.dot(x + 1.2, y + 1.6, MUSCLE[1])


def draw_chest_wound(cv, cx, cy, rng):
    for _ in range(6):
        cv.ellipse(cx - 2.6 + rng.uniform(-0.8, 0.8), cy + rng.uniform(-4, 4), rng.uniform(1.6, 2.5), rng.uniform(1.8, 2.8),
                   MUSCLE, bias=-0.1, tex=0.35, seed=rng.randint(0, 99))
    cv.ellipse(cx - 2.4, cy + 0.3, 1.8, 3.6, BLOOD, bias=-0.7)
    for off in (-2.6, -0.9, 0.9, 2.6):  # рёбра дугами
        for t in range(9):
            tt = t / S
            cv.dot(cx - 4.6 + tt, cy + off + math.sin(tt * 0.9) * 0.6 * (1 if off > 0 else -1), BONE[4 if t < 4 else 2])
    for k in range(5):  # позвоночник
        cv.dot(cx - 3.8, cy - 2.6 + k * 1.3, BONE[3])
    for _ in range(5):
        cv.dot(cx - 2 + rng.uniform(-3, 2), cy + rng.uniform(-7, 7), BLOOD[rng.randint(0, 1)])


def zombie(v, bits, anim, headless=False, outline=True):
    d = VARIANTS[v]
    cv = Canvas(32, 32)
    sway = (1.0, 0.0, -1.0, 0.0)[anim]
    bob = (0.0, 0.5, 0.0, -0.5)[anim]
    cx, cy = 12.2, 16.0 + bob * 0.25
    draw_torso(cv, d, v, cx, cy, random.Random(v * 13 + 1), bits)
    if bits & CHEST:
        draw_chest_wound(cv, cx, cy, random.Random(v + 77))
    b = d["build"]
    for side in (-1, 1):
        sx, sy = 14.6, cy + side * 8.0 * b
        if bits & (ARM_L if side < 0 else ARM_R):
            draw_stump(cv, d, sx, sy, side)
            continue
        ext = sway * side * 1.7
        reach = {"runner": 29.6, "fat": 25.0}.get(d.get("kind", ""), 27.0)
        hx, hy = reach + ext, cy + side * 5.2 + sway * side * 0.4
        draw_arm(cv, d, v, sx, sy, hx, hy, random.Random(v * 7 + side + 3), side)
    hx0, hy0 = 18.0 + bob * 0.35, cy + (0.4 if v == 0 else -0.3)  # голова чуть набок
    cv.shade_area(hx0 - 0.4, hy0, 6.6, 6.4, 0.5)  # тень головы на плечах — голова «отрывается» от тела
    if headless:
        draw_neck_stump(cv, hx0 - 1.2, hy0)
    else:
        if d.get("kind") == "runner":
            hx0 += 1.2  # бегун тянется головой вперёд
        draw_head(cv, d, v, hx0, hy0, bits & HEAD, random.Random(v * 31 + 5))
        if d.get("kind") == "spitter" and not bits & HEAD:
            # светящийся кислотный зоб под челюстью и зелёные слюни
            cv.ellipse(hx0 + 4.4, hy0 + 0.2, 2.0, 3.0, ACID, bias=0.15, tex=0.25, seed=61)
            cv.walk(random.Random(v), hx0 + 3.6, hy0 - 1.5, 0.4, 5, darker(ACID[1], 0.7), 0.6)
            cv.dot(hx0 + 4.0, hy0 - 1.0, (230, 255, 170))
            cv.tube(hx0 + 6.0, hy0 + 0.5, hx0 + 7.2, hy0 + 2.4, 0.7, ACID, w1=0.4)
    if outline:
        cv.outline()
    return cv


def zombie_top_half(v):
    cv = zombie(v, 0, 0, outline=False)
    cut = int(9.5 * S)
    for ny in range(cv.h):
        for nx in range(cut):
            cv.erasen(nx, ny)
    for ny in range(cv.h):
        if cv.getn(cut, ny) is not None:
            cv.putn(cut, ny, MUSCLE[2] if ny % 5 else GUTS[4])
            cv.putn(cut + 1, ny, FLESH[1] if ny % 3 else BLOOD[1])
    cv.ellipse(cut / S + 0.3, 16, 1.1, 1.3, BONE)
    cv.tube(cut / S - 0.5, 13, cut / S - 3.5, 10.5, 1.8, GUTS, tex=0.3)
    cv.tube(cut / S - 0.5, 18, cut / S - 2.8, 21.0, 1.5, GUTS, tex=0.3)
    cv.outline()
    return cv


# --- боец -----------------------------------------------------------------------------------

def player(anim, dirt):
    rng = random.Random(77)
    cv = Canvas(32, 32)
    camo = ramp(hexc("5a6544"))
    camo2 = ramp(hexc("424a30"))
    plate = ramp(hexc("4a5436"))
    pack = ramp(hexc("4a4532"))
    mat = ramp(hexc("3d4a52"))
    glove = ramp(hexc("2e2e2a"))
    gun = ramp(hexc("2a2c30"), spread=0.9)
    helmet = ramp(hexc("4e5838"))
    sway = (0.6, 0.0, -0.6, 0.0)[anim]
    cx, cy = 13.0, 16.0
    # рюкзак со скаткой и рацией
    cv.ellipse(7.4, cy, 3.6, 7.2, pack, tex=0.15)
    cv.tube(4.6, cy - 6.0, 4.6, cy + 6.0, 2.0, mat, bias=0.1)
    for k in range(-5, 6, 2):
        cv.dot(4.6, cy + k, mat[1])
    cv.ellipse(8.0, cy - 4.2, 1.4, 1.6, ramp(hexc("2a2c2e")))
    cv.line(7.6, cy - 5.5, 4.5, cy - 9.5, (40, 42, 44))
    # корпус в камуфляже
    cv.ellipse(cx, cy + sway * 0.25, 6.3, 10.4, camo, tex=0.12)
    for _ in range(12):
        cv.ellipse(cx + rng.uniform(-4, 4), cy + rng.uniform(-8, 8), rng.uniform(0.7, 1.5), rng.uniform(0.7, 1.4), camo2,
                   cond=lambda x, y: cv.filled(x, y))
    # плитник: швы MOLLE и подсумки с магазинами
    cv.ellipse(cx + 0.3, cy, 4.4, 7.6, plate, tex=0.1)
    for py in range(int((cy - 6.5) * S), int((cy + 6.5) * S), 3):
        cv.line(cx - 3.2, py / S, cx + 3.4, py / S, plate[1], cond=lambda nx, ny: cv.getn(nx, ny) is not None)
    for py in (cy - 4.6, cy - 1.6, cy + 1.6, cy + 4.6):
        cv.ellipse(cx - 1.6, py, 1.5, 1.25, plate, bias=0.15)
        cv.dot(cx - 0.5, py - 0.4, gun[3])
        cv.dot(cx - 0.5, py + 0.3, gun[2])
    cv.ellipse(cx + 1, cy - 9.0, 2.6, 1.9, plate, bias=0.1)
    cv.ellipse(cx + 1, cy + 9.0, 2.6, 1.9, plate, bias=-0.1)
    # автомат
    gy = cy + 2.0
    cv.tube(9.5, gy, 13.8, gy, 2.3, gun)
    cv.tube(13.8, gy, 21.0, gy, 2.9, gun, bias=0.1)
    cv.tube(19.0, gy + 1.6, 19.6, gy + 4.2, 1.8, gun)
    cv.tube(21.0, gy, 27.0, gy, 2.2, gun)
    for k in range(int(21 * S), int(27 * S), 2):
        cv.putn(k, int((gy - 1.0) * S), gun[5])
    cv.tube(27.0, gy, 30.6, gy, 1.2, gun, bias=0.2)
    cv.ellipse(31.0, gy, 0.8, 0.9, gun)
    cv.ellipse(17.6, gy - 1.6, 1.9, 0.95, gun, bias=0.2)
    cv.dot(19.2, gy - 1.8, (110, 180, 220))
    cv.line(11.0, gy + 1.4, 18.0, cy + 9.0, (60, 56, 44))
    # руки
    cv.tube(14.5, cy - 8.0, 23.0, gy - 1.0, 3.2, camo, tex=0.1)
    cv.ellipse(23.6, gy - 0.6, 1.7, 1.5, glove)
    cv.tube(14.0, cy + 8.5, 17.0, gy + 2.0, 3.2, camo, bias=-0.1, tex=0.1)
    cv.ellipse(17.0, gy + 1.6, 1.6, 1.5, glove)
    # каска с креплением ПНВ, очками и наушниками
    hx, hy = 15.6, cy + sway * 0.2
    cv.ellipse(hx, hy, 5.0, 5.0, helmet, tex=0.12)
    for _ in range(5):
        cv.dot(hx + rng.uniform(-3, 2), hy + rng.uniform(-3, 3), camo2[2])
    cv.ellipse(hx - 0.6, hy - 4.8, 1.5, 1.1, glove)
    cv.ellipse(hx - 0.6, hy + 4.8, 1.5, 1.1, glove)
    cv.ellipse(hx + 3.6, hy, 1.0, 2.7, ramp(hexc("26323a")), bias=0.2)
    cv.dot(hx + 3.9, hy - 1.1, (160, 200, 220))
    cv.ellipse(hx + 2.4, hy, 0.9, 1.0, gun)
    cv.dot(hx + 5.2, hy, ramp(hexc("b48a64"))[3])
    drng = random.Random(909)
    for _ in range((0, 5, 11, 20)[dirt]):
        cv.stain(drng, drng.uniform(5, 25), drng.uniform(4, 28), drng.uniform(0.6, 1.2 + dirt * 0.35), BLOOD)
    cv.outline(0.3)
    return cv


# --- мёртвые ------------------------------------------------------------------------------

POSES = [
    {"feet": ((2.5, 12.0), (3.0, 20.5)), "hands": ((27.0, 3.5), (12.0, 26.0)), "down": False},
    {"feet": ((3.0, 9.0), (2.5, 22.5)), "hands": ((21.5, 1.8), (23.5, 30.2)), "down": False},
    {"feet": ((2.0, 14.0), (4.5, 22.0)), "hands": ((26.5, 8.0), (25.0, 27.0)), "down": True},  # ничком
]
BURNT = {"shirt": hexc("1c1512"), "pants": hexc("1f1814"), "skin": hexc("2e2018"), "hair": hexc("140f0c"), "build": 1.0}


def corpse(v, pose, headless=False, burnt=False):
    d = dict(BURNT if burnt else VARIANTS[v])
    rng = random.Random(v * 31 + pose * 7 + (3 if headless else 0))
    cv = Canvas(32, 32)
    shirt, skin, pants = ramp(d["shirt"]), ramp(d["skin"]), ramp(d["pants"])
    p = POSES[pose]
    for side, (fx, fy) in zip((-1, 1), p["feet"]):
        cv.tube(11.0, 16 + side * 2.4, fx + 1.5, fy, 3.8, pants, w1=3.2, tex=0.15)
        cv.ellipse(fx, fy, 1.9, 1.6, ramp(hexc("120e0c")) if burnt else SHOES)
    cv.ellipse(15.6, 16, 5.8, 7.4, shirt, tex=0.18)
    inside = body_cond(15.6, 16, 6.2, 7.8)
    if not burnt:
        if v == 1:
            cv.ellipse(11.0, 16, 3.2, 6.0, shirt, bias=-0.1)
        if v == 3:
            cv.ellipse(15.6, 16, 5.2, 6.8, ramp(d["vest"]), tex=0.2)
        if v == 2:
            cv.ellipse(15.8, 16, 4.0, 5.6, ramp(d["vest"]), tex=0.12)
        for _ in range(2):
            cv.tear(rng, 15 + rng.uniform(-3, 3), 16 + rng.uniform(-5, 5), rng.uniform(0, math.tau), 3.0,
                    MUSCLE if rng.random() < 0.5 else skin, cond=inside)
        for _ in range(4):
            cv.stain(rng, 15 + rng.uniform(-4, 4), 16 + rng.uniform(-6, 6), rng.uniform(1.0, 2.2), BLOOD, cond=inside)
    for side, (hx, hy) in zip((-1, 1), p["hands"]):
        draw_arm(cv, d, v, 19.4, 16 + side * 6.8, hx, hy, rng, side)
    dd = dict(d)
    if not burnt and ("hardhat" in d or ("helmet" in d and pose != 0)):
        dd["hair"] = hexc("2a2018")  # каска слетела при падении
        dd.pop("helmet", None)
        dd.pop("hardhat", None)
    if headless:
        draw_neck_stump(cv, 22.0, 16)
    elif p["down"]:
        # лицом вниз: виден затылок
        cv.ellipse(24.4, 16, 4.4, 4.2, ramp(dd.get("hair", hexc("2a2018"))), tex=0.45)
        cv.ellipse(23.0, 13.2, 1.2, 0.9, skin, bias=-0.1)
        cv.ellipse(23.0, 18.8, 1.2, 0.9, skin, bias=-0.2)
    else:
        draw_head(cv, dd, v if not burnt else 0, 24.4, 16, False, rng, face_up=True)
    if burnt:
        for _ in range(20):
            x, y = rng.uniform(4, 28), rng.uniform(4, 28)
            if cv.filled(x, y):
                cv.dot(x, y, (210, 90, 20) if rng.random() < 0.5 else (90, 30, 10))
        for _ in range(7):
            x, y = rng.uniform(8, 22), rng.uniform(10, 22)
            if cv.filled(x, y):
                cv.dot(x, y, BONE[1])
                cv.dot(x + 0.67, y, BONE[2])
    cv.outline(0.36)
    return cv


def legs_half(v):
    d = VARIANTS[v]
    cv = Canvas(24, 24)
    pants = ramp(d["pants"])
    for side, fy in ((-1, 7.0), (1, 17.0)):
        cv.tube(17.0, 12 + side * 2.6, 3.5, fy, 4.0, pants, w1=3.3, tex=0.15)
        cv.ellipse(2.4, fy, 1.9, 1.6, SHOES)
    cv.ellipse(17.5, 12, 3.0, 5.4, pants, tex=0.15)
    cv.ellipse(19.6, 12, 1.7, 4.6, MUSCLE, tex=0.3)
    cv.ellipse(20.0, 12, 0.9, 1.0, BONE)
    cv.tube(20.5, 9.5, 23.0, 6.5, 1.8, GUTS, tex=0.3)
    cv.tube(20.5, 14.5, 22.6, 17.5, 1.5, GUTS, tex=0.3)
    cv.dot(20, 15, BLOOD[0])
    cv.outline()
    return cv


# --- куски --------------------------------------------------------------------------------

def gib_head(v):
    rng = random.Random(v)
    cv = Canvas(14, 14)
    d = dict(VARIANTS[v])
    if "helmet" in d or "hardhat" in d:
        d.pop("helmet", None)
        d.pop("hardhat", None)
        d["hair"] = hexc("2a2018")
    draw_head(cv, d, v, 7.2, 7.0, False, rng, face_up=True)
    cv.ellipse(2.2, 7.0, 1.7, 2.3, MUSCLE, tex=0.3)
    cv.ellipse(1.9, 7.0, 0.7, 0.7, BONE)
    cv.line(1.2, 6.0, 0.2, 4.6, (198, 150, 150))
    cv.outline()
    return cv


def gib_arm(v):
    rng = random.Random(v + 11)
    cv = Canvas(18, 8)
    draw_arm(cv, VARIANTS[v], v, 3.0, 4.0, 13.5, 4.0, rng, 1)
    cv.ellipse(2.0, 4.0, 1.6, 1.9, MUSCLE, tex=0.3)
    cv.tube(2.0, 4.0, 0.4, 3.6, 0.9, BONE)
    cv.outline()
    return cv


def gib_torso(v):
    rng = random.Random(v + 40)
    cv = Canvas(16, 14)
    cv.ellipse(8, 7, 6.0, 5.4, ramp(VARIANTS[v]["shirt"]), tex=0.2)
    cv.ellipse(3.4, 7.5, 2.8, 4.6, MUSCLE, tex=0.35)
    for off in (-2.6, -0.9, 0.9, 2.6):
        cv.tube(1.6, 7.5 + off, 4.6, 7.5 + off * 1.15, 0.7, BONE)
    cv.tube(3.0, 10.0, 0.5, 12.5, 1.4, GUTS, tex=0.3)
    for _ in range(3):
        cv.stain(rng, 8 + rng.uniform(-3, 3), 7 + rng.uniform(-3, 3), 1.2, BLOOD)
    cv.outline()
    return cv


def gib_guts(k):
    rng = random.Random(500 + k)
    w = (18, 14, 10)[k]
    cv = Canvas(w, 8)
    pts = [(1.5 + i * (w - 3) / 6, 4 + math.sin(i * 1.3 + k) * 1.7) for i in range(7)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        cv.tube(x0, y0, x1, y1, 2.5, GUTS, tex=0.25, seed=k)
    for _ in range(5):  # влажные блики
        x, y = rng.choice(pts)
        cv.dot(x + rng.uniform(-0.5, 0.5), y - 0.7, (236, 196, 200))
    for x, y in pts[1:-1:2]:
        cv.dot(x, y + 0.6, GUTS[0])
    cv.dot(pts[0][0], pts[0][1], BLOOD[1])
    cv.outline(0.42)
    return cv


def gib_meat(k):
    rng = random.Random(600 + k)
    s = (8, 7, 6, 9)[k]
    cv = Canvas(s, s)
    for _ in range(3):
        cv.ellipse(s / 2 + rng.uniform(-1, 1), s / 2 + rng.uniform(-1, 1), rng.uniform(s * 0.2, s * 0.32),
                   rng.uniform(s * 0.18, s * 0.3), FLESH, tex=0.35, seed=k)
    for _ in range(3):
        cv.dot(s / 2 + rng.uniform(-1.5, 1.5), s / 2 + rng.uniform(-1.5, 1.5), FAT[3])
    cv.walk(rng, s / 2, s / 2, rng.uniform(0, 6), 4, VEIN, 0.8)
    if k == 3:
        cv.tube(s / 2 - 1.5, s / 2, s / 2 + 2.2, s / 2 - 0.6, 0.9, BONE)
    cv.outline(0.42)
    return cv


def gib_jaw():
    cv = Canvas(8, 8)
    cv.tube(2.0, 1.8, 5.5, 4.0, 1.4, BONE)
    cv.tube(5.5, 4.0, 2.0, 6.2, 1.4, BONE)
    for x, y in ((3.0, 2.6), (4.4, 3.4), (4.4, 4.6), (3.0, 5.4)):
        cv.dot(x + 0.6, y, TEETH)
    cv.ellipse(2.0, 4.0, 1.2, 1.8, MUSCLE, tex=0.3)
    cv.outline(0.42)
    return cv


def gib_eye():
    cv = Canvas(6, 5)
    cv.ellipse(2.4, 2.5, 1.5, 1.4, ramp(hexc("d9d2c0"), spread=0.4))
    cv.dot(3.0, 2.3, (60, 70, 50))
    cv.tube(1.0, 2.5, 0.0, 3.6, 0.6, FLESH)
    cv.outline(0.42)
    return cv


def gib_rib():
    cv = Canvas(14, 10)
    for k in range(4):
        pts = [(2 + t, 2 + k * 2 + math.sin(t * 0.35) * 1.2) for t in range(10)]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            cv.tube(x0, y0, x1, y1, 0.8, BONE)
    cv.tube(1.5, 1.5, 1.5, 8.5, 1.6, MUSCLE, tex=0.3)
    cv.outline(0.42)
    return cv


def gib_spine():
    cv = Canvas(18, 6)
    for k in range(6):
        cv.ellipse(2.5 + k * 2.6, 3, 1.3, 1.6, BONE)
        cv.ellipse(2.5 + k * 2.6, 3, 0.4, 2.2, BONE, bias=0.2)
        cv.dot(3.8 + k * 2.6, 3, FLESH[1])
    cv.outline(0.42)
    return cv


def gib_bone():
    cv = Canvas(12, 6)
    cv.tube(2.5, 3, 9.5, 3, 1.6, BONE)
    for x in (2.0, 10.0):
        cv.ellipse(x, 2.2, 1.2, 1.1, BONE)
        cv.ellipse(x, 3.9, 1.2, 1.1, BONE)
    cv.dot(6, 3, FLESH[2])
    cv.dot(9.8, 3, MUSCLE[2])
    cv.outline(0.42)
    return cv


def gib_skull(k):
    rng = random.Random(700 + k)
    cv = Canvas(7, 7)
    for _ in range(2):
        cv.ellipse(3.5 + rng.uniform(-0.8, 0.8), 3.5 + rng.uniform(-0.8, 0.8), rng.uniform(1.6, 2.4), rng.uniform(1.5, 2.2), BONE)
    cv.dot(3 + k, 3, BRAIN[3])
    cv.dot(4, 4 - k, BLOOD[1])
    cv.walk(rng, 3, 3, 0.5, 3, BONE[0], 0.6)
    cv.outline(0.42)
    return cv


def gib_brain():
    rng = random.Random(800)
    cv = Canvas(8, 7)
    cv.ellipse(4, 3.5, 3.0, 2.5, BRAIN, tex=0.3)
    for _ in range(3):
        cv.walk(rng, 4 + rng.uniform(-1.5, 1.5), 3.5, rng.uniform(0, 6), 4, BRAIN[0], 0.9)
    cv.dot(rng.uniform(2, 6), 5, BLOOD[1])
    cv.outline(0.42)
    return cv


def gib_shard(k):
    rng = random.Random(900 + k)
    s = (10, 8, 6)[k]
    cv = Canvas(s, s)
    c = s / 2
    pts = [(c + math.cos(a) * rng.uniform(s * 0.25, s * 0.45), c + math.sin(a) * rng.uniform(s * 0.25, s * 0.45))
           for a in (0, 1.4, 2.6, 3.9, 5.1)]
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / S, (ny + 0.5) / S
            inside = False
            for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
                if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
                    inside = not inside
            if inside:
                cv.putn(nx, ny, pick(ICE, (x - c) * LIGHT[0] / c + (y - c) * LIGHT[1] / c + 0.3))
    cv.ellipse(c, c, 0.9, 0.9, FLESH)
    cv.dot(c - 1, c - 1, (240, 250, 255))
    cv.outline(0.5)
    return cv


# --- образцы (опыт) ---------------------------------------------------------------------

XP = ramp(hexc("58d68c"), spread=0.7)


def xp_crystal(tier):
    """Светящийся зелёный кристалл-образец: 3 размера (1 / 5 / 25 опыта)."""
    s = (5, 7, 10)[tier]
    cv = Canvas(s, s)
    c = s / 2
    h = s * 0.46
    w = s * 0.28
    pts = [(c, c - h), (c + w, c), (c, c + h), (c - w, c)]  # ромб
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / S, (ny + 0.5) / S
            if abs(x - c) / w + abs(y - c) / h <= 1.0:
                face = 0.7 if x < c else (-0.2 if y > c else 0.25)  # грани: левая светлее
                cv.putn(nx, ny, pick(XP, face + (0.25 if y < c else -0.1)))
    cv.dot(c - w * 0.35, c - h * 0.4, (230, 255, 236))  # блик
    if tier == 2:
        cv.line(c, c - h + 1, c, c + h - 1, XP[5])
    cv.outline(0.4)
    return cv


# --- кредиты --------------------------------------------------------------------------------

GOLD = ramp(hexc("e8b84a"), spread=0.75)


def credit_chip(tier):
    """Золотой жетон-кредит: 3 размера (1 / 5 / 25 кредитов), у крупных — насечки по ободу."""
    s = (5, 6.5, 8)[tier]
    cv = Canvas(s, s)
    c = s / 2
    r = s * 0.42
    for ny in range(cv.h):
        for nx in range(cv.w):
            x, y = (nx + 0.5) / S, (ny + 0.5) / S
            d = math.hypot(x - c, y - c)
            if d > r:
                continue
            light = -((x - c) * 0.6 + (y - c) * 0.8) / r  # свет сверху-слева
            rim = d > r - 0.9
            shade = 0.15 + light * 0.45 - (0.35 if rim else 0.0)
            if tier > 0 and rim and int(math.degrees(math.atan2(y - c, x - c)) // 30) % 2:
                shade -= 0.25  # насечки
            cv.putn(nx, ny, pick(GOLD, shade))
    cv.line(c - r * 0.35, c - r * 0.1, c + r * 0.35, c - r * 0.1, GOLD[1])  # прорезь жетона
    cv.dot(c - r * 0.45, c - r * 0.5, (255, 246, 210))  # блик
    cv.outline(0.4)
    return cv


# --- кровь, пол, следы --------------------------------------------------------------------

def splat(seed, size, stretch=1.0):
    """Маска ТОЛЩИНЫ крови (яркость = толщина): неровные лопасти, густой центр, капли с хвостами.
    Цвет, блик и высыхание считает шейдер blood.gdshader."""
    rng = random.Random(seed)
    w = int(size * stretch)
    img = Image.new("RGBA", (w, size), (0, 0, 0, 0))
    px = img.load()
    c = (w / 2, size / 2)
    lobes = [(c[0] - (w - size) * 0.25, c[1], size * 0.2)]
    if stretch > 1.0:
        n = 10
        for i in range(n):
            t = i / (n - 1)
            lobes.append((w * (0.16 + 0.7 * t), c[1] + rng.uniform(-0.07, 0.07) * size, size * (0.2 - 0.14 * t)))
    for _ in range(rng.randint(6, 10) if stretch <= 1.0 else rng.randint(2, 4)):
        a = rng.uniform(-math.pi, math.pi)
        dist = rng.uniform(0.05, 0.3) * size
        lobes.append((c[0] + math.cos(a) * dist, c[1] + math.sin(a) * dist * 0.8, rng.uniform(0.07, 0.17) * size))
    drops = []
    for _ in range(rng.randint(12, 22)):
        a = rng.uniform(-math.pi, math.pi) if stretch <= 1.0 else rng.uniform(-0.45, 0.45)
        dist = rng.uniform(0.3, 0.48)
        r = rng.uniform(1.4, 3.6)
        drops.append((c[0] + math.cos(a) * dist * w, c[1] + math.sin(a) * dist * size, r, a))
    max_r = size * 0.45
    for y in range(size):
        for x in range(w):
            p = (x + 0.5, y + 0.5)
            depth = 0.0
            for bx, by, br in lobes:
                d = math.hypot(p[0] - bx, p[1] - by)
                if d <= br:
                    depth = max(depth, 1.0 - d / br)
            if depth > 0.0:
                k = min(1.0, math.hypot(p[0] - c[0], p[1] - c[1]) / max_r)
                # густо в центре и в глубине лопастей, тонко по краю
                val = 0.35 + 0.45 * (1.0 - k) + 0.25 * depth + hnoise(x, y, seed) * 0.04
                v = round(255 * max(0.0, min(1.0, val)))
                px[x, y] = (v, v, v, 255)
                continue
            for bx, by, br, a in drops:
                dx, dy = p[0] - bx, p[1] - by
                along = dx * math.cos(a) + dy * math.sin(a)
                across = -dx * math.sin(a) + dy * math.cos(a)
                if (along * along) / (br * br * 2.0) + (across * across) / (br * br) <= 1.0 or \
                        (-br * 4 < along < 0 and abs(across) < br * 0.45):
                    px[x, y] = (150, 150, 150, 255)  # капля — тоньше лужи
                    break
    return img


def footprint():
    rows = ["0011110000011111100",
            "0111111100111111110",
            "1111111110111111111",
            "1111111110111111111",
            "0111111100111111110",
            "0011110000011111100"]
    img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "1":
                img.putpixel((x, y), (255, 255, 255, 255 if 3 < x < 16 else 190))
    return img


def asphalt():
    s = 384  # 128 игровых единиц
    rng = random.Random(1337)
    base = hexc("3d3f43")
    img = Image.new("RGBA", (s, s))
    px = img.load()
    for y in range(s):
        for x in range(s):
            low = (math.sin(x / s * math.tau * 2 + 1.3) + math.sin(y / s * math.tau * 3 + 0.4)
                   + math.sin((x + y) / s * math.tau + 2.1)) / 3
            k = 1.0 + low * 0.05 + hnoise(x, y, 5) * 0.035
            px[x, y] = tuple(min(255, round(c * k)) for c in base) + (255,)
    for _ in range(int(s * s * 0.045)):  # щебень
        x, y = rng.randrange(s), rng.randrange(s)
        c = mix(base, (120, 122, 126), rng.uniform(0.2, 0.5)) if rng.random() < 0.5 else darker(base, 0.72)
        px[x, y] = c + (255,)
    for _ in range(8):  # трещины
        x, y = rng.uniform(0, s), rng.uniform(0, s)
        a = rng.uniform(0, math.tau)
        for _ in range(rng.randint(15, 60)):
            ix, iy = int(x) % s, int(y) % s
            px[ix, iy] = darker(base, 0.72) + (255,)
            a += rng.uniform(-0.5, 0.5)
            x += math.cos(a)
            y += math.sin(a)
    for _ in range(4):  # масляные пятна
        ox, oy, r = rng.uniform(0, s), rng.uniform(0, s), rng.uniform(8, 18)
        for y in range(int(oy - r), int(oy + r)):
            for x in range(int(ox - r), int(ox + r)):
                d = math.hypot(x - ox, (y - oy) * 1.3) / r
                if d < 1.0:
                    ix, iy = x % s, y % s
                    px[ix, iy] = darker(px[ix, iy], 0.82 + 0.18 * d) + (255,)
    return img


# --- сборка ----------------------------------------------------------------------------------

def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    cell = round(32 * S)
    # атлас живых: столбец = биты ран (16), строка = вид × 4 + кадр ходьбы
    atlas = Image.new("RGBA", (16 * cell, len(VARIANTS) * 4 * cell), (0, 0, 0, 0))
    for v in range(len(VARIANTS)):
        for anim in range(4):
            for bits in range(16):
                atlas.paste(zombie(v, bits, anim).image(), (bits * cell, (v * 4 + anim) * cell))
        print("zombie variant", v, "done")
    save(atlas, "zombie_atlas")

    sheet = Image.new("RGBA", (4 * cell, 4 * cell), (0, 0, 0, 0))
    for dirt in range(4):
        for anim in range(4):
            sheet.paste(player(anim, dirt).image(), (anim * cell, dirt * cell))
    save(sheet, "player")

    for v in range(len(VARIANTS)):
        save(zombie(v, 0, 0).image(), "zombie_whole_%d" % v)
        save(zombie(v, 0, 1, headless=True).image(), "zombie_headless_%d" % v)
        save(zombie_top_half(v).image(), "zombie_top_%d" % v)
        save(legs_half(v).image(), "legs_%d" % v)
        for pose in range(len(POSES)):
            save(corpse(v, pose).image(), "corpse_%d_%d" % (v, pose))
            save(corpse(v, pose, headless=True).image(), "corpse_headless_%d_%d" % (v, pose))
        save(gib_head(v).image(), "gib_head_%d" % v)
        save(gib_arm(v).image(), "gib_arm_%d" % v)
        save(gib_torso(v).image(), "gib_torso_%d" % v)
    for pose in range(len(POSES)):
        save(corpse(0, pose, burnt=True).image(), "corpse_burnt_%d" % pose)
    for k in range(3):
        save(gib_guts(k).image(), "gib_guts_%d" % k)
        save(gib_shard(k).image(), "gib_shard_%d" % k)
    for k in range(4):
        save(gib_meat(k).image(), "gib_meat_%d" % k)
    for k in range(2):
        save(gib_skull(k).image(), "gib_skull_%d" % k)
    save(gib_rib().image(), "gib_rib")
    save(gib_spine().image(), "gib_spine")
    save(gib_bone().image(), "gib_bone")
    save(gib_brain().image(), "gib_brain")
    save(gib_jaw().image(), "gib_jaw")
    save(gib_eye().image(), "gib_eye")
    for k in range(8):
        save(splat(100 + k, 30 + k * 6), "blood_%d" % k)
    for k in range(4):
        save(splat(200 + k, 27 + k * 6, 2.3), "spray_%d" % k)
    for t in range(3):
        save(xp_crystal(t).image(), "xp_%d" % t)
        save(credit_chip(t).image(), "credit_%d" % t)
    save(footprint(), "footprint")
    save(asphalt(), "asphalt")
    print("art ->", OUT)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        OUT = sys.argv[1]
    main()
