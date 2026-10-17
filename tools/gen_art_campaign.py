"""Тактическая карта Земли: Natural Earth, без фотографий и сетевых зависимостей."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


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
    # Сетка остаётся сдержанной; заражение рисуется движком поверх географии.
    grid = Image.new("RGBA", image.size)
    gd = ImageDraw.Draw(grid)
    for lon in range(-180, 181, 15):
        x = (lon + 180) / 360 * width
        gd.line((x, 0, x, height), fill=(133, 155, 146, 35), width=scale)
    for lat in range(-75, 76, 15):
        y = (90 - lat) / 180 * height
        gd.line((0, y, width, y), fill=(133, 155, 146, 35), width=scale)
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
