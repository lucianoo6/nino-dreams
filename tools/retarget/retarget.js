import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {GLTFExporter} from 'three/addons/exporters/GLTFExporter.js';
import * as SkeletonUtils from 'three/addons/utils/SkeletonUtils.js';

// ---------- mapas de ossos: fonte -> alvo (esqueleto Hyper3D) ----------
const side=(s)=>s==='L'||s==='l'?'Left':'Right';
export function mapUAL1(){const m={'DEF-hips':'Hips','DEF-spine.001':'Spine','DEF-spine.002':'Spine1','DEF-spine.003':'Spine2','DEF-neck':'Neck','DEF-head':'Head'};
 for(const s of ['L','R']){const S=side(s);
  Object.assign(m,{[`DEF-shoulder.${s}`]:`${S}Shoulder`,[`DEF-upper_arm.${s}`]:`${S}Arm`,[`DEF-forearm.${s}`]:`${S}ForeArm`,[`DEF-hand.${s}`]:`${S}Hand`,
   [`DEF-thigh.${s}`]:`${S}UpLeg`,[`DEF-shin.${s}`]:`${S}Leg`,[`DEF-foot.${s}`]:`${S}Foot`,[`DEF-toe.${s}`]:`${S}ToeBase`});
  for(const [f,F] of [['index','Index'],['middle','Middle'],['pinky','Pinky'],['ring','Ring']]) for(let i=1;i<=3;i++) m[`DEF-f_${f}.0${i}.${s}`]=`${S}Hand${F}${i}`;
  for(let i=1;i<=3;i++) m[`DEF-thumb.0${i}.${s}`]=`${S}HandThumb${i}`;}
 return m;}
export function mapUAL2(){const m={'pelvis':'Hips','spine_01':'Spine','spine_02':'Spine1','spine_03':'Spine2','neck_01':'Neck','Head':'Head'};
 for(const s of ['l','r']){const S=side(s);
  Object.assign(m,{[`clavicle_${s}`]:`${S}Shoulder`,[`upperarm_${s}`]:`${S}Arm`,[`lowerarm_${s}`]:`${S}ForeArm`,[`hand_${s}`]:`${S}Hand`,
   [`thigh_${s}`]:`${S}UpLeg`,[`calf_${s}`]:`${S}Leg`,[`foot_${s}`]:`${S}Foot`,[`ball_${s}`]:`${S}ToeBase`});
  for(const [f,F] of [['index','Index'],['middle','Middle'],['pinky','Pinky'],['ring','Ring'],['thumb','Thumb']]) for(let i=1;i<=3;i++) m[`${f}_0${i}_${s}`]=`${S}Hand${F}${i}`;}
 return m;}
// filho "principal" para medir a direção de cada osso (no alvo)
function primaryChild(tName){
 // coluna, pescoço e clavículas NÃO são alinhados (proporções de pelúcia: cabeça grande à frente do pescoço)
 const m=tName.match(/^(Left|Right)(.*)$/); if(!m) return null; const [_,S,b]=m;
 const c={Arm:'ForeArm',ForeArm:'Hand',Hand:'HandMiddle1',UpLeg:'Leg',Leg:'Foot',Foot:'ToeBase'}[b];
 if(c) return S+c;
 const f=b.match(/^Hand(\w+?)(\d)$/); if(f && +f[2]<3) return `${S}Hand${f[1]}${+f[2]+1}`;
 return null;}

const L=new GLTFLoader();
const v=()=>new THREE.Vector3(), q=()=>new THREE.Quaternion();
function bonesByName(root){const o={};root.traverse(n=>{if(n.isBone)o[n.name]=n;});return o;}
function depthOrder(bones){return Object.values(bones).sort((a,b)=>{const d=x=>{let k=0;while(x.parent){x=x.parent;k++;}return k;};return d(a)-d(b);});}

