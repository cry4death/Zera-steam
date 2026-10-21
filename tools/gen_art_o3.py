"""O3b: объёмные постройки и запечённые детали трёх карт. Только стандартная библиотека."""
from pathlib import Path
import binascii
import json
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art'
MAPS = ('military_airfield', 'cargo_port', 'residential_district')


def tone(rgb, amount):
    return tuple(max(0, min(255, int(v * amount))) for v in rgb[:3])


class Canvas:
    """Небольшой растровый холст; координаты в пикселях, без сглаживания."""
    def __init__(self, w, h, color=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.data = bytearray(bytes((*color[:3], color[3] if len(color) == 4 else 255)) * (w * h))

    def rect(self, x, y, w, h, color):
        x0, y0 = max(0, round(x)), max(0, round(y))
        x1, y1 = min(self.w, round(x+w)), min(self.h, round(y+h))
        if x1 <= x0 or y1 <= y0:
            return
        row = bytes((*color[:3], color[3] if len(color) == 4 else 255)) * (x1-x0)
        for yy in range(y0, y1):
            at = (yy*self.w+x0)*4
            self.data[at:at+len(row)] = row

    def line(self, x0, y0, x1, y1, color, width=1):
        length = max(1, math.ceil(max(abs(x1-x0), abs(y1-y0))))
        for step in range(length+1):
            t = step/length
            self.rect(x0+(x1-x0)*t-width//2, y0+(y1-y0)*t-width//2, width, width, color)

    def poly(self, points, color):
        for y in range(max(0, math.ceil(min(p[1] for p in points))), min(self.h, math.ceil(max(p[1] for p in points)))):
            hits = []
            for (x0,y0),(x1,y1) in zip(points, points[1:]+points[:1]):
                if min(y0,y1) <= y+.5 < max(y0,y1):
                    hits.append(x0+(y+.5-y0)*(x1-x0)/(y1-y0))
            hits.sort()
            for a,b in zip(hits[::2], hits[1::2]):
                self.rect(math.ceil(a), y, math.ceil(b)-math.ceil(a), 1, color)

    def oval(self, x, y, w, h, color):
        if w <= 0 or h <= 0:
            return
        for yy in range(max(0, round(y)), min(self.h, math.ceil(y+h))):
            radius = math.sqrt(max(0, 1-((yy+.5-y-h/2)/(h/2))**2))*w/2
            self.rect(x+w/2-radius, yy, radius*2, 1, color)

    def save(self, path):
        def chunk(name, data):
            return struct.pack('>I',len(data))+name+data+struct.pack('>I',binascii.crc32(name+data)&0xffffffff)
        raw = b''.join(b'\0'+self.data[y*self.w*4:(y+1)*self.w*4] for y in range(self.h))
        path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))


FONT = {
    '0':['111','101','101','101','111'], '1':['010','110','010','010','111'],
    '2':['111','001','111','100','111'], '3':['111','001','111','001','111'],
    '4':['101','101','111','001','001'], '5':['111','100','111','001','111'],
    '6':['111','100','111','101','111'], '7':['111','001','010','010','010'],
    '8':['111','101','111','101','111'], '9':['111','101','111','001','111'],
    'A':['010','101','111','101','101'], 'C':['111','100','100','100','111'],
    'D':['110','101','101','101','110'], 'H':['101','101','111','101','101'],
    'M':['101','111','111','101','101'], 'P':['111','101','111','100','100'],
    'S':['111','100','111','001','111'], 'U':['101','101','101','101','111'],
    '-':['000','000','111','000','000'], ' ':['000']*5,
}


def label(c, text, x, y, color, scale=2):
    for char in text:
        for yy,row in enumerate(FONT.get(char, FONT[' '])):
            for xx,v in enumerate(row):
                if v == '1':
                    c.rect(x+xx*scale,y+yy*scale,scale,scale,color)
        x += 4*scale


def vent(c, x, y, w=32, h=22):
    c.poly([(x+4,y+4),(x+w+10,y+7),(x+w+8,y+h+10),(x+7,y+h+8)],(35,39,35))
    c.rect(x,y,w,h,(114,116,100))
    c.rect(x+2,y+2,w-4,h-5,(65,73,67))
    for yy in range(round(y+5),round(y+h-4),4):
        c.line(x+5,yy,x+w-5,yy,(139,140,117))
    c.rect(x,y+h-4,w,4,(47,54,48))


