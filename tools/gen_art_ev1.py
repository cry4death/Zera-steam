"""EV1: предметный пиксель-арт, 3 px/ед.; без сторонних библиотек.

python -I tools/gen_art_ev1.py
Маленький растеризатор сохраняет одинаковые RGBA PNG на Python 3.12/3.13.
"""
from pathlib import Path
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]


class Sprite:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.p = bytearray(width * height * 4)

    def pixel(self, x, y, color):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            if isinstance(color, str):
                color = tuple(bytes.fromhex(color)) + (255,)
            self.p[(y*self.w+x)*4:(y*self.w+x)*4+4] = bytes(color)

    def rect(self, x, y, w, h, color):
        for yy in range(int(y), int(y+h)):
            for xx in range(int(x), int(x+w)):
                self.pixel(xx, yy, color)

    def line(self, x, y, x1, y1, color, width=1):
        steps = max(abs(int(x1-x)), abs(int(y1-y)), 1)
        for i in range(steps+1):
            self.rect(round(x+(x1-x)*i/steps), round(y+(y1-y)*i/steps), width, width, color)

    def ellipse(self, x, y, w, h, color):
        for yy in range(int(y), int(y+h)):
            for xx in range(int(x), int(x+w)):
                if ((xx+0.5-x-w/2)/(w/2))**2 + ((yy+0.5-y-h/2)/(h/2))**2 <= 1:
                    self.pixel(xx, yy, color)

    def poly(self, points, color):
        for y in range(int(min(p[1] for p in points)), int(max(p[1] for p in points))+1):
            cuts = []
            for a, b in zip(points, points[1:]+points[:1]):
                if min(a[1], b[1]) <= y+0.5 < max(a[1], b[1]):
                    cuts.append(a[0]+(y+0.5-a[1])*(b[0]-a[0])/(b[1]-a[1]))
            cuts.sort()
            for x0, x1 in zip(cuts[::2], cuts[1::2]):
                self.rect(math.ceil(x0), y, max(0, math.ceil(x1)-math.ceil(x0)), 1, color)

    def save(self, name):
        def chunk(kind, data):
            return struct.pack('>I', len(data))+kind+data+struct.pack('>I', zlib.crc32(kind+data)&0xffffffff)
        raw = b''.join(b'\0'+self.p[y*self.w*4:(y+1)*self.w*4] for y in range(self.h))
        data = b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR', struct.pack('>IIBBBBB', self.w, self.h, 8, 6, 0, 0, 0))
        data += chunk(b'IDAT', zlib.compress(raw, 9))+chunk(b'IEND', b'')
        (ROOT/'art'/('activity_'+name+'.png')).write_bytes(data)
        print('ART activity_%s %dx%d bytes=%d' % (name, self.w, self.h, len(data)))


def crate():
    s = Sprite(156, 126)
    s.ellipse(17, 75, 132, 35, (8, 9, 7, 105))
    s.poly([(14, 41), (119, 30), (141, 47), (136, 94), (33, 106), (14, 89)], '1c211b')
    s.poly([(18, 46), (119, 37), (136, 51), (35, 62)], '8c9174')
    s.poly([(20, 51), (33, 66), (33, 100), (20, 86)], '454c3b')
    s.poly([(37, 66), (134, 55), (131, 89), (37, 100)], '666e51')
    for x in [46, 111]:
        s.poly([(x, 40), (x+9, 39), (x+24, 55), (x+24, 92), (x+15, 93), (x+15, 58)], '303933')
        s.line(x+2, 43, x+17, 57, 'a2a58a', 2)
        s.rect(x+15, 69, 11, 9, '161e1b')
        s.rect(x+16, 69, 8, 3, 'b4b39a')
    for x in range(25, 119, 8):
        s.line(x, 48, x+11, 56, '7b8165')
    s.rect(66, 77, 23, 11, 'd0c9a2')
    s.rect(70, 80, 15, 2, '535c48')
    s.rect(75, 78, 2, 8, '535c48')
    s.line(28, 56, 125, 46, 'b3b399', 2)
    s.line(40, 96, 124, 87, '444c3b', 2)
    rng = random.Random(31)
    for _ in range(40):
        x, y = rng.randrange(39, 128), rng.randrange(69, 90)
        s.rect(x, y, rng.randrange(1, 4), 1, '969777')
    s.save('supply')


