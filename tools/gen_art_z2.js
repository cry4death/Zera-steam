// Z2: детерминированная броня на сетке Z1. Node.js, без пакетов.
// Запуск: node tools/gen_art_z2.js. Python в песочнице не запускается.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const root = path.resolve(__dirname, '..');
const art = path.join(root, 'art');
function crc(b) { let c = 0xffffffff; for (const v of b) { c ^= v; for (let j=0;j<8;j++) c=(c>>>1)^((c&1)?0xedb88320:0); } return (c^0xffffffff)>>>0; }
function chunk(t,b) { const h=Buffer.alloc(8),e=Buffer.alloc(4); h.writeUInt32BE(b.length);h.write(t,4);e.writeUInt32BE(crc(Buffer.concat([Buffer.from(t),b])));return Buffer.concat([h,b,e]); }
function png(im,name) { const h=Buffer.alloc(13),rows=[];h.writeUInt32BE(im.w);h.writeUInt32BE(im.h,4);h[8]=8;h[9]=6;for(let y=0;y<im.h;y++)rows.push(Buffer.from([0]),im.b.subarray(y*im.w*4,(y+1)*im.w*4));fs.writeFileSync(path.join(art,name+'.png'),Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',h),chunk('IDAT',zlib.deflateSync(Buffer.concat(rows))),chunk('IEND',Buffer.alloc(0))])); }
function load(name) { const b=fs.readFileSync(path.join(art,name+'.png'));let p=8,w,h,parts=[];while(p<b.length){const n=b.readUInt32BE(p),t=b.toString('ascii',p+4,p+8),d=b.subarray(p+8,p+8+n);if(t==='IHDR'){w=d.readUInt32BE(0);h=d.readUInt32BE(4);if(d[9]!==6)throw Error('RGBA required');}if(t==='IDAT')parts.push(d);p+=n+12;}const raw=zlib.inflateSync(Buffer.concat(parts)),out=Buffer.alloc(w*h*4),stride=w*4;for(let y=0;y<h;y++)for(let x=0;x<stride;x++){const f=raw[y*(stride+1)],a=x>=4?out[y*stride+x-4]:0,bb=y?out[(y-1)*stride+x]:0,c=y&&x>=4?out[(y-1)*stride+x-4]:0;let v=raw[y*(stride+1)+1+x];if(f===1)v+=a;if(f===2)v+=bb;if(f===3)v+=Math.floor((a+bb)/2);if(f===4){const q=a+bb-c,pa=Math.abs(q-a),pb=Math.abs(q-bb),pc=Math.abs(q-c);v+=pa<=pb&&pa<=pc?a:pb<=pc?bb:c;}out[y*stride+x]=v&255;}return {w,h,b:out}; }
function image(w,h) { return {w,h,b:Buffer.alloc(w*h*4)}; }
function put(im,x,y,c) { if(x>=0&&y>=0&&x<im.w&&y<im.h)im.b.set(c.length===4?c:[...c,255],(y*im.w+x)*4); }
function copy(dst,src,ox=0,oy=0,sx=0,sy=0,w=src.w,h=src.h) { for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=((sy+y)*src.w+sx+x)*4;if(src.b[i+3])put(dst,ox+x,oy+y,[...src.b.subarray(i,i+4)]);} }
const edge=[27,31,29],steel=[85,93,88],light=[135,141,128],olive=[69,76,51],dark=[42,47,42],skin=[133,135,109];
function poly(im,pts,c,grain=true) { const xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);for(let y=Math.min(...ys);y<=Math.max(...ys);y++)for(let x=Math.min(...xs);x<=Math.max(...xs);x++){let inside=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){const a=pts[i],b=pts[j];if(((a[1]>y)!==(b[1]>y))&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;}if(inside){const n=grain?(((x*13+y*23)%11)-5)*1.1:0;put(im,x,y,c.map(v=>Math.max(0,Math.min(255,Math.round(v+n)))));}} }
function rect(im,x,y,w,h,c) { poly(im,[[x,y],[x+w,y],[x+w,y+h],[x,y+h]],c); }
function ellipse(im,cx,cy,rx,ry,c) { for(let y=Math.floor(cy-ry);y<=cy+ry;y++)for(let x=Math.floor(cx-rx);x<=cx+rx;x++)if(((x-cx)/rx)**2+((y-cy)/ry)**2<=1)put(im,x,y,c); }
function gear(im,type,mask) {
 if(mask&2){poly(im,[[10,15],[21,13],[25,18],[25,30],[21,35],[10,33],[8,28],[8,20]],edge);poly(im,[[11,16],[20,15],[23,19],[23,29],[20,33],[11,31]],type===1?steel:olive);rect(im,12,18,8,2,light);rect(im,12,25,8,4,dark);for(let y=19;y<31;y+=4)rect(im,9,y,2,2,steel);}
 if(mask&4){for(const y of [8,33]){poly(im,[[12,y],[21,y-1],[25,y+3],[22,y+8],[12,y+7],[9,y+3]],edge);poly(im,[[13,y+1],[20,y],[23,y+3],[20,y+6],[13,y+5]],steel);rect(im,14,y+1,6,1,light);}rect(im,6,17,3,13,steel);}
 if(mask&1){ellipse(im,27,24,8,7,edge);ellipse(im,26,23,7,6,type===1?steel:olive);poly(im,[[25,17],[30,18],[33,21],[33,26],[30,29],[28,28],[29,23]],light);rect(im,29,21,5,5,dark);rect(im,30,22,4,1,[109,121,116]);rect(im,31,26,3,2,edge);if(type===2){ellipse(im,32,28,3,3,dark);rect(im,31,28,3,2,steel);}}
 if(mask&8){poly(im,[[33,7],[39,9],[41,14],[41,35],[38,40],[32,39],[29,33],[29,14]],edge);poly(im,[[34,9],[38,11],[39,15],[39,34],[37,38],[33,37],[31,32],[31,15]],steel);rect(im,32,15,7,6,edge);rect(im,33,16,5,3,[120,137,134]);rect(im,32,26,7,2,light);rect(im,34,29,4,6,dark);for(const y of [12,34]){put(im,33,y,light);put(im,38,y+1,light);}}
}
function bare(im,headless=false) {
 // Снимаем старую каску Z1, под ней остаётся голова, а не вторая каска.
 for(let y=16;y<=31;y++)for(let x=22;x<=36;x++)put(im,x,y,[0,0,0,0]);
 if(!headless){ellipse(im,27,24,6,6,edge);ellipse(im,27,24,5,5,skin);ellipse(im,29,24,3,4,[113,117,93]);rect(im,30,21,2,1,edge);rect(im,30,26,3,1,[87,56,43]);put(im,31,24,[157,151,124]);}
}
const atlas=load('zombie_atlas'),out=image(3072,2304);
for(let type=0;type<3;type++){
 const v=type===1?9:2;
 for(let anim=0;anim<4;anim++)for(let wound=0;wound<16;wound++)for(let mask=0;mask<16;mask++){
  const im=image(48,48);copy(im,atlas,0,0,wound*48,(v*4+anim)*48,48,48);bare(im,!!(wound&8));gear(im,type,mask);const frame=mask+16*wound+256*(type*4+anim);copy(out,im,(frame%64)*48,Math.floor(frame/64)*48);
 }
 // Каждая часть использует тот же рисунок и координаты, что живая броня.
 for(let part=0;part<4;part++) {const im=image(48,48);gear(im,type,1<<part);png(im,`armor_${type}_${part}`);}
 for(const part of ['whole','headless','top','legs','head','arm','torso']){
  const name=['legs','head','arm','torso'].includes(part)?`zombie_${part}_${v}_t0`:`zombie_${part}_${v}`;
  const im=load(name);if(part==='whole'||part==='top')bare(im);if(part==='head'){for(let i=0;i<im.b.length;i+=4)if(im.b[i+3]&&im.b[i+1]>im.b[i]){im.b[i]=128;im.b[i+1]=130;im.b[i+2]=104;}}
  png(im,`zombie_military_${part}_${type}`);
 }
 for(let pose=0;pose<3;pose++)for(const headless of [false,true]){
  const im=load(`zombie_corpse_${headless?'headless_':''}${pose}_${v}_t0`);
  // Та же форма на останках; зелёная каска становится открытой кожей головы.
  if(!headless)for(let y=0;y<im.h;y++)for(let x=0;x<im.w;x++){const i=(y*im.w+x)*4;if(x>im.w*.56&&im.b[i+3]&&im.b[i+1]>im.b[i]&&im.b[i+2]<im.b[i+1]*.9){im.b[i]=118;im.b[i+1]=120;im.b[i+2]=96;}}
  png(im,`zombie_military_corpse_${headless?'headless_':''}${pose}_${type}`);
 }
}
png(out,'zombie_military_atlas');
console.log('Z2ART atlas=3072x2304 types=3 armor_masks=16 wound_masks=16 frames=4 pieces=12 deterministic=true');
