# G3 — gen_art_m4.py: пиксель-арт предметов M4

**Исполнитель:** ChatGPT · **Результат:** один файл `gen_art_m4.py` → сохранить в `GameZ/tasks/inbox/G3/gen_art_m4.py`

---

Ты пишешь Python-скрипт (Python 3.11+, только Pillow), который **процедурно рисует пиксель-арт**
для top-down зомби-шутера и сохраняет PNG. В проекте уже есть генератор `tools/gen_art.py`
со своим холстом и палитрами — твой скрипт лежит рядом (`tools/gen_art_m4.py`) и **импортирует**
его, а не копирует:

```python
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as ga          # Canvas, S, ramp, hexc, pick, mix, darker, hnoise, save, палитры
```

Запуск: `python tools/gen_art_m4.py` — пишет все файлы в `art/` через
`ga.save(cv.image(), "medkit")` (`def save(img, name): img.save(os.path.join(OUT, name + ".png"))`).
Импорт `gen_art` ничего не генерирует (там `if __name__ == "__main__"`). Холст `ga.Canvas` после
рисования превращается в картинку `cv.image()` (RGBA, прозрачный фон).
`python tools/gen_art_m4.py --preview out.png` — дополнительно собирает лист-превью: все спрайты
на сером фоне `(61, 63, 67)`, увеличенные ×4 без сглаживания (`Image.NEAREST`), с отступами.

## Стиль (важно — арт должен вписаться в существующий)

- Вид **строго сверху**. Свет **сверху-слева** (вектор `ga.LIGHT`), тени — вправо-вниз.
- Логическая сетка: персонаж — 32×32 логических единиц. Холст `ga.Canvas(w, h)` рисует в
  `S = 1.5` раза плотнее: логические 10×10 → 15×15 px. Мелкие детали (блики, заклёпки, трещины) —
  в «родные» пиксели (`dot`, `line`, `putn`).
- Объём — через `ellipse`/`tube` с рампами (`ga.ramp(base)` — 6 оттенков от тени к свету).
  Плоские заливки без объёма — нельзя. Пятнистость — параметр `tex`.
- В конце почти всегда `cv.outline(k)` — выборочная тёмная обводка (k 0.3–0.45).
- Палитра приглушённая, грязная, «военный sci-fi в карантинной зоне»: хаки, ржавчина, засохшая
  кровь. Ярко — только то, что игрок должен заметить на полу, залитом кровью (аптечка, деталь,
  контейнер), и кислота.
- Детерминированность: `random.Random(seed)` с фиксированным зерном на каждый спрайт.

## Что нарисовать

| Имя файла | Логический размер → px | Что |
|---|---|---|
| `medkit` | 10×10 → 15×15 | армейская аптечка сверху: светлый корпус (грязно-белый/серый), **красный крест**, ручка, пара пятен крови. Должна читаться на тёмно-красном полу. |
| `weapon_crate` | 14×14 → 21×21 | оружейный ящик: хаки/оливковый металл, рёбра жёсткости, трафаретная маркировка (несколько светлых пикселей-полос), замки, потёртости по углам. |
| `rare_part` | 10×10 → 15×15 | «редкая деталь»: металлическая шестерня/модуль с **синим свечением** (`ga.ramp(ga.hexc("4a8fe0"))`), вокруг 1–2 пикселя ореола полупрозрачным синим. |
| `blood_container` | 28×20 → 42×30 | кровавый контейнер — сброшенный армейский контейнер для образцов: тёмный металл, тёмно-красные полосы-маркировки, круглое окошко с кровью внутри, вмятины, кровь подтекает по борту, 2 «лампы» тускло-красные. Это награда — самый богатый по деталям спрайт. |
| `grenade` | 6×6 → 9×9 | граната сверху: тёмно-оливковый корпус с насечкой, чека-кольцо светлым металлом. |
| `spit_0`, `spit_1`, `spit_2` | 6×6 → 9×9 | плевок кислотой в полёте (летит вправо, +X): капля `ACID` с более светлым ядром и мелкими пузырями; 3 кадра «булькания» — форма чуть меняется. |
| `acid_0`, `acid_1`, `acid_2` | 40×40 → 60×60 | кислотная лужа на асфальте — декаль: неровное пятно (не круг!) из нескольких слившихся эллипсов, края полупрозрачные (альфа 90–140), центр плотнее (≈200), пузыри и светлые блики, тонкая тёмная кайма разъеденного асфальта. Три разные формы. Без `outline`. |
| `icon_grenade` | 8×8 → 12×12 | иконка для HUD: та же граната крупнее, с толстой обводкой, читается на тёмном фоне. |

## Код существующего генератора, которым можно пользоваться

### Помощники и палитры (`gen_art.py`, начало)

```python
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
```

### Холст

```python


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
```

### Палитры кислоты (уже есть в `gen_art.py`)

```python
ACID = ramp(hexc("8fd12e"), spread=0.7)
PUS = ramp(hexc("d9cf5a"), spread=0.5)
```

### Пример существующего предмета — жетон-кредит (так выглядит стиль)

```python
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


```

## Что отдать

1. `gen_art_m4.py` целиком, одним блоком.
2. Короткий список: что и почему нарисовано так.
