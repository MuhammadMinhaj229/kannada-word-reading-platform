import ExcelJS from "exceljs";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/** Generates an authoring template; it is intentionally NOT an approved stimulus bank. */
export async function GET() {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ಪದLab";
  workbook.subject = "Kannada Word Reading item-bank authoring template";
  workbook.description = "Blank 540 scored-item allocation template. Obtain study team approval before use.";
  const sheet = workbook.addWorksheet("Items");
  sheet.columns = [
    { header:"item_id", key:"item_id", width:22 },
    { header:"item_text", key:"item_text", width:24 },
    { header:"item_type", key:"item_type", width:16 },
    { header:"visit_no", key:"visit_no", width:12 },
    { header:"block_no", key:"block_no", width:12 },
    { header:"order_no", key:"order_no", width:12 },
    { header:"approval_status", key:"approval_status", width:18 },
    { header:"nonword_method", key:"nonword_method", width:20 },
    { header:"reviewer_id", key:"reviewer_id", width:18 },
    { header:"reviewed_at", key:"reviewed_at", width:22 }
  ];
  sheet.getRow(1).font = { bold:true, color:{argb:"FFFFFFFF"} };
  sheet.getRow(1).fill = { type:"pattern", pattern:"solid", fgColor:{argb:"FF173D35"} };
  for (let visit=1; visit<=3; visit++) {
    for (let block=1; block<=2; block++) {
      for (let order=1; order<=90; order++) {
        const itemType = order % 2 === 1 ? "word" : "nonword";
        sheet.addRow({
          item_id:`KWR-V${visit}-B${block}-${String(order).padStart(3,"0")}`,
          item_text:"",
          item_type:itemType,
          visit_no:visit,
          block_no:block,
          order_no:order,
          approval_status:"pending",
          nonword_method:"",
          reviewer_id:"",
          reviewed_at:""
        });
      }
    }
  }
  sheet.views = [{ state:"frozen", ySplit:1, xSplit:1, showGridLines:true }];
  sheet.autoFilter = { from:"A1", to:"J541" };
  const readme = workbook.addWorksheet("Instructions");
  readme.addRows([
    ["Field","Instruction"],
    ["Purpose","Authoring template only. This is not an approved item bank."],
    ["Allocation","3 visits × 2 blocks × 90 scored items = 540 items."],
    ["Balance","Each block contains 45 real words and 45 non-words."],
    ["Order","Alternating type slots are a provisional placeholder. PI/statistician must approve final order/randomisation."],
    ["Practice","Five practice items are intended before each scored block; whether additional to 90 requires PI confirmation."],
    ["Approval","Set approval_status=approved only after documented research-team approval."],
    ["Non-word review","Complete nonword_method, reviewer_id and reviewed_at for every non-word."],
    ["Linguistic quality","The app checks structure and approval metadata; it cannot certify Kannada linguistic validity."],
    ["Data safety","Do not include child names or participant data in this authoring workbook."]
  ]);
  readme.getColumn(1).width = 22;
  readme.getColumn(2).width = 105;
  readme.getRow(1).font = { bold:true, color:{argb:"FFFFFFFF"} };
  readme.getRow(1).fill = { type:"pattern", pattern:"solid", fgColor:{argb:"FF173D35"} };
  const buffer = await workbook.xlsx.writeBuffer();
  return new Response(buffer as BodyInit, {
    status:200,
    headers:{
      "Content-Type":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition":'attachment; filename="kannada-item-bank-template.xlsx"',
      "Cache-Control":"no-store"
    }
  });
}
