"""Мелкий металл W1, в той же плотности, что gen_art. Детерминированный запуск."""
from pathlib import Path
from PIL import Image, ImageDraw
import gen_art as ga


def casing(name, length, shell=False):
    img = Image.new('RGBA', (length + 2, 7))
    d = ImageDraw.Draw(img)
    d.rectangle((1, 2, length, 5), fill='#5e4526')
    d.rectangle((2, 2, length-1, 4), fill='#b8322e' if shell else '#c69b50')
    d.line((2, 2, length-1, 2), fill='#f57c5e' if shell else '#ffe5a1')
    d.line((length, 2, length, 5), fill='#ead18a')
    ga.save(img, name)


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
    casing('casing_small', 6)
    casing('casing_rifle', 10)
    casing('casing_shell', 11, True)
    magazine('pistol', 6, 12)
    magazine('rifle', 8, 15)
    magazine('smg', 14, 13)
    print('W1: 3 гильзы, 3 магазина ->', ga.OUT)
