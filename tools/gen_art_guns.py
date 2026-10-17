"""Арт G7: спрайты 16 стволов сбоку (иконки для базы + боевой масштаб).

Запуск рядом с gen_art.py:  python tools/gen_art_guns.py
Пишет в art/:
  gun_<model>.png          иконка (база, арсенал/карточки): ствол вправо, обрезан по контуру, ~50–93 px длиной
  gun_<model>_world.png    та же модель в игровом масштабе (3 px арта = 1 игровая единица): АК ~20 ед, пистолет ~9, Мосинка ~27
  guns_meta.json           точки хвата / поддержки / дула в пикселях каждого спрайта

--out DIR перенаправляет вывод;  --sheet PNG [--old DIR] собирает лист «старые vs новые» (×4 иконки, ×6 боевые)
на асфальте и на крови. Детерминированно: ни одного random, шум — ga.hnoise.
Зависимости: gen_art (Canvas, ramp, hnoise, outline), Pillow, numpy.

Как рисуется: модель описана набором деталей в координатах «иконки» (1 ед = 1 px иконки, +x — к дулу).
Деталь = форма (многоугольник/прямоугольник/эллипс/полоса) + рампа. Затенение — по вертикальному «забегу» пикселей
детали: верхний пиксель — блик, нижний — тень, левый край чуть светлее (свет сверху-слева, как у всех спрайтов).
Боевой спрайт — те же детали, растеризованные в меньшем масштабе (мелкие детали `fine=True` пропускаются).
"""

import argparse
import json
import math
import os
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import gen_art as ga

# --- палитра ------------------------------------------------------------------------------------

BLUED = ga.ramp(ga.hexc("424d56"), spread=0.95)     # воронёная сталь
GUNMET = ga.ramp(ga.hexc("525c63"), spread=0.8)     # серый металл посветлее
STEEL = ga.ramp(ga.hexc("808c92"), spread=0.7)      # светлая сталь
PARK = ga.ramp(ga.hexc("444b50"), spread=0.85)      # паркеризация, зеленоватый
MAG = ga.ramp(ga.hexc("444e55"), spread=0.8)        # магазины
STAINLESS = ga.ramp(ga.hexc("7c888e"), spread=0.6)  # нержавейка (Бульдог)
SLIDE = ga.ramp(ga.hexc("66717a"), spread=0.7)      # светлый затвор (Страж)
POLY = ga.ramp(ga.hexc("3a3e44"), spread=1.0)       # полимер
RUBBER = ga.ramp(ga.hexc("25282b"), spread=0.9)
GRIPR = ga.ramp(ga.hexc("5a3a28"), spread=0.8)      # рукоять револьвера (тёмное дерево/резина)
WOOD = ga.ramp(ga.hexc("8a5730"), spread=0.7)       # тёплое дерево
DWOOD = ga.ramp(ga.hexc("5e3b22"), spread=0.7)      # тёмное дерево / бакелит
BAKE = ga.ramp(ga.hexc("6c3a20"), spread=0.7)
BRASS = ga.ramp(ga.hexc("b8923f"), spread=0.7)
CYAN = ga.ramp(ga.hexc("38b0e8"), spread=0.75)
CYAN_D = ga.ramp(ga.hexc("1c4a66"), spread=0.7)
ORANGE = ga.ramp(ga.hexc("ee8228"), spread=0.8)
HONEY = ga.ramp(ga.hexc("d8a52c"), spread=0.7)
OLIVE = ga.ramp(ga.hexc("4e5a3a"), spread=0.7)
DARKEST = (14, 16, 18)


# --- формы (векторные: принимают массивы X, Y в координатах иконки) --------------------------------

def poly(pts):
    P = [(float(x), float(y)) for x, y in pts]

    def f(X, Y):
        inside = np.zeros(X.shape, bool)
        for i in range(len(P)):
            ax, ay = P[i]
            bx, by = P[(i + 1) % len(P)]
            if ay == by:
                continue
            cond = (ay > Y) != (by > Y)
            xi = ax + (Y - ay) * (bx - ax) / (by - ay)
            inside ^= cond & (X < xi)
        return inside
    return f


def rect(x0, y0, x1, y1):
    return lambda X, Y: (X >= x0) & (X < x1) & (Y >= y0) & (Y < y1)


