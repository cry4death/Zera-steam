// B3b: повторяемая ткань улья и командир в экзоброне. Node.js без пакетов.
// Python 3.12 недоступен в среде; координаты — физические пиксели арта.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const out = path.resolve(__dirname, '../art');
function crc(b) { let c=0xffffffff; for(const v of b){c^=v;for(let j=0;j<8;j++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0; }
function chunk(t,b){const h=Buffer.alloc(8),e=Buffer.alloc(4);h.writeUInt32BE(b.length);h.write(t,4);e.writeUInt32BE(crc(Buffer.concat([Buffer.from(t),b])));return Buffer.concat([h,b,e]);}
function png(im,name){const h=Buffer.alloc(13),rows=[];h.writeUInt32BE(im.w);h.writeUInt32BE(im.h,4);h[8]=8;h[9]=6;for(let y=0;y<im.h;y++)rows.push(Buffer.from([0]),im.b.subarray(y*im.w*4,(y+1)*im.w*4));fs.writeFileSync(path.join(out,name+'.png'),Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',h),chunk('IDAT',zlib.deflateSync(Buffer.concat(rows))),chunk('IEND',Buffer.alloc(0))]));}
const image=(w,h)=>({w,h,b:Buffer.alloc(w*h*4)});
const rgb=h=>h.match(/../g).map(x=>parseInt(x,16));
function put(im,x,y,c){x=Math.round(x);y=Math.round(y);if(x>=0&&y>=0&&x<im.w&&y<im.h)im.b.set(c.length===4?c:[...c,255],(y*im.w+x)*4);}
function noise(x,y,s=0){let n=Math.imul(x+511,374761393)^Math.imul(y+139,668265263)^s;n=Math.imul(n^(n>>>13),1274126177);return((n^(n>>>16))>>>0)/4294967295;}
function poly(im,pts,hex){const c=rgb(hex),xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);for(let y=Math.floor(Math.min(...ys));y<=Math.max(...ys);y++)for(let x=Math.floor(Math.min(...xs));x<=Math.max(...xs);x++){let inside=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){const a=pts[i],b=pts[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;}if(inside)put(im,x,y,c.map(v=>Math.max(0,Math.min(255,v+Math.round((noise(x,y)-.5)*10)))));}}
function rect(im,x,y,w,h,c){poly(im,[[x,y],[x+w,y],[x+w,y+h],[x,y+h]],c);}
function line(im,pts,width,c){c=typeof c==='string'?rgb(c):c;for(let j=1;j<pts.length;j++){let [ax,ay]=pts[j-1],[bx,by]=pts[j],steps=Math.ceil(Math.hypot(bx-ax,by-ay));for(let k=0;k<=steps;k++){let x=ax+(bx-ax)*k/Math.max(1,steps),y=ay+(by-ay)*k/Math.max(1,steps);for(let yy=-width/2;yy<=width/2;yy++)for(let xx=-width/2;xx<=width/2;xx++)if(xx*xx+yy*yy<=width*width/4)put(im,x+xx,y+yy,c);}}}
function flesh(im,cx,cy,rx,ry,base,seed){for(let y=Math.max(0,Math.floor(cy-ry-3));y<Math.min(im.h,cy+ry+3);y++)for(let x=Math.max(0,Math.floor(cx-rx-3));x<Math.min(im.w,cx+rx+3);x++){let u=(x-cx)/rx,v=(y-cy)/ry,r=u*u+v*v,edge=1+.04*Math.sin(v*16+seed)+.03*Math.sin(u*23);if(r<edge){let z=Math.sqrt(Math.max(0,1-r)),l=.48+.5*z-.17*u-.22*v,n=(noise(x,y,seed)-.5)*13;put(im,x,y,r>edge-.06?rgb('241d1b'):base.map(a=>Math.max(0,Math.min(255,Math.round(a*l+n)))));}}}

// Пол с широкими пятнами и капиллярами; нет сетки прямых трещин.
let floor=image(768,512);
for(let y=0;y<floor.h;y++)for(let x=0;x<floor.w;x++){let n=noise(x,y),cloud=Math.sin(x*.018+Math.sin(y*.027)*1.9)*Math.cos(y*.019+Math.sin(x*.012));put(floor,x,y,[48,39,33].map((v,k)=>Math.round(v+cloud*(k===0?5:3)+(n-.5)*5)));}
for(let k=0;k<37;k++){
 let cx=noise(k,3,91)*768,cy=noise(k,9,76)*512,rx=17+noise(k,5)*58,ry=5+noise(k,6)*24;
 for(let y=Math.max(0,Math.floor(cy-ry));y<Math.min(512,cy+ry);y++)for(let x=Math.max(0,Math.floor(cx-rx));x<Math.min(768,cx+rx);x++){let r=((x-cx)/rx)**2+((y-cy)/ry)**2,rag=.12*Math.sin(x*.17+y*.13);if(r<.8+rag)put(floor,x,y,[52+Math.round(noise(x,y)*8),32+Math.round(noise(x,y)*5),29]);}
}
for(let k=0;k<27;k++){
 let pts=[],x0=noise(k,13)*768,y0=noise(k,14)*512,a=noise(k,15)*Math.PI*2,len=35+noise(k,16)*115;
 for(let j=0;j<20;j++){let t=j/19;pts.push([x0+Math.cos(a)*len*t+Math.sin(t*8+k)*7,y0+Math.sin(a)*len*t+Math.cos(t*9+k)*8]);}
 line(floor,pts,3,k%4?'493333':'4e4940');line(floor,pts.map(p=>[p[0]-1,p[1]-1]),1,k%4?'67443e':'62604d');
}
png(floor,'hive_floor');

// Поперечное сечение стенки, повторяемое вдоль неровного кольца.
let wall=image(512,192);
for(let y=0;y<192;y++)for(let x=0;x<512;x++){
 let edge=10+5*Math.sin(x*Math.PI*2/128)+3*Math.sin(x*Math.PI*2/32),v=(y-100)/88;
 if(y<edge||y>184+4*Math.sin(x*Math.PI*2/64))continue;
 let fold=Math.sin(x*Math.PI*2/64+Math.sin(y*.06)*.9),l=.47+.33*Math.sqrt(Math.max(0,1-v*v))+.09*fold-.13*v,n=(noise(x,y)-.5)*14;
 put(wall,x,y,(y<edge+3||y>181?rgb('261d1c'):[137,81,67].map(a=>Math.round(a*l+n))));
}
for(let k=0;k<18;k++){
 let x=k*29+8,pts=[];for(let j=0;j<12;j++)pts.push([x+Math.sin(j*.5+k)*9,25+j*11]);
 line(wall,pts,3,'41282a');line(wall,pts.map(p=>[p[0]+2,p[1]]),1,'9a6753');
}
for(let k=0;k<11;k++)flesh(wall,k*48+15,86+Math.sin(k*2.2)*34,13+k%3*4,9+k%4*3,[141,85,72],k+42);
png(wall,'hive_wall');

// Тело обращено вправо: сапоги, шинель, заражённое лицо, силовые приводы.
let body=image(192,192);
flesh(body,96,104,41,37,[80,83,65],27);
poly(body,[[49,61],[79,56],[111,65],[117,134],[70,143],[43,133],[55,103]],'262c28');
for(const y of [47,120]){
 poly(body,[[51,y],[94,y-4],[107,y+12],[96,y+28],[57,y+24],[40,y+13]],'1c211e');
 poly(body,[[48,y+6],[87,y+3],[95,y+13],[84,y+22],[46,y+19]],'4d5344');
 rect(body,43,y+7,27,6,'6d7260');rect(body,49,y+19,27,7,'222725');
}
flesh(body,131,95,22,20,[134,132,103],82);
poly(body,[[140,91],[157,93],[154,103],[140,109],[143,99]],'4c3a32');
rect(body,145,90,8,3,'252827');rect(body,147,103,7,3,'723c34');
for(const y of [60,130]){rect(body,77,y,44,9,'1b2321');rect(body,80,y+1,37,3,'828a80');rect(body,82,y+5,36,2,'3f4943');}
for(let y=68;y<128;y+=7)line(body,[[57,y],[67,y+2],[88,y+1]],2,'69705b');
png(body,'boss_general');
let plates=[];
let helmet=image(192,192);
flesh(helmet,129,94,24,23,[106,116,102],61);
poly(helmet,[[127,74],[143,76],[153,84],[155,106],[144,113],[137,108],[141,95],[137,84]],'333e3a');
rect(helmet,144,85,13,16,'191f1e');rect(helmet,146,87,10,4,'879d98');
line(helmet,[[118,78],[131,78],[140,82]],3,'c1ad76');
rect(helmet,120,75,6,2,'e0d2a0');plates.push(helmet);
let chest=image(192,192);
poly(chest,[[71,65],[106,62],[121,75],[122,116],[109,130],[73,127],[65,111],[65,81]],'1b2421');
poly(chest,[[75,68],[104,66],[115,77],[115,114],[105,123],[77,119],[70,107],[70,82]],'58614e');
line(chest,[[76,70],[103,69],[113,79]],3,'969d87');rect(chest,84,78,23,6,'b0a575');
rect(chest,78,91,31,19,'313c32');for(let y=94;y<108;y+=4)rect(chest,81,y,24,1,'6b7660');
for(const y of [74,116])for(const x of [74,107])rect(chest,x,y,3,3,'c0bda4');plates.push(chest);
let shoulders=image(192,192);
for(const y of [45,122]){
 poly(shoulders,[[83,y-3],[109,y-5],[124,y+7],[123,y+22],[105,y+29],[81,y+22],[76,y+9]],'1c2421');
 poly(shoulders,[[86,y],[107,y-1],[119,y+9],[118,y+18],[104,y+24],[86,y+18],[81,y+9]],'66705f');
 line(shoulders,[[86,y+2],[105,y+1],[116,y+9]],3,'9da28e');rect(shoulders,89,y+10,19,3,'353e35');
 rect(shoulders,94,y+13,15,2,'b2a36a');
}
plates.push(shoulders);
let shield=image(192,192);
poly(shield,[[146,39],[163,44],[174,58],[177,126],[166,150],[145,148],[135,135],[134,58]],'19201e');
poly(shield,[[149,45],[161,49],[168,61],[171,124],[162,143],[148,141],[141,132],[140,60]],'6c7970');
rect(shield,142,65,28,24,'202a28');rect(shield,145,68,23,11,'8b9d97');
rect(shield,145,97,25,5,'a5a88d');rect(shield,148,108,20,22,'414e46');
for(const y of [55,133])for(const x of [145,164])rect(shield,x,y,3,3,'b4b6a2');
for(let k=0;k<10;k++)line(shield,[[148+k*2,114+(k%3)*7],[153+k*2,112+(k%3)*7]],1,'788679');
plates.push(shield);
plates.forEach((im,k)=>png(im,'boss_general_plate_'+k));
let dead=image(192,192);
for(let y=0;y<192;y++)for(let x=0;x<192;x++){let i=(y*192+x)*4;if(body.b[i+3])put(dead,x,Math.round(115+(y-96)*.5),[Math.round(body.b[i]*.68),Math.round(body.b[i+1]*.64),Math.round(body.b[i+2]*.61),255]);}
png(dead,'boss_general_dead');
console.log('B3BART textures=8 deterministic=true');
