"""Шестнадцать рваных масок луж: плотные сгустки, просветы, капиллярные хвосты.

Детерминированный RGBA PNG; только стандартная библиотека, python -I.
"""
from pathlib import Path
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]


def png(path, width, height, pixels):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    rows = b''.join(b'\0' + pixels[y * width * 4:(y + 1) * width * 4] for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


def generate():
    w, h = 112, 80
    for index in range(16):
        rng = random.Random(810730 + index)
        lobes = [(49, 40, rng.uniform(17, 25), rng.uniform(10, 17))]
        for _ in range(rng.randint(5, 11)):
            lobes.append((rng.uniform(33, 75), rng.uniform(27, 53), rng.uniform(5, 17), rng.uniform(3, 11)))
        holes = [(rng.uniform(29, 79), rng.uniform(24, 55), rng.uniform(1, 3)) for _ in range(24)]
        pixels = bytearray()
        for y in range(h):
            for x in range(w):
                d = max(1 - ((x - cx) / rx)**2 - ((y - cy) / ry)**2 for cx, cy, rx, ry in lobes)
                edge = .07 * math.sin(x * .7 + index) * math.sin(y * .9 - index)
                a = max(0, min(1, (d + edge) * 12))
                for cx, cy, radius in holes:
                    if (x - cx)**2 + (y - cy)**2 < radius**2:
                        a *= .12
                thickness = max(.18, min(1, .35 + d * .5 + .12 * math.sin(x * .21 + math.sin(y * .3))))
                shade = int(thickness * 255)
                pixels.extend((shade, shade, shade, round(a * 255)))
        png(ROOT / 'art' / f'blood_pool_r1e_{index}.png', w, h, pixels)
    print('R1EART masks=16 seed=810730')


if __name__ == '__main__':
    generate()
