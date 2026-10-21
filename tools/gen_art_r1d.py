"""Маски густых разливов: спокойные лопасти и потёк по оси X, без спиц."""
from pathlib import Path
import hashlib
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]


def generate():
    # Рельеф разлива в мировых координатах: широкие сухие островки, без клеток.
    rng = np.random.default_rng(71893)
    relief = np.zeros((512, 512), dtype=float)
    for cells, weight in [(8, .60), (20, .28), (64, .12)]:
        coarse = np.uint8(rng.uniform(0, 255, (cells, cells)))
        tile = Image.fromarray(np.tile(coarse, (3, 3)))
        smooth = np.asarray(tile.resize((1536, 1536), Image.Resampling.BICUBIC), dtype=float)
        relief += smooth[512:1024, 512:1024] * weight / 255
    relief = np.clip((relief - .28) / .44, 0, 1)
    # Края повторения совпадают; размер тайла больше обычного кадра камеры.
    relief = (relief + np.roll(relief, 256, axis=0) + np.roll(relief, 256, axis=1)) / 3
    relief = np.clip((relief - .24) / .52, 0, 1)
    Image.fromarray(np.uint8(relief * 255)).convert('RGBA').save(ROOT / 'art/blood_relief_r1d.png')
    y, x = np.mgrid[0:112, 0:160].astype(float)
    for index in range(8):
        rng = np.random.default_rng(190719 + index)
        field = np.zeros(x.shape)
        # Перекрывающиеся мягкие лопасти образуют один связный разлив.
        lobes = [(60, 56, 37, 27), (87, 57, 27, 20), (111, 59, 22, 10)]
        for _ in range(5):
            lobes.append((rng.uniform(42, 87), rng.uniform(39, 72), rng.uniform(19, 30), rng.uniform(15, 23)))
        for cx, cy, rx, ry in lobes:
            cx += rng.uniform(-5, 5); cy += rng.uniform(-5, 5)
            field = np.maximum(field, 1 - ((x-cx)/rx)**2 - ((y-cy)/ry)**2)
        ripple = .025 * np.sin(x*.19 + index) * np.cos(y*.17-index)
        alpha = np.clip((field + ripple) * 9, 0, 1)
        thickness = .52 + .48 * np.clip(field, 0, 1)
        rgba = np.empty((*x.shape, 4), np.uint8)
        rgba[:, :, :3] = np.uint8(thickness[:, :, None] * 255)
        rgba[:, :, 3] = np.uint8(alpha * 255)
        path = ROOT / 'art' / f'blood_pool_r1d_{index}.png'
        Image.fromarray(rgba).filter(ImageFilter.GaussianBlur(.65)).save(path, optimize=False)
        print(path.name, hashlib.sha256(path.read_bytes()).hexdigest())


if __name__ == '__main__':
    generate()
