declare module "@/lib/jspsych/ldt-choice-plugin.js" {
  import type { JsPsych, JsPsychPlugin } from "jspsych";
  type Trial = {
    stimulusText: string; itemId: string; itemKind: "word"|"nonword";
    phase: "practice"|"scored"; trialNo: number; responseWindowMs: number;
    scoredCompletedAfterThis: number;
    onResponse: (result: { itemId:string; stimulusText:string; itemKind:"word"|"nonword";
      phase:"practice"|"scored"; trialNo:number; response:"word"|"nonword"|"none";
      correct:boolean|null; rtMs:number|null; startedAt:string; respondedAt:string; }) => Promise<void>;
    onMilestone: (count:number) => Promise<void>;
  };
  const Plugin: new (jsPsych:JsPsych) => JsPsychPlugin<Trial>;
  export default Plugin;
}
