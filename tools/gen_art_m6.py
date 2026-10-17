"""Арт M6 (экран базы). Запуск рядом с gen_art.py: python tools/gen_art_m6.py.

Пишет в art/:
  base_bg.png                 1920x1080, фон казармы (бетон, койки, шкафы, ящики, кровь, свет ламп)
  gun_<model>.png (x16)       силуэты стволов сбоку, смотрят вправо, обрезаны по контуру
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


# --- стволы ----------------------------------------------------------------------------------

def gun_ak_s():
    cv = new()
    poly(cv, [(1, 8), (15, 9.5), (15, 14.5), (2.5, 16), (0.6, 12.5)], WOOD, 11)
    box(cv, 15, 7.6, 31, 12.4, DARK_METAL, 12)
    box(cv, 31, 9.0, 43, 12.4, WOOD, 13, 0.6)
    box(cv, 31, 7.2, 45, 8.9, STEEL, 14, 0.3)
    box(cv, 43, 8.7, 58, 10.1, STEEL, 15, 0.3)
    box(cv, 53, 6.9, 54.4, 8.7, STEEL, 16, 0.2)
    box(cv, 57, 8.2, 59, 10.6, DARK_METAL, 17, 0.3)
    poly(cv, [(22, 12.4), (28, 12.4), (30, 17.5), (32.4, 22), (27, 22.8), (22.6, 17)], BLACK, 18)
    grip(cv, [(15.5, 12.4), (19.6, 12.4), (18.4, 18.4), (14.6, 18.4)], DARK_WOOD, 19)
    cv.line(20.5, 12.8, 20.5, 15.4, STEEL[3])
    return finish(cv)


def gun_m4():
    cv = new()
    box(cv, 1, 8.6, 12, 13.4, BLACK, 21, 0.6)
    box(cv, 10, 9.4, 18, 11.8, STEEL, 22, 0.3)
    box(cv, 17, 7.6, 34, 12.6, BLACK, 23)
    box(cv, 20, 5.2, 32, 7.2, BLACK, 24, 0.5)
    cv.line(21, 5.7, 31, 5.7, STEEL[3])
    box(cv, 34, 8.0, 47, 11.8, BLACK, 25, 0.4)
    for x in (37, 40, 43):
        cv.line(x, 8.6, x, 11.2, DARK_METAL[0])
    box(cv, 47, 9.1, 57, 10.3, STEEL, 26, 0.3)
    box(cv, 56.5, 8.4, 59, 11, DARK_METAL, 27, 0.3)
    box(cv, 49.5, 6.4, 51, 9.2, STEEL, 28, 0.2)
    poly(cv, [(24, 12.6), (29, 12.6), (28.2, 20.4), (23, 20.4)], BLACK, 29, bias=0.1)
    cv.line(23.4, 20, 28, 20, STEEL[2])
    grip(cv, [(16.5, 12.6), (20.4, 12.6), (18.8, 19), (14.8, 19)], BLACK, 30)
    return finish(cv)


def gun_butcher():
    cv = new()
    poly(cv, [(1, 8.5), (15, 9.6), (15, 14.4), (2.5, 16.5), (0.6, 12.8)], WOOD, 31)
    box(cv, 15, 7.8, 28, 12.2, DARK_METAL, 32)
    box(cv, 28, 8.2, 59, 9.9, STEEL, 33, 0.3)
    box(cv, 28, 10.2, 51, 11.8, STEEL, 34, 0.3)
    box(cv, 33, 10.6, 45, 14.6, WOOD, 35, 0.6)
    for x in (35, 37.5, 40, 42.5):
        cv.line(x, 11.2, x, 14.0, DARK_WOOD[0])
    box(cv, 58, 7.6, 59.6, 9.9, STEEL, 36, 0.2)
    grip(cv, [(15.5, 12.2), (19.5, 12.2), (18.2, 18), (14.6, 18)], DARK_WOOD, 37)
    return finish(cv)


def gun_shkval():
    cv = new()
    poly(cv, [(3, 9), (15, 9.4), (15, 13.6), (5, 15), (2, 12)], BLACK, 41)
    box(cv, 15, 7.4, 30, 12.6, BLACK, 42)
    box(cv, 20, 8.2, 25, 9.3, BRASS, 43, 0.2)
    box(cv, 30, 8.0, 54, 9.8, STEEL, 44, 0.3)
    box(cv, 30, 10.0, 48, 11.6, STEEL, 45, 0.3)
    box(cv, 31, 10.4, 42, 14.8, BLACK, 46, 0.7)
    for x in (33, 35.5, 38, 40.5):
        cv.line(x, 11.0, x, 14.2, STEEL[1])
    box(cv, 53, 7.4, 56.4, 10, DARK_METAL, 47, 0.3)
    grip(cv, [(15.5, 12.6), (19.6, 12.6), (18.4, 18.6), (14.4, 18.6)], BLACK, 48)
    return finish(cv)


def gun_needle():
    cv = new()
    poly(cv, [(14, 12), (19, 12), (17.6, 19), (13, 19)], BLACK, 51)
    box(cv, 2, 8.4, 12, 12, BLACK, 52, 0.6)
    box(cv, 10, 6.8, 32, 12.4, DARK_METAL, 53)
    box(cv, 14, 4.8, 28, 6.8, STEEL, 54, 0.3)
    box(cv, 32, 7.2, 59, 8.4, STEEL, 55, 0.3)
    box(cv, 32, 10.2, 59, 11.4, STEEL, 56, 0.3)
    cv.line(32, 9.3, 59, 9.3, BLUE[5])
    for x in (35, 40.5, 46, 51.5):
        box(cv, x, 6.2, x + 1.7, 12.6, BLUE, 57 + int(x), 0.3)
        cv.line(x + 0.6, 7, x + 0.6, 11.8, BLUE[5])
    box(cv, 57, 6.6, 60, 12, DARK_METAL, 58, 0.3)
    return finish(cv)


def gun_spear():
    cv = new()
    poly(cv, [(14, 13), (19.6, 13), (18, 21), (12.6, 21)], DARK_WOOD, 61)
    box(cv, 1, 7.6, 12, 13, BLACK, 62, 0.6)
    box(cv, 10, 5.6, 33, 13.6, DARK_METAL, 63)
    box(cv, 14, 3.4, 29, 5.6, STEEL, 64, 0.3)
    box(cv, 33, 6.0, 52, 8.0, STEEL, 65, 0.3)
    box(cv, 33, 11.0, 52, 13.0, STEEL, 66, 0.3)
    cv.line(33, 9.5, 52, 9.5, ORANGE[5])
    for x in (36, 42, 48):
        box(cv, x, 4.8, x + 2.2, 14.2, ORANGE, 67 + int(x), 0.4)
        cv.line(x + 0.8, 5.8, x + 0.8, 13.2, ORANGE[5])
    poly(cv, [(52, 5.4), (61, 9.5), (52, 13.6)], STEEL, 68)
    cv.line(53, 9.5, 59.5, 9.5, ORANGE[5])
    return finish(cv)


def gun_grom():
    cv = new()
    poly(cv, [(2, 7), (14, 10), (14, 13), (3, 11)], DRAB, 71)
    cv.tube(2, 6.4, 15, 9.6, 0.9, STEEL, tex=0.1, seed=71)
    box(cv, 14, 6.6, 27, 13.4, STEEL, 72)
    for k in range(6):
        a = k * math.tau / 6
        cv.dot(20.5 + math.cos(a) * 3.0, 10 + math.sin(a) * 2.6, DARK_METAL[0])
    cv.ellipse(20.5, 10, 1.3, 1.3, DARK_METAL, bias=-0.4)
    box(cv, 27, 5.8, 55, 11.6, DRAB, 73, 0.7)
    box(cv, 54, 4.8, 58.6, 12.6, STEEL, 74, 0.4)
    box(cv, 38, 3.8, 41.5, 5.8, STEEL, 75, 0.2)
    cv.line(30, 7.0, 52, 7.0, DRAB[4])
    grip(cv, [(16, 13.4), (20.4, 13.4), (19, 20), (14.4, 20)], BLACK, 76)
    box(cv, 31, 11.6, 38, 14.4, BLACK, 77, 0.4)
    return finish(cv)


def gun_hive():
    cv = new()
    poly(cv, [(2, 8), (14, 10), (14, 14), (3, 13)], BLACK, 81)
    box(cv, 14, 6.0, 28, 14.4, DARK_METAL, 82)
    for y in (5.2, 8.6, 12.0):
        box(cv, 28, y, 53, y + 3.2, BLACK, 83 + int(y), 0.5)
        box(cv, 52, y - 0.3, 56, y + 3.5, HONEY, 90 + int(y), 0.4)
        cv.ellipse(55.2, y + 1.6, 0.9, 0.9, DARK_METAL, bias=-0.5)
        for x in (33, 38, 43, 48):
            cv.line(x, y + 0.6, x, y + 2.6, HONEY[3])
    box(cv, 28, 2.4, 48, 4.6, HONEY, 95, 0.4)
    for x in (31, 35, 39, 43):
        cv.dot(x, 3.5, DARK_METAL[1])
    grip(cv, [(16, 14.4), (20.4, 14.4), (19, 21), (14.4, 21)], BLACK, 96)
    return finish(cv)


def gun_colt():
    cv = new()
    box(cv, 13, 5.0, 40, 10.0, STEEL, 101, 0.5)
    for x in (13.8, 15.4, 17.0, 18.6):
        cv.line(x, 5.5, x, 9.6, DARK_METAL[1])
    box(cv, 13, 10.0, 31, 13.0, DARK_METAL, 102, 0.4)
    box(cv, 39, 6.2, 43, 9.0, STEEL, 103, 0.3)
    box(cv, 13, 3.6, 15, 5.2, STEEL, 104, 0.2)
    box(cv, 38.4, 3.8, 39.8, 5.2, STEEL, 105, 0.2)
    grip(cv, [(14, 13), (23, 13), (21, 22.4), (11.6, 22.4)], WOOD, 106)
    cv.ellipse(27, 14.6, 2.6, 1.8, DARK_METAL, cond=lambda x, y: y > 14.0 or abs(x - 27) > 1.4)
    cv.line(25.2, 12.6, 25.2, 14.6, STEEL[4])
    return finish(cv)


def gun_guard():
    cv = new()
    box(cv, 12, 5.0, 41, 10.4, BLACK, 111, 0.5)
    box(cv, 36, 5.6, 41, 10.0, STEEL, 112, 0.3)
    for x in (13.4, 15.0, 16.6):
        cv.line(x, 5.5, x, 9.8, STEEL[1])
    box(cv, 12, 10.4, 32, 13.4, BLACK, 113, 0.4)
    box(cv, 40, 6.4, 44, 9.2, STEEL, 114, 0.3)
    box(cv, 12, 3.6, 14, 5.2, STEEL, 115, 0.2)
    box(cv, 38.4, 3.8, 39.8, 5.2, STEEL, 116, 0.2)
    grip(cv, [(13, 13.4), (24, 13.4), (22.4, 24), (11, 24)], BLACK, 117)
    box(cv, 11, 22.6, 22.6, 24.4, STEEL, 118, 0.2)
    cv.ellipse(28, 15.0, 2.8, 1.8, DARK_METAL, cond=lambda x, y: y > 14.4 or abs(x - 28) > 1.5)
    cv.dot(18, 7.8, ORANGE[4])
    return finish(cv)


def gun_bulldog():
    cv = new()
    box(cv, 14, 4.8, 22, 11.4, STEEL, 121)
    box(cv, 22, 4.2, 30, 11.0, STEEL, 122, 0.8)
    for x in (23.4, 25.4, 27.4):
        cv.line(x, 5.0, x, 10.2, DARK_METAL[1])
    box(cv, 30, 6.0, 42, 8.2, STEEL, 123, 0.3)
    box(cv, 30, 8.2, 41, 9.4, STEEL, 124, 0.2)
    box(cv, 41, 5.0, 42.6, 6.4, STEEL, 125, 0.2)
    poly(cv, [(13, 3.4), (16, 3.6), (15.4, 6.2), (12.6, 5.6)], DARK_METAL, 126)
    grip(cv, [(13, 11.4), (21, 11.4), (19.4, 21), (10, 20)], DARK_WOOD, 127)
    cv.ellipse(23.4, 13.6, 2.6, 1.8, DARK_METAL, cond=lambda x, y: y > 13.0 or abs(x - 23.4) > 1.4)
    return finish(cv)


def gun_cowboy():
    cv = new()
    box(cv, 13, 4.8, 21, 11.0, BRASS, 131)
    box(cv, 21, 4.4, 28, 10.6, STEEL, 132, 0.8)
    for x in (22.2, 24.0, 25.8):
        cv.line(x, 5.0, x, 9.8, DARK_METAL[1])
    box(cv, 28, 5.4, 52, 7.6, STEEL, 133, 0.3)
    box(cv, 29, 8.2, 46, 9.4, STEEL, 134, 0.2)
    box(cv, 51, 3.8, 52.6, 5.6, STEEL, 135, 0.2)
    poly(cv, [(11, 2.4), (15.6, 3.2), (15, 6.0), (11.4, 5.2)], DARK_METAL, 136)
    grip(cv, [(11, 11.0), (19, 11.0), (17.8, 20), (7.6, 22)], WOOD, 137)
    box(cv, 8.8, 20.0, 17.6, 22.2, BRASS, 138, 0.2)
    cv.ellipse(23, 13.2, 2.8, 1.8, DARK_METAL, cond=lambda x, y: y > 12.6 or abs(x - 23) > 1.5)
    return finish(cv)


def gun_ppsh():
    cv = new()
    poly(cv, [(1, 9), (14, 9.8), (14, 14.4), (2.4, 16.2), (0.6, 12.6)], WOOD, 141)
    box(cv, 14, 8.0, 27, 12.0, DARK_METAL, 142)
    box(cv, 27, 7.0, 49, 11.6, STEEL, 143, 0.6)
    for i in range(7):
        cv.dot(30 + i * 2.7, 8.4, DARK_METAL[0])
        cv.dot(31.3 + i * 2.7, 10.1, DARK_METAL[0])
    box(cv, 49, 8.2, 58, 10.0, STEEL, 144, 0.3)
    box(cv, 56.4, 7.4, 59.4, 10.8, DARK_METAL, 145, 0.3)
    cv.ellipse(30, 17.4, 5.6, 5.6, STEEL, tex=0.15, seed=146)
    cv.ellipse(30, 17.4, 3.6, 3.6, DARK_METAL, bias=-0.3)
    cv.ellipse(30, 17.4, 1.2, 1.2, STEEL, bias=0.2)
    box(cv, 26.6, 11.6, 33.4, 13.2, DARK_METAL, 147, 0.2)
    grip(cv, [(16, 12.0), (20, 12.0), (18.6, 18), (14.6, 18)], DARK_WOOD, 148)
    return finish(cv)


def gun_osa():
    cv = new()
    cv.tube(1, 9, 12, 9, 0.9, STEEL, tex=0.1, seed=151)
    cv.tube(1, 13.5, 12, 11.5, 0.9, STEEL, tex=0.1, seed=152)
    box(cv, 0.4, 8.2, 2, 14.2, BLACK, 153, 0.3)
    box(cv, 12, 6.4, 35, 11.4, DARK_METAL, 154)
    box(cv, 14, 5.0, 22, 6.6, STEEL, 155, 0.3)
    box(cv, 35, 7.0, 46, 10.6, STEEL, 156, 0.5)
    for i in range(4):
        cv.line(37 + i * 2.4, 7.6, 37 + i * 2.4, 10.0, DARK_METAL[0])
    box(cv, 46, 8.2, 58, 9.6, STEEL, 157, 0.3)
    box(cv, 56.4, 7.4, 59.4, 10.4, DARK_METAL, 158, 0.3)
    box(cv, 25.4, 11.4, 31, 23.8, BLACK, 159, 0.5)
    for y in (14, 17, 20):
        cv.line(26, y, 30.4, y, STEEL[2])
    grip(cv, [(14.6, 11.4), (18.8, 11.4), (17.6, 18), (13.2, 18)], BLACK, 160)
    return finish(cv)


def gun_mosin():
    cv = new()
    poly(cv, [(1, 9.6), (24, 9.6), (31, 9.0), (31, 13.2), (24, 13.6), (5, 17), (0.6, 14)], WOOD, 161)
    box(cv, 17, 8.0, 29, 10.4, DARK_METAL, 162, 0.4)
    box(cv, 31, 8.4, 59, 10.0, STEEL, 163, 0.3)
    box(cv, 46, 10.0, 56, 11.4, WOOD, 164, 0.3)
    box(cv, 58, 7.2, 59.6, 10, STEEL, 165, 0.2)
    cv.tube(22, 11.2, 26, 11.2, 0.8, STEEL)
    cv.line(21.4, 8.6, 20.4, 6.2, STEEL[4])
    cv.ellipse(20.2, 5.8, 0.9, 0.9, STEEL, bias=0.1)
    cv.tube(18, 5.0, 40, 5.0, 2.1, BLACK, tex=0.1, seed=166)
    box(cv, 22, 6.2, 24, 8.2, STEEL, 167, 0.2)
    box(cv, 34, 6.2, 36, 8.4, STEEL, 168, 0.2)
    cv.ellipse(18, 5.0, 1.4, 1.4, DARK_METAL, bias=-0.3)
    return finish(cv)


def gun_winchester():
    cv = new()
    poly(cv, [(1, 9.6), (18, 9.2), (19, 13.2), (14, 13.8), (5, 17), (0.6, 14)], WOOD, 171)
    box(cv, 18, 7.2, 31, 12.0, BRASS, 172, 0.5)
    for x in (21, 25):
        cv.dot(x, 9.2, DARK_METAL[1])
    box(cv, 31, 8.0, 59, 9.8, STEEL, 173, 0.3)
    box(cv, 31, 10.0, 52, 11.4, STEEL, 174, 0.3)
    box(cv, 32, 11.4, 44, 13.8, WOOD, 175, 0.5)
    box(cv, 58, 6.8, 59.6, 9.8, STEEL, 176, 0.2)
    ring(cv, 24.6, 16.0, 4.6, 3.2, STEEL, 177)
    cv.line(20.5, 12.4, 22, 14, STEEL[2])
    box(cv, 40, 6.4, 41.6, 8.1, STEEL, 178, 0.2)
    return finish(cv)


GUNS = {
    "ak_s": gun_ak_s, "m4": gun_m4, "butcher": gun_butcher, "shkval": gun_shkval,
    "needle": gun_needle, "spear": gun_spear, "grom": gun_grom, "hive": gun_hive,
    "colt": gun_colt, "guard": gun_guard, "bulldog": gun_bulldog, "cowboy": gun_cowboy,
    "ppsh": gun_ppsh, "osa": gun_osa, "mosin": gun_mosin, "winchester": gun_winchester,
}


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
    for model, fn in GUNS.items():
        out.append(("gun_" + model, fn()))
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
