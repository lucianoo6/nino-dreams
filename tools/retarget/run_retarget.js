const {chromium}=require('playwright'); const fs=require('fs');
const U1=['Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Sprint_Loop','Jump_Start','Jump_Loop','Jump_Land','Crouch_Idle_Loop','Crouch_Fwd_Loop',
 'Sitting_Enter','Sitting_Idle_Loop','Sitting_Talking_Loop','Sitting_Exit','Interact','PickUp_Table','Swim_Fwd_Loop','Swim_Idle_Loop',
 'Push_Loop','Dance_Loop','Idle_Talking_Loop','Idle_Torch_Loop','Hit_Head','Roll','Spell_Simple_Idle_Loop'];
const U2=['Idle_Lantern_Loop','Idle_Rail_Call','Yes','Idle_No_Loop','LayToIdle','NinjaJump_Start','NinjaJump_Idle_Loop','NinjaJump_Land',
 'Slide_Start','Slide_Loop','Slide_Exit','ClimbUp_1m_RM','Walk_Carry_Loop','Chest_Open','Idle_FoldArms_Loop','Hit_Knockback'];
(async()=>{const b=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const p=await b.newPage();
p.on('console',m=>console.log('console',m.text()));p.on('pageerror',e=>console.log('err',e.message));
await p.goto('http://127.0.0.1:8765/retarget.html');await p.waitForFunction('window.ready===true');
for (const who of ['nino','mel']){
 const r=await p.evaluate(([who,U1,U2])=>window.run(who+'_rig.glb',[['ual/ual1.glb','ual1',U1,'ual_'],['ual/ual2.glb','ual2',U2,'ual_']]),[who,U1,U2]);
 fs.writeFileSync(who+'_anims.glb',Buffer.from(r.b64,'base64')); console.log(who,r.names.length,'clips', fs.statSync(who+'_anims.glb').size);}
await b.close();})();
