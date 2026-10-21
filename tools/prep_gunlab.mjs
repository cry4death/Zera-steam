// Детерминированный отбор CC0: только короткие фрагменты, архив не распаковывается.
import fs from 'node:fs';
import path from 'node:path';
import {inflateRawSync} from 'node:zlib';
import {execFileSync} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'..'), src='C:/Users/Dev/Desktop/zera-assets/firearm_cc0';
if(process.argv.includes('--reference')){
 const out=path.join(root,'design/tasks/reports/w6_ab/reference');fs.mkdirSync(out,{recursive:true});
 for(let gun of ['pistol','revolver','smg','rifle','shotgun','sniper','rail','launcher'])fs.writeFileSync(path.join(out,gun+'.wav'),execFileSync('git',['show',`main:sfx/weapons/${gun}/shot_0.wav`],{cwd:root,maxBuffer:5000000}));
 fs.writeFileSync(path.join(out,'bus.tres'),execFileSync('git',['show','main:default_bus_layout.tres'],{cwd:root}));
 fs.writeFileSync(path.join(out,'revision.txt'),execFileSync('git',['rev-parse','main'],{cwd:root}));
 console.log('GUNLAB reference extracted main (8 WAV + bus)');process.exit(0);
}
function read(b){let fmt,raw;for(let p=12;p+8<b.length;){let n=b.readUInt32LE(p+4),id=b.toString('ascii',p,p+4);if(id==='fmt ')fmt=b.subarray(p+8,p+8+n);if(id==='data')raw=b.subarray(p+8,p+8+n);p+=8+n+(n&1);}let ch=fmt.readUInt16LE(2),rate=fmt.readUInt32LE(4),bits=fmt.readUInt16LE(14),float=fmt.readUInt16LE(0)===3,step=bits/8;let x=new Float64Array(raw.length/step/ch);for(let i=0;i<x.length;i++){for(let c=0;c<ch;c++){let p=(i*ch+c)*step;x[i]+=(float?raw.readFloatLE(p):bits===24?raw.readIntLE(p,3)/8388608:raw.readInt16LE(p)/32768)/ch;}}return {x,rate};}
function wav(x){let b=Buffer.alloc(44+x.length*2);b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(44100,24);b.writeUInt32LE(88200,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(x.length*2,40);for(let i=0;i<x.length;i++)b.writeInt16LE(Math.round(Math.max(-.999,Math.min(.999,x[i]))*32767),44+i*2);return b;}
const kernels=new Map();
function resample(x,start,len,rate){
 let phases=kernels.get(rate);if(!phases){phases=[];const fc=Math.min(.47,20500/rate);for(let phase=0;phase<256;phase++){let h=[],sum=0;for(let k=-32;k<=32;k++){let t=k-phase/256,w=.42+.5*Math.cos(Math.PI*t/33)+.08*Math.cos(2*Math.PI*t/33),v=(t===0?2*fc:Math.sin(2*Math.PI*fc*t)/(Math.PI*t))*w;h.push(v);sum+=v;}phases.push(h.map(v=>v/sum));}kernels.set(rate,phases);}
 let y=new Float64Array(Math.floor(len*44100/rate));for(let i=0;i<y.length;i++){let p=start+i*rate/44100,j=Math.floor(p),h=phases[Math.min(255,Math.round((p-j)*256))],v=0;for(let k=-32;k<=32;k++)if(j+k>=0&&j+k<x.length)v+=x[j+k]*h[k+32];y[i]=v;}return y;
}
// ZIP central directory читается с конца, в память попадают только выбранные WAV.
const fd=fs.openSync(path.join(src,'raw_master_tracks.zip'),'r'),size=fs.fstatSync(fd).size;
function bytes(pos,n){let b=Buffer.alloc(n);fs.readSync(fd,b,0,n,pos);return b;}
let end=bytes(size-65557,65557),e=end.lastIndexOf(Buffer.from([0x50,0x4b,5,6]));let cd=bytes(end.readUInt32LE(e+16),end.readUInt32LE(e+12)),entries={};
for(let p=0;p+46<cd.length;){let n=cd.readUInt16LE(p+28),extra=cd.readUInt16LE(p+30),comment=cd.readUInt16LE(p+32),name=cd.toString('utf8',p+46,p+46+n);entries[name]={pos:cd.readUInt32LE(p+42),n:cd.readUInt32LE(p+20),method:cd.readUInt16LE(p+10)};p+=46+n+extra+comment;}
function zip(name){let q=entries[name];if(!q)throw Error(name);let h=bytes(q.pos,30),b=bytes(q.pos+30+h.readUInt16LE(26)+h.readUInt16LE(28),q.n);return q.method===8?inflateRawSync(b):b;}
const specs={
 pistol:[['1911','A_42P','1911_close'],['1911','A_34P','1911_mid'],['Walther PPQ','X_31P','walther_close']],
 revolver:[['Smith & Wesson 642','V_27P','sw642_close'],['Smith & Wesson 642','V_22P','sw642_mid'],['Ruger Single Six','S_11P','ruger_mid']],
 smg:[['PPSh','P_30P','ppsh_close'],['PPSh','P_16P','ppsh_mid'],['Carl Gustav M45','G_20P','m45_mid']],
 rifle:[['AK-47','C_28P','ak47_close'],['AK-47','C_31P','ak47_mid'],['AR-15','D_32P','ar15_close']],
 shotgun:[['Mossberg','N_30P','mossberg_close'],['Nova','O_21P','nova_close'],['Model 12','K_17P','model12_mid']],
 sniper:[['Mosin Nagant','M_21P','mosin_close'],['Mosin Nagant','M_26P','mosin_mid'],['1917','B_24P','springfield_close']],
 rail:[['Mosin Nagant','M_21P','mosin_close'],['SKS','U_14P','sks_close'],['1917','B_16P','springfield_mid']],
 launcher:[['Mossberg','N_30P','mossberg_close'],['Model 12','K_22P','model12_close'],['Nova','O_17P','nova_mid']]
};
let library={version:1,catalog:{},guns:{}},lines=['# Gun Lab — CC0 sources','', 'Firearm Sound Library (CC0), локальная библиотека firearm_cc0. Дистанции — по Prepared Master Sheet.csv; raw — независимая позиция/микрофон, без выдуманной дистанции.','Моно PCM16, 44100 Гц, удалены DC и тишина, пик −1 dBFS, плавное окончание; без синтетического низа и запечённых слоёв.',''];
function emit(gun,name,b,take,origin,mechanic=false){let {x,rate}=read(b),peak=0;for(let v of x)peak=Math.max(peak,Math.abs(v));let hits=[];for(let i=0;i<x.length;i++)if(Math.abs(x[i])>peak*.3&&(hits.length===0||i-hits.at(-1)>rate*.65))hits.push(i);if(!hits.length)throw Error(origin);let start=Math.max(0,hits[Math.min(take,hits.length-1)]-Math.round(rate*.004));let len=Math.min(x.length-start,Math.round(rate*1.5)),y=resample(x,start,len,rate);let mean=y.reduce((a,b)=>a+b,0)/y.length;peak=0;for(let i=0;i<y.length;i++){y[i]-=mean;peak=Math.max(peak,Math.abs(y[i]));}for(let i=0;i<y.length;i++)y[i]=y[i]/Math.max(peak,.0001)*.89125*Math.min(1,(y.length-i)/882,i/22);let rel=`${gun}/${name}.wav`;fs.mkdirSync(path.join(root,'sfx/gunlab',gun),{recursive:true});fs.writeFileSync(path.join(root,'sfx/gunlab',rel),wav(y));library.catalog[gun].push(rel);lines.push(`- \`${rel}\` ← ${origin}, дубль ${take+1}.`);return rel;}
for(let [gun,sp]of Object.entries(specs)){library.catalog[gun]=[];for(let i=0;i<sp.length;i++){let [folder,file,name]=sp[i],b=fs.readFileSync(path.join(src,'extracted/Prepared SFX Library',folder,file+'.wav'));emit(gun,name+'_1',b,0,`${folder}/${file}.wav (Prepared)`);if(i===0)emit(gun,name+'_2',b,1,`${folder}/${file}.wav (Prepared)`);}
 let [folder,file]=sp[0],rawId={pistol:'A_39',revolver:'V_27',smg:'P_25',rifle:'C_39',shotgun:'N_29',sniper:'M_22',rail:'M_23',launcher:'N_24'}[gun],rawName=`Master Tracks/${folder}/${rawId}.wav`;
 emit(gun,'raw_mic_1',zip(rawName),0,`raw_master_tracks.zip:${rawName} (см. master_sheet.xlsx: отдельная позиция микрофона)`);
 // Механика — отдельная запись A2 с прежним CC0-происхождением из manifest.
 let mechGun=['rail','launcher'].includes(gun)?'shotgun':gun;
 let mech=fs.readdirSync(path.join(root,'sfx/weapons',mechGun)).find(x=>x.startsWith('rack_')&&x.endsWith('.wav'))||'dry_0.wav';
 emit(gun,'mechanism_1',fs.readFileSync(path.join(root,'sfx/weapons',mechGun,mech)),0,`sfx/weapons/${mechGun}/${mech} (A2, см. sfx/manifest.json)`);
 let cat=library.catalog[gun],heavy=['shotgun','sniper','launcher','rail'].includes(gun),auto=['smg','rifle'].includes(gun);
 let layer=(source,gain,pitch,start,length,fade,delay)=>({source,gain,pitch,start,length,fade,delay,pitch_random:.012,gain_random:.5});
 library.guns[gun]={volume:heavy?3:1,low_cut:35,high_cut:19000,bass:heavy?5:2,mid:gun==='rifle'?3:0,drive:.12,attack: .2,room:.65,wet:.12,shake:1,recoil:1,flash:1,layers:[layer(cat[0],-1,1,0,auto?.18:.42,.045,0),layer(cat[2],heavy?-8:-13,heavy?.72:.88,.006,auto?.14:.3,.075,0),layer(cat[5],-21,1,0,.18,.03,.045),layer(cat[3],-8,1,.055,auto?.52:1.3,.25,.035)]};
 if(gun==='shotgun'){Object.assign(library.guns[gun],{volume:6,bass:5.5,drive:.22,attack:.35,wet:.17});Object.assign(library.guns[gun].layers[0],{gain:-3});Object.assign(library.guns[gun].layers[1],{gain:-2,pitch:.82,length:.42});}
}
fs.closeSync(fd);for(let rel of Object.values(library.catalog).flat()){let imp=path.join(root,'sfx/gunlab',rel+'.import');if(fs.existsSync(imp))fs.writeFileSync(imp,fs.readFileSync(imp,'utf8').replace(/compress\/mode=\d+/,'compress/mode=0'));}fs.writeFileSync(path.join(root,'sfx/gunlab/library.json'),JSON.stringify(library,null,2)+'\n');fs.writeFileSync(path.join(root,'sfx/gun_tuning.json'),JSON.stringify({version:1,guns:library.guns},null,2)+'\n');fs.writeFileSync(path.join(root,'sfx/gunlab/SOURCES.md'),lines.join('\n')+'\n');console.log(`GUNLAB PREP guns=8 candidates=${Object.values(library.catalog).flat().length} mono=44100 pcm=16`);
