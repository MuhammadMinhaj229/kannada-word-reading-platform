import { ParameterType } from "jspsych";

const info = {
  name: "ldt-choice",
  parameters: {
    stimulusText: { type: ParameterType.STRING, default: undefined },
    itemId: { type: ParameterType.STRING, default: undefined },
    itemKind: { type: ParameterType.STRING, default: undefined },
    phase: { type: ParameterType.STRING, default: "scored" },
    trialNo: { type: ParameterType.INT, default: 1 },
    responseWindowMs: { type: ParameterType.INT, default: 10000 },
    onResponse: { type: ParameterType.FUNCTION, default: undefined },
    onMilestone: { type: ParameterType.FUNCTION, default: undefined },
    scoredCompletedAfterThis: { type: ParameterType.INT, default: 0 },
  },
};

function makeButton(label, className, value) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = className;
  button.textContent = label;
  button.dataset.response = value;
  return button;
}

export default class LdtChoicePlugin {
  static info = info;
  constructor(jsPsych) { this.jsPsych = jsPsych; }

  async trial(displayElement, trial) {
    const frame = document.createElement("section");
    frame.className = "ldt-trial-frame";
    const prompt = document.createElement("p");
    prompt.className = "ldt-trial-prompt";
    prompt.textContent = "ಈ ಪದ ನಿಜವಾದ ಪದವೇ?";
    const stimulus = document.createElement("div");
    stimulus.className = "ldt-trial-stimulus kn-text";
    stimulus.textContent = trial.stimulusText;
    const actions = document.createElement("div");
    actions.className = "ldt-trial-actions";
    const wordButton = makeButton("ಪದ", "ldt-answer ldt-answer-word", "word");
    const nonwordButton = makeButton("ಪದವಲ್ಲ", "ldt-answer ldt-answer-nonword", "nonword");
    actions.append(wordButton, nonwordButton);
    frame.append(prompt, stimulus, actions);
    displayElement.replaceChildren(frame);

    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    const startedAtMs = performance.now();
    const startedAt = new Date().toISOString();
    let timerId;
    const result = await new Promise((resolve) => {
      let settled = false;
      const finish = (response) => {
        if (settled) return;
        settled = true;
        window.clearTimeout(timerId);
        resolve({ response, rtMs: response === "none" ? null : performance.now() - startedAtMs });
      };
      wordButton.addEventListener("click", () => finish("word"), { once: true });
      nonwordButton.addEventListener("click", () => finish("nonword"), { once: true });
      timerId = window.setTimeout(() => finish("none"), trial.responseWindowMs);
    });

    const respondedAt = new Date().toISOString();
    const correct = result.response === "none" ? null : result.response === trial.itemKind;
    const record = {
      itemId: trial.itemId, stimulusText: trial.stimulusText, itemKind: trial.itemKind,
      phase: trial.phase, trialNo: trial.trialNo, response: result.response,
      correct, rtMs: result.rtMs, startedAt, respondedAt,
    };
    await trial.onResponse(record);
    if (trial.phase === "scored" && trial.scoredCompletedAfterThis > 0 && trial.scoredCompletedAfterThis % 5 === 0) {
      await trial.onMilestone(trial.scoredCompletedAfterThis);
    }
    displayElement.replaceChildren();
    return record;
  }
}
