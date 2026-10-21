"""Пиксельные предметные иконки казармы. Python 3.12+, Pillow; без RNG."""
from pathlib import Path
import json
from PIL import Image

# Общие пиксельные данные позволяют воспроизвести атлас без конкретного растеризатора.
PIXELS = r'''{
"bullet":["............",".....b......","....bbb.....","....bLb.....","....bLb.....","....sss.....","....sLs.....","....sLs.....","....sLs.....","....sss.....","....bbb.....","............"],
"sight":[".....LL.....",".....LL.....","...ssssss...","..ss....ss..","..s......s..","LLs..bb..sLL","LLs..bb..sLL","..s......s..","..ss....ss..","...ssssss...",".....LL.....",".....LL....."],
"burst":[".....b......","....bbb.....","....bLb.....","..b.sss.b...",".bbbsLsbbb..",".bLbsLsbLb..",".sssbLbsss..",".sLssss sLs.",".sLs...sLs..",".bbb...bbb..","............","............"],
"brace":["............","..ooooooo...","..oLLLLLo...","..ooosooo...","..ooosooo...","bbbbbbbbbbb.","bLLLbbLLLbb.","..ooosooo...","...oosoo....","....oso.....",".....o......","............"],
"reload":["..b.........","..bbbsss....","..bbb..ss...","..bb....ss..","..s..L...s..","..s..L...s..","..s..LLL.s..","..s......s..","...ss...ss..","....sssss...","............","............"],
"mag":["...bbbbbb...","..ssssssss..","...sLLsss...","...ssisss...","...ssisss...","...sssiss...","...sssiss...","....ssiss...","....sssiss..","....sssiss..","....ssssss..","............"],
"boot":["............","....ooooo...","....oLLLo...","....ooLoo...","....oLLLo...","....ooLoo...","....ooooo...","...oooooo...","..ooooooooo.","..oLLLLLLLo.","..sssssssss.","............"],
"shield":["............","..ooooooo...","..oLLLLLo...","..ooosooo...","..ooosooo...","..ooosooo...","..ooosooo...","..ooosooo...","...oosoo....","....oso.....",".....o......","............"],
"vest":["...o...o....","..ooo.ooo...",".ooooooooo..",".ooooooooo..","..ossssso...","..osLLsso...","..ossssso...","..osLLsso...","..ossssso...","..ooooooo...","..ooooooo...","............"],
"med":["............","....ssss....","....s..s....",".LLLLLLLLLL.",".LLLLrrLLLL.",".LLLLrrLLLL.",".LLrrrrrrLL.",".LLrrrrrrLL.",".LLLLrrLLLL.",".LLLLrrLLLL.",".LLLLLLLLLL.","............"],
"clock":["....bbbb....",".....ss.....","...ssssss...","..ss....ss..","..s..L...s..","..s..L...s..","..s..LLL.s..","..s......s..","..ss....ss..","...ssssss...","............","............"],
"grenade":[".....sss....","....s..s....","....sLss....","...oooLLs...","..oooooLs...","..ooiooos...","..ooooooLs..","..ooioooo...","..ooooooo...","...ooooo....","....ooo.....","............"],
"blast":["............",".....b......",".....b......","..b..bb..b..","..bbbbb.bb..","...bbbbbb...","...bbbLbb...","..bbbLLLbb..","..bbbLLLbbb.",".bbbbbbbbbb.",".ssssssssss.","............"],
"dna":["............","...bs..sb...","....bssb....","....sbb s...","...sbbbb s..","...sLLLLbs..","....sbb s...","....bssb....","...bs..sb...","...sLLLLs...","....bssb....","............"]
}'''
PALETTE = {"i": "#242525", "s": "#8d9996", "L": "#c4c6b4", "b": "#b19a64", "o": "#778064", "r": "#905e50"}


def generate():
    sprites = json.loads(PIXELS)
    atlas = Image.new("RGBA", (24 * len(sprites), 24))
    for index, rows in enumerate(sprites.values()):
        for y, row in enumerate(rows):
            for x, key in enumerate(row[:12]):
                if key in PALETTE:
                    for dy in range(2):
                        for dx in range(2):
                            atlas.putpixel((index * 24 + x * 2 + dx, y * 2 + dy), tuple(bytes.fromhex(PALETTE[key][1:])) + (255,))
    target = Path(__file__).resolve().parents[1] / "art" / "tree_icons.png"
    atlas.save(target, optimize=True)
    print("TREE_ART icons=14 size=336x24 deterministic=true")


if __name__ == "__main__":
    generate()
