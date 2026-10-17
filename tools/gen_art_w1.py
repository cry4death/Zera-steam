"""Мелкий металл W1, в той же плотности, что gen_art. Детерминированный запуск."""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw
import gen_art as ga


def casing(name, length, shell=False):
    """Мелкая гильза: приглушённая латунь, тёмная база и один светлый ряд-блик."""
    img = Image.new('RGBA', (length + 2, 4))
    d = ImageDraw.Draw(img)
    d.rectangle((1, 1, length, 2), fill='#5f3029' if shell else '#6b5a38')
    d.line((1, 1, length, 1), fill='#92473c' if shell else '#a38b55')
    d.point((length, 1), fill='#b07a60' if shell else '#c3ad76')
    ga.save(img, name)


def flash(kind, variant):
    """Раздельные изогнутые языки: жар у дула, просветы и прозрачная бахрома."""
    rng = random.Random(2718 + variant + 101 * ('small', 'rifle', 'shotgun', 'sniper', 'launcher').index(kind))
    length, height, spread = {'small': (22, 22, .3), 'rifle': (34, 38, .2),
                              'shotgun': (40, 40, .5), 'sniper': (47, 38, .16),
                              'launcher': (34, 38, .7)}[kind]
    img = Image.new('RGBA', (length + 8, height))
    # Каждый язык — цепочка сужающихся пятен, а не сплошной треугольник.
    blunt = kind == 'launcher' # тупой клуб: короткие толстые языки в широком веере
    tongues = [(length * rng.uniform(.6, .75) if blunt else length * rng.uniform(.82, 1), rng.uniform(-.06, .06), 4.2 if blunt else 2.6)]
    count = {'small': 4, 'rifle': 3, 'shotgun': 6, 'sniper': 3, 'launcher': 7}[kind]
    for j in range(count):
        side = -1 if j % 2 else 1
        reach = rng.uniform(.22, .55) if blunt else rng.uniform(.3, .86)
        tongues.append((length * reach, side * rng.uniform(spread * .35, spread), rng.uniform(2.6, 3.8) if blunt else rng.uniform(1.3, 2.4)))
    if kind in ('rifle', 'sniper'):
        # Боковые выхлопы дульного тормоза: короткие, не «крест».
        tongues.extend([(height * .3, -1.3, 1.7), (height * .26, 1.25, 1.5)])
    samples = []
    for reach, angle, radius in tongues:
        bend, phase = rng.uniform(-1.8, 1.8), rng.random() * math.tau
        for step in range(int(reach * 2)):
            t = step / (reach * 2)
            along = t * reach
            across = math.sin(t * 6 + phase) * bend * t
            x = 3 + along * math.cos(angle) - across * math.sin(angle)
            y = height / 2 + along * math.sin(angle) + across * math.cos(angle)
            r = max(.3, radius * (1 - t) ** .9 * (1 + .3 * math.sin(t * 31 + phase)))
            samples.append((x, y, r, t))
    heat_map = {}
    for y in range(height):
        for x in range(length + 8):
            heat = 0.0
            for sx, sy, r, t in samples:
                d2 = ((x - sx) ** 2 + (y - sy) ** 2) / (r * r)
                if d2 < 5:
                    heat = max(heat, math.exp(-d2 * .8) * (1 - .55 * t))
            heat *= rng.uniform(.8, 1.06)
            heat_map[x, y] = heat
    for (x, y), heat in heat_map.items():
        if heat < .08:
            continue
        # Белое ядро — только у дула; дальше жёлтый, оранжевый, красный, бахрома.
        if heat > .86 and x < length * .3:
            color = (255, 250, 226, 255)
        elif heat > .64:
            color = (255, 208, 70, 235)
        elif heat > .4:
            color = (255, 130, 28, 205)
        elif heat > .2:
            color = (214, 66, 18, 160)
        else:
            color = (150, 38, 10, round(heat * 420))
        img.putpixel((x, y), color)
    # Искры за краем огня.
    for _ in range({'small': 2, 'rifle': 3, 'shotgun': 5, 'sniper': 3, 'launcher': 4}[kind]):
        sx = rng.randint(int(length * .45), length + 5)
        sy = round(height / 2 + rng.uniform(-1, 1) * min(height / 2 - 2, 2 + sx * spread * .6))
        if img.getpixel((sx, sy))[3] < 40:
            img.putpixel((sx, sy), rng.choice([(255, 196, 80, 230), (255, 120, 30, 200)]))
    ga.save(img, f'flash_{kind}_{variant}')


def magazine(gun, width, height):
    img = Image.new('RGBA', (width+2, height+2))
    d = ImageDraw.Draw(img)
    if gun == 'smg':
        d.ellipse((1, 1, width, height), fill='#171d22', outline='#7a8585')
        d.ellipse((3, 3, width-2, height-2), outline='#4f5a5e')
    else:
        d.rectangle((1, 1, width, height), fill='#1b2329', outline='#778384')
        d.line((3, 3, 3, height-1), fill='#4d5b62')
        d.line((1, height, width, height), fill='#adb5a0')
    ga.save(img, 'mag_'+gun)


if __name__ == '__main__':
    Path(ga.OUT).mkdir(parents=True, exist_ok=True)
    casing('casing_small', 3)
    casing('casing_rifle', 5)
    casing('casing_shell', 4, True)
    magazine('pistol', 6, 12)
    magazine('rifle', 8, 15)
    magazine('smg', 14, 13)
    for kind in ('small', 'rifle', 'shotgun', 'sniper', 'launcher'):
        for variant in range(4):
            flash(kind, variant)
    print('W2: 3 гильзы, 3 магазина, 20 вспышек ->', ga.OUT)
