"""Тактическая карта Земли: Natural Earth, без фотографий и сетевых зависимостей."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw
import numpy as np


# Порядок совпадает с CampaignCatalog.REGIONS; это оперативные зоны, не границы стран.
CENTERS = [(52, 30), (48, 6), (61, 95), (30, 45), (27, 15), (36, 116), (42, -100), (21, 78)]


def region_maps(image: Image.Image, output: Path) -> None:
    width, height = image.size
    lat = np.deg2rad(90 - (np.arange(height)[:, None] + .5) * 180 / height)
    lon = np.deg2rad((np.arange(width)[None, :] + .5) * 360 / width - 180)
    x, y, z = np.cos(lat) * np.sin(lon), np.broadcast_to(np.sin(lat), (height, width)), np.cos(lat) * np.cos(lon)
    scores = []
    for i, (a, b) in enumerate(CENTERS):
        a, b = np.deg2rad([a, b])
        # Низкочастотная неровность общей границы, без рассыпанных пикселей.
        wobble = .012 * np.sin(x * 22 + i * 2) * np.sin(z * 19 + y * 17 + i)
        scores.append(x * np.cos(a) * np.sin(b) + y * np.sin(a) + z * np.cos(a) * np.cos(b) + wobble)
    scores = np.stack(scores)
    ids = np.argmax(scores, axis=0).astype(np.uint8) + 1
    land = np.asarray(image)[:, :, 0] > 35
    border = ((ids != np.roll(ids, 1, 0)) | (ids != np.roll(ids, 1, 1))) & land
    density = np.clip((scores.max(axis=0) - .88) / .12, 0, 1)
    density = density * density * (3 - 2 * density)
    density *= .78 + .22 * np.sin(x * 27 + y * 13) * np.sin(z * 24 - y * 19)
    encoded = np.zeros((height, width, 4), dtype=np.uint8)
    encoded[:, :, 0] = np.where(land, ids, 0)
    encoded[:, :, 1] = (density * 255).astype(np.uint8)
    encoded[:, :, 2] = border * 255
    encoded[:, :, 3] = land * 255
    Image.fromarray(encoded).save(output / "globe_regions.png")

    # Условные огни городов; не демографические данные и не дополнительные игровые объекты.
    cities = Image.new("L", (width, height))
    cd = ImageDraw.Draw(cities)
    rng = np.random.default_rng(20261018)
    locations = [(51, 0), (49, 2), (52, 13), (52, 21), (50, 30), (56, 38), (60, 30),
                 (41, 29), (31, 31), (25, 55), (35, 51), (55, 83), (56, 93), (43, 132),
                 (40, 116), (31, 121), (36, 140), (37, 127), (23, 113), (19, 73), (29, 77),
                 (23, 90), (14, 101), (41, -74), (42, -88), (34, -118), (38, -122), (30, -96), (49, -123)]
    for a, b in locations:
        xx = round((b + 180) / 360 * width) % width
        yy = round((90 - a) / 180 * height)
        if land[yy, xx]:
            cd.ellipse((xx - 1, yy - 1, xx + 1, yy + 1), fill=220)
        for _ in range(18):
            xx = round((b + 180 + rng.normal(0, .9)) / 360 * width) % width
            yy = round((90 - a + rng.normal(0, .55)) / 180 * height)
            if 0 <= yy < height and land[yy, xx]:
                cd.point((xx, yy), fill=int(rng.integers(110, 256)))
    cities = Image.fromarray(np.where(land, np.asarray(cities), 0).astype(np.uint8))
    cities.save(output / "globe_cities.png")
    print("CAMPAIGNART globe_regions.png RGBA: zone/density/border/land; globe_cities.png; seed=20261018")


def generate(source: Path, output: Path) -> None:
    scale = 2
    width, height = 2048 * scale, 1024 * scale
    ocean = (12, 18, 19)
    land = (66, 72, 69)
    image = Image.new("RGB", (width, height), ocean)
    draw = ImageDraw.Draw(image)
    data = json.loads(source.read_text(encoding="utf-8"))

    def ring_points(ring):
        # Разворачиваем переход через 180°, затем рисуем копии по обе стороны шва.
        points = []
        previous = None
        for lon, lat, *_ in ring:
            if previous is not None:
                while lon - previous > 180:
                    lon -= 360
                while lon - previous < -180:
                    lon += 360
            previous = lon
            points.append(((lon + 180) / 360 * width, (90 - lat) / 180 * height))
        return points

    for feature in data["features"]:
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        for polygon in polygons:
            for index, ring in enumerate(polygon):
                points = ring_points(ring)
                for offset in (-width, 0, width):
                    shifted = [(x + offset, y) for x, y in points]
                    draw.polygon(shifted, fill=land if index == 0 else ocean)
                    draw.line(shifted, fill=(109, 122, 114), width=scale)
    output.mkdir(parents=True, exist_ok=True)
    region_maps(image.resize((2048, 1024), Image.Resampling.NEAREST), output)
    # Редкая сетка остаётся сдержанной; заражение рисуется поверх суши.
    grid = Image.new("RGBA", image.size)
    gd = ImageDraw.Draw(grid)
    for lon in range(-180, 181, 30):
        x = (lon + 180) / 360 * width
        gd.line((x, 0, x, height), fill=(133, 155, 146, 17), width=scale)
    for lat in range(-60, 61, 30):
        y = (90 - lat) / 180 * height
        gd.line((0, y, width, y), fill=(133, 155, 146, 17), width=scale)
    image = Image.alpha_composite(image.convert("RGBA"), grid).convert("RGB")
    output.mkdir(parents=True, exist_ok=True)
    image.resize((2048, 1024), Image.Resampling.LANCZOS).save(output / "globe_land.png")
    (output / "globe_credits.txt").write_text(
        "Natural Earth 1:50m land — public domain.\n"
        "https://www.naturalearthdata.com/about/terms-of-use/\n"
        "GeoJSON: https://github.com/nvkelso/natural-earth-vector\n"
        "Source: ne_50m_land.geojson; downloaded 2026-10-17.\n"
        "Raster styling: Z.E.R.A., tools/gen_art_campaign.py (Pillow).\n",
        encoding="utf-8",
    )
    print("CAMPAIGNART globe_land.png 2048x1024; Natural Earth public domain")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path(r"C:\Users\Dev\Desktop\zera-assets\naturalearth\ne_50m_land.geojson"))
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "art")
    args = parser.parse_args()
    generate(args.source, args.output)
