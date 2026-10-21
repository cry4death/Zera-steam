// Детерминированные атласы огня. Node без пакетов: Python заблокирован средой.
const fs = require('node:fs'), zlib = require('node:zlib'), path = require('node:path');
const root = path.resolve(__dirname, '..');
function crc(b) { let c=0xffffffff; for(const v of b){c^=v;for(let j=0;j<8;j++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0; }
function chunk(t,b){t=Buffer.from(t);const n=Buffer.alloc(4),c=Buffer.alloc(4);n.writeUInt32BE(b.length);c.writeUInt32BE(crc(Buffer.concat([t,b])));return Buffer.concat([n,t,b,c]);}
function png(w,h,b,file){const head=Buffer.alloc(13);head.writeUInt32BE(w);head.writeUInt32BE(h,4);head[8]=8;head[9]=6;const rows=[];for(let y=0;y<h;y++)rows.push(Buffer.from([0]),b.subarray(y*w*4,(y+1)*w*4));fs.writeFileSync(path.join(root,'art',file),Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',head),chunk('IDAT',zlib.deflateSync(Buffer.concat(rows))),chunk('IEND',Buffer.alloc(0))]));}
function hash(x,y){return ((Math.imul(x+71,374761393)^Math.imul(y+13,668265263))>>>0)/4294967296;}
const palette=[[95,39,23],[183,57,17],[235,94,19],[255,151,36],[255,208,92],[255,237,170]];
// Струя: цельный сужающийся у сопла объём с расщеплённым рваным концом.
let w=160,h=64,b=Buffer.alloc(w*h*8*4);
for(let f=0;f<8;f++)for(let y=0;y<h;y++)for(let x=0;x<w;x++){
 const t=x/(w-1),phase=f*Math.PI/4;
 const wave=Math.sin(t*19-phase*2)*t*3+Math.sin(t*43-phase)*t*1.8;
 const dy=y-31.5-wave,half=1.8+Math.pow(t,.8)*21;
 const rag=Math.sin(t*33+phase+dy*.35)*2+Math.sin(t*71-phase*2)*1.2;
 const d=Math.abs(dy)/(half+rag);
 const tongueEnd=.84+.13*Math.sin(dy*.33+phase)+.04*Math.sin(dy*.91-phase);
 if(d>1||t>tongueEnd&&t>.78)continue;
 const noise=hash(x+f*37,y+f*23);
 const core=(1-d)*(.92-t*.28)+.11*Math.sin(t*49-phase*3+dy*.3)+noise*.13;
 const color=palette[Math.max(0,Math.min(5,Math.floor(core*6)))];
 const i=((f*h+y)*w+x)*4;b.set([...color,Math.round(245*Math.min(1,(1-d)*5))],i);
}
png(w,h*8,b,'fx_flame_jet.png');
// Языки на теле: три неравных факела и редкий дым, без круглых частиц.
w=48;h=64;b=Buffer.alloc(w*h*8*4);
for(let f=0;f<8;f++)for(let y=0;y<h;y++)for(let x=0;x<w;x++){
 const phase=f*Math.PI/4,up=(54-y)/48;let heat=-1;
 for(let k=0;k<3;k++){
  const height=[34,46,28][k]+Math.sin(phase+k*2)*5;
  const u=(54-y)/height,center=12+k*11+Math.sin(u*9-phase*2+k)*u*4;
  const width=(1-u)*[8,9,7][k]+Math.sin(u*18+phase+k)*1.7;
  if(u>=0&&u<1&&Math.abs(x-center)<width)heat=Math.max(heat,(1-Math.abs(x-center)/Math.max(1,width))*.75+(1-u)*.25);
 }
 const i=((f*h+y)*w+x)*4;
 if(heat>=0)b.set([...palette[Math.min(5,Math.floor(heat*6))],Math.round(235*Math.min(1,heat*5+.25))],i);
 else if(up>.45&&up<1.13){const center=25+Math.sin(up*10-phase)*6,width=5+(up-.45)*7;const d=Math.abs(x-center)/width;if(d<1&&hash(x+f*5,y)>.25)b.set([51,48,43,Math.round((1-d)*65)],i);}
}
png(w,h*8,b,'fx_body_fire.png');
console.log('W7B_ART flame_frames=8 body_frames=8 deterministic=true');
