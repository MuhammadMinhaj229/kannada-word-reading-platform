import ExcelJS from "exceljs";
import type { StimulusItem } from "@/lib/protocol";
import { validateApprovedItemBank } from "@/lib/item-bank/validate";
export interface WorkbookImportResult {
  bankVersion:string; fileName:string; items:StimulusItem[]; valid:boolean;
  errors:string[]; warnings:string[]; counts:ReturnType<typeof validateApprovedItemBank>["counts"];
}
function cellText(value:unknown):string {
  if(value===null||value===undefined)return "";
  if(typeof value==="object"&&"text" in value)return String((value as {text:unknown}).text??"").trim();
  if(typeof value==="object"&&"result" in value)return String((value as {result:unknown}).result??"").trim();
  return String(value).trim();
}
function cellNumber(value:unknown):number { const n=Number(cellText(value)); return Number.isFinite(n)?n:Number.NaN; }
async function sha256(buffer:ArrayBuffer):Promise<string>{
  const digest=await crypto.subtle.digest("SHA-256",buffer);
  return Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,"0")).join("");
}
/** Parses the assessor-supplied workbook in-browser; no upload or network request occurs. */
export async function parseItemBankWorkbook(file:File):Promise<WorkbookImportResult>{
  const buffer=await file.arrayBuffer(); const bankVersion=`sha256-${(await sha256(buffer)).slice(0,16)}`;
  const workbook=new ExcelJS.Workbook(); await workbook.xlsx.load(buffer);
  const sheet=workbook.getWorksheet("Items");
  const empty=(errors:string[]):WorkbookImportResult=>({bankVersion,fileName:file.name,items:[],valid:false,errors,warnings:[],counts:{total:0,words:0,nonwords:0,byBlock:{}}});
  if(!sheet)return empty(['Missing required worksheet: "Items".']);
  const headerMap=new Map<string,number>();
  sheet.getRow(1).eachCell((cell,col)=>headerMap.set(cellText(cell.value).toLowerCase(),col));
  const required=["item_id","item_text","item_type","visit_no","block_no","order_no","approval_status"];
  const missing=required.filter(name=>!headerMap.has(name));
  if(missing.length)return empty([`Missing required columns: ${missing.join(", ")}`]);
  const get=(row:ExcelJS.Row,name:string)=>{const col=headerMap.get(name);return col?row.getCell(col).value:undefined;};
  const items:StimulusItem[]=[]; const rowErrors:string[]=[];
  for(let rowNo=2;rowNo<=sheet.rowCount;rowNo++){
    const row=sheet.getRow(rowNo); const id=cellText(get(row,"item_id")); const text=cellText(get(row,"item_text"));
    if(!id&&!text)continue;
    const rawType=cellText(get(row,"item_type")).toLowerCase();
    const itemKind=rawType==="word"?"word":rawType==="nonword"?"nonword":null;
    if(!itemKind)rowErrors.push(`Row ${rowNo}: item_type must be word or nonword.`);
    const approval=cellText(get(row,"approval_status")).toLowerCase();
    const reviewerId=cellText(get(row,"reviewer_id")); const reviewedAt=cellText(get(row,"reviewed_at"));
    const visitNo=cellNumber(get(row,"visit_no")); const blockNo=cellNumber(get(row,"block_no")); const order=cellNumber(get(row,"order_no"));
    items.push({itemId:id,text,itemKind:itemKind??"invalid",visitNo:visitNo as StimulusItem["visitNo"],
      blockNo:blockNo as StimulusItem["blockNo"],order,bankVersion,approved:approval==="approved",
      nonwordMethod:cellText(get(row,"nonword_method")),reviewerId,reviewedAt});
    if(approval!=="approved")rowErrors.push(`Row ${rowNo}: approval_status must be approved.`);
    if(itemKind==="nonword"&&!reviewerId)rowErrors.push(`Row ${rowNo}: reviewer_id required for non-word.`);
    if(itemKind==="nonword"&&!reviewedAt)rowErrors.push(`Row ${rowNo}: reviewed_at required for non-word.`);
    if(!Number.isFinite(visitNo))rowErrors.push(`Row ${rowNo}: visit_no must be numeric.`);
    if(!Number.isFinite(blockNo))rowErrors.push(`Row ${rowNo}: block_no must be numeric.`);
    if(!Number.isFinite(order))rowErrors.push(`Row ${rowNo}: order_no must be numeric.`);
  }
  const validation=validateApprovedItemBank(items); const errors=[...rowErrors,...validation.errors];
  return {bankVersion,fileName:file.name,items,valid:errors.length===0&&validation.valid,
    errors:Array.from(new Set(errors)),warnings:validation.warnings,counts:validation.counts};
}
