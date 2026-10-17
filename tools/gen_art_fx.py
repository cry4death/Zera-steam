"""E1: объёмные выбросы огня/копоти. Детерминированно, без внешних ассетов.

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python tools/gen_art_fx.py
Флипбуки: 12 столбцов × 3 варианта; дым: 8 столбцов. Фильтр nearest.
"""
from pathlib import Path
import math
import random
import numpy as np
from PIL import Image, ImageDraw
import gen_art as ga

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art'
REPORT = ROOT / 'design/tasks/reports'


def noise(x, y, seed):
    """Непрерывный шум: родной hash gen_art, интерполяция между узлами."""
    ix, iy = np.floor(x).astype(int), np.floor(y).astype(int)
    u, v = x - ix, y - iy
    u, v = u*u*(3-2*u), v*v*(3-2*v)
    def h(a, b):
        n = (a.astype(np.int64)*374761393 + b.astype(np.int64)*668265263 + seed*1442695041) & 0xffffffff
        n = ((n ^ (n >> 13))*1274126177) & 0xffffffff
        return ((n ^ (n >> 16)) & 65535)/32767.5 - 1
    return (h(ix, iy)*(1-u)+h(ix+1, iy)*u)*(1-v)+(h(ix, iy+1)*(1-u)+h(ix+1, iy+1)*u)*v


def cloud(size, t, variant, smoke=False):
    rng = random.Random(18041 + variant*131)
    y, x = np.mgrid[0:size, 0:size].astype(float)
    x, y = (x+.5)/size*2-1, (y+.5)/size*2-1
    n = noise(x*5 + t*.8, y*5+t*1.6, 57+variant)
    fine = noise(x*19-t, y*19+t*2, 111+variant)
    warp = n*.095 + fine*.024
    density = np.full(x.shape, -10.)
    shade = np.zeros(x.shape)
    pockets = np.zeros(x.shape)
    # Отдельные клубы перекрываются, но сохраняют разную температуру и светотень.
    for k in range(19):
        a = rng.random()*math.tau
        reach = rng.uniform(.08, .46)
        growth = .40 + .60*min(1., t*3.5) if not smoke else .60+t*.32
        cx = math.cos(a)*reach*growth + math.sin(t*3+k)*.025
        cy = math.sin(a)*reach*growth*.83 - t*.10
        r = rng.uniform(.15, .30)*growth*(1 + .15*t)
        dx, dy = (x-cx)/(r*1.05), (y-cy)/r
        d = np.sqrt(dx*dx+dy*dy) + warp/r
        inside = 1-d
        take = inside > density
        z = np.sqrt(np.maximum(0., 1-np.minimum(d*d, 1.)))
        lit = np.clip(dx*ga.LIGHT[0]+dy*ga.LIGHT[1]+z*ga.LIGHT[2], -1, 1)
        shade = np.where(take, lit, shade)
        pockets = np.where(take, rng.uniform(-.18, .22), pockets)
        density = np.maximum(density, inside)
    edge = np.clip(density*9, 0, 1)
    if smoke:
        value = np.clip((shade+1)*.5 + n*.16 + fine*.06, 0, 1)
        ramp = ga.ramp(ga.hexc('474743'), n=7, spread=1.05)
        rgb = np.array(ramp)[np.minimum(6, (value*7).astype(int))]
        alpha = edge*(.91-t*.28)*255
    else:
        # Жар уходит пятнами изнутри; поздние кадры — сажа с тлеющими карманами.
        heat = np.clip(1.10-pow(t, .65)*1.25 + density*.10 + pockets*.28
                       + noise(x*7+t*1.7, y*7-t*2.8, 302+variant)*.38
                       + n*.18 + fine*.085, 0, 1)
        palette = np.array([ga.hexc(c) for c in
                            ('24262a','353533','4a4038','702e20','aa3916','e75b18','ff952b','ffd26b','fff0b9','fff8df')])
        rgb = palette[np.minimum(9, (heat*10).astype(int))]
        soot = heat < .30
        lighting = np.where(soot, .78 + (shade+1)*.23, 1.)
        rgb = np.clip(rgb*lighting[..., None], 0, 255)
        alpha = edge*255*(1 if t < .67 else 1-(t-.67)*1.8)
    rgba = np.dstack([rgb, alpha]).astype(np.uint8)
    return Image.fromarray(rgba)


