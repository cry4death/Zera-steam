"""Z1: только zombie_*; исходные примитивы, палитра и сетка gen_art.py.

python -I tools/gen_art_z1.py; Godot --headless --path . --import
Альфа 254 отмечает ткань; 255 — кожа, кровь и остальные материалы.
"""
import importlib.util
import pathlib
import random
import sys

sys.dont_write_bytecode = True

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('zera_art', ROOT / 'tools/gen_art.py')
g = importlib.util.module_from_spec(spec)
spec.loader.exec_module(g)

# Первые семь индексов сохраняют прежний смысл во всех старых стендах.
PEOPLE = [
    ('office', 'офисный', '706957', '343b49', '969385', '382c25', .92, {}),
    ('medic', 'медик', '81968f', '54696a', 'b0a58e', '302820', .94, {'role': 'medic'}),
    ('police', 'полицейский', '394650', '293944', '686e72', '30251b', 1.07, {'role': 'police', 'helmet': g.hexc('414b58')}),
    ('overalls', 'механик', '6a704c', '424f58', '676250', '211a15', 1.08, {'role': 'overalls'}),
    ('hood', 'в капюшоне', '69615e', '42433f', '8e8b94', '312e2c', .93, {'role': 'hood'}),
    ('old', 'пожилой', '8c7b65', '514b45', 'aaa38b', 'a9a399', .86, {'role': 'old'}),
    ('athlete', 'спортсмен', '7f4942', '3b414e', '6d695f', '201c19', .91, {'role': 'sport', 'fresh': True}),
    ('skirt', 'в платье', '64556d', '47434d', 'a39d8a', '4c3226', 1.02, {'role': 'skirt'}),
    ('homeless', 'бездомный', '6b6047', '4b5141', '68674d', '504a3c', 1.03, {'role': 'coat'}),
    ('delivery', 'курьер', '9b784c', '4a5050', '57554b', '232020', .96, {'role': 'bag'}),
    ('runner_sport', 'бегун: атлет', '596a76', '31363c', '9c9a89', '2c221d', .76, {'kind': 'runner', 'role': 'sport'}),
    ('fat_apron', 'толстяк: фартук', '91867a', '4e473c', '847569', '493d30', 1.40, {'kind': 'fat', 'role': 'apron'}),
    ('spitter_coat', 'плевун: халат', '858975', '474d3d', 'a29d73', '403c2b', .97, {'kind': 'spitter'}),
    ('crawler', 'ползун', '796353', '42444a', '969781', '494137', .89, {'crawler': True}),
]
for name, label, shirt, pants, skin, hair, build, extra in PEOPLE:
    g.VARIANTS.append(dict(name=name, shirt=g.hexc(shirt), pants=g.hexc(pants), skin=g.hexc(skin), hair=g.hexc(hair), build=build, **extra))

# Положение головы и рук меняет контур, а не только цвет спины.
for v, lean, tilt, hands, reach in [(7, -.8, 1.4, 7.2, 26.), (8, .4, -.6, 6.6, 27.),
        (9, -.6, -.8, 8., 25.), (10, -1., 1., 8.4, 26.), (11, -1.2, -1.6, 4., 26.),
        (12, -1.6, 1.7, 6., 24.), (13, 1.0, -.3, 4., 28.), (14, -.3, 1.3, 7.5, 25.),
        (15, -.9, -.7, 8., 24.), (16, .6, -1.2, 4.5, 28.), (17, 1., -.5, 3.4, 29.), (20, .8, .6, 9., 27.)]:
    g.VARIANTS[v].update(lean=lean, tilt=tilt, hands=hands, reach=reach)

TONES = [(1., 1., 1.), (1.015, .94, .845), (.915, 1.02, 1.10)]
g.ACID = g.ramp(g.hexc('8b9e4f'), spread=.5)
_head, _stain, _arm = g.draw_head, g.Canvas.stain, g.draw_arm
_fresh = False

def stain(self, *args, **kwargs):
    if not _fresh:
        _stain(self, *args, **kwargs)

g.Canvas.stain = stain


