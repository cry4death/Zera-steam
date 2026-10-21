"""B2: детерминированные органические боссы; Python 3.12, Pillow, numpy."""
from pathlib import Path
import math
import random
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'art'
SIZE = (288, 264)
INK = '#211a18'


def flesh(im, box, color, seed, rough=9):
    """Объём ткани: верхний свет, неровный край, пятна под кожей."""
    rng = np.random.default_rng(seed)
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = x1-x0, y1-y0
    yy, xx = np.mgrid[:h, :w]
    x, y = (xx-w*.5)/(w*.5), (yy-h*.5)/(h*.5)
    r = x*x+y*y
    ripple = .025*np.sin(y*19+seed)+.02*np.sin(x*27-y*8)
    mask = r < 1+ripple
    z = np.sqrt(np.maximum(0, 1-r))
    light = .43 + .47*z - .20*x - .20*y
    grain = rng.integers(-rough, rough+1, (h,w))
    mottling = np.sin(xx*.19+yy*.13)*np.cos(yy*.16)*5
    rgb = np.clip(np.array(color)[None,None,:]*light[:,:,None]+grain[:,:,None]+mottling[:,:,None],0,255)
    edge = (r > .91+ripple) & mask
    rgb[edge] = (31,23,21)
    arr = np.zeros((h,w,4), dtype=np.uint8)
    arr[:,:,:3] = rgb.astype(np.uint8)
    arr[:,:,3] = mask*255
    im.alpha_composite(Image.fromarray(arr), (x0,y0))