def main():
    ART.mkdir(exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    rows = []
    for name, size in [('small', 96), ('medium', 144), ('large', 192)]:
        sheet = Image.new('RGBA', (size*12, size*3))
        for variant in range(3):
            for frame in range(12):
                sheet.paste(cloud(size, frame/11, variant), (frame*size, variant*size))
        sheet.save(ART / f'fx_explosion_{name}.png')
        if name == 'medium':
            for v in range(3):
                rows.append((f'FIRE {v} / 0 - 0.65 s', [sheet.crop((k*size,v*size,(k+1)*size,(v+1)*size)) for k in range(12)]))
    smoke = Image.new('RGBA', (96*8, 96))
    for k in range(8):
        smoke.paste(cloud(96, k/7, 4, True), (k*96, 0))
    smoke.save(ART / 'fx_smoke.png')
    rows.append(('SMOKE / 1.5 - 3 s', [smoke.crop((k*96,0,(k+1)*96,96)) for k in range(8)]))
    extras = []
    for k in range(3):
        size = 144
        y,x = np.mgrid[0:size,0:size].astype(float)
        x,y = (x-72)/72,(y-72)/72
        d = np.hypot(x, y*1.16)
        rough = noise(x*5,y*5,80+k)*.23 + noise(x*23,y*23,91+k)*.08
        alpha = np.clip((.73-d+rough)*3,0,1)*(.55 + noise(x*40,y*40,110+k)*.15)
        rgba = np.dstack([np.full_like(x,18),np.full_like(x,17),np.full_like(x,16),alpha*255]).astype(np.uint8)
        scorch = Image.fromarray(rgba)
        scorch.save(ART / f'fx_scorch_{k}.png')
        extras.append(scorch)
    atlas = Image.new('RGBA', (12*7, 12))
    for material_index, (name, base) in enumerate([('asphalt','414247'),('metal','737b7c')]):
        for k in range(3):
            cv = ga.Canvas(12,12,s=1)
            rmp = ga.ramp(ga.hexc(base))
            cv.ellipse(6,6,3+k*.6,2+k*.4,rmp,tex=.2,seed=k)
            # Сколы, прямые грани и верхний блик вместо круглой гальки.
            for y in range(12):
                for x in range(12):
                    if x+y < 7 or x-y > 4 or y > 8:
                        cv.erasen(x,y)
            cv.image().save(ART / f'fx_debris_{name}_{k}.png')
            atlas.paste(cv.image(), ((material_index*3+k)*12, 0))
            extras.append(cv.image())
    spark = Image.new('RGBA',(7,3))
    ImageDraw.Draw(spark).line((0,1,6,1),fill='#f1b34b',width=1)
    spark.putpixel((5,1),(255,237,170,255))
    spark.save(ART / 'fx_debris_spark.png')
    atlas.paste(spark, (6*12+2, 4))
    atlas.save(ART / 'fx_debris_atlas.png')
    rows.append(('SCORCH / ASPHALT / METAL',extras+[spark]))
    preview = Image.new('RGB',(1460,len(rows)*160),(39,41,43))
    draw = ImageDraw.Draw(preview)
    for row,(label,frames) in enumerate(rows):
        draw.text((8,row*160+3),label,fill=(215,211,193))
        for k,img in enumerate(frames):
            img = img.resize((112,112),Image.Resampling.NEAREST)
            preview.paste(img,(8+k*120,row*160+27),img)
    preview.save(REPORT/'e1_sheet.png')
    print('E1: 3 fire sheets (12 x 3), smoke (8), 3 scorch, 7 debris; deterministic')


if __name__ == '__main__':
    main()
