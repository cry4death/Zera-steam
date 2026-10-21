"""C6b: плоть и полевое оборудование. Локальные numpy/Pillow, плотность арта 3."""
from pathlib import Path
import hashlib
import random
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'art'
REPORT = OUT.parent / 'design/tasks/reports'
D = 3


def canvas(size):
    return Image.new('RGBA', (size[0]*D, size[1]*D))


def line(im, pts, col, w=1):
    ImageDraw.Draw(im).line([(round(x*D), round(y*D)) for x,y in pts], fill=col, width=max(1,round(w*D)), joint='curve')


def poly(im, pts, col):
    ImageDraw.Draw(im).polygon([(round(x*D), round(y*D)) for x,y in pts], fill=col)


def oval(im, box, col):
    ImageDraw.Draw(im).ellipse(tuple(round(v*D) for v in box),fill=col)


def curve(pts):
    a,b,c,d = [np.array(p,dtype=float) for p in pts]
    return [tuple((1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d) for t in np.linspace(0,1,45)]


def ground(ruined=False):
    im=canvas((80,72)); rng=random.Random(706)
    for _ in range(65):
        x,y=rng.uniform(12,68),rng.uniform(44,65); r=rng.uniform(2,9)
        oval(im,(x-r,y-r*.4,x+r,y+r*.5),(31,20,18,rng.randrange(70,150)))
    roots=[[(35,48),(18,47),(20,60),(2,60)],[(31,48),(14,41),(17,33),(4,37)],
           [(37,50),(26,62),(21,57),(14,69)],[(49,48),(57,61),(67,50),(78,57)],
           [(52,43),(69,43),(64,32),(76,28)],[(42,54),(48,62),(54,63),(65,68)],
           [(29,45),(15,48),(11,55),(1,49)]]
    for n,pts in enumerate(roots):
        pts=curve(pts)
        for i in range(len(pts)-1):
            t=i/(len(pts)-1); w=4.4*(1-t)**1.3+.22
            line(im,[(x+.4,y+1) for x,y in pts[i:i+2]],(20,17,15,180),w+1.1)
            line(im,pts[i:i+2],'#36221d' if ruined else '#4b2821',w)
            line(im,[(x-.3,y-.4) for x,y in pts[i:i+2]],'#583428' if ruined else '#704634',max(.2,w*.22))
        for k in (19,31):
            x,y=pts[k]
            line(im,curve([(x,y),(x-2,y+2),(x+5,y+5),(x+(6 if n%2 else -5),y+7)]),'#3a211c',.65)
    return im


def node(stage='closed'):
    ruined=stage=='ruined'; im=ground(ruined) if stage in ('closed','ruined') else canvas((80,72))
    y,x=np.mgrid[0:216,0:240]/D; rng=np.random.default_rng(706)
    warp=np.sin(y*.24+x*.08)*1.2+np.sin(x*.41-y*.14)*.55
    h=np.zeros_like(x)
    # Общая масса с неодинаковыми складками, освещение по рельефу.
    for cx,cy,rx,ry,z in [(31,38,11,19,1),(44,27,12,17,1.26),(55,44,11,14,.91),(24,51,10,8,.66),(40,53,12,10,.8),(58,55,9,6,.45)]:
        if ruined: cy=54+(cy-42)*.29; ry*=.39; z*=.36
        f=np.exp(-(((x-cx+warp)/rx)**2+((y-cy+np.sin(x*.2))/ry)**2)*1.8)*z
        h=np.maximum(h,f)+np.minimum(h,f)*.14
    gy,gx=np.gradient(h,1/D); light=np.clip(.56-gx*3.8-gy*2.9+h*.13,.16,1.1)
    folds=np.clip(np.sin(y*.98+x*.37+np.sin(x*.23)*3+h*7),0,1)**9
    rgb=np.stack([48+light*65,24+light*35,23+light*27],axis=-1)
    rgb+=(folds*h)[...,None]*np.array([26,13,9])+rng.normal(0,1.35,x.shape)[...,None]
    rot=np.clip(np.sin(x*.21+y*.17)*np.sin(y*.32-x*.11)-.43,0,1)*h
    rgb+=rot[...,None]*np.array([9,24,1])
    if ruined: rgb*=np.array([.76,.74,.72])
    rgba=np.zeros((*x.shape,4),dtype=np.uint8); rgba[...,:3]=np.clip(rgb,0,255).astype(np.uint8)
    rgba[...,3]=np.where(h>.105,255,0).astype(np.uint8); im.alpha_composite(Image.fromarray(rgba))
    # Поглощённая решётка, поверх металла лежат сухожилия.
    poly(im,[(54,45),(64,42),(67,53),(59,56)],'#292b25'); line(im,[(55,45),(63,43),(66,52)],'#74715a',.7)
    for k in range(4): line(im,[(57+k*1.7,45),(59+k*1.7,52)],'#494e42',.6)
    for k in range(3):
        pts=curve([(51,44+k*2),(57,41+k*2),(57,52),(63,55+k)])
        line(im,pts,'#60382c',1.8); line(im,[(x,y-.5) for x,y in pts],'#94634a',.35)
    if not ruined:
        for pts in [[(37,17),(31,26),(36,37),(27,49)],[(48,20),(56,29),(44,33),(48,48)],[(24,36),(20,44),(34,48),(31,56)]]:
            pts=curve(pts); line(im,pts,'#492728',.8); line(im,[(x+.5,y) for x,y in pts],'#7e4d40',.25)
    # Кровяные костные обломки, без черепа и белых костей.
    for a,b in [((17,56),(24,49)),((43,59),(48,54)),((53,57),(57,60))]:
        line(im,[a,b],'#5b2821',2.4); line(im,[(a[0]+1,a[1]),b],'#9b8560',.9)
    wounds=0 if stage=='closed' else (1 if stage=='open' else 2 if stage=='damaged' else 3)
    tears=[[(41,19),(48,24),(44,31),(47,40),(40,47),(37,38),(40,30),(37,24)],
           [(24,36),(30,39),(28,45),(32,51),(27,55),(22,50),(24,43)],
           [(49,43),(55,46),(54,54),(48,59),(44,54),(48,50)]]
    if ruined: tears=[[(25,52),(38,49),(48,54),(58,53),(62,58),(49,61),(36,57),(27,59)]]; wounds=1
    for n,pts in enumerate(tears[:wounds]):
        poly(im,pts,'#55221f'); line(im,pts+[pts[0]],'#8b4537',1.5)
        cx=sum(p[0] for p in pts)/len(pts); inner=[(cx+(px-cx)*.65,py) for px,py in pts]
        poly(im,inner,'#230f12'); line(im,[(px-.6,py) for px,py in pts[1:4]],'#a45943',.5)
        line(im,inner[2:5],'#69291f',1.1)
        if n or stage in ('damaged','critical','ruined'):
            b=max(pts,key=lambda p:p[1]); line(im,curve([b,(b[0]+2,b[1]+2),(b[0]-3,62),(b[0]+5,65)]),'#66271e',1.3)
            oval(im,(b[0]-4,62,b[0]+9,65),(65,22,18,210))
    if not ruined:
        for pts in [[(29,29),(28,34),(26,37)],[(49,27),(51,30),(51,33)],[(33,53),(36,54),(39,54)]]: line(im,pts,'#af8060',.4)
    return im


def container():
    im=canvas((40,36)); oval(im,(3,25,38,33),(19,20,17,170))
    poly(im,[(5,11),(13,7),(35,10),(36,26),(28,31),(5,27)],'#272e2b')
    poly(im,[(6,11),(13,8),(34,10),(27,15)],'#b0b1a0'); poly(im,[(6,13),(27,16),(27,29),(6,26)],'#7a847a')
    poly(im,[(28,16),(35,12),(35,25),(28,29)],'#4b574f'); line(im,[(7,14),(26,17)],'#c4c3ab',.6)
    for x in (9,23):
        line(im,[(x,14),(x,27)],'#353e37',1.8); poly(im,[(x-1,20),(x+1,20),(x+1,23),(x-1,23)],'#b6b39c')
    line(im,[(15,8),(15,4),(24,5),(24,9)],'#252c29',2.2); line(im,[(15,5),(24,6)],'#a1a798',.6)
    poly(im,[(14,18),(21,19),(21,26),(14,25)],'#d0cdb0'); line(im,[(17,19),(17,24)],'#7a342b',1)
    for x in (30,32): line(im,[(x,18),(x,23)],'#222e2c',1.3); line(im,[(x,20),(x,22)],'#819789',.4)
    return im


def beacon(lit=False):
    im=canvas((40,48)); oval(im,(2,37,38,46),(18,20,16,155))
    for foot in [(6,43),(31,42),(22,46)]:
        line(im,[(19,26),foot],'#252e29',2.9); line(im,[(18.5,26),(foot[0]-.5,foot[1])],'#8b9280',.8)
        line(im,[(foot[0]-2,foot[1]),(foot[0]+2,foot[1])],'#4d574b',1.3)
    poly(im,[(12,35),(20,34),(24,38),(24,42),(13,42)],'#424c3e')
    line(im,curve([(16,25),(7,30),(28,32),(18,36)]),'#232a24',.7)
    poly(im,[(12,15),(23,14),(26,17),(26,28),(13,29)],'#303d35')
    poly(im,[(13,16),(23,15),(23,27),(13,28)],'#69725c'); line(im,[(14,16),(22,15)],'#a6aa8c',.7)
    for y in range(20,26,2): line(im,[(15,y),(20,y-.5)],'#303c32',.5)
    line(im,[(23,15),(24,3)],'#3b4539',.8); line(im,[(24,3),(25,1)],'#9a9f8b',.4)
    poly(im,[(14,12),(16,9),(21,9),(23,12),(22,15),(14,15)],'#282f28')
    poly(im,[(15,11),(21,11),(22,14),(15,14)],'#d3ab5b' if lit else '#887748')
    if lit: line(im,[(16,11),(20,11)],'#e0c383',.55)
    return im


def zone():
    im=canvas((120,120)); rng=random.Random(708)
    # Изношенные направляющие, поперечины и посадочный трафарет.
    for x in (12,108):
        for y in range(17,107,17): poly(im,[(x-1,y),(x+1,y-.5),(x+1,y+9),(x-1,y+10)],(154,149,114,155))
    for y in (14,106):
        for x in range(28,97,15): poly(im,[(x,y),(x+8,y),(x+8,y+1.4),(x,y+1.4)],(154,149,114,155))
    for a,b in [((52,51),(52,68)),((66,51),(66,68)),((52,59),(66,59))]: line(im,[a,b],(150,146,112,105),1.6)
    px=im.load()
    for _ in range(4500):
        x,y=rng.randrange(im.width),rng.randrange(im.height)
        if px[x,y][3]: px[x,y]=(0,0,0,0)
    for x,y in [(9,14),(108,24),(11,104),(109,102)]:
        oval(im,(x-3,y+1,x+5,y+5),(24,25,20,155)); poly(im,[(x-2,y+2),(x+3,y+2),(x+2,y-6),(x,y-7)],'#8e6239')
        poly(im,[(x,y-6),(x+1,y-6),(x+1,y+1),(x-1,y+1)],'#bc8651')
        line(im,[(x-1,y-2),(x+2,y-2)],'#b8b298',1); line(im,[(x-3,y+3),(x+4,y+3)],'#383a2c',1)
    return im


def generate():
    sprites={'campaign_node':node('open'),'campaign_node_closed':node(),'campaign_node_damaged':node('damaged'),
             'campaign_node_critical':node('critical'),'campaign_node_ruined':node('ruined'),'campaign_node_roots':ground(),
             'campaign_beacon':beacon(),'campaign_beacon_lit':beacon(True),'campaign_beacon_zone':zone(),'campaign_sample':container()}
    for name,im in sprites.items(): im.save(OUT/(name+'.png'),optimize=True)
    return sprites


def sheet(sprites):
    tile=Image.new('RGB',(5*1500,2*1500),(44,44,37)); d=ImageDraw.Draw(tile)
    for i,(name,im) in enumerate(sprites.items()):
        x=(i%5)*1500; y=(i//5)*1500
        if name in ('campaign_node','campaign_node_damaged','campaign_node_critical'):
            im=Image.alpha_composite(ground(),im)
        view=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
        tile.paste(view,(x+(1500-view.width)//2,y+10),view); d.text((x+8,y+1476),name.replace('campaign_',''),fill=(195,191,165))
    tile.save(REPORT/'c6b_sheet.png',optimize=True)


if __name__=='__main__':
    sprites=generate(); hashes={n:hashlib.sha256((OUT/(n+'.png')).read_bytes()).hexdigest() for n in sprites}
    generate(); assert hashes=={n:hashlib.sha256((OUT/(n+'.png')).read_bytes()).hexdigest() for n in sprites}
    sheet(sprites); print(f'C6BART sprites={len(sprites)} density=3 seed=706 deterministic=true')