export async function retarget(srcFile,tgtFile,clipNames,map,prefix,fps=30){
 const sg=await L.loadAsync(srcFile), tg=await L.loadAsync(tgtFile);
 const src=SkeletonUtils.clone(sg.scene), tgt=SkeletonUtils.clone(tg.scene);
 src.updateMatrixWorld(true); tgt.updateMatrixWorld(true);
 const sB=bonesByName(src), tB=bonesByName(tgt);
 const inv={}; for(const [s0,t] of Object.entries(map)){const s=THREE.PropertyBinding.sanitizeNodeName(s0); if(sB[s]&&tB[t]) inv[t]=s; else console.log('sem par',s0,t);}
 console.log('mapeados',Object.keys(inv).length);
 // pose de referência da fonte: T-pose (A_TPose quadro 0)
 const mx=new THREE.AnimationMixer(src);
 const tpose=sg.animations.find(c=>c.name==='A_TPose');
 if(tpose){mx.clipAction(tpose).play();mx.setTime(0);mx.stopAllAction();mx.clipAction(tpose).play();mx.setTime(0);} src.updateMatrixWorld(true);
 const sRefQ={}, sRefP={}; for(const t in inv){const b=sB[inv[t]]; sRefQ[t]=b.getWorldQuaternion(q()); sRefP[t]=b.getWorldPosition(v());}
 // coloca o ALVO na mesma pose da fonte, alinhando a direção de cada osso
 const order=depthOrder(tB);
 for(const b of order){const c=primaryChild(b.name); if(!c||!tB[c]||!inv[b.name]||!inv[c]||b.name==='Hips') continue;
  tgt.updateMatrixWorld(true);
  const cur=tB[c].getWorldPosition(v()).sub(b.getWorldPosition(v())).normalize();
  const des=sRefP[c].clone().sub(sRefP[b.name]).normalize();
  const sw=q().setFromUnitVectors(cur,des);
  const w=b.getWorldQuaternion(q()); const nw=sw.multiply(w);
  const pw=b.parent.getWorldQuaternion(q()); b.quaternion.copy(pw.invert().multiply(nw)); }
 tgt.updateMatrixWorld(true);
 const tRefQ={}; for(const b of order) tRefQ[b.name]=b.getWorldQuaternion(q());
 const tRefLocal={}; for(const b of order) tRefLocal[b.name]=b.quaternion.clone();
 const hipsRefT=tB.Hips.getWorldPosition(v()), hipsRefS=sRefP.Hips;
 const scale=hipsRefT.y/hipsRefS.y; // proporção de altura do quadril (chão em y≈0 nos dois? ajustado abaixo)
 const tFloor=new THREE.Box3().setFromObject(tgt).min.y, sFloor=new THREE.Box3().setFromObject(src).min.y;
 const hScale=(hipsRefT.y-tFloor)/(hipsRefS.y-sFloor);
 const restLocalQ={}, restLocalP={}; for(const b of order){restLocalQ[b.name]=b.quaternion.clone();restLocalP[b.name]=b.position.clone();}
 const clips=[];
 for(const name of clipNames){
  const clip=sg.animations.find(c=>c.name===name); if(!clip){console.log('falta',name);continue;}
  mx.stopAllAction(); const act=mx.clipAction(clip); act.play();
  const n=Math.max(2,Math.round(clip.duration*fps)+1); const times=[];
  const qv={}, pv=[]; for(const b of order) qv[b.name]=[];
  for(let i=0;i<n;i++){const t=Math.min(clip.duration,i/fps); times.push(t); mx.setTime(t); src.updateMatrixWorld(true);
   for(const b of order){
    if(inv[b.name]){const sw=sB[inv[b.name]].getWorldQuaternion(q());
     const d=sw.multiply(sRefQ[b.name].clone().invert()); const desired=d.multiply(tRefQ[b.name].clone());
     b.parent.updateWorldMatrix(true,false); const pw=b.parent.getWorldQuaternion(q());
     b.quaternion.copy(pw.invert().multiply(desired));}
    else b.quaternion.copy(restLocalQ[b.name]);
    b.updateMatrixWorld(true); qv[b.name].push(...b.quaternion.toArray());}
   const sp=sB[inv.Hips].getWorldPosition(v()).sub(hipsRefS).multiplyScalar(hScale);
   const wp=hipsRefT.clone().add(sp); tB.Hips.parent.updateWorldMatrix(true,false);
   const lp=tB.Hips.parent.worldToLocal(wp); pv.push(lp.x,lp.y,lp.z); tB.Hips.position.copy(lp);}
  const tracks=[]; for(const b of order) tracks.push(new THREE.QuaternionKeyframeTrack(`${b.name}.quaternion`,times,qv[b.name]));
  tracks.push(new THREE.VectorKeyframeTrack('Hips.position',times,pv));
  clips.push(new THREE.AnimationClip(prefix+name,clip.duration,tracks));
  for(const b of order){b.quaternion.copy(restLocalQ[b.name]);b.position.copy(restLocalP[b.name]);}
 }
 return {clips, tg};
}

export async function exportLib(tg, clips){
 const scene=SkeletonUtils.clone(tg.scene);
 const plain=new THREE.MeshStandardMaterial({color:0x888888});
 scene.traverse(o=>{if(o.isMesh) o.material=plain;});
 const ex=new GLTFExporter();
 const buf=await ex.parseAsync(scene,{binary:true,animations:clips,onlyVisible:false});
 return buf;
}