def parachute():
    s = Sprite(228, 228)
    s.poly([(17, 76), (33, 35), (72, 13), (123, 9), (182, 31), (212, 74), (194, 80), (174, 72), (151, 82), (126, 75), (102, 85), (78, 76), (50, 85)], '333a32')
    panels = [([(21, 74), (39, 38), (74, 18), (56, 51), (49, 80)], 'b9b9a1'),
              ([(52, 79), (60, 49), (82, 17), (111, 14), (104, 79), (77, 70)], '8e9985'),
              ([(109, 77), (118, 15), (145, 19), (164, 48), (150, 76), (127, 69)], 'b0b69a'),
              ([(155, 76), (166, 50), (151, 21), (180, 36), (205, 72), (193, 74), (175, 67)], '788772')]
    for p, c in panels:
        s.poly(p, c)
    for x in [22, 51, 80, 107, 128, 154, 176, 207]:
        s.line(x, 78, 106 if x < 115 else 132, 211, 'c6c4ac')
    s.rect(99, 207, 39, 8, '3c4839')
    s.save('parachute')


def zone():
    s = Sprite(312, 312)
    rng = random.Random(18)
    # Истёртые брезентовые полосы и четыре мешка, не интерфейсное кольцо.
    for x, y, angle in [(38, 36, 0), (245, 39, 1), (37, 246, 2), (246, 243, 3)]:
        s.ellipse(x-6, y+8, 36, 18, (0, 0, 0, 65))
        s.poly([(x, y), (x+25, y-2), (x+28, y+13), (x+3, y+17), (x-3, y+10)], '73735a')
        s.line(x+3, y+2, x+22, y, 'a8a084', 2)
        s.line(x+8, y+4, x+9, y+13, '545941')
    for _ in range(75):
        x, y = rng.randrange(80, 232), rng.randrange(80, 232)
        if abs(x-156)+abs(y-156) < 115:
            s.rect(x, y, 2, 1, (133, 121, 90, 90))
    # Погрузочный крест из вытертой краски.
    for x, y, w, h in [(137, 120, 37, 8), (151, 105, 8, 37)]:
        for yy in range(y, y+h):
            for xx in range(x, x+w):
                if rng.random() > 0.29:
                    s.pixel(xx, yy, (178, 172, 137, 115))
    s.save('zone')


def pack():
    s = Sprite(66, 72)
    s.rect(13, 17, 43, 45, '232a28')
    s.rect(16, 16, 35, 40, 'a6ae9b')
    s.rect(18, 17, 29, 4, 'd0d0b9')
    s.rect(22, 10, 22, 7, '343e39')
    s.rect(27, 9, 12, 3, 'a4ad9c')
    for x in [19, 44]:
        s.rect(x, 16, 4, 40, '596252')
        s.rect(x-1, 40, 6, 4, 'cad0b4')
    s.rect(26, 29, 14, 16, '833d32')
    s.rect(30, 31, 5, 12, 'e6debf')
    s.rect(27, 35, 11, 4, 'e6debf')
    s.line(22, 54, 47, 54, '525c50', 2)
    s.save('carrier')


