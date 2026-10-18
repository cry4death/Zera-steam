"""O2: земля, переходы и крыши. Локальные RNG, свет и рампы из gen_art."""
from pathlib import Path
import json
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import gen_art as ga

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art'
REPORT = ROOT / 'design/tasks/reports'
SYMBOLS = '=-.,:~*#'


def grounds():
    atlas = Image.new('RGBA', (1024, 512))
    bases = ['303332', '303332', '55554d', '3b4330', '514939', '827354', 'a1a49b', '555650']
    asphalt = Image.open(ART / 'asphalt.png').convert('RGBA')
    asphalt.resize((1024,1024),Image.Resampling.NEAREST).save(ART/'map_road.png')
    for material, base in enumerate(bases):
        for variant in range(16):
            rng = np.random.default_rng(981 + material * 61 + variant)
            rgb = np.array(ga.hexc(base), dtype=float)
            noise = rng.normal(0, 1.8, (64, 64, 1))
            array = np.uint8(np.clip(rgb + noise, 0, 255))
            tile = Image.fromarray(array).convert('RGBA')
            d = ImageDraw.Draw(tile)
            if material < 2:
                x, y = (variant % 4) * 192, (variant // 4) * 192
                tile = asphalt.crop((x, y, x + 96, y + 96)).resize((64, 64), Image.Resampling.NEAREST)
                d = ImageDraw.Draw(tile)
            if material == 1:
                tile = Image.new('RGBA',(64,64)); d = ImageDraw.Draw(tile)
                d.rectangle((29, 0, 32, 63), fill=(143, 128, 79, 255))
                for k in range(30):
                    x, y = int(rng.integers(29, 33)), int(rng.integers(0, 64))
                    d.rectangle((x, y, x + 1, y + 2), fill=(62, 62, 51))
            if material == 2:
                d.line((0, 0, 63, 0), fill=(45, 46, 42), width=2)
                if variant % 3 == 0:
                    d.line((31, 2, 31, 63), fill=(68, 69, 61))
            if material in (3, 4, 5):
                rr = random.Random(634 + variant + material * 80)
                for k in range(32 if material == 3 else 10):
                    x, y = rr.randrange(64), rr.randrange(64)
                    c = ga.darker(tuple(rgb), rr.uniform(.76, 1.18))
                    d.line((x, y, x + rr.randrange(1, 4), y - 1), fill=c, width=1)
            if material == 7:
                d.line((0, 0, 63, 0), fill=(61, 63, 58))
                d.line((0, 0, 0, 63), fill=(63, 65, 59))
            atlas.paste(tile, (variant * 64, material * 64))
    atlas.save(ART / 'map_ground.png')
    edges = Image.new('RGBA', (256, 320))
    for kind in range(5):
        for side in range(4):
            tile = Image.new('RGBA', (64, 64))
            d = ImageDraw.Draw(tile)
            rr = random.Random(561 + kind)
            if kind == 0:
                d.rectangle((0, 0, 5, 63), fill=(31, 33, 30, 230))
                d.rectangle((3, 0, 6, 63), fill=(125, 122, 105, 255))
                for y in range(0, 64, 21):
                    d.line((3, y, 6, y + 1), fill=(51, 53, 47), width=2)
            else:
                color = [(49, 57, 36), (67, 58, 43), (120, 103, 72), (164, 169, 160)][kind - 1]
                for y in range(64):
                    reach = rr.randrange(2, 9)
                    d.line((0, y, reach, y), fill=(*color, rr.randrange(110, 220)))
            if side == 1:
                tile = tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            elif side == 2:
                tile = tile.transpose(Image.Transpose.ROTATE_270)
            elif side == 3:
                tile = tile.transpose(Image.Transpose.ROTATE_90)
            edges.paste(tile, (side * 64, kind * 64))
    edges.save(ART / 'map_edges.png')


def roof(skin, w, h, variant):
    """Крыша нужного размера: парапет, стены в тени, оборудование без регулярной сетки."""
    W, H = w * 2, h * 2
    rng = random.Random(491 + w * 11 + h * 3 + skin * 71 + variant * 138)
    im = Image.new('RGBA', (W, H))
    d = ImageDraw.Draw(im)
    palette = ['51534c', '7b7058', '535c53', '656b60', '5e6157', '4a5b5b', '777563', '7c7b69', '333d2c', '5e5d41', '5c6045', '943f30']
    base = ga.hexc(palette[skin])
    if skin == 0:
        base = [(78,81,73),(81,75,65),(67,76,74)][variant]
    dark, light = ga.darker(base, .55), ga.mix(base, (169, 163, 135), .35)
    d.rectangle((0, 0, W - 1, H - 1), fill=dark)
    d.rectangle((2, 2, W - 7, H - 8), fill=base)
    if skin == 8:
        im = Image.new('RGBA', (W, H)); d = ImageDraw.Draw(im)
        for k in range(max(25, w * h // 150)):
            x, y = rng.randrange(8, W - 8), rng.randrange(8, H - 8)
            r = rng.randrange(20, 38)
            d.ellipse((x-r, y-r, x+r, y+r), fill=ga.darker(base, rng.uniform(.7, 1.15)))
            d.arc((x-r+2, y-r+2, x+r-2, y+r-2), 190, 285, fill=(65, 73, 48), width=3)
        return im
    if skin == 1:
        # Уцелевшие фрагменты перекрытий: оголённая кладка, щели и сколотые углы.
        for y in range(8,H-8,18):
            d.line((6,y,W-9,y),fill=dark,width=2)
            for x in range(10+(y//18%2)*20,W-12,42):
                d.line((x,y,x,y+15),fill=ga.darker(base,.69),width=2)
        for k in range(max(5,w//25)):
            x=rng.randrange(7,W-8); y=rng.choice((3,H-10))
            d.polygon([(x,y),(min(W-5,x+12),y),(x+3,max(0,y-7))],fill=(48,46,37))
        d.line((W//4,H//2,W//3,H//2+7,W//2,H//2-4,W*3//4,H//2+12),fill=(44,43,34),width=3)
    elif skin in (0, 3):
        d.rectangle((9, 9, W - 14, H - 17), fill=ga.darker(base, .78))
        d.line((2, H-9, 2, 2, W-8, 2), fill=light, width=3)
        d.line((8, H-16, 8, 8, W-15, 8), fill=dark, width=3)
        if w > 90 and h > 70:
            for k in range(2 + variant):
                x, y = rng.randrange(22, W-65), rng.randrange(22, H-52)
                d.rectangle((x+7, y+7, x+49, y+34), fill=ga.darker(base, .46))
                d.rectangle((x, y, x+40, y+26), fill=(92, 95, 82), outline=(42, 47, 42), width=3)
                for xx in range(x+6, x+36, 5):
                    d.line((xx, y+5, xx, y+21), fill=(48, 54, 48), width=2)
            # Заплаты рубероида, редкие швы без регулярного шума.
            if w > 220 and h > 150:
                bx, by = W*2//3, H//3
                d.rectangle((bx+8,by+10,bx+85,by+64),fill=ga.darker(base,.42))
                d.rectangle((bx,by,bx+76,by+52),fill=ga.mix(base,(145,139,111),.21),outline=dark,width=4)
                d.line((bx-60,by+18,bx-12,by+18,bx-12,by+34,bx,by+34),fill=(112,112,94),width=5)
            # Надстройки и ремонтные заплаты задают масштаб корпуса.
            for k in range(2 + variant):
                px,py = rng.randrange(18,W-90),rng.randrange(18,H-70)
                d.rectangle((px,py,px+rng.randrange(28,64),py+rng.randrange(18,48)),fill=ga.darker(base,.65))
            x, y = W//3 + variant*13, H//3
            d.rectangle((x, y, x+28, y+36), fill=(55, 58, 51), outline=(116, 114, 94), width=2)
        # Окна и водостоки на южном фасаде.
        for x in range(20, W - 22, 48):
            d.rectangle((x, H-7, x+16, H-3), fill=(28, 34, 32))
    elif skin == 2:
        d.line((1, 2, W-2, 2), fill=light, width=2)
        for x in range(5, W-4, 16):
            d.line((x, 3, min(W-2,x+12), H-3), fill=(110, 116, 98))
            d.line((x, H-3, min(W-2,x+12), 3), fill=(65, 76, 69))
    elif skin in (4, 5, 10):
        if skin == 5:
            base = [(65, 82, 81), (95, 68, 49), (76, 78, 55)][variant]
            d.rectangle((3,3,W-7,H-8), fill=base)
        for x in range(9, W-8, 12 if skin == 5 else 28):
            d.line((x, 5, x, H-12), fill=ga.darker(base,.6), width=2)
            d.line((x+2, 5, x+2, H-12), fill=light)
        if skin == 4:
            d.rectangle((2, 2, W-8, 10), fill=(118, 58, 44))
            d.rectangle((W-50, H-45, W-12, H-12), fill=(27, 29, 27))
            d.line((W-47,H-40,W-20,H-18),fill=(62,60,45),width=3)
        if skin == 10:
            d.line((3,H//2,W-8,H//2), fill=(122,121,81), width=3)
            d.polygon([(5,H//2),(W//2,8),(W-9,H//2)],fill=(102,105,70))
    elif skin == 6:
        d.rounded_rectangle((3,3,W-8,H-9), radius=min(W,H)//3, fill=base, outline=light, width=3)
        for x in (W//4, W*3//4):
            d.line((x, 3, x, H-10), fill=dark, width=5)
        d.ellipse((W//2-8,H//2-8,W//2+8,H//2+8),fill=dark,outline=light,width=2)
    elif skin == 7:
        d.rectangle((6,6,W-12,H-13),fill=(48,58,55),outline=light,width=6)
        d.rectangle((18,18,W-24,H-25),fill=(40,46,42),outline=(88,87,70),width=3)
        d.ellipse((W//2-20,H//2-20,W//2+20,H//2+20),fill=(107,105,86),outline=(53,55,46),width=4)
        d.rectangle((W//2-7,H//2-10,W//2+5,H//2+5),fill=(147,140,112))
    elif skin == 9:
        for x in range(0,W,32):
            for y in range(0,H,30):
                d.rectangle((x+2,y+2,min(x+29,W-4),min(y+27,H-4)),fill=base,outline=light,width=2)
                d.line((x+4,y+4,min(x+26,W-5),min(y+24,H-5)),fill=dark,width=3)
    else:
        d.rectangle((3,3,W-6,H-8),fill=base,outline=light,width=2)
        d.rectangle((5,5,W-9,max(6,H//2)),fill=(28,39,39))
    # Пятна ремонта, ржавчина и трещины с разным расположением на каждой крыше.
    if W > 60 and H > 60 and skin != 7:
        for k in range(max(8,w*h//1700)):
            x, y = rng.randrange(12,W-16), rng.randrange(12,H-18)
            d.line((x,y,min(W-10,x+rng.randrange(3,19)),min(H-12,y+rng.randrange(1,6))),fill=ga.darker(base,rng.uniform(.6,.9)),width=2)
    return im


def sizes():
    result = set()
    skins = {'B':0, 'R':1, 'W':2, 'T':8}
    for path in (ROOT/'maps').glob('*.json'):
        rows = json.loads(path.read_text(encoding='utf-8'))['structures']
        used = set()
        for y in range(len(rows)):
            for x in range(len(rows[0])):
                c = rows[y][x]
                if c not in skins or (x,y) in used: continue
                w = 1
                while x+w < len(rows[0]) and rows[y][x+w] == c and (x+w,y) not in used: w+=1
                h = 1
                while y+h < len(rows) and all(rows[y+h][xx] == c and (xx,y+h) not in used for xx in range(x,x+w)): h+=1
                used.update((xx,yy) for yy in range(y,y+h) for xx in range(x,x+w))
                result.add((skins[c],w*32,h*32))
    result.update([(3,56,48),(2,48,5),(4,146,78),(6,76,36),(11,16,12),(2,180,6),(9,24,28),(3,90,28),(0,34,40),(5,152,48),(10,120,66),(10,96,60),(9,60,48),(7,80,64)])
    return sorted(result)


def decals():
    atlas = Image.new('RGBA',(512,128))
    for variant in range(4):
        im = Image.new('RGBA',(128,128)); d = ImageDraw.Draw(im)
        rng = random.Random(891+variant)
        if variant == 0:
            for k in range(15):
                x,y=rng.randrange(32,92),rng.randrange(32,92); r=rng.randrange(8,22)
                d.ellipse((x-r,y-r,x+r,y+r),fill=(19,24,22,145))
        elif variant == 1:
            d.ellipse((33,33,95,95),fill=(30,33,31),outline=(95,96,80),width=3)
            d.ellipse((38,38,90,90),outline=(51,57,51),width=2)
            for y in range(47,83,7): d.line((46,y,83,y),fill=(61,68,60),width=2)
        elif variant == 2:
            pts=[(10,25),(33,38),(42,66),(67,78),(76,107),(108,120)]
            d.line(pts,fill=(26,29,25,210),width=3)
            d.line((42,66,21,78,13,102),fill=(30,31,25,165),width=2)
        else:
            for x in (34,83):
                for y in range(3,125,8):
                    d.line((x,y,x+11,y+4),fill=(34,33,26,100),width=3)
        atlas.paste(im,(variant*128,0))
    atlas.save(ART/'map_decals.png')
    wall = Image.new('RGBA',(128,32)); d=ImageDraw.Draw(wall)
    for k in range(36):
        rng=random.Random(k+683); x,y=rng.randrange(4,120),rng.randrange(2,18)
        d.ellipse((x,y,x+rng.randrange(3,12),y+rng.randrange(2,7)),fill=(91,12,15,220))
        if k%4==0: d.line((x,y,x+1,y+14),fill=(67,9,12,190),width=2)
    wall.save(ART/'map_wall_blood.png')


def road_overlays():
    # Уточняющий контур трассы убирает ступени сетки 32 px на косой дороге.
    for path in (ROOT/'maps').glob('*.json'):
        data=json.loads(path.read_text(encoding='utf-8'))
        if 'road_path' not in data:
            continue
        size=(len(data['ground'][0])*32,len(data['ground'])*32)
        points=[(round(x*32),round(y*32)) for x,y in data['road_path']]
        mask=Image.new('L',size); d=ImageDraw.Draw(mask)
        d.line(points,fill=255,width=260,joint='curve')
        overlay=Image.new('RGBA',size,(80,71,53,255)); overlay.putalpha(mask)
        roadmask=Image.new('L',size); d=ImageDraw.Draw(roadmask)
        d.line(points,fill=255,width=224,joint='curve')
        tile=Image.open(ART/'map_road.png').convert('RGBA').resize((512,512),Image.Resampling.NEAREST)
        road=Image.new('RGBA',size)
        for y in range(0,size[1],tile.height):
            for x in range(0,size[0],tile.width): road.paste(tile,(x,y))
        road.putalpha(roadmask); overlay=Image.alpha_composite(overlay,road)
        d=ImageDraw.Draw(overlay)
        for a,b in zip(points,points[1:]):
            dx,dy=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dy)
            for t in range(0,round(length),48):
                end=min(t+21,length)
                d.line((a[0]+dx*t/length,a[1]+dy*t/length,a[0]+dx*end/length,a[1]+dy*end/length),fill=(130,117,75),width=2)
        overlay.save(ART/f'map_road_overlay_{data["id"]}.png')


def main():
    grounds()
    decals()
    road_overlays()
    samples = []
    for skin,w,h in sizes():
        for variant in range(3):
            im = roof(skin,w,h,variant)
            im.save(ART/f'map_roof_{skin}_{w}_{h}_{variant}.png')
            if variant == 0: samples.append((f'{skin} / {w} x {h}',im))
    sheet = Image.new('RGB',(1536,420+math.ceil(len(samples)/5)*170),(28,30,28))
    d = ImageDraw.Draw(sheet); font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
    d.text((16,12),'O2 / ground, edges, roofs and landmarks',font=font,fill=(188,181,157))
    tile = Image.open(ART/'map_ground.png').convert('RGB')
        # В листе земля уменьшена до читаемой полосы; ориентиры ниже.
    sheet.paste(tile.resize((1024,320),Image.Resampling.NEAREST),(16,40))
    for i,(label,im) in enumerate(samples):
        x,y=(i%5)*306+10,420+(i//5)*170
        im.thumbnail((280,130),Image.Resampling.NEAREST)
        sheet.paste(im,(x,y),im)
        d.text((x,y+136),label,font=font,fill=(167,163,142))
    sheet.save(REPORT/'o2_tiles.png')
    print(f'MAPART ground=16x8 edges=4x5 roofs={len(samples)*3} deterministic=true')


if __name__ == '__main__':
    main()