def tendon(im, pts, width=8, color='#663a30'):
    d = ImageDraw.Draw(im)
    d.line(pts, fill=INK, width=width+4, joint='curve')
    d.line(pts, fill=color, width=width, joint='curve')
    d.line([(x-1,y-2) for x,y in pts], fill='#9d6a50', width=max(1,width//4), joint='curve')


def wound(im, center, scale=1):
    x,y=center; d=ImageDraw.Draw(im)
    angle=math.sin(x*.31+y*.17)*1.6
    def at(a,b):
        return (x+(a*math.cos(angle)-b*math.sin(angle))*scale,
                y+(a*math.sin(angle)+b*math.cos(angle))*scale)
    pts=[at(-12,-1),at(-6,-4),at(-2,-2),at(2,-5),at(13,1),at(5,4),at(-3,2),at(-7,4)]
    d.polygon(pts, fill='#281312')
    d.line(pts[:5], fill='#9b4938', width=2)
    d.line([at(-7,1),at(-2,-1),at(3,2),at(7,1)],fill='#663126',width=2)
    d.line([at(-1,-3),at(2,1),at(4,2)],fill='#a57356',width=1)
    d.line([at(-6,-4),at(-8,-8),at(-7,-11)],fill='#6b382e',width=1)


def head(im, x,y, scale, seed):
    flesh(im,(x-6*scale,y-7*scale,x+6*scale,y+8*scale),(143,125,96),seed)
    d=ImageDraw.Draw(im)
    # Вид сверху: рваный скальп и затылок, без ряда одинаковых лиц.
    d.polygon([(x-5*scale,y-2*scale),(x-3*scale,y-6*scale),(x+4*scale,y-5*scale),
               (x+5*scale,y+scale),(x+2*scale,y-2*scale)],fill='#4a3b2d')
    d.line([(x-2*scale,y-2*scale),(x+scale,y+2*scale),(x,y+5*scale)],fill='#756047',width=max(1,round(scale)))
    d.line([(x-4*scale,y+5*scale),(x,y+7*scale)],fill='#4b3027',width=max(1,round(scale)))


def limb(im, x,y,angle,scale,seed):
    end=(x+math.cos(angle)*30*scale,y+math.sin(angle)*30*scale)
    elbow=(x+math.cos(angle+.4)*16*scale,y+math.sin(angle+.4)*16*scale)
    tendon(im,[(x,y),elbow,end],max(3,int(9*scale)),'#77614d')
    d=ImageDraw.Draw(im)
    for k in range(4):
        p=(end[0]+math.cos(angle)*8*scale+math.sin(angle)*(k-1.5)*2*scale,
           end[1]+math.sin(angle)*8*scale-math.cos(angle)*(k-1.5)*2*scale)
        d.line([end,p],fill='#a18b66',width=max(1,int(2*scale)))


def mother(stage):
    im=Image.new('RGBA',SIZE); rng=random.Random(200+stage)
    # Врастающие в пол сухожилия; асимметрия тела не похожа на эмблему.
    for k in range(11):
        a=k*math.tau/11
        x,y=144+math.cos(a)*55,136+math.sin(a)*50
        points=[(x+math.cos(a+t*.7)*t*74,y+math.sin(a+t*.7)*t*65) for t in np.linspace(0,1,15)]
        tendon(im,points,5)
    flesh(im,(72,33,220,224),(133,91,78),101)
    flesh(im,(92,42,209,191),(151,107,91),102)
    d=ImageDraw.Draw(im)
    # Продольные складки живота, мелкие сосуды и прозрачная нижняя мембрана.
    for k in range(15):
        yy=66+k*9
        pts=[(100+t, yy+math.sin(t*.033+k*.45)*11+math.sin(t*.11+k)*2) for t in range(91)]
        d.line(pts,fill='#674137',width=2)
        d.line([(x,y-2) for x,y in pts[:65]],fill='#9b6d58',width=1)
    for k in range(17):
        x,y=rng.randint(100,193),rng.randint(64,193)
        flesh(im,(x-8,y-5,x+11,y+10),(143,87,73),150+k,12)
    for k in range(28):
        x,y=rng.randint(103,194),rng.randint(69,198)
        d.line([(x,y),(x-4,y-7),(x-2,y-13)],fill='#654b45',width=1)
    flesh(im,(118,161,184,235),(145,70,61),103)
    wound(im,(151,208),1.8)
    # Сросшийся человеческий торс и утонувшая голова вместо лица-маски.
    flesh(im,(103,39,170,91),(113,101,77),104)
    head(im,131,43,1.5,105)
    limb(im,108,65,3.6,.85,106)
    limb(im,167,66,-.4,.8,107)
    for k in range(stage*3-2):
        wound(im,(rng.randint(108,190),rng.randint(86,186)),rng.uniform(.6,1.3))
    return im


def meat(stage):
    im=Image.new('RGBA',SIZE); rng=random.Random(314)
    if stage==3:
        flesh(im,(100,82,190,188),(155,73,58),311)
        for k in range(7):
            tendon(im,[(121+k*7,100),(116+k*8,135),(128+k*5,174)],3,'#8b4435')
        for x,y,a in [(115,104,3.7),(175,106,-.6),(119,162,2.4),(178,156,.5)]:
            limb(im,x,y,a,.9,312)
        head(im,144,93,1.7,313)
        wound(im,(149,142),1.1)
        return im
    flesh(im,(35 if stage==1 else 57,31,252 if stage==1 else 231,242),(116,67,53),320)
    # Разные положения и размеры трупов: масса читается как тела, а не как камни.
    corpses=[]
    for k in range(23 if stage==1 else 13):
        a=k*2.399; rad=math.sqrt((k+.4)/23)*81
        x,y=144+math.cos(a)*rad,132+math.sin(a)*rad*.94
        sc=rng.uniform(.8,1.28)
        corpses.append((y,x,sc,k))
    for y,x,sc,k in sorted(corpses):
        part=Image.new('RGBA',(100,112))
        skin=(rng.randint(110,155),rng.randint(85,112),rng.randint(64,86))
        flesh(part,(35,28,66,83),skin,330+k,13)
        flesh(part,(32,29,65,51),skin,360+k,11)
        head(part,48,22,1.25,390+k)
        d=ImageDraw.Draw(part)
        # Разорванная одежда, ключицы и открытые ребра смещены у каждого тела.
        cloth=['#454c42','#514c3b','#50413a','#655b4a'][k%4]
        d.polygon([(36,47),(48,54),(57,43),(65,54),(63,75),(52,69),(41,81),(36,64)],fill=cloth)
        d.line([(36,37),(45,40),(53,36),(61,40)],fill='#ad9070',width=2)
        for rib in range(3):
            d.line([(40,44+rib*4),(48,47+rib*4),(55,44+rib*4)],fill='#b09573',width=1)
        limb(part,35,39,2.1+k*.23,.83,400+k)
        if k%2==0:
            limb(part,62,42,.9+k*.17,.76,440+k)
        tendon(part,[(43,73),(36,87),(41,101)],8,cloth)
        tendon(part,[(59,73),(64,86),(59,100)],7,'#74513f')
        wound(part,(54,62),.65)
        angle=rng.uniform(-180,180)
        part=part.rotate(angle,resample=Image.Resampling.NEAREST,expand=True)
        part=part.resize((int(part.width*sc),int(part.height*sc)),Image.Resampling.NEAREST)
        im.alpha_composite(part,(int(x-part.width/2),int(y-part.height/2)))
    for k in range(4+stage*2):
        wound(im,(rng.randint(85,201),rng.randint(77,199)),rng.uniform(.7,1.3))
    if stage==2:
        tendon(im,[(80,165),(61,179),(52,204)],7)
        tendon(im,[(206,110),(230,117),(241,139)],5)
    return im


def sac(stage=1):
    im=Image.new('RGBA',(72,90))
    d=ImageDraw.Draw(im)
    # Тяжёлая слизь у места прикрепления, без отдельной обводки-значка.
    d.polygon([(10,75),(23,70),(48,73),(62,80),(67,85),(48,87),
               (34,84),(17,88),(5,83)],fill='#49402d')
    d.line([(12,81),(26,79),(36,83),(51,81),(60,84)],fill='#928469',width=2)
    if stage==3:
        # Опавшие лоскуты: верхнего купола и содержимого больше нет.
        d.polygon([(10,69),(14,48),(22,62),(27,58),(31,77),(47,74),
                   (51,59),(60,52),(58,76),(50,83),(25,85)],fill='#322323')
        d.polygon([(14,50),(20,65),(26,62),(24,78),(16,75)],fill='#967660')
        d.polygon([(59,55),(53,73),(42,79),(49,82),(59,77)],fill='#80624e')
        d.line([(17,58),(20,73),(26,79)],fill='#b29a7c',width=2)
        d.line([(55,66),(52,76),(44,79)],fill='#c0ac8a',width=1)
        return im
    flesh(im,(9,5,64,83),(147,122,91),500)
    # Под оболочкой — затылок, согнутая спина, плечо и поджатые ноги.
    body=Image.new('RGBA',im.size)
    flesh(body,(25,23,50,65),(64,55,48),501,3)
    flesh(body,(23,18,43,38),(72,64,55),502,3)
    flesh(body,(35,49,54,69),(57,47,43),503,3)
    bd=ImageDraw.Draw(body)
    bd.line([(28,39),(23,49),(31,55)],fill='#51453b',width=6)
    bd.line([(44,57),(34,67),(28,62)],fill='#54463c',width=7)
    bd.line([(43,34),(48,43),(47,50)],fill='#877357',width=2)
    im.alpha_composite(body)
    # Полупрозрачная плёнка смягчает силуэт; свет лежит на ней, а не на теле.
    film=Image.new('RGBA',im.size)
    fd=ImageDraw.Draw(film)
    fd.ellipse((12,8,61,80),fill=(163,139,104,46))
    fd.polygon([(16,29),(19,17),(30,10),(40,10),(27,20),(23,37),(22,60),(17,53)],
               fill=(188,170,130,65))
    im.alpha_composite(film)
    d=ImageDraw.Draw(im)
    for pts in [[(30,8),(26,20),(19,32),(17,48)],[(26,20),(34,28),(37,40)],
                [(60,32),(54,41),(56,58),(49,72)],[(54,41),(45,43),(40,49)],
                [(19,60),(29,70),(33,81)],[(29,70),(37,65)],[(56,58),(48,61)]]:
        d.line(pts,fill='#765348',width=1)
    d.line([(20,23),(18,31),(18,40)],fill='#c5b799',width=2)
    d.line([(22,18),(25,15),(29,14)],fill='#d3c7a7',width=2)
    d.line([(53,68),(50,73),(44,76)],fill='#9f9171',width=1)
    tendon(im,[(31,9),(30,3),(38,0)],3)
    if stage==2:
        # Разошедшийся край и свисающий лоскут ломают силуэт купола.
        d.polygon([(56,28),(63,24),(67,39),(58,48),(61,57),(49,66),
                   (53,53),(48,43)],fill='#2d2020')
        d.line([(56,28),(51,39),(54,49),(49,66)],fill='#ad866c',width=2)
        d.polygon([(60,29),(67,24),(69,41),(62,47),(64,38)],fill='#9a7d60')
        d.line([(66,30),(67,38),(62,44)],fill='#c2ac86',width=1)
    return im


def main():
    for stage in (1,2,3):
        mother(stage).save(OUT/f'boss_mother_{stage}.png')
        meat(stage).save(OUT/f'boss_meat_{stage}.png')
    sacs=Image.new('RGBA',(216,90))
    for stage in (1,2,3):
        sacs.alpha_composite(sac(stage),((stage-1)*72,0))
    sacs.save(OUT/'boss_sac.png')
    im=Image.new('RGBA',(78,174))
    tendon(im,[(42,164),(25,123),(51,83),(31,45),(38,12)],19,'#784634')
    d=ImageDraw.Draw(im)
    d.polygon([(29,21),(37,0),(48,22),(43,39)],fill='#beaa83')
    for k in range(7):
        flesh(im,(25+(k%2)*8,42+k*15,42+(k%2)*8,56+k*15),(167,95,72),610+k)
    im.save(OUT/'boss_tentacle.png')
    im=Image.new('RGBA',(72,66)); flesh(im,(9,14,62,57),(145,78,57),620)
    limb(im,34,33,2.9,.7,621); wound(im,(42,33),.8)
    im.save(OUT/'boss_piece.png')
    # Гниль запекается в одну текстуру: один вызов рисования на лужу.
    rng=np.random.default_rng(703)
    yy,xx=np.mgrid[:192,:192]
    x,y=(xx-96)/91,(yy-96)/91
    angle=np.arctan2(y,x)
    radius=np.sqrt(x*x+y*y)
    border=.91+.045*np.sin(angle*7)+.035*np.cos(angle*11)
    mask=radius<border
    light=np.maximum(0,1-radius)*.35+.65
    grain=rng.integers(-8,9,(192,192))
    mold=np.sin(xx*.13+yy*.07)*np.cos(yy*.17-xx*.04)*9
    arr=np.zeros((192,192,4),dtype=np.uint8)
    for channel,base in enumerate((64,59,40)):
        arr[:,:,channel]=np.clip(base*light+grain+mold,0,255)
    arr[:,:,3]=mask*255
    arr[:,:,:3][(radius>border-.055)&mask]=(30,28,22)
    im=Image.fromarray(arr)
    d=ImageDraw.Draw(im)
    for k in range(55):
        a=k*2.399; r=math.sqrt((k+.5)/55)*69
        x,y=96+math.cos(a)*r,96+math.sin(a)*r
        d.ellipse((x-2,y-1,x+3,y+2),fill='#817249' if k%3 else '#3c3523')
        if k%4==0:
            d.line([(x,y),(x+5,y+3),(x+7,y+1)],fill='#211e17',width=1)
    im.save(OUT/'boss_rot.png')
    # Сравнение реального размера: 2 экранных пикселя на мировую единицу.
    sheet=Image.new('RGBA',(1100,310),(40,39,34,255))
    d=ImageDraw.Draw(sheet)
    for x,label in [(90,'OPERATIVE'),(310,'OBJECT-7'),(580,'MOTHER'),(880,'MEAT MOUNTAIN')]:
        d.text((x-40,265),label,fill='#c4b39b')
    player=Image.open(OUT/'player.png').convert('RGBA')
    player=player.crop((0,0,48,48)).resize((32,32),Image.Resampling.NEAREST)
    sheet.alpha_composite(player,(80,170))
    old=Image.open(OUT/'boss.png').convert('RGBA').crop((0,0,144,144))
    old=old.resize((96,96),Image.Resampling.NEAREST)
    sheet.alpha_composite(old,(270,120))
    for x,im in [(490,mother(1)),(790,meat(1))]:
        im=im.resize((192,176),Image.Resampling.NEAREST)
        sheet.alpha_composite(im,(x,55))
    sac_im=sac().resize((48,60),Image.Resampling.NEAREST)
    for sx,sy in [(-36,-26),(34,-25),(-35,27),(35,28)]:
        sheet.alpha_composite(sac_im,(490+96+sx*2-24,55+88+sy*2-30))
    report=OUT.parent/'design/tasks/reports'
    sheet.convert('RGB').save(report/'b2_lineup.png')
    print('B2ART textures=10 deterministic=true')


if __name__=='__main__':
    main()
