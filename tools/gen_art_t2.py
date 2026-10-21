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
"turret":["............","..sssssssss.","..sLLLsssss.","..ssssss....","....ooo.....","....ooo.....","...sosos....","...s..ss....","..ss...ss...",".ss.....ss..","............","............"],
"dna":["............","...bs..sb...","....bssb....","....sbb s...","...sbbbb s..","...sLLLLbs..","....sbb s...","....bssb....","...bs..sb...","...sLLLLs...","....bssb....","............"],
"area":["....ssss....","..ss....ss..",".s........s.",".s...bb...s.","s...bbbb...s","s..bbLLbb..s","s..bbLLbb..s","s...bbbb...s",".s...bb...s.",".s........s.","..ss....ss..","....ssss...."],
"charge":["......ss....",".....ss.....",".....r......","...bbrbb....","..bLLbLLb...","..bLLbLLb...","..bLLbLLb...","..sssssss...","..bLLbLLb...","..bLLbLLb...","...bbbbb....","............"],
"throw":["......ssss..","....ss...sss","...s......ss","..s......s.s",".s..........",".s..........",".......ss...","......soos..","......oLoo..","......oooo..",".......oo...","............"],
"wave":["..s.........","...s..s.....","....s..s....",".....s..s...","..bb..s..s..",".bLLb.s..s..",".bLLb.s..s..","..bb..s..s..",".....s..s...","....s..s....","...s..s.....","..s........."],
"repel":["............","..b.....b...","..bb....bb..","..bLb...bLb.","..bLLb..bLLb","ssbLLLb.bLLL","ssbLLLb.bLLL","..bLLb..bLLb","..bLb...bLb.","..bb....bb..","..b.....b...","............"],
"grenade_cooldown":["...sss......","...s.s..bb..","..ooos..bbb.",".oLooos.bbbb",".ooooos.b...",".ooooo..b...","..ooo.......",".....sLLLs..","....s..L..s.","....s..LL.s.","....s.....s.",".....sssss.."],
"grenade_reload":["...sss......","...s.s..b...","..ooos..bb..",".oLooos.bbb.",".ooooos.b...",".ooooo..b...","..ooo...b...",".....ssssss.",".....sLLsss.",".....ssssss.","......sssss.","......sssss."],
"grenade_speed":["...sss......","...s.s......","..ooos..b.b.",".oLooos..b.b",".ooooos.b.b.",".ooooo......","..ooo.oooo..","......oLLo..","......oooo..",".....oooooo.","....oLLLLLo.","....sssssss."],
"fuse":["......b.b...",".......b....","......b.b...",".....s......","....s.......","...s........","..sssss.....","..soLLs.....","..soios.....","..soios.....","..sssss.....","............"],
"fragments":[".bb......bb.",".bL......Lb.","............",".....ss.....","....soo s...","...soLLos...","...soLLos...","....soos....",".....ss.....","............",".bL......Lb.",".bb......bb."]
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
    target = Path(__file__).resolve().parents[1] / "art" / "tree_t2_icons.png"
    atlas.save(target, optimize=True)
    print(f"TREE_ART icons={len(sprites)} size={atlas.width}x24 deterministic=true")


if __name__ == "__main__":
    generate()
