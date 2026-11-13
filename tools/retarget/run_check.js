const {chromium}=require('playwright');
const sets={a:[['ual_Idle_Loop',0.5],['ual_Walk_Loop',0.3],['ual_Jog_Fwd_Loop',0.25],['ual_Sprint_Loop',0.2],['ual_Jump_Start',0.3],['ual_Jump_Loop',0.2],['ual_Jump_Land',0.1],['ual_Crouch_Fwd_Loop',0.4]],
 b:[['ual_Idle_Torch_Loop',0.5],['ual_Idle_Lantern_Loop',0.5],['ual_Idle_Rail_Call',0.8],['ual_Sitting_Talking_Loop',1.0],['ual_Swim_Fwd_Loop',0.5],['ual_Dance_Loop',1.0],['ual_LayToIdle',0.3],['ual_NinjaJump_Idle_Loop',0.3]]};
(async()=>{const b=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const p=await b.newPage({viewport:{width:1800,height:700}});
p.on('console',m=>console.log('console',m.text()));p.on('pageerror',e=>console.log('err',e.message));
for(const [who,set] of [['nino','a'],['nino','b'],['mel','a'],['mel','b']]){
 await p.goto(`http://127.0.0.1:8765/check.html?m=${who}_rig.glb&a=${who}_anims.glb&s=${encodeURIComponent(JSON.stringify(sets[set]))}`);
 await p.waitForFunction('window.done===true',{timeout:240000}); await p.screenshot({path:`check_${who}_${set}.png`});}
await b.close();})();
