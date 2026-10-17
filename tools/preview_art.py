"""Сборка превью арта на сером фоне (для проверки глазами): python tools/preview_art.py out.png"""

import os
import sys

from PIL import Image

ART = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art"))
SCALE = 3
C = 48  # размер ячейки персонажа
BG = (61, 63, 67, 255)


def load(name):
    return Image.open(os.path.join(ART, name + ".png")).convert("RGBA")


def main(out):
    atlas = load("zombie_atlas")
    rows = []
    # живые: каждый вид, кадры ходьбы, несколько комбинаций ран
    for v in range(4):
        row = [atlas.crop((b * C, (v * 4 + a) * C, b * C + C, (v * 4 + a) * C + C)) for a in range(4) for b in (0,)]
        row += [atlas.crop((b * C, v * 4 * C, b * C + C, v * 4 * C + C)) for b in (1, 2, 4, 8, 15)]
        rows.append(row)
    player = load("player")
    rows.append([player.crop((a * C, d * C, a * C + C, d * C + C)) for d in range(4) for a in (0, 2)])
    rows.append([load("corpse_%d_%d" % (v, p)) for v in range(4) for p in range(3)])
    rows.append([load("corpse_headless_%d_0" % v) for v in range(4)] + [load("corpse_burnt_0"), load("zombie_top_0"),
                                                                       load("legs_2"), load("zombie_headless_3")])
    gibs = ["gib_head_0", "gib_head_2", "gib_head_3", "gib_arm_1", "gib_torso_3", "gib_guts_0", "gib_guts_1", "gib_rib",
            "gib_spine", "gib_bone", "gib_brain", "gib_skull_0", "gib_meat_0", "gib_meat_3", "gib_jaw", "gib_eye", "gib_shard_0"]
    rows.append([load(g) for g in gibs])
    cell = 50
    w = max(len(r) for r in rows) * cell
    sheet = Image.new("RGBA", (w, len(rows) * cell), BG)
    for y, row in enumerate(rows):
        for x, im in enumerate(row):
            sheet.alpha_composite(im, (x * cell + (cell - im.width) // 2, y * cell + (cell - im.height) // 2))
    sheet = sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.NEAREST)
    sheet.save(out)


if __name__ == "__main__":
    main(sys.argv[1])