def building(skin, w, h, variant):
    c = Canvas(w*2,h*2)
    W,H = c.w,c.h
    rng = random.Random(73011+skin*31+w*7+h+variant*149)
    base = (86,98,90) if skin in (12,18) else (109,104,86)
    if variant == 1:
        base = tone(base,.92)
    elif variant == 2:
        base = (99,94,78) if skin in (12,18) else (104,108,98)
    wall = 68 if skin == 13 else 52
    east = 18
    roof_h = H-wall
    # Вся видимая стена остаётся внутри прежнего OBB.
    c.rect(0,0,W,H,(31,36,32))
    c.rect(3,3,W-east-3,roof_h-3,base)
    c.poly([(W-east,3),(W-2,19),(W-2,H-3),(W-east,roof_h)],tone(base,.52))
    c.rect(3,roof_h,W-east-3,wall-3,(91,91,78) if skin == 13 else (77,83,75))
    c.rect(3,roof_h+3,W-east-4,6,(42,47,43))
    c.line(2,2,W-east,2,tone(base,1.42),3)
    c.line(2,2,2,roof_h,tone(base,1.2),3)
    c.line(W-east,2,W-east,roof_h,tone(base,.52),3)
    c.line(2,H-4,W-2,H-4,(24,29,26),5)
    if skin in (12,18):
        # Двускатная кровля: светлая и затенённая половины, конёк, крепёж.
        c.rect(W//2,5,W//2-east-2,roof_h-7,tone(base,.79))
        for y in range(12,roof_h-3,20):
            c.line(5,y,W-east-4,y,tone(base,.72),2)
            c.line(5,y+2,W-east-4,y+2,tone(base,1.12))
            for x in range(17,W-east-5,64):
                c.rect(x,y+3,2,2,tone(base,.6))
        c.line(W//2,4,W//2,roof_h-2,(139,143,122),3)
        for y in (roof_h//3,roof_h*2//3):
            c.rect(W//4,y,W//2,18,(25,40,41))
            c.line(W//4,y,W*3//4,y,(145,150,125),2)
            for x in range(W//4+9,W*3//4,16):
                c.line(x,y+2,x,y+15,(72,91,85),2)
        # Две большие створки, ролики и повреждённые нижние панели.
        gate_x,gate_w = W*.19,W*.54
        c.rect(gate_x,roof_h+10,gate_w,wall-15,(33,41,40))
        for x in range(round(gate_x+4),round(gate_x+gate_w-2),14):
            c.rect(x,roof_h+13,10,wall-21,(62,72,67))
            c.line(x,roof_h+13,x,H-9,(100,109,95))
        c.line(W//2,roof_h+12,W//2,H-7,(21,28,27),3)
        c.rect(18,roof_h+15,17,wall-21,(35,44,41))
        c.rect(30,roof_h+30,2,3,(157,146,104))
        label(c,'H-'+str(variant+1),W-100,roof_h+16,(163,156,124),2)
        for x in (12,W-east-12):
            c.line(x,8,x,H-9,(47,60,54),4)
            c.line(x-2,8,x-2,H-9,(123,130,111))
        vent(c,W*.14,roof_h*.2)
        vent(c,W*.79,roof_h*.72,28,22)
    else:
        # Рубероид со швами и заплатами, парапет, люк и теплотрасса.
        roof = tone(base,.83)
        c.rect(10,10,W-east-19,roof_h-19,roof)
        for y in range(18,roof_h-8,48):
            c.line(12,y,W-east-12,y,tone(roof,.85),2)
            c.line(12,y+2,W-east-12,y+2,tone(roof,1.08))
        for k in range(max(3,w//100)):
            x,y = rng.randrange(18,W-east-72),rng.randrange(20,roof_h-65)
            c.rect(x,y,50,36,tone(roof,rng.uniform(.75,.94)))
        for x,y in [(W*.17,roof_h*.24),(W*.68,roof_h*.56),(W*.45,roof_h*.76)]:
            vent(c,x,y,38,28)
        c.rect(W*.42+8,roof_h*.25+10,38,38,tone(base,.4))
        c.rect(W*.42,roof_h*.25,36,36,(121,121,102))
        c.rect(W*.42+4,roof_h*.25+5,25,26,(60,66,59))
        c.line(W*.42+34,roof_h*.25+16,W*.58,roof_h*.25+16,(128,127,109),5)
        c.line(W*.58,roof_h*.25+16,W*.58,roof_h*.55,(128,127,109),5)
        for x in range(16,W-east-20,42):
            for y in (roof_h+12,roof_h+38):
                c.rect(x,y,22,17,(36,47,47))
                c.line(x,y+17,x+23,y+17,(145,140,116),2)
                c.line(x+10,y+1,x+10,y+14,(90,105,98))
        door = W*.57
        c.rect(door,roof_h+30,24,wall-35,(36,41,36))
        c.rect(door+2,roof_h+32,19,12,(67,83,78))
        c.rect(door-5,roof_h+26,35,4,(138,134,112))
        for x in range(10,W-east,80):
            c.line(x,roof_h+8,x,H-7,(67,69,59))
        c.line(W-east-9,9,W-east-9,H-7,(46,53,46),3)
    for k in range(max(40,w*h//500)):
        x,y = rng.randrange(7,W-east-6),rng.randrange(8,roof_h-4)
        c.rect(x,y,rng.randrange(2,9),1,tone(base,rng.uniform(.68,1.14)))
    return c


def container(w, h, variant):
    c = Canvas(w*2,h*2)
    W,H = c.w,c.h
    rng = random.Random(91031+variant)
    base = [(78,91,86),(110,73,51),(86,91,62)][variant]
    tiers = (1,2,3)[variant]
    face = 28+tiers*18
    roof = H-face
    c.rect(0,0,W,H,(25,31,28))
    c.rect(3,3,W-17,roof-3,base)
    c.rect(W-14,6,11,H-8,tone(base,.51))
    c.line(4,3,W-15,3,tone(base,1.55),3)
    c.line(3,3,3,H-5,tone(base,1.3),3)
    for y in range(12,roof-3,12):
        c.rect(7,y,W-26,3,tone(base,.52))
        c.line(8,y+4,W-20,y+4,tone(base,1.22),2)
    c.rect(4,roof,W-19,face-4,tone(base,.77))
    for level in range(tiers):
        y = roof+level*(face-4)/tiers
        hh = (face-4)/tiers
        c.line(4,y,W-15,y,(29,34,30),3)
        c.line(7,y+3,W-18,y+3,tone(base,1.24))
        for x in (7,W//2+1):
            c.rect(x,y+5,W//2-13,hh-8,tone(base,.9))
            for bar in (x+5,x+W//2-21):
                c.line(bar,y+6,bar,y+hh-5,(153,151,125),2)
                c.line(bar-2,y+hh-8,bar+4,y+hh-8,(26,32,28),2)
        c.line(W//2,y+3,W//2,y+hh-1,(29,34,30),3)
    label(c,'C'+str(410+variant*137),12,20,(177,171,135),2)
    label(c,str(22+variant),14,roof+8,(185,175,136),1)
    # Угловые отливки, петли и потёки от швов.
    for x in (3,W-19):
        for y in (3,roof-8,H-10):
            c.rect(x,y,11,7,tone(base,.55))
            c.rect(x+2,y+2,6,3,(166,158,121))
    for k in range(28):
        x = rng.choice((rng.randrange(5,15),rng.randrange(W-28,W-17),rng.randrange(14,W-25)))
        y = rng.randrange(34,H-10)
        c.rect(x,y,rng.randrange(1,4),rng.randrange(3,14),(104,67,43))
        c.rect(x+1,y,1,3,(146,100,61))
    return c


def prop(skin,w,h,variant):
    c = Canvas(w*2,h*2)
    W,H = c.w,c.h
    dark,edge = (30,37,32),(145,146,118)
    if skin == 14:
        c.poly([(0,10),(W-12,10),(W-2,H-2),(3,H-2)],(65,71,62))
        c.poly([(3,4),(W-15,4),(W-12,10),(0,10)],(138,143,125))
        for x in range(10,W-10,28):
            c.line(x,10,x+7,H-6,(90,96,82),3)
            c.rect(x+3,7,4,3,dark)
    elif skin == 15:
        c.rect(4,H*.4,W-9,H*.55,(53,65,51))
        c.line(4,H-5,W-6,H-5,dark,5)
        c.rect(5,H*.37,W-12,4,edge)
        c.line(W*.25,H*.7,W*.5,10,(83,94,73),8)
        c.line(W*.75,H*.7,W*.5,10,(83,94,73),8)
        c.poly([(9,6),(W-9,6),(W*.7,H*.34),(W*.3,H*.34)],(48,65,53))
        for x in range(12,W-9,8):
            c.line(x,8,W*.5+(x-W*.5)*.5,H*.31,(141,148,112),2)
        c.line(10,7,W-10,7,edge,3)
        c.line(W*.5,H*.3,W*.5,H*.55,edge,3)
    elif skin == 16:
        # Сбитый вертолёт: отдельные кабина, двигатель, лопасти и хвостовая балка.
        if w < 60:
            c.poly([(2,H*.35),(W-4,2),(W-4,H-3),(2,H*.65)],(73,86,65))
            c.line(4,H*.4,W-5,3,(132,137,100),2)
        else:
            c.poly([(10,H*.5),(W*.3,6),(W*.77,4),(W-5,H*.35),(W-4,H*.69),(W*.76,H-5),(W*.24,H-7)],(32,42,33))
            c.poly([(12,H*.43),(W*.3,6),(W*.76,5),(W-10,H*.35),(W*.72,H*.66),(W*.25,H*.68)],(84,98,74))
            c.rect(W*.41,11,W*.2,H*.4,(105,111,81))
            c.poly([(W*.75,9),(W-9,H*.34),(W*.85,H*.53),(W*.72,H*.48)],(27,48,48))
            c.line(W*.75,10,W*.75,H*.5,(132,140,115),2)
            c.rect(W*.32,H*.24,15,17,(28,38,31))
            for x in range(round(W*.32)+2,round(W*.32)+14,4):
                c.line(x,H*.25,x,H*.25+13,(138,140,108))
            c.line(W*.2,H*.72,W*.82,H*.78,dark,4)
            c.line(W*.2,H*.72,W*.82,H*.72,(153,155,120),2)
            c.line(2,H-9,W-12,6,(44,53,40),5)
            c.line(4,H-11,W-12,4,(128,137,107),2)
            c.line(W*.5,4,W*.48,H-3,(46,57,43),6)
            c.oval(W*.47,H*.4,10,9,(152,153,116))
    elif skin == 19:
        c.rect(5,H-37,W-10,32,dark)
        for x in (12,W-28):
            c.oval(x,H-28,22,21,(24,30,28))
            c.oval(x+5,H-24,10,10,(100,108,91))
        c.poly([(12,H-30),(W-12,H-30),(W-31,H*.35),(33,H*.35)],(117,109,73))
        c.rect(30,H*.4,W-64,H*.43,(87,86,59))
        c.rect(W-67,H*.28,36,36,(141,129,85))
        c.rect(W-62,H*.31,25,19,(32,52,51))
        # Ажурная ферма читается на крыше базы, крюк висит над ней.
        for y in range(5,round(H*.7),16):
            c.line(25,y,W-60,y+14,(157,143,92),4)
            c.line(W-60,y,25,y+14,(65,69,48),3)
        c.line(24,5,24,H*.72,(185,164,104),5)
        c.line(W-59,5,W-59,H*.72,(185,164,104),5)
        c.line(W-15,18,W-15,H*.6,(31,39,34),2)
        c.line(W-15,H*.6,W-22,H*.66,(157,150,113),3)
        label(c,'04',W-53,H*.65,(201,184,133),2)
    elif skin == 20:
        c.rect(3,6,W-6,H-10,(34,39,32))
        c.rect(5,5,W-12,H-20,(118,116,88))
        c.line(8,6,W-10,6,(172,166,129),3)
        for x in range(10,W-22,24):
            c.rect(x,H-17,18,10,(29,45,43))
            c.line(x,H-5,x+18,H-5,(76,79,61),2)
        for x in (W*.24,W*.62):
            vent(c,x,14,23,15)
        c.rect(W-25,10,12,H-30,(30,46,43))
        c.poly([(W*.45,5),(W*.54,16),(W*.48,24),(W*.6,34)],(45,45,33))
    elif skin == 21:
        c.rect(2,3,W-4,H-6,(31,43,34))
        c.rect(4,3,W-9,H-15,(84,105,79))
        c.line(5,4,W-7,4,(142,153,119),2)
        for x in (8,W//2):
            c.rect(x,7,W//2-11,H-24,(61,80,59))
            c.line(x,8,x+W//2-12,8,(123,140,107))
        c.rect(3,H-11,W-6,6,(44,60,42))
        c.rect(W//2-6,H-11,12,3,(159,154,119))
    return c


def structures(data):
    rows = data['structures']
    seen = set()
    result = []
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch == ' ' or (x,y) in seen:
                continue
            w = 1
            while x+w < len(row) and row[x+w] == ch and (x+w,y) not in seen:
                w += 1
            h = 1
            while y+h < len(rows) and all(rows[y+h][xx] == ch and (xx,y+h) not in seen for xx in range(x,x+w)):
                h += 1
            seen.update((xx,yy) for yy in range(y,y+h) for xx in range(x,x+w))
            result.append((x*32,y*32,w*32,h*32,ch))
    return result


def stain(c,rng,x,y,r,color):
    points = []
    for k in range(12):
        a = k*math.tau/12
        rr = r*rng.uniform(.6,1.2)
        points.append((x+math.cos(a)*rr,y+math.sin(a)*rr*.44))
    c.poly(points,color)


def pallet(c,x,y):
    c.rect(x+3,y+3,22,16,(32,35,29))
    for yy in range(0,14,3):
        c.rect(x,y+yy,20,2,(116,104,73))
        c.rect(x+3,y+yy,1,1,(51,53,40))
        c.rect(x+16,y+yy,1,1,(51,53,40))


def workshop_litter(c,rng,x,y):
    # Низкий хлам: спущенные покрышки, кабель, снятые панели и упавшие канистры.
    pallet(c,x,y)
    for dx,dy in ((34,4),(43,9)):
        c.oval(x+dx+2,y+dy+2,10,7,(39,45,37))
        c.oval(x+dx,y+dy,9,6,(27,33,29))
        c.oval(x+dx+2,y+dy+1,5,3,(92,96,77))
        c.oval(x+dx+3,y+dy+2,3,1,(34,42,33))
    for k in range(6):
        dx,dy = rng.randrange(8,52),rng.randrange(13,24)
        color = rng.choice(((126,116,86),(110,119,108),(70,80,71)))
        c.line(x+dx,y+dy,x+dx+6,y+dy+1,color,2)
    c.oval(x+55,y+6,13,8,(38,45,37))
    c.oval(x+57,y+7,9,5,(91,91,66))
    c.oval(x+59,y+8,5,3,(40,47,37))


def ground(data):
    name = data['id']
    rows = data['ground']
    if name == 'residential_district':
        rows = [row.translate(str.maketrans({'.':'#', ',':':'})) for row in rows]
    rng = random.Random(61073+MAPS.index(name)*473)
    c = Canvas(2560,1440)
    palettes = {
        'military_airfield':{'=':(54,58,55),'#':(99,102,91),':':(67,74,48)},
        'cargo_port':{'=':(49,63,65),'#':(94,101,93),'~':(32,55,60),':':(49,63,65)},
        'residential_district':{'=':(63,62,57),'#':(113,110,96),':':(70,76,48)},
    }
    palette = palettes[name]
    # Незаметное зерно и крупные пятна материала вместо контрастной шахматки.
    colors = {}
    for material,base in palette.items():
        colors[material] = [bytes((*tuple(max(0,v+n) for v in base),255)) for n in range(-3,4)]
    for y in range(c.h):
        row = bytearray()
        for cell,ch in enumerate(rows[y//32]):
            grain = colors.get(ch,colors['='])
            shade = ((cell//3*17+y//96*13)%5)-2
            for xx in range(32):
                n = max(0,min(6,3+shade//2+rng.randrange(-1,2)))
                row.extend(grain[n])
        c.data[y*c.w*4:(y+1)*c.w*4] = row
    # Швы бетонных плит и мелкого дворового мощения.
    stride = 48 if name == 'residential_district' else 96
    for y in range(0,c.h,stride):
        for x in range(0,c.w,stride):
            if rows[min(44,y//32)][min(79,x//32)] != '#':
                continue
            color = (83,85,75) if name != 'cargo_port' else (70,81,77)
            ex = next((xx for xx in range(x,min(c.w,x+stride)) if rows[y//32][xx//32]!='#'),min(c.w,x+stride))
            ey = next((yy for yy in range(y,min(c.h,y+stride)) if rows[yy//32][x//32]!='#'),min(c.h,y+stride))
            c.line(x,y,max(x,ex-2),y,color)
            c.line(x,y,x,max(y,ey-2),color)
            c.line(x+1,y+1,max(x+1,ex-2),y+1,tone(palette['#'],1.07))
            if rng.random() < .26:
                for k in range(rng.randrange(3,8)):
                    at = rng.randrange(stride)
                    c.line(x+at,y,x+at+2,y-rng.randrange(2,5),(68,77,49))
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch == ':':
                # Сухая растительность и разбитый край покрытия.
                for k in range(4):
                    px,py = x*32+rng.randrange(32),y*32+rng.randrange(32)
                    c.line(px,py,px+2,py-2,(88,94,59))
            for dx,dy in ((1,0),(0,1)):
                if x+dx >= 80 or y+dy >= 45 or rows[y+dy][x+dx] == ch:
                    continue
                if ch == '~' or rows[y+dy][x+dx] == '~':
                    color = (139,132,99)
                elif ch == ':' or rows[y+dy][x+dx] == ':':
                    color = (100,104,79)
                else:
                    color = (79,85,75)
                if dx:
                    c.line(x*32+31,y*32,x*32+31,y*32+31,color,2)
                else:
                    c.line(x*32,y*32+31,x*32+31,y*32+31,color,2)
    # Износ и мусор не меняют ни коллизию, ни сетку PF1.
    for k in range(1000):
        x,y = rng.randrange(24,2536),rng.randrange(24,1416)
        ch = rows[y//32][x//32]
        if ch not in '=#':
            continue
        base = palette[ch]
        if k % 4 == 0:
            stain(c,rng,x,y,rng.randrange(7,32),tone(base,rng.uniform(.80,.95)))
        elif k % 4 == 1:
            pts = [(x,y),(x+7,y+2),(x+12,y-1),(x+22,y+5)]
            for a,b in zip(pts,pts[1:]):
                c.line(*a,*b,tone(base,.62))
        else:
            c.rect(x,y,rng.randrange(1,4),rng.randrange(1,3),tone(base,rng.uniform(.72,1.25)))
    # Проекции крупных объектов запечены один раз; свет всегда с северо-запада.
    for index,(x,y,w,h,ch) in enumerate(structures(data)):
        if ch == 'Q':
            continue
        length = (18,27,36)[index%3] if ch == 'C' else 34
        c.poly([(x+4,y+h-4),(x+w-3,y+9),(x+w+length,y+length),(x+w+length,y+h+length),(x+length,y+h+length)],(35,42,36))
        c.poly([(x+w,y+4),(x+w+length+4,y+length),(x+w+length+4,y+h+length+3),(x+length,y+h+length+3),(x+length,y+h+length)],(44,49,41))
        # Узкие полосы служебного мусора у цоколя, свободные коридоры шире них.
        if ch in 'HAD':
            for i in range(max(2,w//110)):
                if rng.random() < .38:
                    continue
                xx = x+18+i*96+rng.randrange(-7,13)
                yy = y+h+rng.randrange(5,13)
                if i % 2 == 0:
                    workshop_litter(c,rng,xx,yy)
                else:
                    pallet(c,xx,yy)
                c.rect(xx+29,yy+4,4,3,(138,132,104))
                c.rect(xx+38,yy+7,3,2,(61,65,55))
            for xx in range(x+24,x+w-10,80):
                c.rect(xx,y+h+1,28,5,(45,49,43))
                for dx in range(2,27,4):
                    c.line(xx+dx,y+h+1,xx+dx,y+h+4,(104,108,88))
    # Тени сценок тоже направлены на юго-восток, независимо от поворота корпуса.
    footprints = {
        'blast_wall':[(0,0,128,16)], 'radar':[(0,0,64,48)],
        'helicopter':[(0,0,88,28),(-65,0,52,10)],
        'fuel_bowser':[(0,0,76,36)], 'dock_crane':[(0,0,96,80)],
        'bus_wreck':[(0,0,112,32)], 'dumpsters':[(0,0,32,20)],
        'bus_stop':[(0,-24,90,28),(80,-20,34,40)],
        'cargo_spill':[(-48,0,60,48),(40,18,24,28)],
    }
    for piece in data['set_pieces']:
        a = math.radians(piece.get('angle',0))
        ox,oy = (v*32 for v in piece['at'])
        for dx,dy,w,h in footprints.get(piece['type'],[]):
            corners = []
            for x,y in ((dx-w/2,dy-h/2),(dx+w/2,dy-h/2),(dx+w/2,dy+h/2),(dx-w/2,dy+h/2)):
                corners.append((ox+x*math.cos(a)-y*math.sin(a),oy+x*math.sin(a)+y*math.cos(a)))
            # Выпуклая оболочка исходного и сдвинутого прямоугольника.
            points = sorted(corners+[(x+17,y+19) for x,y in corners])
            def cross(a,b,p):
                return (b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0])
            hull = []
            for p in points:
                while len(hull)>1 and cross(hull[-2],hull[-1],p)<=0:
                    hull.pop()
                hull.append(p)
            lower = len(hull)
            for p in reversed(points[:-1]):
                while len(hull)>lower and cross(hull[-2],hull[-1],p)<=0:
                    hull.pop()
                hull.append(p)
            c.poly(hull[:-1],(36,43,37))
    if name == 'military_airfield':
        # Полоса, рулёжная линия и следы колёс на стоянках.
        for y in range(38,1420,142):
            c.rect(1918,y,6,64,(169,168,133))
        for x in (1760,1840,1960,2040):
            c.rect(x,73,11,122,(177,176,144))
        c.line(1721,12,1721,1426,(137,142,116),2)
        c.line(2145,12,2145,1426,(137,142,116),2)
        c.line(96,650,1480,650,(163,148,95),2)
        c.line(1480,650,1600,730,(163,148,95),2)
        c.line(1600,730,1600,1140,(163,148,95),2)
        label(c,'04',1815,215,(153,153,126),9)
        for x,y,w,h,ch in structures(data):
            if ch != 'H':
                continue
            for xx in range(x+8,x+w,20):
                c.line(xx,y+h+20,xx+9,y+h+31,(145,132,85),3)
            for xx in (x+w*.35,x+w*.64):
                c.line(xx,y+h+37,xx+11,y+h+104,(70,75,66),2)
                c.line(xx+7,y+h+38,xx+18,y+h+105,(74,78,68),2)
            # Технические площадки у ангаров: вытертые дуги и масляные пятна.
            stain(c,rng,x+w*.65,y+h+63,33,(67,74,65))
        for x,y in ((1260,180),(1210,1170),(2310,270),(2350,1200)):
            c.line(x-48,y-36,x+48,y-36,(143,134,93),2)
            c.line(x-48,y-36,x-48,y+28,(143,134,93),2)
            c.line(x+48,y-36,x+48,y+28,(143,134,93),2)
            c.oval(x-8,y-4,16,8,(40,48,41))
            c.rect(x-2,y-8,4,6,(133,132,103))
        # Сломанные лопасти шире фюзеляжа, но лежат на земле и не сужают проход.
        x,y = 1952,832
        stain(c,rng,x+14,y+9,59,(39,46,39))
        for dx,dy in ((-64,-35),(57,-43),(-54,46),(67,32)):
            c.line(x+9,y+10,x+dx+9,y+dy+10,(30,37,31),7)
            c.line(x,y,x+dx,y+dy,(40,49,38),6)
            c.line(x-1,y-1,x+dx-1,y+dy-1,(113,123,94),2)
            c.line(x+dx*.9,y+dy*.9,x+dx,y+dy,(157,150,107),3)
        c.oval(x-7,y-6,14,12,(36,45,34))
        c.oval(x-4,y-5,8,7,(137,143,106))
    elif name == 'cargo_port':
        for x in (820,1170,1550):
            for y in range(24,1410,96):
                c.rect(x,y,3,38,(143,143,109))
        for x in (2060,2089):
            c.line(x,32,x,1390,(26,37,37),4)
            c.line(x+3,32,x+3,1390,(126,134,119),2)
            for y in range(36,1390,26):
                c.line(x-5,y,x+9,y,(62,72,66),3)
        for x,y,w,h,ch in structures(data):
            if ch == 'Q':
                # Вода: короткие волны и причальная стенка, без свечения.
                for k in range(max(30,w*h//1400)):
                    xx,yy=x+rng.randrange(w),y+rng.randrange(h)
                    c.line(xx,yy,xx+rng.randrange(4,23),yy,(43,65,67))
                c.line(x,y,x,y+h,(30,42,40),6)
                c.line(x-5,y,x-5,y+h,(146,140,111),3)
                for yy in range(y+12,y+h,44):
                    c.rect(x-13,yy,10,18,(30,36,33))
                    c.line(x-13,yy,x-4,yy,(94,100,84),2)
            elif ch == 'C':
                label(c,str(10+x//160+y//320),x+6,y+h+47,(139,143,116),2)
                if (x//32+y//32)%3 == 0:
                    pallet(c,x+8,y+h+12)
        for x,y in ((2240,250),(2240,1018)):
            # Крановая ферма и её длинная тень над пирсом; основание — OBB сценки.
            c.poly([(x+14,y+26),(x+200,y+54),(x+203,y+74),(x+10,y+51)],(31,43,39))
            c.line(x,y,x+179,y-20,(53,61,47),7)
            c.line(x,y-15,x+179,y-35,(156,139,87),4)
            c.line(x,y,x+179,y-20,(145,128,79),4)
            for xx in range(0,174,22):
                c.line(x+xx,y-xx/9-14,x+xx+22,y-(xx+22)/9,(120,114,76),3)
                c.line(x+xx,y-xx/9,x+xx+22,y-(xx+22)/9-14,(104,102,69),2)
            c.line(x+179,y-33,x+179,y+17,(27,37,33),2)
            c.line(x+179,y+17,x+173,y+22,(155,147,108),3)
    else:
        # Разметка улиц и парковки, переходы на перекрёстках.
        for x in (880,1970):
            for y in range(20,1440,100):
                c.rect(x,y,2,40,(158,148,102))
        for x in range(24,2560,100):
            if not (760<x<995 or 1845<x<2080):
                c.rect(x,702,40,2,(157,148,103))
        for x in (770,1858):
            for y in (587,812):
                for xx in range(x,x+210,29):
                    c.rect(xx,y,14,33,(173,165,137))
        for x in range(1330,1720,52):
            c.line(x,880,x,980,(157,150,119),2)
        # Площадка, песочница, качели и скамьи остаются проходимыми.
        c.rect(350,338,300,181,(63,73,47))
        c.rect(367,354,266,149,(136,127,89))
        c.rect(372,359,256,139,(75,85,54))
        c.line(500,359,500,498,(125,128,89))
        c.rect(1370,421,126,72,(143,131,93))
        c.rect(1376,427,114,60,(160,146,105))
        for k in range(75):
            x,y=rng.randrange(1378,1489),rng.randrange(429,484)
            c.rect(x,y,2,1,(139,128,91))
        for x in (1325,1390):
            c.line(x+8,382,x+31,418,(44,50,39),3)
            c.line(x,351,x-12,397,(121,126,102),3)
            c.line(x,351,x+13,397,(80,91,74),3)
        c.line(1325,351,1390,351,(150,151,120),4)
        for x in (1344,1368):
            c.line(x,352,x,382,(49,58,46))
        c.rect(1340,382,33,6,(133,109,69))
        for x,y in ((330,541),(1235,536),(2210,880),(140,1220)):
            c.rect(x+4,y+7,51,13,(43,49,36))
            for yy in range(0,10,3):
                c.rect(x,y+yy,48,2,(125,107,72))
            c.rect(x+5,y+10,3,4,(46,53,41))
            c.rect(x+39,y+10,3,4,(46,53,41))
    c.save(ART/f'map_ground_{name}.png')


def main():
    count = 0
    # Только новые виды O3 и вертикальные контейнеры порта; старый арт сохраняется.
    sizes = {(14,128,16),(15,64,48),(16,88,28),(16,52,10),
             (19,96,80),(20,112,32),(21,32,20)}
    data = [json.loads((ROOT/'maps'/f'{name}.json').read_text(encoding='utf-8')) for name in MAPS]
    skins = {'H':12,'A':13,'D':18,'C':5}
    for profile in data:
        sizes.update((skins[ch],w,h) for x,y,w,h,ch in structures(profile) if ch in skins)
    for skin,w,h,variant in sorted((*size,v) for size in sizes for v in range(3)):
        path = ART/f'map_roof_{skin}_{w}_{h}_{variant}.png'
        if skin in (12,13,18):
            image = building(skin,w,h,variant)
        elif skin == 5 and (w,h) == (64,160):
            image = container(w,h,variant)
        elif skin in (14,15,16,19,20,21):
            image = prop(skin,w,h,variant)
        else:
            continue
        image.save(path)
        count += 1
    for profile in data:
        ground(profile)
    print(f'O3BART maps=3 roofs={count} deterministic=true collision_changes=0')


if __name__ == '__main__':
    main()
