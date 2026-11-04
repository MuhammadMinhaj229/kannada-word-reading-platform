import { PROTOCOL, type StimulusItem } from "@/lib/protocol";
export interface ItemBankValidation {
  valid: boolean; errors: string[]; warnings: string[];
  counts: { total: number; words: number; nonwords: number;
    byBlock: Record<string,{total:number;words:number;nonwords:number}> };
}
/** Structural checks only; this cannot prove linguistic validity of Kannada items. */
export function validateApprovedItemBank(items: StimulusItem[]): ItemBankValidation {
  const errors:string[]=[]; const warnings:string[]=[];
  const ids=new Set<string>(); const stimuli=new Map<string,string>(); const positions=new Set<string>();
  const byBlock:ItemBankValidation["counts"]["byBlock"]={}; let words=0; let nonwords=0;
  for (const item of items) {
    const id=String(item.itemId??"").trim(); const text=String(item.text??"").trim();
    const key=`${item.visitNo}-${item.blockNo}`;
    if(!id) errors.push("An item is missing its stable itemId.");
    else if(ids.has(id)) errors.push(`Duplicate itemId: ${id}`); else ids.add(id);
    if(!text) errors.push(`Item ${id||"(no ID)"} has empty Kannada text.`);
    else { const normal=text.normalize("NFC"); const prior=stimuli.get(normal);
      if(prior) errors.push(`Duplicate stimulus text in ${prior} and ${id}.`); else stimuli.set(normal,id); }
    if(!Number.isInteger(item.visitNo)||item.visitNo<1||item.visitNo>PROTOCOL.visitCount) errors.push(`Item ${id} has invalid visitNo.`);
    if(!Number.isInteger(item.blockNo)||item.blockNo<1||item.blockNo>PROTOCOL.blocksPerVisit) errors.push(`Item ${id} has invalid blockNo.`);
    if(!Number.isInteger(item.order)||item.order<1||item.order>PROTOCOL.scoredItemsPerBlock) errors.push(`Item ${id} has invalid order; expected 1–90.`);
    else { const pos=`${key}-${item.order}`; if(positions.has(pos)) errors.push(`Duplicate position ${item.order} in block ${key}.`); positions.add(pos); }
    byBlock[key]??={total:0,words:0,nonwords:0}; byBlock[key].total++;
    if(item.itemKind==="word"){words++;byBlock[key].words++;}
    else if(item.itemKind==="nonword"){nonwords++;byBlock[key].nonwords++;}
    else errors.push(`Item ${id} has unsupported itemKind.`);
    if(item.approved!==true) errors.push(`Item ${id} is not marked approved.`);
    if(!item.bankVersion?.trim()) errors.push(`Item ${id} has no bankVersion.`);
    if(item.itemKind==="nonword"){
      if(!item.nonwordMethod?.trim()) errors.push(`Non-word ${id} has no generation method.`);
      if(!item.reviewerId?.trim()) errors.push(`Non-word ${id} has no reviewer ID.`);
      if(!item.reviewedAt?.trim()) errors.push(`Non-word ${id} has no review date.`);
    }
  }
  if(items.length!==540) errors.push(`Expected 540 scored items; found ${items.length}.`);
  if(words!==270) errors.push(`Expected 270 real words; found ${words}.`);
  if(nonwords!==270) errors.push(`Expected 270 non-words; found ${nonwords}.`);
  for(let visitNo=1;visitNo<=3;visitNo++) for(let blockNo=1;blockNo<=2;blockNo++){
    const key=`${visitNo}-${blockNo}`; const c=byBlock[key]??{total:0,words:0,nonwords:0};
    if(c.total!==90) errors.push(`Visit ${visitNo}, block ${blockNo}: expected 90, found ${c.total}.`);
    if(c.words!==45) errors.push(`Visit ${visitNo}, block ${blockNo}: expected 45 words, found ${c.words}.`);
    if(c.nonwords!==45) errors.push(`Visit ${visitNo}, block ${blockNo}: expected 45 non-words, found ${c.nonwords}.`);
    for(let order=1;order<=90;order++) if(!positions.has(`${key}-${order}`)) errors.push(`Visit ${visitNo}, block ${blockNo}: missing order ${order}.`);
  }
  const versions=new Set(items.map(x=>x.bankVersion?.trim()).filter(Boolean));
  if(versions.size>1) errors.push("A workbook must contain one consistent bankVersion.");
  return {valid:errors.length===0&&warnings.length===0,errors,warnings,counts:{total:items.length,words,nonwords,byBlock}};
}
