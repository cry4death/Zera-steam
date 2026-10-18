"""O1: детерминированный атлас препятствий; три пикселя на единицу мира."""
import math
import os
import random

import gen_art as ga
from PIL import Image, ImageDraw, ImageFont, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 288, 144
NAMES = [f"{name}_{state}" for name in ("sedan", "hatch", "police", "jeep", "truck") for state in range(4)]
NAMES += ["red", "red_leak", "acid", "acid_leak", "jersey", "sandbags", "fence", "wood"]
NAMES += ["tires", "bags", "paper", "boards", "glass", "cone"]


def sprite(index):
    rng = random.Random(7301 + index // 4 if index < 20 else 7301 + index)
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    cx, cy = W // 2, H // 2
    if index < 20:
        kind, state = divmod(index, 4)
        length = 252 if kind == 4 else (174 if kind == 1 else 192)
        width = 94 if kind >= 3 else 84
        x, y = cx - length // 2, cy - width // 2
        base = [(83, 93, 96), (91, 62, 53), (131, 134, 124), (72, 79, 53), (71, 76, 51)][kind]
        if state == 3:
            base = (43, 42, 37)
        dark, light = ga.darker(base, .48), ga.mix(base, (180, 177, 155), .28)
        # Колёса, пороги и отдельная обводка со стороны тени.
        for wx in (x + 23, x + length - 42):
            for wy in (y - 5, y + width - 8):
                d.rounded_rectangle((wx, wy, wx + 24, wy + 15), 3, fill=(19, 21, 21))
                d.line((wx + 3, wy + 2, wx + 20, wy + 2), fill=(55, 57, 54), width=2)
        d.rounded_rectangle((x, y, x + length, y + width), 11, fill=dark)
        d.rounded_rectangle((x + 3, y + 2, x + length - 4, y + width - 5), 9, fill=base)
        d.line((x + 9, y + 3, x + length - 12, y + 3), fill=light, width=2)
        d.line((x + length - 4, y + 12, x + length - 4, y + width - 8), fill=dark, width=4)
        # Двигатель справа, окна с наклоном, крыша, швы дверей.
        cabin0, cabin1 = x + length * [.28, .16, .30, .38, .69][kind], x + length * [.68, .72, .68, .75, .84][kind]
        glass = (32, 48, 53) if state < 3 else (18, 21, 21)
        d.polygon([(cabin0-11,y+10),(cabin0+7,y+9),(cabin0+7,y+width-9),(cabin0-11,y+width-11)], fill=glass)
        d.polygon([(cabin1,y+8),(cabin1+20,y+14),(cabin1+20,y+width-14),(cabin1,y+width-8)], fill=glass)
        d.rectangle((cabin0+10,y+8,cabin1-3,y+width-9), fill=light if state < 3 else (57,55,47))
        for wy in (y+8, y+width-13):
            d.rectangle((cabin0+13,wy,cabin1-7,wy+4), fill=glass)
        for wx in ((cabin0+9, cabin1-2, x+length-28) if kind != 1 else (cabin1-2, x+length-22)):
            d.line((wx,y+14,wx,y+width-15), fill=dark, width=2)
        d.rectangle((x+length-8,y+12,x+length-4,y+26), fill=(179,174,122) if state < 3 else (70,64,46))
        d.rectangle((x+length-8,y+width-27,x+length-4,y+width-13), fill=(179,174,122) if state < 3 else (70,64,46))
        for wy in (y+15,y+width-20):
            d.rectangle((x+1,wy,x+5,wy+7), fill=(111,36,30))
        d.line((x+length-25,y+16,x+length-25,y+width-16), fill=light, width=1)
        # Зеркала, дверные ручки, решётка и рёбра капота.
        for wy in (y-4,y+width-1):
            d.rectangle((cabin1-4,wy,cabin1+8,wy+4),fill=dark)
            d.line((cabin1-3,wy,cabin1+6,wy),fill=light)
        for wx in (cabin0+18,cabin1-15):
            for wy in (y+5,y+width-7):
                d.line((wx,wy,wx+7,wy),fill=(39,43,42),width=2)
                d.point((wx,wy-1),fill=light)
        for wy in range(y+30,y+width-27,4):
            d.line((x+length-5,wy,x+length-1,wy),fill=(30,33,30),width=2)
        d.line((cabin1+27,y+18,x+length-17,y+20),fill=light)
        d.line((cabin1+27,y+width-18,x+length-17,y+width-20),fill=dark)
        if kind == 1:
            d.line((cabin0+4,y+11,cabin0+4,y+width-12),fill=(104,114,106),width=2)
            d.rectangle((x+8,cy-18,x+21,cy+18),fill=(42,44,40))
        if kind == 3:
            d.rectangle((cabin0+12,y+17,cabin1-6,y+width-19),fill=(85,91,61))
            d.line((cabin0+19,y+18,cabin0+19,y+width-20),fill=(114,115,78),width=3)
        if state == 1 and kind in (1,2):
            d.polygon([(cabin0+12,y+4),(cabin0-6,y-18),(cabin0+23,y-18),(cabin0+34,y+3)],fill=base,outline=dark)
        if kind == 2:
            d.rectangle((cabin0+12,y+32,cabin1-6,y+44), fill=(30,36,39))
            d.rectangle((cabin0+15,y+33,cabin0+29,y+39), fill=(111,39,35))
            d.rectangle((cabin1-26,y+33,cabin1-10,y+39), fill=(47,75,112))
            d.text((cabin0+13,y+48), "02", fill=(52,58,59), font=ImageFont.load_default())
        if kind == 3:
            for yy in range(y+17,y+width-15,8):
                d.line((x+15,yy,x+39,yy), fill=dark, width=3)
            d.ellipse((x+7,cy-16,x+39,cy+16), fill=(27,29,26), outline=(88,87,66), width=3)
        if kind == 4:
            d.rectangle((x+10,y+5,x+length-81,y+width-7), fill=(78,81,54) if state < 3 else (46,43,35))
            for wx in range(x+21,x+length-80,31):
                d.line((wx,y+6,wx-4,y+width-8), fill=(104,102,70) if state < 3 else (71,62,45), width=3)
            d.line((x+12,cy,x+length-83,cy), fill=(55,60,42), width=2)
        # Сколы, грязь и потёртости лежат на окрашенном металле.
        for _ in range(180):
            xx, yy = rng.randrange(x+6,x+length-6), rng.randrange(y+6,y+width-6)
            c = im.getpixel((xx,yy))
            d.point((xx,yy), fill=(*ga.darker(c, rng.uniform(.66,.94)),255))
        if state:
            for _ in range(9 if state < 3 else 24):
                xx, yy = rng.randrange(x+12,x+length-10), rng.randrange(y+10,y+width-10)
                d.line((xx,yy,xx-9,yy+4), fill=(29,30,27), width=2)
                d.line((xx-1,yy-2,xx-10,yy+2), fill=(118,105,80), width=1)
            for wx in (cabin0, cabin1+9):
                d.line((wx,cy-21,wx+8,cy-9,wx+1,cy,wx+12,cy+14), fill=(113,133,125), width=1)
        if state == 3:
            d.rectangle((cabin0+15,y+19,cabin1-8,y+width-19), fill=(17,20,19))
            for yy in (y+19,y+width-21):
                d.line((cabin0+10,yy,cabin1-6,yy), fill=(93,79,57), width=3)
        # Небольшой объём панелей и холодная зернистость как у gen_art.
        for yy in range(y+3,y+width-3):
            for xx in range(x+4,x+length-4):
                c=im.getpixel((xx,yy))
                if c[3] == 0:
                    continue
                noise=ga.hnoise(xx,yy,index)*4
                bevel=1.0+0.10*math.cos((yy-y)/width*math.pi)
                im.putpixel((xx,yy),tuple(max(0,min(255,round(v*bevel+noise))) for v in c[:3])+(c[3],))
    elif index < 24:
        green = index >= 22
        base = (69,85,41) if green else (121,51,39)
        d.ellipse((cx-18,cy-18,cx+18,cy+18), fill=(24,26,23))
        d.ellipse((cx-16,cy-17,cx+15,cy+14), fill=base, outline=ga.mix(base,(174,165,130),.35), width=2)
        d.arc((cx-12,cy-13,cx+11,cy+11),90,270,fill=ga.darker(base,.6),width=2)
        d.ellipse((cx+5,cy-9,cx+10,cy-4), fill=(29,30,24), outline=(141,133,100))
        d.polygon([(cx-5,cy-6),(cx+4,cy+7),(cx-9,cy+7)], fill=(165,145,81))
        d.line((cx-3,cy-1,cx-3,cy+3), fill=(53,44,29), width=2)
        if index % 2:
            d.ellipse((cx+4,cy+6,cx+10,cy+11),fill=(18,22,17))
            d.line((cx+7,cy+11,cx+10,cy+15),fill=(111,127,48) if green else (70,28,22),width=3)
    elif index == 24:
        d.polygon([(cx-66,cy+15),(cx-61,cy-9),(cx+60,cy-9),(cx+66,cy+15)],fill=(67,68,61))
        d.rectangle((cx-59,cy-12,cx+59,cy+1),fill=(128,126,109))
        d.line((cx-58,cy-12,cx+57,cy-12),fill=(164,159,134),width=2)
        for xx in range(cx-53,cx+52,25):
            d.polygon([(xx,cy+2),(xx+9,cy+2),(xx+20,cy+13),(xx+11,cy+13)],fill=(159,130,57))
        for _ in range(60):
            xx,yy=rng.randrange(cx-58,cx+58),rng.randrange(cy-10,cy+13)
            d.point((xx,yy),fill=(84,84,74))
    elif index == 25:
        for row in range(2):
            for k in range(3):
                xx=cx-31+k*21+row*6; yy=cy-11+row*12
                d.rounded_rectangle((xx,yy,xx+24,yy+14),5,fill=(109,99,68),outline=(53,53,39),width=2)
                d.line((xx+4,yy+3,xx+18,yy+3),fill=(142,129,88),width=1)
    elif index == 26:
        for xx in range(cx-66,cx+67,9):
            d.line((xx,cy-10,min(xx+18,cx+67),cy+10),fill=(84,93,87,210),width=1)
            d.line((xx,cy+10,min(xx+18,cx+67),cy-10),fill=(70,80,76,220),width=1)
        for xx in (cx-66,cx,cx+66):
            d.rectangle((xx-2,cy-15,xx+2,cy+17),fill=(84,91,82))
            d.line((xx-2,cy-15,xx-2,cy+16),fill=(131,133,112))
        d.line((cx-66,cy-12,cx+66,cy-12),fill=(130,131,110))
        for xx in range(cx-62,cx+60,8):
            d.line((xx,cy-15,xx+4,cy-9),fill=(148,142,117))
    elif index == 27:
        for xx in (cx-35,cx+30):
            d.line((xx-6,cy-17,xx+8,cy+18),fill=(63,53,36),width=7)
            d.line((xx+7,cy-16,xx-6,cy+18),fill=(123,104,67),width=6)
        d.rectangle((cx-48,cy-4,cx+48,cy+5),fill=(148,127,80))
        for xx in range(cx-40,cx+40,18):
            d.polygon([(xx,cy-4),(xx+9,cy-4),(xx+14,cy+5),(xx+5,cy+5)],fill=(57,57,44))
    elif index == 28:
        for xx,yy in ((cx-11,cy+3),(cx+9,cy-4)):
            d.ellipse((xx-14,yy-13,xx+14,yy+13),fill=(25,28,27),outline=(58,59,52),width=3)
            d.ellipse((xx-7,yy-7,xx+7,yy+6),fill=(0,0,0,0),outline=(15,18,18),width=2)
    elif index == 29:
        for xx,yy in ((cx-10,cy+1),(cx+9,cy-4)):
            d.ellipse((xx-12,yy-10,xx+13,yy+12),fill=(43,48,42),outline=(24,29,26),width=2)
            d.line((xx-4,yy-8,xx+3,yy-2,xx+6,yy+6),fill=(71,73,59),width=2)
            d.polygon([(xx-4,yy-9),(xx,yy-16),(xx+4,yy-9)],fill=(74,77,61))
    elif index == 30:
        for _ in range(8):
            xx,yy=rng.randrange(cx-27,cx+20),rng.randrange(cy-15,cy+12)
            d.polygon([(xx,yy),(xx+9,yy+1),(xx+8,yy+8),(xx-2,yy+7)],fill=(145,142,119))
            d.line((xx+1,yy+3,xx+6,yy+3),fill=(88,88,75))
    elif index == 31:
        for xx,yy in ((cx-25,cy-9),(cx-16,cy+3),(cx-5,cy-2)):
            d.polygon([(xx,yy),(xx+46,yy+3),(xx+44,yy+9),(xx-2,yy+6)],fill=(89,74,48))
            d.line((xx,yy,xx+46,yy+3),fill=(124,109,74))
    elif index == 32:
        for _ in range(18):
            xx,yy=rng.randrange(cx-28,cx+28),rng.randrange(cy-17,cy+16)
            d.polygon([(xx,yy),(xx+7,yy+1),(xx-2,yy+5)],fill=(84,114,113,140))
    else:
        d.rectangle((cx-11,cy-10,cx+12,cy+12),fill=(41,40,32))
        d.ellipse((cx-7,cy-7,cx+7,cy+7),fill=(149,84,37),outline=(86,54,31),width=2)
        d.ellipse((cx-4,cy-4,cx+4,cy+4),fill=(189,175,122))
        d.ellipse((cx-2,cy-3,cx+3,cy+2),fill=(114,64,31))
    return im


def bloody(im, index, stage):
    if not stage:
        return im
    rng = random.Random(8123 + index // 4 * 73 + index % 4 * 19)
    layer = Image.new("RGBA", im.size)
    d = ImageDraw.Draw(layer)
    bounds = im.getbbox()
    # Три разных места попадания, косые следы и мелкий разлёт вокруг основной кляксы.
    for impact in range(stage):
        cx = rng.randrange(bounds[0]+3,bounds[2]-2)
        cy = rng.randrange(bounds[1]+3,bounds[3]-2)
        direction = rng.uniform(-1.1,1.1)
        for k in range(24):
            xx = round(cx + rng.gauss(0,17))
            yy = round(cy + rng.gauss(0,8))
            rr = rng.randrange(1,5)
            d.ellipse((xx-rr,yy-rr,xx+rr*2,yy+rr),fill=(82+rng.randrange(30),9,13,215))
            if k % 5 == 0:
                d.line((xx,yy,xx+direction*16,yy+10+rng.randrange(8)),fill=(69,8,11,180),width=2)
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"),im.getchannel("A")))
    return Image.alpha_composite(im,layer)


def main():
    atlas = Image.new("RGBA", (W*8,H*17))
    sprites = [sprite(i) for i in range(len(NAMES))]
    for stage in range(4):
        for i,im in enumerate(sprites):
            n=stage*len(NAMES)+i
            atlas.paste(bloody(im,i,stage),(n%8*W,n//8*H))
    atlas.save(os.path.join(ROOT,"art","map_vehicles.png"))
    # Контактный лист ×4 относительно игровых размеров; асфальт и кровь.
    sheet=Image.new("RGB",(1536,1970),(27,29,29))
    d=ImageDraw.Draw(sheet)
    font=ImageFont.truetype("C:/Windows/Fonts/consola.ttf",16)
    d.text((20,14),"O2 / VEHICLES   |   4x world scale   |   intact - damaged - burning - wreck",font=font,fill=(197,189,159))
    for i,im in enumerate(sprites):
        x,y=(i%4)*384,60+(i//4)*208
        asphalt=Image.open(os.path.join(ROOT,"art/asphalt.png")).convert("RGB")
        for xx in range(0,384,asphalt.width):
            for yy in range(0,170,asphalt.height):
                sheet.paste(asphalt.crop((0,0,min(asphalt.width,384-xx),min(asphalt.height,170-yy))),(x+xx,y+yy))
        if i%4 >=2:
            for spot in range(7):
                rng=random.Random(i*100+spot)
                mask=Image.open(os.path.join(ROOT,f"art/blood_{spot%8}.png")).convert("RGBA")
                mask=mask.resize((130,130),Image.Resampling.NEAREST)
                paint=Image.new("RGBA",mask.size,(69,13,17))
                paint.putalpha(mask.getchannel("A"))
                sheet.paste(paint,(x+rng.randrange(250),y+rng.randrange(40)),paint)
        pic=bloody(im,i,2 if i%4>=2 else 0).resize((384,192),Image.Resampling.NEAREST)
        sheet.paste(pic,(x,y-10),pic)
        if i <20 and i%4 ==2:
            row=(i//4)%3; frame=2+(i//4)%4
            fire=Image.open(os.path.join(ROOT,"art/fx_explosion_medium.png")).convert("RGBA").crop((frame*144,row*144,(frame+1)*144,(row+1)*144))
            fire=fire.resize((100,112),Image.Resampling.NEAREST)
            sheet.paste(fire,(x+170+(i//4%4)*15,y+5+(i//4%3)*12),fire)
        d.text((x+14,y+174),NAMES[i],font=font,fill=(181,179,156))
    sheet.save(os.path.join(ROOT,"design/tasks/reports/o2_vehicles.png"))
    print("OBSTART atlas=2304x2448 tiles=136 blood_stages=4 deterministic=true")


if __name__ == "__main__":
    main()
