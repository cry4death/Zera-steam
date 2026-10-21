"""Материалы базы Z.E.R.A. Малые бесшовные текстуры, фиксированный сид."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def material(name, base, cloth=False):
    seed = 20261019 + int(cloth)
    def next_value():
        nonlocal seed
        seed = (1664525 * seed + 1013904223) & 0xffffffff
        return seed
    image = Image.new("RGB", (128, 128))
    pixels = image.load()
    for y in range(128):
        for x in range(128):
            grain = (-2, -1, 0, 0, 0, 1, 2)[next_value() % 7]
            if cloth:
                grain += (1 if x % 4 < 2 else -1) + (1 if y % 4 < 2 else -1)
            elif next_value() % 200 == 0:
                grain += 5
            pixels[x, y] = tuple(max(0, min(255, c + grain)) for c in base)
    image.save(ROOT / "art" / (name + ".png"), optimize=True)


if __name__ == "__main__":
    material("ui_steel", (21, 27, 27))
    material("ui_canvas", (36, 45, 40), cloth=True)
    print("U2ART textures=2 seed=20261019")