def head(cv, d, v, x, y, broken, rng, face_up=False):
    if d.get('role') == 'hood':
        cv.ellipse(x - 1.8, y, 5.2, 6.2, g.ramp(d['shirt']), tex=.2, seed=v)
    _head(cv, d, v, x, y, broken, rng, face_up)
    if d.get('kind') == 'spitter' and not broken:
        cv.ellipse(x + 3.4, y + 1.0, 3.6, 5.0, g.ramp(g.hexc('99946c')), tex=.25, seed=v)
        cv.ellipse(x + 4.8, y + 1.0, 1.4, 2.1, g.ramp(g.hexc('72763f')), tex=.3, seed=v)
    if d.get('role') in ('police', 'bag') and not broken:
        cloth = g.ramp(d['shirt'])
        cv.ellipse(x - 2, y, 3.7, 4.5, cloth, tex=.15, seed=v)
        cv.tube(x + .7, y - 3.4, x + .7, y + 3.4, 1.0, cloth)

def arm(cv, d, v, sx, sy, hx, hy, rng, side, bare_from=.38):
    if v == 15 and side < 0:
        g.draw_stump(cv, d, sx, sy, side)
    else:
        _arm(cv, d, v, sx, sy, hx, hy, rng, side, bare_from)

g.draw_head, g.draw_arm = head, arm

def render(v, function, *args, **kwargs):
    global _fresh
    _fresh = g.VARIANTS[v].get('fresh', False)
    cv = function(v, *args, **kwargs)
    if g.VARIANTS[v].get('crawler') and function in (g.zombie, g.zombie_top_half, g.corpse):
        cut = round(10.0 * g.S)
        for y in range(cv.h):
            for x in range(cut):
                cv.erasen(x, y)
        # Рваный срез вместо целого туловища; живой ползёт на руках.
        cv.ellipse(10.3, 16, 1.2, 5.0, g.MUSCLE, tex=.2)
        cv.outline()
    return cv.image()

def material_image(v, function, *args, **kwargs):
    image = render(v, function, *args, **kwargs)
    data = g.VARIANTS[v]
    saved = dict(data)
    # Контрольный рендер меняет только ткань, включая её тени и контур.
    for key in ('shirt', 'pants', 'vest'):
        if key in data:
            data[key] = (18, 203, 221)
    probe = render(v, function, *args, **kwargs)
    data.clear()
    data.update(saved)
    a, b = np.array(image), np.array(probe)
    mask = (a[:, :, 3] > 0) & np.any(a[:, :, :3] != b[:, :, :3], axis=2)
    a[mask, 3] = 254
    return Image.fromarray(a), mask

def tint(image, mask, tone):
    a = np.array(image)
    a[mask, :3] = np.clip(np.floor(a[mask, :3].astype(float) * TONES[tone] + .5), 0, 255).astype('uint8')
    a[a[:, :, 3] > 0, 3] = 255
    return Image.fromarray(a)

def main():
    out = ROOT / 'art'
    count = len(g.VARIANTS)
    atlas = Image.new('RGBA', (768, count * 192))
    for v in range(count):
        for anim in range(4):
            for bits in range(16):
                image, _ = material_image(v, g.zombie, bits, anim)
                atlas.paste(image, (bits * 48, (v * 4 + anim) * 48))
        parts = [('whole', g.zombie, (0, 0), {}), ('headless', g.zombie, (0, 1), {'headless': True}),
                 ('top', g.zombie_top_half, (), {}), ('legs', g.legs_half, (), {}),
                 ('head', g.gib_head, (), {}), ('arm', g.gib_arm, (), {}), ('torso', g.gib_torso, (), {})]
        for pose in range(3):
            parts += [(f'corpse_{pose}', g.corpse, (pose,), {}), (f'corpse_headless_{pose}', g.corpse, (pose,), {'headless': True})]
        for name, function, args, kwargs in parts:
            image, mask = material_image(v, function, *args, **kwargs)
            for tone in range(3):
                # Обычные whole/headless/top оставляют совместимые имена.
                filename = f'zombie_{name}_{v}.png' if tone == 0 and name in ('whole', 'headless', 'top') else f'zombie_{name}_{v}_t{tone}.png'
                tint(image, mask, tone).save(out / filename)
        print('Z1ART variant', v, g.VARIANTS[v]['name'], flush=True)
    atlas.save(out / 'zombie_atlas.png')
    print(f'Z1ART atlas={atlas.width}x{atlas.height} rgba_bytes={atlas.width * atlas.height * 4} appearances={count * 3}')

if __name__ == '__main__':
    main()
