import { localDb } from "@/lib/storage/db";
import type { StoredTrial, LocalSession } from "@/lib/storage/db";

export interface ExportResult { trials: number; sessions: number; filename: string; }

function csvCell(value: unknown): string {
  let text = value === null || value === undefined ? "" : String(value);
  // Prevent spreadsheet formula execution when exported values are opened in Excel.
  if (/^[\s]*[=+@-]/.test(text)) text = `'${text}`;
  return `"${text.replace(/"/g, '""')}"`;
}
function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url; anchor.download = filename; anchor.rel = "noopener";
  document.body.appendChild(anchor); anchor.click(); anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1500);
}
function rowsForCsv(trials: StoredTrial[]): string {
  const fields: (keyof StoredTrial)[] = [
    "sessionId","childStudyId","assessorId","visitNo","blockNo","itemId","stimulusText",
    "itemKind","phase","trialNo","response","correct","rtMs","startedAt","respondedAt",
    "appVersion","bankVersion","isDemo"
  ];
  const lines = [fields.map(csvCell).join(",")];
  for (const trial of trials) lines.push(fields.map(field => csvCell(trial[field])).join(","));
  return `\uFEFF${lines.join("\r\n")}`;
}
export async function exportLocalTrials(
  format: "csv" | "xlsx",
  studyIdFilter = ""
): Promise<ExportResult> {
  const [allTrials, sessions] = await Promise.all([
    localDb.trials.orderBy("respondedAt").toArray(),
    localDb.sessions.orderBy("startedAt").toArray()
  ]);
  const filter = studyIdFilter.trim().toLocaleLowerCase();
  const trials = filter
    ? allTrials.filter(trial => trial.childStudyId.toLocaleLowerCase() === filter)
    : allTrials;
  if (trials.length === 0) throw new Error("No local trial records match this filter.");

  const timestamp = new Date().toISOString().replace(/[:.]/g,"-");
  if (format === "csv") {
    const filename = `padalab-trials-${timestamp}.csv`;
    downloadBlob(new Blob([rowsForCsv(trials)], {type:"text/csv;charset=utf-8"}), filename);
    return {trials:trials.length,sessions:sessions.length,filename};
  }

  const ExcelJS = (await import("exceljs")).default;
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ಪದLab";
  workbook.subject = "Local Kannada Word Reading assessment export";
  workbook.created = new Date();
  const trialSheet = workbook.addWorksheet("Trials");
  const trialColumns = [
    ["sessionId","Session ID"],["childStudyId","Child Study ID"],["assessorId","Assessor ID"],
    ["visitNo","Visit"],["blockNo","Test Block"],["itemId","Item ID"],["stimulusText","Stimulus"],
    ["itemKind","Item Type"],["phase","Phase"],["trialNo","Trial No"],["response","Response"],
    ["correct","Correct"],["rtMs","Reaction Time (ms)"],["startedAt","Started At"],
    ["respondedAt","Responded At"],["appVersion","App Version"],["bankVersion","Item Bank Version"],
    ["isDemo","Demo Record"]
  ] as const;
  trialSheet.columns = trialColumns.map(([key,header])=>({header,key,width:header.length>16?22:16}));
  for (const trial of trials) {
    const row: Record<string,unknown> = {};
    for (const [key] of trialColumns) row[key] = trial[key as keyof StoredTrial] ?? "";
    trialSheet.addRow(row);
  }
  trialSheet.views = [{state:"frozen",ySplit:1}];
  trialSheet.autoFilter = {from:"A1",to:`R${Math.max(1,trials.length+1)}`};
  const sessionSheet = workbook.addWorksheet("Sessions");
  sessionSheet.columns = [
    {header:"Session ID",key:"sessionId",width:38},{header:"Child Study ID",key:"childStudyId",width:20},
    {header:"Assessor ID",key:"assessorId",width:18},{header:"Visit",key:"visitNo",width:10},
    {header:"Test Block",key:"blockNo",width:12},{header:"Bank Version",key:"bankVersion",width:24},
    {header:"Started At",key:"startedAt",width:26},{header:"Completed At",key:"completedAt",width:26},
    {header:"Status",key:"status",width:18},{header:"Demo",key:"isDemo",width:10}
  ];
  const sessionFilter = filter ? sessions.filter(s=>s.childStudyId.toLocaleLowerCase()===filter) : sessions;
  for (const session of sessionFilter) sessionSheet.addRow(session as LocalSession);
  sessionSheet.views = [{state:"frozen",ySplit:1}];
  const notes = workbook.addWorksheet("Export Info");
  notes.addRows([
    ["Exported at",new Date().toISOString()],
    ["Trial records",trials.length],
    ["Session records",sessionFilter.length],
    ["Filter",filter || "All local records"],
    ["Storage","Exported from this browser's local IndexedDB"],
    ["Research safety","Confirm authorised transfer and retention under the approved study protocol."]
  ]);
  notes.getColumn(1).width=25; notes.getColumn(2).width=95;
  const buffer = await workbook.xlsx.writeBuffer();
  const filename = `padalab-assessment-${timestamp}.xlsx`;
  downloadBlob(new Blob([buffer as BlobPart],{type:"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}),filename);
  return {trials:trials.length,sessions:sessionFilter.length,filename};
}