def fuel():
    s = Sprite(234, 192)
    s.ellipse(19, 145, 202, 36, (10, 9, 7, 100))
    # Тёмная топливная лужа, асимметрия по краям.
    s.poly([(9, 142), (30, 122), (74, 130), (101, 116), (144, 124), (176, 114), (216, 132), (227, 153), (193, 166), (157, 159), (130, 181), (85, 169), (41, 177)], (26, 24, 19, 115))
    for x, y in [(36, 35), (104, 55)]:
        s.rect(x, y+9, 58, 95, '342b25')
        s.ellipse(x, y+83, 58, 25, '49382c')
        s.rect(x+4, y+14, 49, 75, '835849')
        s.rect(x+8, y+15, 13, 73, 'a6785c')
        s.rect(x+42, y+18, 8, 69, '644536')
        s.ellipse(x, y, 58, 26, '3c3830')
        s.ellipse(x+3, y+2, 52, 20, '9e8462')
        s.ellipse(x+7, y+4, 43, 14, '80694e')
        s.ellipse(x+37, y+6, 8, 7, '2d3029')
        for yy in [y+28, y+69, y+87]:
            s.rect(x+1, yy, 56, 4, '343830')
            s.rect(x+5, yy, 48, 2, 'a8956b')
        s.poly([(x+23, y+42), (x+34, y+49), (x+29, y+62), (x+20, y+56)], 'c5b881')
        s.poly([(x+25, y+45), (x+30, y+51), (x+27, y+57), (x+24, y+54)], '594b36')
    s.line(151, 150, 188, 155, '171e1b', 3)
    s.line(187, 155, 200, 144, '4b5144', 2)
    s.rect(178, 125, 41, 26, '252c28')
    s.rect(180, 123, 35, 23, 'a0966c')
    s.rect(184, 127, 16, 6, '3f493a')
    s.rect(206, 127, 5, 5, 'bc783b')
    s.line(192, 121, 192, 109, '202822', 3)
    s.rect(187, 105, 12, 5, '6a715c')
    s.save('fuel')
    # Остаток после детонации — низкий, пустой силуэт.
    b = Sprite(234, 192)
    b.ellipse(22, 115, 191, 55, (21, 18, 15, 145))
    b.poly([(35, 126), (48, 103), (73, 112), (91, 104), (99, 141), (68, 153), (36, 144)], '34342b')
    b.poly([(112, 146), (107, 127), (132, 108), (148, 122), (166, 116), (169, 143)], '403b30')
    b.line(48, 120, 80, 119, '81755b', 2)
    b.line(125, 127, 155, 136, '705b43', 2)
    b.save('fuel_spent')


def smoke():
    s = Sprite(126, 192)
    rng = random.Random(98)
    for i in range(13):
        x = 23+i*2+rng.randrange(-12, 12)
        y = 165-i*11
        size = 14+i*4
        s.ellipse(x, y, size, size*.67, (151-i*3, 126-i*3, 83-i*2, max(15, 110-i*7)))
    s.rect(44, 175, 14, 7, '464d40')
    s.rect(46, 174, 8, 3, 'd59d58')
    s.save('smoke')


def fuel_zone():
    s = Sprite(456, 456)
    rng = random.Random(193)
    # Пятно топлива и канистры обозначают настоящую дальность детонации.
    points = []
    for j in range(44):
        angle = j*math.tau/44
        radius = rng.randrange(194, 216)
        points.append((228+math.cos(angle)*radius, 228+math.sin(angle)*radius))
    s.poly(points, (28, 26, 20, 90))
    for x, y in [(228, 13), (432, 228), (228, 431), (13, 228)]:
        s.ellipse(x-6, y+7, 22, 13, (8, 10, 7, 90))
        s.poly([(x-6, y-7), (x+9, y-7), (x+12, y+9), (x-7, y+11)], '69694a')
        s.rect(x-3, y-12, 9, 5, '343c2c')
        s.rect(x-3, y-6, 2, 13, 'a49d72')
        s.line(x-1, y-3, x+7, y+5, '464e37')
    s.save('fuel_zone')


if __name__ == '__main__':
    crate()
    parachute()
    zone()
    pack()
    fuel()
    smoke()
    fuel_zone()
