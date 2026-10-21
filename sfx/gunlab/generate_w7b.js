// Физические шумовые модели и записанная механика CC0; все слои доступны пульту W6.
const fs=require('node:fs'),path=require('node:path');
const dir=__dirname,root=path.resolve(dir,'../..');let seed=771107;
function rnd(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/2147483648-1;}
function wav(kind,layer){const rate=44100,n=Math.round(rate*.72),b=Buffer.alloc(44+n*2);b.write('RIFF');b.writeUInt32LE(36+n*2,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(n*2,40);let lo=0,mid=0,pulse=0,phase=0,fuel=0;
 for(let i=0;i<n;i++){const t=i/rate,noise=rnd();lo=lo*.985+noise*.015;mid=mid*.64+noise*.36;let x=0;
  if(kind==='flamer'){
   fuel=fuel*.998+rnd()*.002;
   x=layer===0?(mid*.95+lo*4)*(1+fuel*2):layer===1?(noise-mid)*.14:layer===2?Math.sin(t*2*Math.PI*43)*.18+lo*2:0;
   if(layer===3){if(rnd()>.999) pulse=.85;pulse*=.997;x=noise*pulse;}
  }else if(kind==='saw'){
   const hz=(layer===1?71:94)+Math.sin(t*17)*3+lo*13;phase+=hz/rate;
   const stroke=Math.exp(-((phase%1)*18));
   x=layer===0?(stroke-.09)*1.8+Math.sin(phase*Math.PI*2)*.22:layer===1?Math.tanh((mid*.8+stroke*.45)*3)*.5:layer===2?(noise-mid)*(.2+.8*stroke)*.42:lo*3+Math.sin(phase*Math.PI*4)*.15;
  }else if(kind==='tesla'){
   if(rnd()>.993)pulse=.6+rnd()*.4;pulse*=.988;
   x=layer===0?(noise-mid)*pulse*1.2:layer===1?Math.sin(t*Math.PI*200)*(.18+.1*Math.sin(t*79)):layer===2?mid*pulse*.6:lo*2*Math.exp(-t*7);
   x*=Math.exp(-t*(layer===1?8:13));
  }else{
   x=layer===0?mid*Math.exp(-t*95)*2:layer===1?Math.sin(t*Math.PI*2*(145-70*t))*Math.exp(-t*38)*.75:layer===2?(noise-mid)*Math.exp(-Math.pow((t-.045)/.03,2))*.25:mid*Math.exp(-Math.pow((t-.16)/.015,2))*1.4;
  }
  const env=Math.min(1,t/.006)*Math.min(1,(.72-t)/.035);b.writeInt16LE(Math.round(Math.tanh(x)*env*29000),44+i*2);
 }return b;
}
const libfile=path.join(dir,'library.json'),tunefile=path.join(root,'sfx/gun_tuning.json');
const lib=JSON.parse(fs.readFileSync(libfile)),tuning=JSON.parse(fs.readFileSync(tunefile));
for(const kind of ['flamer','saw','tesla','crossbow']){
 const p=tuning.guns[kind];p.volume={flamer:-6,saw:-5,tesla:-3,crossbow:-1}[kind];p.room=.12;p.wet=.06;p.drive=kind==='saw'?.13:.04;
 p.layers.forEach((l,i)=>{const source='w7/'+kind+'_'+i+'.wav';const rendered=wav(kind,i);if(kind!=='crossbow'||i!==0)fs.writeFileSync(path.join(dir,source),rendered);const imp=path.join(dir,source+'.import');if(fs.existsSync(imp))fs.writeFileSync(imp,fs.readFileSync(imp,'utf8').replace(/compress\/mode=\d+/,'compress/mode=0'));l.source=source;l.start=0;l.pitch=1;l.pitch_random=.025;l.gain_random=.7;l.gain=[-1,-9,-12,-14][i];l.length=kind==='flamer'?.20:kind==='saw'?.26:.35;l.fade=kind==='flamer'||kind==='saw'?.045:.028;l.delay=0;});
 // Щелчок замка — реальная запись CC0 из набора W6, остальные слои — синтез.
 if(kind==='crossbow'){p.layers[0].source='rifle/mechanism_1.wav';p.layers[0].length=.10;p.layers[0].pitch=1.6;p.layers[3].delay=.12;}
 lib.catalog[kind]=[...new Set(p.layers.map(l=>l.source))];lib.guns[kind]=structuredClone(p);
}
fs.writeFileSync(libfile,JSON.stringify(lib,null,2)+'\n');fs.writeFileSync(tunefile,JSON.stringify(tuning,null,2)+'\n');
console.log('W7B_SOUND physical_synthesis=15 recorded_mechanism=1 layers=16 seed=771107');