def ell(cx, cy, rx, ry):
    return lambda X, Y: ((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2 <= 1.0


def bez(p0, p1, p2, n=16):
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    return pts


def strip(pts, w0, w1=None):
    """Полоса заданной ширины вдоль ломаной (дуга рычага, изогнутый магазин, рукоять)."""
    w1 = w0 if w1 is None else w1
    n = len(pts)
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        w = (w0 + (w1 - w0) * i / max(1, n - 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return poly(left + right[::-1])


def inter(a, b):
    return lambda X, Y: a(X, Y) & b(X, Y)


# --- холст детали -------------------------------------------------------------------------------

class Gun:
    SS = 3  # подвыборок на пиксель по каждой оси

    def __init__(self, W, H, k, fine):
        self.k, self.fine = k, fine
        self.cv = ga.Canvas(math.ceil(W * k) + 2, math.ceil(H * k) + 2, 1.0)
        w, h, n = self.cv.w, self.cv.h, self.SS
        jj, ii = np.mgrid[0:h * n, 0:w * n]
        self.X = (ii + 0.5) / n / k
        self.Y = (jj + 0.5) / n / k
        self.w, self.h = w, h

    def mask(self, shape, cut=(), thr=0.5):
        n = self.SS
        hit = shape(self.X, self.Y)
        for c in cut:
            hit &= ~c(self.X, self.Y)
        cov = hit.reshape(self.h, n, self.w, n).sum(axis=(1, 3)) / (n * n)
        return cov >= thr

    def part(self, shape, rmp, style="metal", seed=1, fine=False, cut=(), thr=0.5):
        if fine and not self.fine:
            return
        m = self.mask(shape, cut, thr)
        h, w = m.shape
        last = len(rmp) - 1
        for x in range(w):
            y = 0
            while y < h:
                if not m[y, x]:
                    y += 1
                    continue
                y0 = y
                while y < h and m[y, x]:
                    y += 1
                tot = y - y0
                for yy in range(y0, y):
                    top, bot = yy - y0, y - 1 - yy
                    if style == "flat":
                        idx = 2
                    elif style == "glow":
                        idx = last if top == 0 and tot > 2 else last - 1
                    elif tot == 1:
                        idx = 3
                    elif tot == 2:
                        idx = 4 if top == 0 else 1
                    elif top == 0:
                        idx = 4
                    elif bot == 0:
                        idx = 0
                    else:
                        idx = 3 - round(top / (tot - 1) * 2.0)
                    if style != "flat" and style != "glow" and tot >= 3 and (x == 0 or not m[yy, x - 1]):
                        idx = min(last, idx + 1)  # левый край ловит свет
                    if style == "wood":
                        idx += (ga.hnoise(x // 5, yy, seed) > 0.55) - (ga.hnoise(x // 5, yy, seed + 9) > 0.62)
                        idx = max(0, min(last, idx))
                    self.cv.putn(x, yy, rmp[idx])

    def px(self, x, y):
        return int(math.floor(x * self.k)), int(math.floor(y * self.k))

    def dot(self, x, y, col, fine=False):
        if fine and not self.fine:
            return
        self.cv.putn(*self.px(x, y), col)

    def line(self, x0, y0, x1, y1, col, fine=False):
        if fine and not self.fine:
            return
        a, b = self.px(x0, y0), self.px(x1, y1)
        st = max(abs(b[0] - a[0]), abs(b[1] - a[1]), 1)
        for i in range(st + 1):
            self.cv.putn(round(a[0] + (b[0] - a[0]) * i / st), round(a[1] + (b[1] - a[1]) * i / st), col)

    def vlines(self, xs, y0, y1, col, fine=True):
        for x in xs:
            self.line(x, y0, x, y1, col, fine)

    def hlines(self, ys, x0, x1, col, fine=True):
        for y in ys:
            self.line(x0, y, x1, y, col, fine)


# --- стволы -------------------------------------------------------------------------------------
# Каждая функция рисует деталями в координатах иконки и возвращает точки: grip (задняя рука), support (передняя), muzzle.

def ak_s(g):
    # складной (подкидной) стальной приклад: каркас с отверстием
    g.part(poly([(0, 7), (3, 6.5), (27, 10), (27, 16), (2.5, 21.5), (0, 21)]), BLUED,
           cut=[poly([(5, 9.8), (22, 12), (22, 13.8), (6.5, 17.6)])])
    g.part(rect(0, 6.5, 2.8, 21.5), GUNMET)
    # изогнутый рожок
    g.part(strip(bez((43.5, 14), (44.5, 26), (57, 32.4), 16), 8.2), MAG)
    for t in (0.3, 0.5, 0.7, 0.88):
        px_, py_ = bez((43.5, 14), (44.5, 26), (57, 32.4), 20)[int(t * 20)]
        g.line(px_ - 3.4, py_ + 1.0, px_ + 3.6, py_ - 1.0, MAG[0], fine=True)
    # рукоять, скоба
    g.part(poly([(28, 15.5), (35, 15.5), (32.6, 29.4), (25.6, 29.4)]), BAKE, style="wood", seed=3)
    g.part(strip([(35, 16), (36, 20.3), (40, 21.2), (43, 16)], 1.3), GUNMET)
    g.part(rect(38, 16, 39.2, 18.8), BLUED)
    # ствольная коробка
    g.part(poly([(26, 8.2), (29, 6.6), (46, 6.6), (49, 8.2), (49, 15.5), (26, 15.5)]), BLUED)
    g.part(poly([(43, 6.6), (44.5, 4.2), (52, 4.2), (53, 6.6)]), GUNMET)
    g.hlines([11], 31, 44, BLUED[0])
    # деревянное цевьё и газовая трубка над стволом
    g.part(poly([(48, 8.6), (68, 8.6), (69.5, 10.4), (69.5, 15), (67, 16), (48, 16)]), WOOD, style="wood", seed=5)
    g.vlines([53, 57, 61], 10, 14, DWOOD[0])
    g.part(rect(46, 6.3, 71, 8.4), STEEL)
    g.part(rect(68, 9.6, 87, 12), BLUED)
    g.part(rect(68, 12.6, 78, 13.6), STEEL)
    g.part(rect(70, 5.8, 75.5, 12.8), GUNMET)
    g.part(rect(75.5, 8, 80.5, 9.6), GUNMET)
    g.part(rect(77, 3, 78.8, 8), GUNMET)
    g.part(poly([(83.5, 8.8), (88.5, 8.8), (91, 10), (91, 12.8), (83.5, 12.8)]), GUNMET)
    g.line(85.5, 9.4, 85.5, 12.2, DARKEST, fine=True)
    return {"grip": (31, 19), "support": (59, 12), "muzzle": (91, 10.9)}


def m4(g):
    # телескопический приклад и буферная трубка
    g.part(poly([(0, 8.2), (2.5, 7.4), (10, 9), (21, 11.2), (21, 16), (10, 17.4), (2.5, 20), (0, 19)]), POLY)
    g.part(rect(20, 11.6, 35, 15.2), POLY)
    g.vlines([6, 10, 14], 9.5, 17, POLY[0])
    g.part(rect(0, 8.2, 2, 19), RUBBER)
    # прямой магазин
    g.part(strip([(50, 18), (51.2, 24), (52.5, 32)], 7.5), GUNMET)
    g.hlines([24, 28], 48.3, 55, GUNMET[0])
    # рукоять, скоба
    g.part(poly([(34, 19.5), (40.5, 19.5), (38.5, 30), (32, 30)]), POLY)
    g.part(strip([(41, 19.5), (42, 22.8), (47, 23.2), (49, 19.5)], 1.3), POLY)
    g.part(rect(44.6, 19.5, 45.8, 21.6), BLUED)
    # нижняя и верхняя части ствольной коробки
    g.part(poly([(32, 14), (57, 14), (57, 19.5), (34, 19.5), (32, 17)]), PARK)
    g.part(rect(33, 8, 58, 14.2), PARK)
    g.hlines([11.4], 44, 53, PARK[0])
    g.part(rect(45.5, 9, 47, 11), BLUED, fine=True)
    # ручка переноски с прицелом
    g.part(rect(35, 3.6, 56, 5.6), BLUED)
    g.part(rect(35, 3.6, 37.6, 8.2), BLUED)
    g.part(rect(53.4, 3.6, 56, 8.2), BLUED)
    g.part(poly([(33.6, 3.6), (35.4, 1.6), (40, 1.6), (41, 3.6)]), GUNMET)
    # круглое цевьё с вентиляцией
    g.part(poly([(58, 9), (73.5, 9), (74, 10), (74, 15), (73.5, 16), (58, 16)]), POLY)
    g.vlines([61, 64, 67, 70], 10.5, 14.6, POLY[0])
    # газоблок, мушка, ствол, пламегаситель
    g.part(rect(74, 10.2, 79.5, 14.8), GUNMET)
    g.part(poly([(75, 10.2), (76, 3), (78, 3), (78.8, 10.2)]), BLUED)
    g.part(rect(79, 11.2, 86, 13.8), BLUED)
    g.part(rect(85, 10.6, 91, 14.4), GUNMET)
    g.vlines([86.8, 88.4, 90], 10.8, 14.2, DARKEST)
    return {"grip": (37, 24), "support": (66, 12.5), "muzzle": (91, 12.5)}


def butcher(g):
    # полимерная ложа (прямая) с пистолетной рукоятью
    g.part(poly([(0, 8.5), (5, 8), (28, 9.5), (28, 16.5), (5, 19), (0, 18)]), POLY)
    g.part(poly([(27, 15.5), (33.5, 15.5), (31.5, 26), (25.5, 26)]), POLY)
    g.hlines([13.2, 15.2], 8, 22, POLY[0])
    # ствольная коробка, скоба
    g.part(poly([(28, 8.4), (46, 7.6), (47, 9), (47, 15.5), (28, 15.5)]), GUNMET)
    g.part(rect(35, 10, 45, 12.6), BLUED)
    g.part(strip([(33, 15.5), (34, 19.6), (40, 19.8), (43, 15.5)], 1.3), GUNMET)
    g.part(rect(37.6, 15.5, 38.8, 18), BLUED)
    # ствол и трубчатый магазин под ним
    g.part(rect(46, 8.6, 90, 11.8), BLUED)
    g.part(rect(46, 12.4, 82, 14.8), GUNMET)
    g.part(rect(80, 12, 84, 15.4), STEEL)
    g.dot(88.5, 8, STEEL[4])
    g.dot(88.5, 7.4, STEEL[5])
    # подвижное цевьё с рёбрами
    g.part(poly([(54, 11), (75, 11), (76, 12.4), (76, 17.4), (74, 18.8), (54, 18.8), (52.4, 17)]), POLY)
    g.vlines([57, 59.6, 62.2, 64.8, 67.4, 70, 72.6], 12.6, 17.4, POLY[0])
    return {"grip": (29, 20), "support": (64, 15), "muzzle": (90, 10.2)}


def shkval(g):
    # деревянная ложа с изгибом шейки и затыльником
    g.part(poly([(0, 9.5), (3, 8), (30, 9.2), (30, 16.6), (22, 17.4), (18, 18.4), (5, 23), (0, 22)]), WOOD, style="wood", seed=7)
    g.part(rect(0, 9.2, 2.4, 22.2), RUBBER)
    # ствольная коробка, курок, скоба
    g.part(poly([(24.5, 5.8), (28, 6.6), (28.8, 9.6), (25, 9.6)]), STEEL)
    g.part(rect(28, 7.6, 50, 15.6), BLUED)
    g.part(rect(38, 9.6, 48, 11.4), BLUED)
    g.line(38, 10.5, 48, 10.5, DARKEST, fine=True)
    g.part(strip([(33, 15.6), (34, 19.8), (40, 20), (43, 15.6)], 1.3), BLUED)
    g.part(rect(37.6, 15.6, 38.8, 18.2), STEEL)
    # длинный ствол и трубчатый магазин
    g.part(rect(50, 8.4, 91, 11.4), BLUED)
    g.part(rect(50, 12, 84, 14.2), GUNMET)
    g.part(rect(82, 11.6, 86, 14.8), STEEL)
    g.dot(89.4, 7.4, STEEL[4])
    # деревянное цевьё-помпа с рифлением
    g.part(poly([(52, 11.4), (76, 11.4), (77, 12.6), (77, 17.6), (75.5, 18.8), (52, 18.8)]), WOOD, style="wood", seed=8)
    g.vlines([56, 58.4, 60.8, 63.2, 65.6, 68, 70.4, 72.8], 13, 17.6, DWOOD[0])
    return {"grip": (26, 14), "support": (64, 15), "muzzle": (91, 9.9)}


def colt(g):
    # рукоять: рамка, спуск на «бобровом хвосте», деревянные щёчки с насечкой
    g.part(poly([(12.4, 11.4), (27, 11.4), (27, 16), (24.4, 33.4), (9.6, 33.4), (10.6, 23)]), GUNMET)
    g.part(poly([(6.8, 9.4), (14, 10.4), (14.4, 15.6), (9, 14.4)]), BLUED)
    g.part(poly([(14.6, 16), (25, 16), (22.8, 31.6), (12, 31.6)]), DWOOD, style="wood", seed=11)
    for y in (18, 20.6, 23.2, 25.8, 28.4):
        g.line(14.4 - (y - 18) * 0.15, y, 24.6 - (y - 18) * 0.32, y, DWOOD[0], fine=True)
    g.dot(19, 24.4, STEEL[4])
    g.part(rect(9.4, 31.8, 24.6, 34.6), GUNMET)
    # рамка под затвором, скоба, спуск
    g.part(rect(12, 11, 40, 15.6), GUNMET)
    g.part(poly([(38, 11), (48.6, 11), (48.6, 14.6), (38, 15.6)]), GUNMET)
    g.part(strip([(26, 15.6), (26.6, 19.6), (33, 19.8), (36.4, 15.6)], 1.5), GUNMET)
    g.part(rect(30.6, 15.6, 31.8, 18.2), BLUED)
    # затвор с насечками, окно выброса, мушка и целик
    g.part(rect(11, 5, 50, 11.4), BLUED)
    g.part(rect(26, 5.6, 38, 7.8), [DARKEST] * 6)
    g.vlines([13, 14.6, 16.2, 17.8, 19.4, 21], 5.8, 10.8, BLUED[0])
    g.vlines([40.5, 42, 43.5], 5.8, 10.8, BLUED[0])
    g.part(rect(11.6, 3.2, 15, 5), BLUED)
    g.part(rect(47.6, 3.2, 50, 5), BLUED)
    # курок со шпорой, втулка ствола
    g.part(poly([(7.4, 4.4), (11.6, 4.2), (12, 9.6), (9, 9.6)]), STEEL)
    g.part(rect(49.6, 6.8, 54, 10.8), STEEL)
    return {"grip": (18, 22), "support": (18, 22), "muzzle": (54, 8.8)}


def guard(g):
    # полимерная рамка: прямая рукоять, угловатая скоба, планка Пикатинни, увеличенный магазин
    g.part(poly([(12, 11.6), (30, 11.6), (30, 16), (26, 32), (11.4, 32), (12, 21)]), POLY)
    g.part(poly([(10, 30.6), (26.6, 30.6), (26.6, 34.2), (10, 34.2)]), RUBBER)
    g.hlines([18, 20.6, 23.2, 25.8, 28.4], 12.6, 27, POLY[0])
    g.part(poly([(30, 11.6), (50, 11.6), (50, 15), (30, 16)]), POLY)
    g.vlines([40, 43, 46], 12.6, 14.4, DARKEST)
    g.part(strip([(28.6, 16), (29, 21.6), (38, 21.8), (40, 16)], 1.6), POLY)
    g.part(rect(33, 16, 34.4, 19.4), BLUED)
    # угловатый затвор без курка
    g.part(poly([(10, 4.8), (43, 4.8), (52, 8.4), (52, 12), (10, 12)]), SLIDE)
    g.part(rect(26, 5.6, 38, 7.8), BLUED)
    for i in range(5):
        g.line(11.6 + i * 1.5, 11.2, 13.2 + i * 1.5, 5.8, SLIDE[0], fine=True)
    g.part(rect(11, 3.4, 14.4, 4.8), BLUED)
    g.part(rect(40.6, 3.4, 42.8, 4.8), BLUED)
    g.part(rect(51.4, 8.6, 53.4, 11), STEEL)
    return {"grip": (18, 22), "support": (18, 22), "muzzle": (53.4, 9.8)}


def bulldog(g):
    # скруглённая «ботинковая» рукоять
    g.part(poly([(9, 12), (22.6, 12), (22.6, 16), (22, 24), (19.4, 28.4), (11.4, 29.6), (7, 26), (5.8, 19.4), (7, 14)]), GRIPR)
    g.part(ell(12.6, 26.4, 6.6, 3.6), GRIPR)
    for y in (17, 20, 23):
        g.line(8 - (y - 17) * 0.1, y, 20.4, y, GRIPR[0], fine=True)
    # рамка с горбом под скрытый курок
    g.part(poly([(7, 8), (12, 4.4), (16, 4.8), (27, 5.6), (27, 15.6), (22, 16), (8.6, 14)]), STAINLESS)
    # барабан с проточками
    g.part(rect(26, 5, 38.4, 15.6), STAINLESS)
    g.vlines([29.6, 33.2, 36.4], 6.4, 14.4, STAINLESS[0])
    # короткий ствол, кожух экстрактора, мушка
    g.part(rect(37.6, 6.8, 51, 10.8), STAINLESS)
    g.part(rect(37.6, 10.8, 47, 13.8), STAINLESS)
    g.part(poly([(47.6, 5.2), (51, 5.6), (51, 6.8), (47.6, 6.8)]), STAINLESS)
    g.part(strip([(23, 15.6), (24, 20.4), (31, 20.6), (34, 15.6)], 1.3), STAINLESS)
    g.part(rect(27.4, 15.6, 28.6, 18.4), BLUED)
    return {"grip": (14, 20), "support": (14, 20), "muzzle": (51, 8.8)}


def cowboy(g):
    # изогнутая «сливовая» рукоять с латунной рамкой
    g.part(strip(bez((24, 12), (15, 20), (7, 31), 14), 11.5, 8.5), WOOD, style="wood", seed=13)
    g.part(strip(bez((26, 14.4), (19, 22), (12.6, 31.4), 14), 1.6), BRASS)
    g.part(strip([(24, 14.4), (24.6, 19.4), (33.4, 19.8), (37.4, 14.4)], 1.7), BRASS)
    # курок со шпорой, рамка и барабан
    g.part(rect(14, 5.6, 29, 14.6), BLUED)
    g.part(rect(28, 5, 41, 14.8), STEEL)
    g.vlines([31.4, 34.6, 37.8], 6.4, 13.8, STEEL[0])
    g.part(rect(14, 12.6, 28, 14.8), BRASS)
    g.part(poly([(18, 9.8), (15, 8.6), (13, 6.2), (11.8, 3.8), (13.4, 2.8), (15.8, 4.4), (18, 7)]), STEEL)
    # длинный ствол, штанга экстрактора, мушка
    g.part(rect(40, 6.6, 72.6, 10.2), BLUED)
    g.part(rect(41, 11.2, 66, 13), GUNMET)
    g.part(rect(66, 10.8, 68.6, 13.4), STEEL)
    g.part(rect(70.4, 4.4, 72.6, 6.6), BLUED)
    return {"grip": (17, 20), "support": (17, 20), "muzzle": (72.6, 8.4)}


def ppsh(g):
    # деревянная ложа с шейкой
    g.part(poly([(0, 13), (2, 10), (14, 9.5), (34, 10), (34, 16), (30, 24), (26.6, 24), (26, 17), (10, 19), (2.4, 22.6), (0, 20)]),
           WOOD, style="wood", seed=17)
    g.part(rect(0, 11, 2, 21), RUBBER)
    # кожух ствола с овальными отверстиями
    g.part(rect(34, 7.2, 78, 15.4), BLUED)
    for r in (9.6, 12.8):
        for i in range(10):
            g.part(ell(47.5 + i * 2.9, r, 1.2, 0.95), [DARKEST] * 6, thr=0.3)
    # затворная коробка и целик
    g.part(rect(30, 6.6, 46, 15.6), BLUED)
    g.part(poly([(33, 6.6), (34.4, 3.6), (42, 3.6), (43, 6.6)]), GUNMET)
    # дисковый магазин (барабан)
    g.part(ell(46, 25, 10, 10), GUNMET)
    g.part(ell(46, 25, 7.6, 7.6), BLUED)
    g.part(ell(46, 25, 2.4, 2.4), STEEL)
    for a in range(0, 360, 45):
        g.dot(46 + math.cos(math.radians(a)) * 5, 25 + math.sin(math.radians(a)) * 5, GUNMET[3], fine=True)
    g.part(strip([(31, 15.6), (32, 21.2), (38, 21.6), (40.6, 15.6)], 1.3), BLUED)
    g.part(rect(35.4, 15.6, 36.6, 18.4), STEEL)
    # дульный компенсатор со скосом, мушка в кольце
    g.part(poly([(78, 7), (86.4, 7), (91, 10.4), (91, 15), (78, 15)]), GUNMET)
    g.line(83, 8.4, 83, 14, DARKEST, fine=True)
    g.part(rect(79, 3.8, 80.6, 7), GUNMET)
    return {"grip": (29, 20), "support": (58, 12), "muzzle": (91, 11.5)}


def osa(g):
    # складной проволочный приклад-рамка
    g.part(poly([(0, 7.6), (30, 9), (30, 15), (0, 22)]), POLY,
           cut=[poly([(2.8, 10), (28, 11.4), (28, 13.4), (2.8, 18.8)])])
    g.part(rect(0, 7.6, 2.2, 22), GUNMET)
    # прямой магазин
    g.part(rect(52, 14.6, 59.4, 33.4), GUNMET)
    g.hlines([19, 23, 27, 31], 52, 59.4, GUNMET[0])
    # рукоять и скоба
    g.part(poly([(33, 14.8), (39.6, 14.8), (38, 25.4), (32, 25.4)]), POLY)
    g.part(strip([(40, 15), (41, 19.8), (49, 20), (52, 15)], 1.3), GUNMET)
    g.part(rect(44.6, 15, 45.8, 17.6), BLUED)
    # трубчатая ствольная коробка, целик
    g.part(poly([(28.4, 9), (30, 7.6), (56, 7.6), (56, 14.8), (30, 14.8), (28.4, 13)]), PARK)
    g.part(rect(38, 9.4, 50, 11.4), BLUED)
    g.line(38, 10.4, 50, 10.4, DARKEST, fine=True)
    g.part(poly([(33, 7.6), (34.4, 5), (40, 5), (41, 7.6)]), GUNMET)
    # кожух ствола с отверстиями
    g.part(rect(56, 8, 80, 14.4), PARK)
    for r in (9.8, 12.6):
        for i in range(8):
            g.dot(58.4 + i * 2.9, r, DARKEST)
    g.part(rect(79, 7.8, 86, 14.6), GUNMET)
    g.vlines([81, 83, 85], 8.8, 13.8, DARKEST)
    g.part(rect(81, 4.6, 82.8, 7.8), GUNMET)
    return {"grip": (35, 20), "support": (56, 11), "muzzle": (86, 11)}


def mosin(g):
    # длинная деревянная ложа
    g.part(poly([(0, 9.6), (3, 8), (14, 10.4), (28, 11.4), (44, 11.4), (79, 10.6), (79, 14.6), (46, 15), (38, 15.4),
                 (33, 16.8), (30.6, 19.4), (27, 18.8), (20, 17), (10, 19.6), (4, 23.4), (0, 22)]), WOOD, style="wood", seed=19)
    g.part(rect(0, 9, 2.4, 22.8), STEEL)
    # затвор: рукоять вниз
    g.part(rect(17, 8.2, 30, 10.8), GUNMET)
    g.part(strip([(21.6, 10.4), (21.2, 17), (18.6, 22.6)], 1.7), STEEL)
    g.part(ell(18.2, 23.6, 2.6, 2.6), STEEL)
    # ствольная коробка, длинный ствол, прицельная планка
    g.part(rect(28, 7.4, 46.6, 12.6), BLUED)
    g.part(rect(46, 8.4, 91, 11.2), BLUED)
    g.part(poly([(48, 8.4), (53, 6.6), (57, 6.6), (58.4, 8.4)]), GUNMET)
    g.part(rect(56, 8, 58.2, 15.2), STEEL)
    g.part(rect(71, 8, 73.2, 15.2), STEEL)
    g.part(rect(87.6, 6.2, 89.6, 8.4), BLUED)
    g.part(strip([(33, 15.6), (34, 19.8), (41, 20), (44, 15.4)], 1.2), BLUED)
    g.part(rect(37.4, 15.4, 38.6, 17.8), STEEL)
    return {"grip": (28, 15), "support": (62, 13), "muzzle": (91, 9.8)}


def winchester(g):
    # деревянная ложа с прямой «шейкой» и латунным затыльником
    g.part(poly([(0, 9), (3, 8), (26, 10), (30, 11), (30, 15.4), (26, 17), (18, 18), (5, 23), (0, 22)]), WOOD, style="wood", seed=23)
    g.part(rect(0, 9, 2.6, 22.4), BRASS)
    # скоба-рычаг
    g.part(strip([(47, 15.4), (50.4, 22.6), (45, 27.2), (36, 27.4), (31.4, 22), (31, 15.6)], 1.9), GUNMET)
    g.part(rect(37, 15.4, 38.2, 18.2), BLUED)
    # ствольная коробка, курок
    g.part(poly([(25, 6.4), (28.6, 7), (29, 10), (26, 10)]), STEEL)
    g.part(rect(28, 8, 47, 15.6), BLUED)
    g.part(rect(33, 9.8, 44, 11.8), [DARKEST] * 6)
    g.part(ell(31, 12.8, 1, 1), BRASS, fine=True)
    # ствол, трубчатый магазин, цевьё
    g.part(rect(46, 8.8, 88, 11.6), BLUED)
    g.part(rect(46, 12, 80, 14), GUNMET)
    g.part(poly([(50, 13.6), (69, 13.6), (70, 15), (70, 17), (68, 18.2), (50, 18.2)]), WOOD, style="wood", seed=24)
    g.part(rect(78, 11.6, 82, 14.4), STEEL)
    g.part(rect(83.6, 6.4, 85.8, 8.8), BLUED)
    return {"grip": (27, 14), "support": (60, 16), "muzzle": (88, 10.2)}


def needle(g):
    # угловатая полимерная рама с отверстием, ствольная коробка
    g.part(poly([(0, 9), (4, 8), (25, 10.5), (25, 17.4), (5, 21.4), (0, 20)]), POLY,
           cut=[poly([(4, 11.4), (20, 13), (20, 14.6), (5, 17.8)])])
    g.part(rect(24, 8, 46, 17.4), GUNMET)
    g.part(rect(30, 10.4, 41, 12.6), CYAN, style="glow")
    g.part(poly([(28, 17.4), (34, 17.4), (32, 27.4), (26, 27.4)]), POLY)
    g.part(strip([(35, 17.4), (36, 21.6), (42, 21.8), (45, 17.4)], 1.3), GUNMET)
    g.part(rect(40, 17.4, 54, 22.6), POLY)
    g.part(rect(42, 19.2, 52, 20.6), CYAN, style="glow")
    # рельсы и катушки
    g.part(rect(46, 8.4, 90, 10.2), STEEL)
    g.part(rect(46, 13.4, 90, 15.2), STEEL)
    g.part(rect(46, 10.2, 92, 13.4), CYAN_D)
    g.line(48, 11.8, 92, 11.8, CYAN[4])
    for i in range(6):
        x = 51 + i * 6
        g.part(rect(x, 4.6, x + 3, 19), POLY)
        g.part(rect(x + 1, 6, x + 2, 17.6), CYAN, style="glow")
    g.part(poly([(90, 8.4), (96, 11.8), (90, 15.2)]), STEEL)
    return {"grip": (30, 21), "support": (60, 15), "muzzle": (96, 11.8)}


def spear(g):
    # тяжёлый приклад с отверстием
    g.part(poly([(0, 8), (4, 7), (25, 9.4), (25, 18.4), (5, 22.4), (0, 21)]), POLY,
           cut=[poly([(4, 10.8), (20, 12.4), (20, 15), (5, 18.6)])])
    g.part(rect(24, 7, 47, 18.4), GUNMET)
    g.part(rect(29, 9.6, 41, 12.4), ORANGE, style="glow")
    g.part(poly([(28, 18.4), (34.4, 18.4), (32, 28.4), (25.6, 28.4)]), POLY)
    g.part(strip([(35, 18.4), (36, 22.4), (42.4, 22.6), (45.4, 18.4)], 1.4), GUNMET)
    g.part(rect(40, 18.4, 56, 24.4), POLY)
    g.part(rect(42, 20.4, 54, 22.4), ORANGE, style="glow")
    # массивный кожух ствола и оранжевые кольца
    g.part(rect(46, 7.8, 94, 15.8), BLUED)
    g.part(rect(46, 11, 94, 12.6), ORANGE, style="glow")
    for i in range(4):
        x = 52 + i * 9
        g.part(rect(x, 1.8, x + 5, 21.6), POLY)
        g.part(rect(x + 1, 3.2, x + 4, 20.2), ORANGE, style="glow")
    # остриё
    g.part(poly([(93, 6.4), (104, 11.8), (93, 17.2)]), STEEL)
    g.line(93, 11.8, 103, 11.8, STEEL[5], fine=True)
    return {"grip": (30, 22), "support": (62, 16), "muzzle": (104, 11.8)}


def grom(g):
    # деревянный приклад
    g.part(poly([(0, 10), (3, 8.6), (26, 11), (30, 11), (30, 17), (24, 17.6), (6, 22.4), (0, 21)]), WOOD, style="wood", seed=29)
    g.part(rect(0, 9.6, 2.4, 21.6), RUBBER)
    # переломная ствольная коробка, скоба
    g.part(rect(28, 8.2, 44, 16.8), BLUED)
    g.part(rect(32, 10.4, 40, 12.2), [DARKEST] * 6)
    g.part(strip([(33, 16.8), (34, 21), (40, 21.2), (43, 16.8)], 1.3), BLUED)
    g.part(rect(37.6, 16.8, 38.8, 19.4), STEEL)
    # короткий толстый ствол
    g.part(rect(44, 6.4, 86, 15.4), OLIVE)
    g.part(rect(84, 6.4, 88.4, 15.4), BLUED)
    g.part(rect(60, 6.2, 62, 15.6), STEEL)
    g.part(rect(72, 6.2, 74, 15.6), STEEL)
    g.part(poly([(46, 14.6), (64, 14.6), (64, 19.4), (47, 19.4)]), DWOOD, style="wood", seed=30)
    # откидной целик и мушка
    g.part(rect(53.4, 0.8, 55.8, 6.4), STEEL)
    g.part(rect(51, 5.4, 58.4, 6.4), GUNMET)
    g.part(rect(81.6, 4, 83.4, 6.4), BLUED)
    return {"grip": (26, 14), "support": (54, 16), "muzzle": (88.4, 10.9)}


def hive(g):
    # телескопический проволочный приклад
    g.part(poly([(0, 7.4), (26, 9.4), (26, 14.6), (0, 20)]), POLY,
           cut=[poly([(2.6, 9.6), (24, 11.2), (24, 13), (2.6, 17.6)])])
    g.part(rect(0, 7.4, 2.2, 20), GUNMET)
    # рукоять и скоба
    g.part(poly([(30, 17), (36, 17), (34, 28), (28, 28)]), POLY)
    g.part(strip([(36.4, 17), (37.4, 21.6), (44, 21.8), (47, 17)], 1.3), GUNMET)
    # большой револьверный барабан-кассета с шестигранной сотой
    g.part(ell(46, 11.5, 12, 11.5), GUNMET)
    g.part(ell(46, 11.5, 9.6, 9.2), BLUED)
    g.part(inter(ell(46, 11.5, 12, 11.5), rect(37.4, 0, 39.4, 30)), HONEY)
    g.part(inter(ell(46, 11.5, 12, 11.5), rect(52.6, 0, 54.6, 30)), HONEY)
    for dx, dy in ((-3.4, -4), (-3.4, 4), (3.4, -4), (3.4, 4), (0, -7), (0, 7), (-3.4, 0), (3.4, 0)):
        g.part(ell(46 + dx, 11.5 + dy, 1.5, 1.5), [DARKEST] * 6, fine=True)
    g.part(rect(23, 6, 36, 15.8), PARK)
    # короткий толстый ствол, дульный срез
    g.part(rect(56, 6.4, 78, 17), PARK)
    g.part(rect(76, 5.8, 81.4, 17.6), BLUED)
    g.part(rect(78.4, 8, 81.4, 15.6), HONEY[0:1] * 6)
    # верхняя планка с прицелом
    g.part(rect(34, 2, 56, 3.8), BLUED)
    g.part(rect(52, 0.6, 55, 3.8), GUNMET)
    g.part(rect(36, 0.6, 38.6, 3.8), GUNMET)
    # передняя рукоять
    g.part(poly([(60, 17), (66, 17), (65.4, 28.4), (60.6, 28.4)]), POLY)
    return {"grip": (33, 22), "support": (63, 23), "muzzle": (81.4, 11.7)}


GUNS = {
    "ak_s": ak_s, "m4": m4, "butcher": butcher, "shkval": shkval,
    "needle": needle, "spear": spear, "grom": grom, "hive": hive,
    "colt": colt, "guard": guard, "bulldog": bulldog, "cowboy": cowboy,
    "ppsh": ppsh, "osa": osa, "mosin": mosin, "winchester": winchester,
}

# Длина боевого спрайта в пикселях арта (3 px = 1 игровая единица).
WORLD_LEN = {
    "ak_s": 61, "m4": 57, "butcher": 69, "shkval": 75, "needle": 66, "spear": 73, "grom": 60, "hive": 60,
    "colt": 27, "guard": 28, "bulldog": 24, "cowboy": 39, "ppsh": 60, "osa": 55, "mosin": 81, "winchester": 70,
}
CANVAS = (110, 44)


def render(model, k, fine, outline_k=0.3):
    g = Gun(CANVAS[0], CANVAS[1], k, fine)
    pts = GUNS[model](g)
    g.cv.outline(outline_k)
    img = g.cv.image()
    box = img.getbbox()
    img = img.crop(box)
    meta = {"size": [img.width, img.height]}
    for name, (x, y) in pts.items():
        meta[name] = [max(0, min(img.width - 1, int(round(x * k - box[0])))),
                      max(0, min(img.height - 1, int(round(y * k - box[1]))))]
    return img, meta


def build(model):
    """Иконка и боевой спрайт модели: ((img, meta), (img, meta))."""
    icon, imeta = render(model, 1.0, True)
    k = WORLD_LEN[model] / icon.width
    world, wmeta = render(model, k, k >= 0.8, 0.32)
    wmeta["length_units"] = round(world.width / 3.0, 1)
    return (icon, imeta), (world, wmeta)


# --- лист сравнения ---------------------------------------------------------------------------

ASPHALT = (61, 63, 67)
BLOODBG = (60, 12, 14)


def up(img, k):
    return img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)


def sheet(results, path, old_dir=None):
    names = {"ak_s": "АК-С", "m4": "М4", "butcher": "Мясник", "shkval": "Шквал", "needle": "Игла", "spear": "Копьё",
             "grom": "Гром", "hive": "Улей", "colt": "Кольт", "guard": "Страж", "bulldog": "Бульдог",
             "cowboy": "Ковбой", "ppsh": "ППШ", "osa": "Оса", "mosin": "Мосинка", "winchester": "Винчестер"}
    cols = [("old S6 x4", 4, 420), ("icon x4 асфальт", 4, 440), ("icon x4 кровь", 4, 440),
            ("world x6 асфальт", 6, 640), ("world x6 кровь", 6, 640)]
    row_h, lab_w, head = 190, 130, 28
    W = lab_w + sum(c[2] for c in cols)
    H = head + row_h * len(results)
    im = Image.new("RGB", (W, H), (20, 20, 22))
    d = ImageDraw.Draw(im)
    font = None
    for fp in ("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/segoeui.ttf"):
        if os.path.exists(fp):
            font = ImageFont.truetype(fp, 13)
            break
    x = lab_w
    for title, _, w in cols:
        d.text((x + 6, 8), title, fill=(220, 220, 210), font=font)
        x += w
    for r, (model, (icon, _), (world, _)) in enumerate(results):
        y = head + r * row_h
        d.text((6, y + 8), "%s\n%s\nicon %dx%d\nworld %dx%d" % (model, names[model], *icon.size, *world.size), fill=(230, 230, 220), font=font)
        x = lab_w
        for ci, (title, k, w) in enumerate(cols):
            bg = BLOODBG if "кровь" in title else ASPHALT
            d.rectangle((x, y, x + w - 2, y + row_h - 2), fill=bg)
            if ci == 0:
                src = None
                if old_dir:
                    p = os.path.join(old_dir, "gun_%s.png" % model)
                    if os.path.exists(p):
                        src = Image.open(p).convert("RGBA")
            else:
                src = icon if "icon" in title else world
            if src is not None:
                big = up(src, k)
                im.paste(big, (x + 8, y + (row_h - big.height) // 2), big)
            x += w
    im.save(path)


# --- запуск -----------------------------------------------------------------------------------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", metavar="DIR", help="куда писать вместо art/")
    ap.add_argument("--sheet", metavar="PNG", help="лист сравнения (старые vs новые)")
    ap.add_argument("--old", metavar="DIR", help="папка со старыми gun_*.png для листа")
    ap.add_argument("--only", metavar="IDS", help="только эти модели через запятую (для итераций)")
    args = ap.parse_args(argv)
    out = os.path.abspath(args.out) if args.out else ga.OUT
    os.makedirs(out, exist_ok=True)
    ids = args.only.split(",") if args.only else list(GUNS)
    results = []
    meta = {}
    for model in ids:
        (icon, imeta), (world, wmeta) = build(model)
        icon.save(os.path.join(out, "gun_%s.png" % model))
        world.save(os.path.join(out, "gun_%s_world.png" % model))
        results.append((model, (icon, imeta), (world, wmeta)))
        meta[model] = {"icon": imeta, "world": wmeta}
        print("gun_%s.png %dx%d  world %dx%d" % (model, *icon.size, *world.size))
    if not args.only:
        doc = {"note": "grip/support/muzzle - точки в пикселях соответствующего спрайта (ствол смотрит вправо); 3 px арта = 1 игровая единица",
               "models": meta}
        lines = []
        for m in sorted(meta):
            parts = ["\"%s\": %s" % (k, json.dumps(meta[m][k], sort_keys=True)) for k in ("icon", "world")]
            lines.append("  \"%s\": {%s}" % (m, ", ".join(parts)))
        text = "{" + "\n" + " \"note\": " + json.dumps(doc["note"], ensure_ascii=False) + "," + "\n" + " \"models\": {" + "\n" + (",\n").join(lines) + "\n" + " }" + "\n" + "}" + "\n"
        with open(os.path.join(out, "guns_meta.json"), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    if args.sheet:
        sheet(results, args.sheet, args.old)


if __name__ == "__main__":
    main()
