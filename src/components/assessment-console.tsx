"use client";
import { useMemo, useRef, useState } from "react";
import { initJsPsych } from "jspsych";
import LdtChoicePlugin from "@/lib/jspsych/ldt-choice-plugin.js";
import { PROTOCOL, type ItemKind, type TrialResponse } from "@/lib/protocol";
import { localDb, persistTrial } from "@/lib/storage/db";
import { parseItemBankWorkbook } from "@/lib/item-bank/import-xlsx";
import PwaRegistration from "@/components/pwa-registration";

type Screen="overview"|"setup"|"bank"|"game"|"reports"|"settings";
type Demo={itemId:string;text:string;itemKind:ItemKind};
const practice:Demo[]=[
 {itemId:"PRACTICE-01",text:"ಮನೆ",itemKind:"word"},
 {itemId:"PRACTICE-02",text:"ಮರ",itemKind:"word"},
 {itemId:"PRACTICE-03",text:"ಹಾಲು",itemKind:"word"},
 {itemId:"PRACTICE-04",text:"ಮಳೆ",itemKind:"word"},
 {itemId:"PRACTICE-05",text:"ನದಿ",itemKind:"word"}
];
// Fictional visual-demo strings only. They are not screened non-words or study stimuli.
const demo:Demo[]=[
 {itemId:"DEMO-01",text:"ಮನೆ",itemKind:"word"},{itemId:"DEMO-02",text:"ಲಮನೆ",itemKind:"nonword"},
 {itemId:"DEMO-03",text:"ಮರ",itemKind:"word"},{itemId:"DEMO-04",text:"ಕಿರಮ",itemKind:"nonword"},
 {itemId:"DEMO-05",text:"ಹಾಲು",itemKind:"word"},{itemId:"DEMO-06",text:"ಪಹೂ",itemKind:"nonword"},
 {itemId:"DEMO-07",text:"ಮಳೆ",itemKind:"word"},{itemId:"DEMO-08",text:"ನಲಮ",itemKind:"nonword"},
 {itemId:"DEMO-09",text:"ನದಿ",itemKind:"word"},{itemId:"DEMO-10",text:"ಕಿಮನೆ",itemKind:"nonword"}
];
const nav:{id:Screen;label:string;kn:string;icon:string}[]=[
 {id:"overview",label:"Overview",kn:"ಅವಲೋಕನ",icon:"⌂"},{id:"setup",label:"Session setup",kn:"ಮಕ್ಕಳ ವಿವರ",icon:"◎"},
 {id:"bank",label:"Word bank",kn:"ಪದಗಳ ಪಟ್ಟಿ",icon:"▤"},{id:"game",label:"Child game",kn:"ಮಕ್ಕಳ ಆಟ",icon:"✳"},
 {id:"reports",label:"Reports & export",kn:"ವರದಿಗಳು",icon:"▥"},{id:"settings",label:"Settings",kn:"ಸೆಟ್ಟಿಂಗ್‌ಗಳು",icon:"⚙"}
];
const uid=()=>globalThis.crypto?.randomUUID?.()??`demo-${Date.now()}-${Math.random().toString(16).slice(2)}`;
type Reward={count:number;resume:()=>void}|null;
export default function AssessmentConsole(){
 const [screen,setScreen]=useState<Screen>("overview");
 const [running,setRunning]=useState(false);const [finished,setFinished]=useState(false);
 const [phase,setPhase]=useState<"practice"|"scored">("practice");const [progress,setProgress]=useState(0);
 const [reward,setReward]=useState<Reward>(null);const [studyId,setStudyId]=useState("");const [assessorId,setAssessorId]=useState("");
 const [visit,setVisit]=useState("1");const [block,setBlock]=useState("1");const [notes,setNotes]=useState("");
 const [fileName,setFileName]=useState("");const [bankStatus,setBankStatus]=useState("No item bank imported");
 const [bankErrors,setBankErrors]=useState<string[]>([]);const [busy,setBusy]=useState(false);
 const mount=useRef<HTMLDivElement>(null);const sessionId=useRef(uid());
 const title=useMemo(()=>nav.find(x=>x.id===screen)?.label??"Overview",[screen]);
 const progressMax=phase==="practice"?5:10;
 async function startDemo(){
   if(!mount.current||running)return;sessionId.current=uid();setRunning(true);setFinished(false);setProgress(0);setPhase("practice");setReward(null);
   const jsPsych=initJsPsych({display_element:mount.current,on_finish:()=>{setRunning(false);setFinished(true);}});
   const trial=(item:Demo,index:number,trialPhase:"practice"|"scored")=>({
    type:LdtChoicePlugin,stimulusText:item.text,itemId:item.itemId,itemKind:item.itemKind,phase:trialPhase,
    trialNo:index+1,responseWindowMs:PROTOCOL.provisionalResponseWindowMs,
    scoredCompletedAfterThis:trialPhase==="scored"?index+1:0,
    onResponse:async(result:{itemId:string;stimulusText:string;itemKind:ItemKind;phase:"practice"|"scored";trialNo:number;response:ItemKind|"none";correct:boolean|null;rtMs:number|null;startedAt:string;respondedAt:string})=>{
      const row:TrialResponse={...result,sessionId:sessionId.current,childStudyId:"DEMO-ONLY",assessorId:"DEMO-ONLY",
        visitNo:1,blockNo:1,appVersion:"0.1.0-demo",bankVersion:"DEMO-NOT-APPROVED",isDemo:true};
      await persistTrial(row);setPhase(trialPhase);setProgress(index+1);
    },
    onMilestone:async(count:number)=>new Promise<void>(resolve=>setReward({count,resume:resolve}))
   });
   jsPsych.run([...practice.map((x,i)=>trial(x,i,"practice")),...demo.map((x,i)=>trial(x,i,"scored"))] as never[]);
 }
 async function importBank(file?:File){
   if(!file)return;setFileName(file.name);setBankErrors([]);setBusy(true);setBankStatus("Validating workbook…");
   try{
    const result=await parseItemBankWorkbook(file);setBankErrors(result.errors.slice(0,15));
    if(!result.valid){setBankStatus(`Rejected — ${result.errors.length} issue(s)`);return;}
    await localDb.banks.put({bankVersion:result.bankVersion,importedAt:new Date().toISOString(),itemCount:result.items.length,
      approvedBy:"Reviewer IDs are recorded per item",approvalReference:result.bankVersion,payload:JSON.stringify(result.items)});
    setBankStatus(`Accepted locally · ${result.items.length} items · ${result.bankVersion}`);
   }catch(e){setBankStatus("Could not read workbook");setBankErrors([e instanceof Error?e.message:"Unknown parsing error"]);}
   finally{setBusy(false);}
 }
 return <main className="shell">
  <aside className="sidebar">
   <div className="brand"><span className="brand-mark">ಪ</span><div><b>ಪದ<span>Lab</span></b><small>KANNADA WORD READING</small></div></div>
   <div className="study-tag">● PHFI · CDLR <small>REVIEW BUILD</small></div><p className="nav-title">WORKSPACE</p>
   <nav>{nav.map(n=><button key={n.id} onClick={()=>setScreen(n.id)} className={screen===n.id?"nav active":"nav"}><i>{n.icon}</i><span>{n.label}<small>{n.kn}</small></span></button>)}</nav>
   <div className="sidebar-bottom"><b>Offline-first</b><small>Local tablet storage</small><p>Assessor workspace · Demo only</p></div>
  </aside>
  <section className="main">
   <header><span>Research workspace　/　<b>{title}</b></span><div><label className="demo-tag">● DEMO DATA ONLY</label><PwaRegistration/></div></header>
   {screen==="overview"&&<div className="content">
    <div className="heading"><div><label>ASSESSMENT WORKSPACE · NEXT.JS OFFLINE PWA</label><h1>Kannada word reading <em>assessment</em></h1><p>A child-friendly lexical-decision experience with a controlled research workflow.</p></div><button className="primary" onClick={()=>setScreen("game")}>Preview child game →</button></div>
    <div className="stats">{[["540","Scored items","270 real + 270 non-words"],["03","Visits","Two blocks per visit"],["06","Test blocks","90 scored items each"],["45 / 45","Block balance","Real words / non-words"]].map(x=><article key={x[0]}><small>{x[1]}</small><strong>{x[0]}</strong><span>{x[2]}</span></article>)}</div>
    <div className="grid">
     <article className="panel"><label>ASSESSMENT STRUCTURE</label><h2>Three visits. Six balanced blocks.</h2><p>Five practice trials are proposed before each scored block; PI confirmation is pending.</p>
      {[1,2,3].map(v=><div className="visit" key={v}><b>Visit 0{v}</b><span>Test {(v-1)*2+1} · 90</span><span>Test {(v-1)*2+2} · 90</span><strong>180 items</strong></div>)}
      <small>Each of the 540 scored items is intended to appear once. Confirm allocation with the study PI.</small>
     </article>
     <article className="panel"><label>CHILD EXPERIENCE</label><h2>One word. One clear choice.</h2><div className="preview"><small>ಕನ್ನಡ ಪದ ಓದು · 05 / 90</small><div className="bar"><i/></div><p>ಈ ಪದ ನಿಜವಾದ ಪದವೇ?</p><strong>ಮನೆ</strong><div><span>ಪದ</span><span>ಪದವಲ್ಲ</span></div></div><small>Illustrative display only; stimulus is not an approved item.</small></article>
    </div>
    <article className="panel roadmap"><label>DELIVERY ROADMAP</label><div className="roadmap-row"><span>01 · Architecture & references — prepared</span><span>02 · Game engine — demo</span><span>03 · Excel import + local persistence — implemented starter</span><span>04 · Kannada voice + tablet validation — pending</span><span>05 · REDCap export mapping — pending</span></div></article>
   </div>}
   {screen==="setup"&&<div className="content narrow"><label>ASSESSOR WORKFLOW</label><h1>Assessment setup</h1><article className="panel form">
    <h2>Child and assessor details</h2><div className="fields">
     <label>Child study ID<input value={studyId} onChange={e=>setStudyId(e.target.value)} placeholder="KWR-0001"/></label>
     <label>Assessor ID<input value={assessorId} onChange={e=>setAssessorId(e.target.value)} placeholder="ASR-003"/></label>
     <label>Visit<select value={visit} onChange={e=>setVisit(e.target.value)}><option value="1">Visit 1</option><option value="2">Visit 2</option><option value="3">Visit 3</option></select></label>
     <label>Test block<select value={block} onChange={e=>setBlock(e.target.value)}><option value="1">Test 1 · 90 items</option><option value="2">Test 2 · 90 items</option></select></label>
     <label className="wide">Assessor notes<textarea rows={4} value={notes} onChange={e=>setNotes(e.target.value)} placeholder="Session context, interruptions or technical notes"/></label>
    </div><p className="warning">Setup is a UI prototype. Real session locking, duplicate-session rules and recovery are pending.</p>
   </article></div>}
   {screen==="bank"&&<div className="content narrow"><label>STIMULUS MANAGEMENT</label><h1>Word bank</h1><article className="panel form"><h2>Import approved 540-item workbook</h2><p>Six blocks · 90 items per block · 45 real words + 45 non-words.</p><a className="secondary" href="/templates/kannada-item-bank-template.xlsx" download>Download Excel template ↓</a>
    <label className="upload">Select .xlsx workbook<input type="file" accept=".xlsx" onChange={e=>void importBank(e.target.files?.[0])}/></label>
    {fileName&&<p>{fileName} · {busy?"Checking…":bankStatus}</p>}{bankErrors.length>0&&<ul className="errors">{bankErrors.map((e,i)=><li key={i}>{e}</li>)}</ul>}
    <p className="warning">Structural validation does not prove a non-word is linguistically invalid. Native Kannada reviewer approval must be genuine and documented. Accepted bank stays in this browser only.</p>
   </article></div>}
   {screen==="game"&&<div className="content">
    <div className="heading"><div><label>CHILD-FACING EXPERIENCE · DEMONSTRATION ONLY</label><h1>ಮಕ್ಕಳ ಆಟ <em>Child game</em></h1><p>Five practice trials followed by a short ten-item demo block.</p></div><button className="secondary" onClick={()=>setScreen("overview")}>← Workspace</button></div>
    <div className="panel audio"><div><label>KANNADA VOICE INSTRUCTIONS</label><h2>ಮೊದಲು ಅಭ್ಯಾಸ ಮಾಡೋಣ</h2><p>Approved female Kannada recordings have not yet been added.</p></div><b>♫ Audio pending</b></div>
    <div className="game-layout"><section className="game-stage"><div className="stage-top"><b>ಕನ್ನಡ ಪದ ಓದು</b><span>DEMO MODE · NOT FOR PARTICIPANTS</span></div>
      {running&&<div className="game-progress"><div><span>{phase==="practice"?"ಅಭ್ಯಾಸ (Practice)":"ಪರೀಕ್ಷೆ (Test)"}</span><b>{progress} / {progressMax}</b></div><div className="bar"><i style={{width:`${progress/progressMax*100}%`}}/></div></div>}
      <div className="game-mount" ref={mount}>{!running&&!finished&&<div className="game-intro"><div className="collectibles">🧁　⭐　🍫</div><h2>ಆಟ ಆಡಲು ಸಿದ್ಧವೇ?</h2><p>ಮೊದಲು 5 ಅಭ್ಯಾಸ ಪದಗಳು. ನಂತರ ಚಿಕ್ಕ ಮಾದರಿ ಪರೀಕ್ಷೆ.</p><button className="primary" onClick={()=>void startDemo()}>ಆಟ ಪ್ರಾರಂಭಿಸಿ (Start demo) →</button></div>}
      {finished&&<div className="game-intro"><div className="collectibles">🧁　⭐　🍫</div><h2>ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದೀರಿ!</h2><p>ಮಾದರಿ ಆಟ ಮುಗಿದಿದೆ. (Demo complete.)</p><button className="primary" onClick={()=>void startDemo()}>ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ</button></div>}</div>
      <footer>One stimulus at a time · Rewards are not linked to correctness</footer>
    </section><aside className="panel game-rules"><label>GAME RULES</label><h2>Research-first game design</h2><ul><li>Five practice trials.</li><li>90 scored items per real test block.</li><li>Reward every five completed scored trials.</li><li>No correctness feedback in scored trials.</li><li>Silence during stimulus presentation.</li></ul><p className="warning">Fictional demo strings are not approved study stimuli.</p></aside></div>
    {reward&&<div className="reward-layer"><div className="reward-card"><strong>{reward.count%3===0?"🧁":reward.count%2===0?"🍫":"⭐"}</strong><h2>ಚೆನ್ನಾಗಿದೆ!</h2><p>ಚಿಕ್ಕ ಬಹುಮಾನ! · You completed {reward.count} demo items.</p><button className="primary" onClick={()=>{const f=reward.resume;setReward(null);f();}}>ಮುಂದುವರಿಸಿ →</button></div></div>}
   </div>}
   {screen==="reports"&&<div className="content narrow"><label>LOCAL REPORTING</label><h1>Reports & export</h1><article className="panel"><h2>Export for existing REDCap workflow</h2><p>Trial responses are written to IndexedDB locally. CSV/XLSX export controls and REDCap field mapping are still pending.</p><div className="stats mini"><article><strong>Local</strong><small>Trial storage</small></article><article><strong>CSV</strong><small>Planned REDCap import</small></article><article><strong>No API</strong><small>Current architecture</small></article></div></article></div>}
   {screen==="settings"&&<div className="content narrow"><label>APPLICATION CONFIGURATION</label><h1>Settings</h1><article className="panel settings"><p><b>Offline readiness</b><span>Requires tablet test</span></p><p><b>Kannada audio</b><span>Pending approved recordings</span></p><p><b>Response window</b><span>10 seconds · provisional</span></p><p><b>Cloud database</b><span>Not configured</span></p><p><b>Research integration</b><span>Manual REDCap import first</span></p></article></div>}
  </section><footer className="app-footer">ಪದLab · Research assessment prototype · No live participant data · Build 0.1.0</footer>
 </main>;
}
