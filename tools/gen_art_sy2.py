"""Детерминированный знак передачи заряда: металл, направление, дробовой веер."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
im = Image.new("RGBA", (24, 24))
d = ImageDraw.Draw(im)
d.rectangle((2, 6, 7, 18), fill="#171d1e", outline="#a99b72")
d.rectangle((3, 4, 6, 6), fill="#c5b78d")
for y in (9, 12, 15):
    d.line((4, y, 5, y), fill="#e1cf9f", width=1)
d.polygon([(9, 10), (13, 10), (13, 7), (18, 12), (13, 17), (13, 14), (9, 14)], fill="#171d1e")
d.line([(9, 12), (15, 12), (13, 10)], fill="#d9cfb7", width=1)
d.line((15, 12, 13, 14), fill="#d9cfb7")
for y in (7, 11, 15):
    d.rectangle((19, y, 21, y + 2), fill="#171d1e")
    d.point((20, y + 1), fill="#e1cf9f")
im.save(root / "art/sy2_overflow.png")
