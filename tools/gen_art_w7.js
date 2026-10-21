// Детерминированные спрайты W7. Node.js 18+, без пакетов; запуск: node tools/gen_art_w7.js.
// Python в среде исполнителя недоступен. Старые PNG и их метаданные не перезаписываются.
const fs = require('node:fs');
const zlib = require('node:zlib');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const additions = [["an94","RIFLE","Автомат АН-94","АН-94",2,"rifle","doubletap",{}],["coach","SHOTGUN","Дробовик «Кучер»","Кучер",1,"shotgun","slug",{"mag":2,"rate":1.8,"reload":1.4}],["harpoon","RAIL","Рейлган «Гарпун»","Гарпун",1,"rail","last_round",{"mag":2,"damage":25}],["thumper","LAUNCHER","Гранатомёт «Факел»","Факел",1,"launcher","tracer",{"damage":18,"radius":34}],["makarov","PISTOL","Пистолет ПМ","ПМ",1,"pistol","last_round",{"mag":8,"damage":10}],["nagant","REVOLVER","Револьвер «Наган»","Наган",1,"revolver","execute",{"mag":7,"damage":24}],["mp5","SMG","ПП MP5","MP5",2,"smg","doubletap",{"mag":30,"rate":10,"spread":3}],["tikka","SNIPER","Винтовка «Тикка»","Тикка",1,"sniper","focus",{"damage":40,"pierce":2}],["pkm","LMG","Пулемёт ПКМ","ПКМ",0,"lmg","brace",{}],["rpk","LMG","Пулемёт РПК","РПК",1,"lmg","tracer",{"mag":60,"reload":2.5,"damage":5.5}],["pecheneg","LMG","Пулемёт «Печенег»","Печенег",2,"lmg","quick_spin",{"rate":9,"mag":80}],["m134","MINIGUN","Миниган М134","М134",0,"minigun","spin",{}],["gatling","MINIGUN","Миниган «Картечница»","Картечница",1,"minigun","quick_spin",{"damage":2.6,"mag":120,"reload":3.2}],["vulcan","MINIGUN","Миниган «Вулкан»","Вулкан",2,"minigun","last_round",{"mag":90,"damage":3.2}],["lpo","FLAMER","Огнемёт ЛПО","ЛПО",0,"flamer","flame",{}],["torch","FLAMER","Огнемёт «Смола»","Смола",1,"flamer","napalm",{"damage":1.8,"mag":45}],["furnace","FLAMER","Огнемёт «Горн»","Горн",2,"flamer","wide",{"range":65,"damage":2.2}],["druzhba","SAW","Бензопила «Дружба»","Дружба",0,"saw","cleave",{}],["rescuer","SAW","Пила «Спасатель»","Спасатель",1,"saw","sweep",{"range":49,"damage":6.5}],["butcher_saw","SAW","Пила «Забойщик»","Забойщик",2,"saw","execute",{"rate":4,"damage":9}],["skif","CROSSBOW","Арбалет «Скиф»","Скиф",0,"crossbow","pin",{}],["ballista","CROSSBOW","Арбалет «Баллиста»","Баллиста",2,"crossbow","explosive_bolt",{"damage":27,"pierce":1,"mag":2}],["repeater","CROSSBOW","Арбалет «Егерь»","Егерь",1,"crossbow","return_bolt",{"damage":29,"mag":5}],["saiga","AUTO_SHOTGUN","Дробовик «Сайга»","Сайга",0,"auto_shotgun","drum",{}],["aa12","AUTO_SHOTGUN","Дробовик AA-12","AA-12",1,"auto_shotgun","slug",{"spread":3,"mag":8}],["striker","AUTO_SHOTGUN","Дробовик «Страйкер»","Страйкер",2,"auto_shotgun","last_round",{"mag":8,"rate":3}],["svd","DMR","Винтовка СВД","СВД",0,"dmr","focus",{}],["sks","DMR","Карабин СКС","СКС",1,"dmr","return_bolt",{"damage":17,"mag":10,"pierce":0}],["m14","DMR","Винтовка M14","M14",2,"dmr","doubletap",{"damage":16,"rate":3,"mag":20}],["arc","TESLA","Разрядник «Дуга»","Дуга",0,"tesla","arc",{}],["fork","TESLA","Разрядник «Вилка»","Вилка",1,"tesla","fork",{"damage":8,"mag":10}],["storm","TESLA","Разрядник «Гроза»","Гроза",2,"tesla","ground",{"damage":10,"range":120}]];
const old = [["ak_s","RIFLE","Автомат АК-С"],["m4","RIFLE","Карабин М4"],["butcher","SHOTGUN","Мясник"],["shkval","SHOTGUN","Шквал"],["needle","RAIL","Игла"],["spear","RAIL","Копьё"],["grom","LAUNCHER","Гром"],["hive","LAUNCHER","Улей"],["colt","PISTOL","Кольт"],["guard","PISTOL","Страж"],["bulldog","REVOLVER","Бульдог"],["cowboy","REVOLVER","Ковбой"],["ppsh","SMG","ППШ"],["osa","SMG","Оса"],["mosin","SNIPER","Мосинка"],["winchester","SNIPER","Винчестер"]];
const C = {steel:[105,116,119], metal:[67,76,79], dark:[38,44,46], wood:[111,75,43], olive:[84,92,61], brass:[151,124,67], rubber:[38,37,35], red:[121,68,44]};
function crc(b) { let c=0xffffffff; for(const v of b){c^=v;for(let j=0;j<8;j++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0; }
function chunk(type,b){ const t=Buffer.from(type), n=Buffer.alloc(4), end=Buffer.alloc(4); n.writeUInt32BE(b.length);end.writeUInt32BE(crc(Buffer.concat([t,b])));return Buffer.concat([n,t,b,end]);}
function png(im,file){const h=Buffer.alloc(13);h.writeUInt32BE(im.w);h.writeUInt32BE(im.h,4);h[8]=8;h[9]=6;const rows=[];for(let y=0;y<im.h;y++)rows.push(Buffer.from([0]),im.b.subarray(y*im.w*4,(y+1)*im.w*4));fs.writeFileSync(file,Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',h),chunk('IDAT',zlib.deflateSync(Buffer.concat(rows))),chunk('IEND',Buffer.alloc(0))]));}
function load(file){const b=fs.readFileSync(file);let p=8,w,h,parts=[];while(p<b.length){const n=b.readUInt32BE(p),t=b.toString('ascii',p+4,p+8),d=b.subarray(p+8,p+8+n);if(t==='IHDR'){w=d.readUInt32BE(0);h=d.readUInt32BE(4);if(d[9]!==6)throw Error('RGBA required');}if(t==='IDAT')parts.push(d);p+=n+12;}const raw=zlib.inflateSync(Buffer.concat(parts)),out=Buffer.alloc(w*h*4),stride=w*4;for(let y=0;y<h;y++){const f=raw[y*(stride+1)];for(let x=0;x<stride;x++){const a=x>=4?out[y*stride+x-4]:0,bb=y?out[(y-1)*stride+x]:0,c=y&&x>=4?out[(y-1)*stride+x-4]:0;let v=raw[y*(stride+1)+1+x];if(f===1)v+=a;if(f===2)v+=bb;if(f===3)v+=Math.floor((a+bb)/2);if(f===4){const q=a+bb-c,pa=Math.abs(q-a),pb=Math.abs(q-bb),pc=Math.abs(q-c);v+=pa<=pb&&pa<=pc?a:pb<=pc?bb:c;}out[y*stride+x]=v&255;}}return {w,h,b:out};}
function image(w,h,bg){const im={w,h,b:Buffer.alloc(w*h*4)};if(bg)for(let i=0;i<w*h;i++)im.b.set([...bg,255],i*4);return im;}
function dot(im,x,y,c){x=Math.round(x);y=Math.round(y);if(x>=0&&y>=0&&x<im.w&&y<im.h)im.b.set([...c,255],(y*im.w+x)*4);}
function paste(dst,src,ox,oy,k=1){for(let y=0;y<src.h*k;y++)for(let x=0;x<src.w*k;x++){const i=(Math.floor(y/k)*src.w+Math.floor(x/k))*4;if(src.b[i+3])dot(dst,ox+x,oy+y,[...src.b.subarray(i,i+3)]);}}
function render(type,v,k=1){
 const im=image(Math.ceil(114*k),Math.ceil(50*k)); const poly=(pts,c)=>{const ys=pts.map(p=>p[1]),y0=Math.min(...ys)*k,y1=Math.max(...ys)*k;for(let y=Math.floor(y0);y<=y1;y++)for(let x=0;x<im.w;x++){let hit=false;for(let a=0,b=pts.length-1;a<pts.length;b=a++){const [ax,ay]=pts[a].map(n=>n*k),[bx,by]=pts[b].map(n=>n*k);if((ay>y)!=(by>y)&&x<(bx-ax)*(y-ay)/(by-ay)+ax)hit=!hit;}if(hit){const t=(y-y0)/Math.max(1,y1-y0);const light=t<.15?1.35:t>.8?.58:1.08-t*.4;dot(im,x,y,c.map(n=>Math.round(n*light)));}}};
 const r=(x,y,w,h,c)=>poly([[x,y],[x+w,y],[x+w,y+h],[x,y+h]],c);
 const line=(x,y,xx,yy,c,w=1)=>{const n=Math.max(Math.abs(xx-x),Math.abs(yy-y))*k;for(let j=0;j<=n;j++)r(x+(xx-x)*j/n,y+(yy-y)*j/n,w,w,c);};
 const stock=(wood=false)=>{poly([[2,17],[26,19],[32,24],[6,31],[2,30]],wood?C.wood:C.dark);r(2,17,3,15,C.rubber);};
 const grip=()=>poly([[29,24],[36,24],[34,39],[26,38]],C.rubber);
 const box=(drum=false)=>{if(drum){poly([[43,26],[57,26],[64,34],[61,43],[48,45],[40,39]],C.metal);}else poly([[44,24],[52,24],[56,40],[47,41]],C.dark);};
 let points={grip:[31,28],support:[61,24],muzzle:[104,20]};let world=66;
 if(type==='SAW'){
  r(18,22,35,18,v===2?C.olive:C.red);r(23,18,22,5,C.dark);grip();r(38,13,4,13,C.steel);r(38,12,19,4,C.steel);poly([[49,24],[94+(v*5),24],[105+(v*2),28],[99+(v*2),34],[49,34]],C.steel);r(53,28,46+v*2,3,C.dark);for(let x=55;x<103;x+=5){r(x,24,2,2,C.dark);r(x,33,2,2,C.dark);}r(24,27,20,1,C.dark);r(21,30,3,3,C.brass);points={grip:[30,30],support:[44,18],muzzle:[103,29]};world=72;
 }else if(type==='CROSSBOW'){
  stock(true);grip();r(29,20,62,7,C.wood);r(40,18,60,3,C.steel);poly([[72,3],[79,4],[90,22],[79,46],[72,46],[82,23]],v===1?C.olive:C.dark);line(74,5,48,23,C.steel);line(48,23,74,45,C.steel);r(48,21,58,1,C.brass);r(44,14,18,3,C.dark);r(47,11,12,3,C.steel);if(v===2)box();points={grip:[31,27],support:[61,25],muzzle:[105,22]};world=74;
 }else if(type==='FLAMER'){
  if(v!==1)stock();else{r(14,19,12,7,C.dark);r(16,17,3,4,C.brass);}grip();r(24,17,41,12,C.olive);r(61,20,37+v*3,5,C.dark);r(98+v*3,18,5,9,C.steel);r(v===1?35:40,30,v===1?26:18,15,v===1?C.brass:C.olive);r(47,28,5,3,C.steel);line(26,26,18,40,C.rubber,2);line(18,40,44,39,C.rubber,2);r(28,20,28,1,C.steel);points={grip:[31,28],support:[65,23],muzzle:[103+v*3,22]};world=68;
 }else if(type==='TESLA'){
  if(v!==1)stock();else{line(4,15,27,19,C.steel,2);line(4,15,4,28,C.steel,2);}grip();r(25,18,38,12,C.olive);box();r(61,20,30,5,C.dark);for(let x=62;x<(v===1?78:87);x+=v===1?7:5)r(x,v===1?10:13,3,v===1?26:19,C.brass);if(v===1){line(80,20,97,9,C.steel,2);line(80,26,97,38,C.steel,2);r(96,8,12,3,C.steel);r(96,37,12,3,C.steel);r(89,23,21,2,C.steel);}else{r(88,18,14,3,C.steel);r(88,26,14,3,C.steel);r(99,15,3,6,C.steel);r(99,27,3,6,C.steel);}r(32,14,17,4,C.steel);points={grip:[31,28],support:[61,26],muzzle:[v===1?110:102,24]};world=64;
 }else if(type==='MINIGUN'){
  r(3,20,27,12,C.dark);r(26,16,32,20,v===1?C.wood:C.olive);grip();r(38,32,19,14,C.dark);r(33,9,3,8,C.steel);r(33,8,23,3,C.steel);for(let y=16;y<34;y+=5)r(57,y,47+v*2,3,C.steel);r(63,14,5,22,C.dark);r(91+v*2,14,5,22,C.dark);if(v===1){r(67,12,23,26,C.metal);for(let x=70;x<88;x+=5)r(x,15,2,19,C.dark);line(24,24,18,35,C.brass,2);line(18,35,10,35,C.brass,2);r(8,33,6,5,C.wood);}points={grip:[31,29],support:[46,11],muzzle:[105+v*2,25]};world=83;
 }else if(type==='AUTO_SHOTGUN'){
  if(v===0){
   poly([[2,17],[24,20],[25,24],[4,31],[2,28],[17,23],[2,20]],C.metal);grip();
   r(25,18,33,10,C.metal);r(57,19,29,8,C.olive);r(85,20,23,3,C.steel);
   poly([[43,27],[51,27],[52,35],[59,43],[53,47],[45,40]],C.dark);r(75,15,3,5,C.steel);
  }else if(v===1){
   poly([[3,15],[33,15],[37,18],[83,18],[91,23],[87,30],[28,30],[27,23],[3,29]],C.metal);grip();
   r(89,21,15,4,C.steel);r(47,28,11,18,C.rubber);r(50,31,2,12,C.steel);
   r(40,12,27,4,C.dark);r(57,17,23,2,C.steel);for(let x=69;x<86;x+=4)r(x,22,2,5,C.dark);
  }else{
   line(3,13,33,18,C.steel,2);line(3,13,3,25,C.steel,2);grip();
   r(28,19,32,11,C.metal);r(57,19,37,9,C.dark);r(92,20,13,6,C.steel);
   poly([[44,28],[62,28],[67,33],[65,42],[48,44],[42,39]],C.olive);
   for(let x=46;x<65;x+=5)r(x,31,2,10,C.dark);r(72,28,5,13,C.rubber);
   r(43,12,3,7,C.steel);r(43,11,29,3,C.metal);r(70,12,3,7,C.steel);
  }
  points={grip:[31,28],support:[73,26],muzzle:[106,23]};world=70;
 }else if(type==='LMG'){
  stock(v===1);grip();r(27,17,35,12,C.metal);if(v===1)poly([[43,27],[51,27],[53,36],[62,45],[56,49],[46,41]],C.metal);else r(43,29,25,18,C.olive);r(61,19,30,8,v===1?C.wood:C.dark);r(90,20,20,3,C.steel);if(v!==1)r(72,14,19,3,C.dark);r(91,16,3,6,C.steel);line(86,25,78,43,C.metal,2);line(86,25,98,43,C.metal,2);for(let x=63;x<87;x+=4)r(x,21,2,3,C.steel);r(35,14,17,3,C.dark);points={grip:[31,28],support:[71,24],muzzle:[109,21]};world=82;
 }else if(type==='DMR'){
  stock(true);r(24,18,37,11,C.metal);r(61,20,33+v*3,7,C.wood);r(94+v*3,21,14,3,C.steel);
  if(v===1){poly([[22,25],[41,25],[40,34],[29,38],[25,34]],C.wood);r(43,28,12,5,C.metal);r(34,15,40,4,C.wood);r(37,14,21,2,C.steel);r(87,16,3,5,C.steel);line(48,24,55,29,C.steel);}
  else{grip();box();r(36,11,31,5,C.dark);r(34,10,5,7,C.steel);r(63,10,7,7,C.steel);if(v===2){r(2,13,20,5,C.wood);r(71,8,19,4,C.dark);}else{poly([[5,23],[20,22],[25,25],[10,29]],C.dark);}}
  points={grip:[31,28],support:[73,25],muzzle:[108,22]};world=76;
 }else if(type==='RIFLE'){
  stock();grip();r(22,17,42,11,C.metal);r(59,18,34,9,C.dark);r(92,20,17,3,C.steel);
  poly([[40,27],[51,27],[55,40],[47,43],[40,36]],C.dark);r(38,12,18,4,C.dark);r(45,10,4,4,C.steel);
  for(let x=65;x<89;x+=5)r(x,19,2,5,C.steel);r(5,24,13,2,C.steel);world=74;
 }else if(type==='SHOTGUN'){
  stock(true);r(23,19,22,11,C.metal);r(43,20,40,4,C.steel);r(43,25,40,4,C.dark);r(45,29,20,4,C.wood);
  poly([[25,27],[34,27],[32,35],[25,34]],C.wood);line(33,30,41,34,C.steel);line(41,34,44,28,C.steel);
  points={grip:[30,29],support:[56,30],muzzle:[83,23]};world=55;
 }else if(type==='RAIL'){
  stock();grip();r(25,18,32,12,C.metal);r(42,29,15,12,C.dark);r(55,21,45,4,C.steel);
  for(let x=58;x<92;x+=8)r(x,15,3,16,C.brass);r(93,14,6,5,C.steel);r(93,28,6,5,C.steel);
  poly([[98,14],[108,18],[99,19]],C.steel);poly([[98,28],[108,28],[99,33]],C.steel);
  r(29,14,19,3,C.dark);world=76;
 }else if(type==='LAUNCHER'){
  stock(true);grip();r(25,18,23,13,C.metal);r(46,16,42,17,C.olive);r(87,15,6,19,C.dark);
  r(50,31,24,5,C.wood);r(36,12,4,6,C.steel);r(72,11,3,7,C.steel);r(53,18,24,2,C.steel);
  points={grip:[31,28],support:[62,32],muzzle:[93,24]};world=61;
 }else if(type==='PISTOL'){
  poly([[25,15],[55,15],[61,19],[60,24],[26,24],[23,21]],C.metal);r(26,15,28,3,C.steel);
  poly([[28,23],[42,23],[37,41],[25,40]],C.rubber);line(40,26,49,30,C.steel);line(49,30,52,24,C.steel);
  r(28,20,8,1,C.dark);r(27,12,3,3,C.dark);r(55,13,2,3,C.dark);
  points={grip:[32,28],support:[42,24],muzzle:[61,21]};world=29;
 }else if(type==='REVOLVER'){
  r(34,18,22,9,C.metal);r(53,19,34,3,C.steel);r(81,17,3,3,C.dark);r(37,17,13,13,C.steel);
  for(let x=38;x<49;x+=4)r(x,20,1,7,C.dark);
  poly([[33,26],[43,27],[39,40],[31,43],[26,37]],C.wood);line(43,29,52,33,C.metal);line(52,33,57,26,C.metal);
  r(30,15,5,7,C.dark);points={grip:[35,29],support:[48,25],muzzle:[87,20]};world=38;
 }else if(type==='SMG'){
  poly([[3,18],[22,20],[28,25],[3,30],[3,27],[18,24],[3,21]],C.metal);grip();r(25,19,33,9,C.metal);
  r(58,20,24,9,C.dark);r(82,21,10,3,C.steel);r(84,16,3,7,C.dark);r(24,15,25,3,C.dark);
  poly([[43,27],[51,27],[54,40],[50,44],[45,42]],C.dark);r(81,17,8,2,C.steel);
  points={grip:[31,28],support:[65,25],muzzle:[92,22]};world=59;
 }else if(type==='SNIPER'){
  poly([[2,22],[35,23],[39,28],[29,34],[4,38],[2,35]],C.dark);r(30,21,41,8,C.metal);
  r(68,22,41,2,C.steel);r(35,14,35,5,C.dark);r(32,13,7,7,C.steel);r(67,13,6,7,C.steel);
  r(51,19,3,4,C.dark);line(52,26,58,31,C.steel);r(55,30,4,3,C.dark);r(43,28,10,7,C.dark);
  points={grip:[31,28],support:[64,25],muzzle:[109,22]};world=77;
 }else{
  const pistol=['PISTOL','REVOLVER'].includes(type), shot=['SHOTGUN','AUTO_SHOTGUN'].includes(type), rail=type==='RAIL', launch=type==='LAUNCHER';
  if(!pistol)stock(['DMR','SNIPER'].includes(type));grip();
  if(pistol){r(24,16,38+v*3,9,C.steel);r(60+v*3,18,11,5,C.dark);if(type==='REVOLVER')r(37,17,13,12,C.metal);line(36,28,48,34,C.metal);line(48,34,52,25,C.metal);points={grip:[31,29],support:[41,25],muzzle:[71+v*3,20]};world=32;}
  else{r(26,17,35,12,C.metal);r(61,19,33+v*3,7,shot?C.dark:C.wood);r(93+v*3,20,14,3,C.steel);box(shot||type==='SMG');if(['DMR','SNIPER'].includes(type)){r(36,11,31,5,C.dark);r(34,10,5,7,C.steel);r(63,10,7,7,C.steel);}if(rail){r(50,14,51,4,C.steel);r(50,27,51,4,C.steel);for(let x=58;x<96;x+=9)r(x,16,4,13,C.brass);}if(launch){r(38,14,61,19,C.olive);r(98,13,6,21,C.dark);}r(77,15,3,4,C.steel);if(v===2)r(65,9,19,4,C.dark);world=shot?70:76;}
 }
 // Фурнитура и выштамповка не теряются в боевом размере. У моделей разная навеска.
 if(!['CROSSBOW','SAW'].includes(type)){
  for(let x=30;x<56;x+=7){r(x,20,2,1,C.steel);r(x,24,4,1,C.dark);}
  r(34,25,12,1,C.dark);r(52,18,4,3,C.dark);r(54,18,1,1,C.steel);
  line(35,30,43,33,C.metal);line(43,33,47,26,C.metal);
 }
 if(type==='LMG'){
  for(let x=46;x<(v===1?54:65);x+=4)r(x,33,1,11,C.dark);
  if(v===2){r(63,10,28,3,C.dark);r(66,7,3,5,C.steel);r(86,7,3,5,C.steel);}
  if(v===0)for(let y=30;y<43;y+=4)r(37,y,6,2,C.brass);
 }
 if(type==='MINIGUN'){
  for(let x=29;x<55;x+=5)r(x,22,2,8,C.dark);
  if(v===1){r(40,36,29,10,C.metal);r(43,38,22,2,C.dark);}
  if(v===2){r(24,5,7,13,C.dark);r(24,4,28,3,C.steel);r(49,5,3,9,C.dark);r(3,32,15,10,C.olive);}
 }
 if(type==='FLAMER'){
  r(43,34,13,1,C.steel);r(44,41,12,2,C.dark);r(65,26,20,1,C.steel);
  if(v===1){r(62,13,4,13,C.brass);r(60,12,8,3,C.dark);}
  if(v===2){poly([[95,16],[110,13],[110,32],[95,29]],C.steel);points.muzzle=[109,22];}
 }
 if(type==='TESLA'){
  r(36,32,16,8,C.olive);r(39,33,2,5,C.brass);r(46,33,2,5,C.brass);
  if(v===2){r(30,7,18,6,C.steel);r(33,5,12,2,C.dark);r(29,34,3,10,C.brass);}
 }
 if(type==='SAW'){
  for(let x=23;x<43;x+=4)r(x,28,2,6,C.dark);
  if(v===1){r(15,16,3,21,C.steel);r(14,15,22,3,C.steel);r(19,39,22,6,C.dark);}
  if(v===2){r(23,13,28,5,C.dark);r(26,12,21,2,C.olive);}
 }
 if(type==='CROSSBOW'&&v===1){r(26,31,27,7,C.olive);r(29,32,19,2,C.dark);r(71,1,8,5,C.steel);r(71,43,8,5,C.steel);r(46,29,5,13,C.brass);r(42,39,13,3,C.steel);}
 if(type==='CROSSBOW'&&v===2){r(48,7,21,11,C.metal);r(50,6,17,2,C.wood);for(let x=52;x<68;x+=4)r(x,9,1,7,C.brass);}
 if(type==='SMG'){poly([[43,27],[50,27],[51,35],[56,42],[52,45],[46,39]],C.metal);r(61,20,20,2,C.steel);}
 if(type==='DMR'&&v!==1){
  for(let x=65;x<90;x+=5)r(x,21,2,2,C.dark);
  if(v===2){r(0,11,22,7,C.dark);r(71,8,19,4,C.dark);}
 }
 // Контур не раздувает тонкие детали; свет сверху слева как в основном генераторе.
 const outline=Buffer.from(im.b);for(let y=1;y<im.h-1;y++)for(let x=1;x<im.w-1;x++){const i=(y*im.w+x)*4;if(im.b[i+3])continue;if([i-4,i+4,i-im.w*4,i+im.w*4].some(j=>im.b[j+3]))outline.set([15,18,19,255],i);}im.b=outline;
 let x0=im.w,y0=im.h,x1=0,y1=0;for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++)if(im.b[(y*im.w+x)*4+3]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}const cropped=image(x1-x0+1,y1-y0+1);for(let y=0;y<cropped.h;y++)im.b.copy(cropped.b,y*cropped.w*4,((y+y0)*im.w+x0)*4,((y+y0)*im.w+x1+1)*4);
 const meta={size:[cropped.w,cropped.h]};for(const [key,p]of Object.entries(points))meta[key]=[Math.round(p[0]*k-x0),Math.round(p[1]*k-y0)];return {im:cropped,meta,world};
}
const font={A:'010101111101101',B:'110101110101110',C:'011100100100011',D:'110101101101110',E:'111100110100111',F:'111100110100100',G:'011100101101011',H:'101101111101101',I:'111010010010111',J:'001001001101010',K:'101101110101101',L:'100100100100111',M:'101111111101101',N:'101111111111101',O:'010101101101010',P:'110101110100100',Q:'010101101111011',R:'110101110101101',S:'011100010001110',T:'111010010010010',U:'101101101101111',V:'101101101101010',W:'101101111111101',X:'101101010101101',Y:'101101010010010',Z:'111001010100111','0':'111101101101111','1':'010110010010111','2':'110001010100111','3':'110001010001110','4':'101101111001001','5':'111100110001110','6':'011100111101111','7':'111001010010010','8':'111101111101111','9':'111101111001110','_':'000000000000111','-':'000000111000000'};
function text(im,s,x,y,k=2,col=[184,187,178]){for(const ch of s.toUpperCase()){const f=font[ch];if(f)for(let j=0;j<15;j++)if(f[j]==='1')for(let yy=0;yy<k;yy++)for(let xx=0;xx<k;xx++)dot(im,x+(j%3)*k+xx,y+Math.floor(j/3)*k+yy,col);x+=4*k;}}
function sheet(records,file){const types=[...new Set(records.map(r=>r[1]))],row=214,im=image(1680,types.length*row+48,[37,40,40]);text(im,'ZERA / ARSENAL  '+records.length+' MODELS',20,14,3);types.forEach((type,j)=>{const y=48+j*row;text(im,type,14,y+15,2);records.filter(r=>r[1]===type).forEach((r,i)=>{const src=load(path.join(root,'art/gun_'+r[0]+'.png'));paste(im,src,190+i*490,y+12,4);text(im,r[0],190+i*490,y+190,2);if(process.argv.includes('--weapon-fx')){paste(im,src,480+i*490,y+169);text(im,'1X',450+i*490,y+190,1);}});});png(im,file);}
const before=process.argv.includes('--before');
const weaponFx=process.argv.includes('--weapon-fx');
if(!before){
 const meta={models:{}};
 for(const m of additions){const type=m[1],v=additions.filter(a=>a[1]===type).findIndex(a=>a[0]===m[0]);const a=render(type,v),w=render(type,v,a.world/a.im.w),large=render(type,v,2);
  const aa=a,ww=w,ll=large;
  png(aa.im,path.join(root,'art/gun_'+m[0]+'.png'));png(ww.im,path.join(root,'art/gun_'+m[0]+'_world.png'));png(ll.im,path.join(root,'art/gun_'+m[0]+'_large.png'));if(!weaponFx)png(aa.im,path.join(root,'art/hud_gun_'+m[0]+'.png'));meta.models[m[0]]={icon:aa.meta,world:ww.meta,large:ll.meta};
 }
 fs.writeFileSync(path.join(root,'art/gun_meta_w7.json'),JSON.stringify(meta,null,2)+'\n');
 if(!weaponFx)for(const kind of ['fuel','chain_link','bolt','cell']){const sizes=[[4,12],[3,8],[2,6],[1,4]],im=image(8,30);let oy=0;for(const [w,h]of sizes){for(let y=0;y<h;y++)for(let x=0;x<w;x++){if(kind==='bolt'&&x!==Math.floor(w/2)&&y>2&&y<h-3)continue;if(kind==='chain_link'&&w>2&&x===1&&y%4===2)continue;dot(im,x,oy+y,kind==='fuel'?C.olive:kind==='cell'?C.metal:C.steel);if(y<2)dot(im,x+w,oy+y,[220,220,210]);}oy+=h;}png(im,path.join(root,'art/hud_round_'+kind+'.png'));}
 // Старым моделям — крупный исходник без изменения боевых PNG.
 for(const [id]of old){const a=load(path.join(root,'art/gun_'+id+'.png')),im=image(a.w*2,a.h*2);paste(im,a,0,0,2);png(im,path.join(root,'art/gun_'+id+'_large.png'));}
}
sheet(before?old:[...old,...additions.map(m=>[m[0],m[1],m[2]])],path.join(root,'design/tasks/reports/'+(weaponFx?'w7b':'w7')+'_lineup'+(before?'_before':'')+'.png'));
console.log('ART models='+ (before?old.length:old.length+additions.length)+' deterministic=true');
