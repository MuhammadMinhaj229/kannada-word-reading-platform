"use client";

import { useEffect, useRef, useState } from "react";
import { PROTOCOL, type ItemKind, type TrialResponse } from "@/lib/protocol";
import { localDb, persistTrial } from "@/lib/storage/db";
import { parseItemBankWorkbook } from "@/lib/item-bank/import-xlsx";
import { exportLocalTrials } from "@/lib/export/local-export";
import PwaRegistration from "@/components/pwa-registration";

type Screen = "game" | "settings";
type SettingsSection = "session" | "bank" | "audio" | "export" | "protocol";
type Demo = { itemId: string; text: string; itemKind: ItemKind };
type Reward = { count: number; resume: () => void; audioDone: boolean } | null;

const practice: Demo[] = [
  { itemId: "PRACTICE-01", text: "ಮನೆ", itemKind: "word" },
  { itemId: "PRACTICE-02", text: "ಮರ", itemKind: "word" },
  { itemId: "PRACTICE-03", text: "ಹಾಲು", itemKind: "word" },
  { itemId: "PRACTICE-04", text: "ಮಳೆ", itemKind: "word" },
  { itemId: "PRACTICE-05", text: "ನದಿ", itemKind: "word" }
];

// Fictional visual-demo strings only. They are not screened non-words or study stimuli.
const demo: Demo[] = [
  { itemId: "DEMO-01", text: "ಮನೆ", itemKind: "word" },
  { itemId: "DEMO-02", text: "ಲಮನೆ", itemKind: "nonword" },
  { itemId: "DEMO-03", text: "ಮರ", itemKind: "word" },
  { itemId: "DEMO-04", text: "ಕಿರಮ", itemKind: "nonword" },
  { itemId: "DEMO-05", text: "ಹಾಲು", itemKind: "word" },
  { itemId: "DEMO-06", text: "ಪಹೂ", itemKind: "nonword" },
  { itemId: "DEMO-07", text: "ಮಳೆ", itemKind: "word" },
  { itemId: "DEMO-08", text: "ನಲಮ", itemKind: "nonword" },
  { itemId: "DEMO-09", text: "ನದಿ", itemKind: "word" },
  { itemId: "DEMO-10", text: "ಕಿಮನೆ", itemKind: "nonword" }
];

const settingsTabs: { id: SettingsSection; title: string; subtitle: string }[] = [
  { id: "session", title: "Session", subtitle: "Child & assessor" },
  { id: "bank", title: "Item bank", subtitle: "Excel workbook" },
  { id: "audio", title: "Audio", subtitle: "Kannada voice" },
  { id: "export", title: "Data & export", subtitle: "Local records" },
  { id: "protocol", title: "Protocol", subtitle: "Study configuration" }
];

const uid = () => globalThis.crypto?.randomUUID?.() ?? `demo-${Date.now()}-${Math.random().toString(16).slice(2)}`;

function getKannadaVoice(): SpeechSynthesisVoice | undefined {
  if (typeof window === "undefined" || !("speechSynthesis" in window)) return undefined;
  const voices = window.speechSynthesis.getVoices();
  return voices.find((voice) => voice.lang.toLowerCase() === "kn-in")
    ?? voices.find((voice) => voice.lang.toLowerCase().startsWith("kn"));
}

/** Wait briefly because Android/Chrome may populate its voice catalogue asynchronously. */
function waitForKannadaVoice(timeoutMs = 1500): Promise<SpeechSynthesisVoice | undefined> {
  if (typeof window === "undefined" || !("speechSynthesis" in window)) return Promise.resolve(undefined);
  const existing = getKannadaVoice();
  if (existing) return Promise.resolve(existing);

  return new Promise((resolve) => {
    let settled = false;
    const finish = (voice?: SpeechSynthesisVoice) => {
      if (settled || !voice) return;
      settled = true;
      window.clearTimeout(timeoutId);
      window.speechSynthesis.removeEventListener("voiceschanged", onVoicesChanged);
      resolve(voice);
    };
    const onVoicesChanged = () => finish(getKannadaVoice());
    const timeoutId = window.setTimeout(() => {
      if (settled) return;
      settled = true;
      window.speechSynthesis.removeEventListener("voiceschanged", onVoicesChanged);
      resolve(getKannadaVoice());
    }, timeoutMs);

    window.speechSynthesis.addEventListener("voiceschanged", onVoicesChanged);
    onVoicesChanged();
  });
}

/** Browser speech is used only for short instructions and reward cues, never for test stimuli. */
async function speakKannada(text: string): Promise<boolean> {
  if (typeof window === "undefined" || !("speechSynthesis" in window)) return false;
  const voice = getKannadaVoice() ?? await waitForKannadaVoice();
  if (!voice) return false;

  return new Promise((resolve) => {
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.voice = voice;
    utterance.lang = voice.lang || "kn-IN";
    utterance.rate = 0.9;
    utterance.pitch = 1.05;
    utterance.volume = 1;
    utterance.onend = () => resolve(true);
    utterance.onerror = () => resolve(false);
    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
  });
}

export default function AssessmentConsole() {
  const [screen, setScreen] = useState<Screen>("game");
  const [settingsSection, setSettingsSection] = useState<SettingsSection>("session");
  const [running, setRunning] = useState(false);
  const [launching, setLaunching] = useState(false);
  const [finished, setFinished] = useState(false);
  const [gameError, setGameError] = useState("");
  const [phase, setPhase] = useState<"practice" | "scored">("practice");
  const [progress, setProgress] = useState(0);
  const [reward, setReward] = useState<Reward>(null);
  const [studyId, setStudyId] = useState("");
  const [assessorId, setAssessorId] = useState("");
  const [visit, setVisit] = useState("1");
  const [block, setBlock] = useState("1");
  const [notes, setNotes] = useState("");
  const [fileName, setFileName] = useState("");
  const [bankStatus, setBankStatus] = useState("No item bank imported");
  const [bankErrors, setBankErrors] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [exportFilter, setExportFilter] = useState("");
  const [exportBusy, setExportBusy] = useState(false);
  const [exportStatus, setExportStatus] = useState("");
  const [autoAudio, setAutoAudio] = useState(true);
  const [voiceReady, setVoiceReady] = useState(false);
  const [audioNotice, setAudioNotice] = useState("");
  const mount = useRef<HTMLDivElement>(null);
  const sessionId = useRef(uid());

  useEffect(() => {
    const refreshVoice = () => setVoiceReady(Boolean(getKannadaVoice()));
    refreshVoice();
    if (!("speechSynthesis" in window)) return;
    window.speechSynthesis.addEventListener("voiceschanged", refreshVoice);
    return () => window.speechSynthesis.removeEventListener("voiceschanged", refreshVoice);
  }, []);

  const progressMax = phase === "practice" ? 5 : 10;

  async function startDemo() {
    if (!mount.current || running || launching) return;
    setLaunching(true);
    setGameError("");
    setAudioNotice("");

    // Start speech directly from the user's tap, then wait for it to finish before trial 1.
    const instructionAudio = autoAudio
      ? speakKannada("ಆಟಕ್ಕೆ ಸ್ವಾಗತ. ಪರದೆಯ ಮೇಲೆ ಕಾಣಿಸುವ ಪದವನ್ನು ನೋಡಿ. ಇದು ನಿಜವಾದ ಪದವೇ ಅಥವಾ ಪದವಲ್ಲವೇ ಎಂದು ಆಯ್ಕೆಮಾಡಿ. ಮೊದಲು ಅಭ್ಯಾಸ ಮಾಡೋಣ.")
      : Promise.resolve(true);

    try {
      const [{ initJsPsych }, { default: LdtChoicePlugin }] = await Promise.all([
        import("jspsych"),
        import("@/lib/jspsych/ldt-choice-plugin.js")
      ]);

      const audioPlayed = await instructionAudio;
      if (autoAudio && !audioPlayed) {
        setAudioNotice("ಈ ಸಾಧನದಲ್ಲಿ ಕನ್ನಡ ಧ್ವನಿ ಲಭ್ಯವಿಲ್ಲ. ಆಟ ಮುಂದುವರಿಯುತ್ತದೆ; ಧ್ವನಿ ಸೂಚನೆ ಕೇಳಿಸಲಿಲ್ಲ.");
      }

      sessionId.current = uid();
      setRunning(true);
      setFinished(false);
      setProgress(0);
      setPhase("practice");
      setReward(null);

      const jsPsych = initJsPsych({
        display_element: mount.current,
        on_finish: () => {
          setRunning(false);
          setFinished(true);
          if (autoAudio) void speakKannada("ಚೆನ್ನಾಗಿದೆ. ಆಟ ಮುಗಿದಿದೆ.");
        }
      });

      const trial = (item: Demo, index: number, trialPhase: "practice" | "scored") => ({
        type: LdtChoicePlugin,
        stimulusText: item.text,
        itemId: item.itemId,
        itemKind: item.itemKind,
        phase: trialPhase,
        trialNo: index + 1,
        responseWindowMs: PROTOCOL.provisionalResponseWindowMs,
        scoredCompletedAfterThis: trialPhase === "scored" ? index + 1 : 0,
        onResponse: async (result: {
          itemId: string; stimulusText: string; itemKind: ItemKind; phase: "practice" | "scored";
          trialNo: number; response: ItemKind | "none"; correct: boolean | null; rtMs: number | null;
          startedAt: string; respondedAt: string
        }) => {
          const row: TrialResponse = {
            ...result, sessionId: sessionId.current, childStudyId: "DEMO-ONLY", assessorId: "DEMO-ONLY",
            visitNo: 1, blockNo: 1, appVersion: "0.1.0-demo", bankVersion: "DEMO-NOT-APPROVED", isDemo: true
          };
          await persistTrial(row);
          setPhase(trialPhase);
          setProgress(index + 1);
        },
        onMilestone: async (count: number) => new Promise<void>((resolve) => {
          setReward({ count, resume: resolve, audioDone: !autoAudio });
          if (autoAudio) {
            void speakKannada("ಚೆನ್ನಾಗಿದೆ. ನಿಮಗೆ ಒಂದು ಚಿಕ್ಕ ಬಹುಮಾನ.").then(() => {
              setReward((current) => current?.count === count ? { ...current, audioDone: true } : current);
            });
          }
        })
      });

      jsPsych.run([
        ...practice.map((item, index) => trial(item, index, "practice")),
        ...demo.map((item, index) => trial(item, index, "scored"))
      ] as never[]);
    } catch (error) {
      window.speechSynthesis?.cancel();
      setRunning(false);
      setGameError(error instanceof Error ? error.message : "Could not start the demo.");
    } finally {
      setLaunching(false);
    }
  }

  async function runExport(format: "csv" | "xlsx") {
    if (exportBusy) return;
    setExportBusy(true);
    setExportStatus("");
    try {
      const result = await exportLocalTrials(format, exportFilter);
      setExportStatus(`Downloaded ${result.filename} · ${result.trials} trial records · original local records retained.`);
    } catch (error) {
      setExportStatus(error instanceof Error ? error.message : "Export failed. Local records were not deleted.");
    } finally {
      setExportBusy(false);
    }
  }

  async function importBank(file?: File) {
    if (!file) return;
    setFileName(file.name);
    setBankErrors([]);
    setBusy(true);
    setBankStatus("Validating workbook…");
    try {
      const result = await parseItemBankWorkbook(file);
      setBankErrors(result.errors.slice(0, 15));
      if (!result.valid) {
        setBankStatus(`Rejected — ${result.errors.length} issue(s)`);
        return;
      }
      await localDb.banks.put({
        bankVersion: result.bankVersion,
        importedAt: new Date().toISOString(),
        itemCount: result.items.length,
        approvedBy: "Reviewer approval metadata supplied in workbook; not independently verified",
        approvalReference: result.bankVersion,
        payload: JSON.stringify(result.items)
      });
      setBankStatus(`Accepted locally · ${result.items.length} items · ${result.bankVersion}`);
    } catch (error) {
      setBankStatus("Could not read workbook");
      setBankErrors([error instanceof Error ? error.message : "Unknown parsing error"]);
    } finally {
      setBusy(false);
    }
  }

  async function testAudio() {
    if (!autoAudio) {
      setAudioNotice("Automatic voice instructions are switched off.");
      return;
    }
    setAudioNotice("ಕನ್ನಡ ಧ್ವನಿಯನ್ನು ಪರೀಕ್ಷಿಸಲಾಗುತ್ತಿದೆ…");
    const played = await speakKannada("ನಮಸ್ಕಾರ. ಆಟಕ್ಕೆ ಸ್ವಾಗತ. ಮೊದಲು ಅಭ್ಯಾಸ ಮಾಡೋಣ.");
    setAudioNotice(played
      ? "ಕನ್ನಡ ಧ್ವನಿ ಸಿದ್ಧವಾಗಿದೆ. ಆಟ ಆರಂಭಿಸಿದಾಗ ಸೂಚನೆಗಳು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಕೇಳಿಸುತ್ತವೆ."
      : "ಈ ಸಾಧನದ ಬ್ರೌಸರ್‌ನಲ್ಲಿ ಕನ್ನಡ ಧ್ವನಿ ಲಭ್ಯವಿಲ್ಲ. ಅನುಮೋದಿತ ಕನ್ನಡ ಧ್ವನಿ ಕಡತಗಳನ್ನು ಸೇರಿಸುವ ಅಗತ್ಯವಿದೆ.");
  }

  const sectionTitle = settingsTabs.find((tab) => tab.id === settingsSection)?.title ?? "Settings";

  return (
    <>
      <a className="skip-link" href="#main-content">Skip to content</a>
      <main className={running ? "shell is-playing" : "shell"}>
        <aside className="sidebar">
          <div className="brand">
            <span className="brand-mark">ಪ</span>
            <div><b>ಪದ<span>Lab</span></b><small>KANNADA WORD READING</small></div>
          </div>
          <div className="study-tag">● PHFI · CDLR <small>REVIEW BUILD</small></div>
          <p className="nav-title">APP</p>
          <nav aria-label="Main navigation">
            <button type="button" onClick={() => setScreen("game")} aria-current={screen === "game" ? "page" : undefined} className={screen === "game" ? "nav active" : "nav"}>
              <i aria-hidden="true">✳</i><span>Game<small>ಆಟ</small></span>
            </button>
            <button type="button" onClick={() => { setScreen("settings"); setSettingsSection("session"); }} aria-current={screen === "settings" ? "page" : undefined} className={screen === "settings" ? "nav active" : "nav"}>
              <i aria-hidden="true">⚙</i><span>Settings<small>ಸೆಟ್ಟಿಂಗ್‌ಗಳು</small></span>
            </button>
          </nav>
          <div className="sidebar-bottom"><b>Offline-first</b><small>Local tablet storage</small><p>Assessor workspace · Demo only</p></div>
        </aside>

        <section className="main">
          <header>
            <span>ಪದLab　/　<b>{screen === "game" ? "Game" : sectionTitle}</b></span>
            <div><label className="demo-tag">● DEMO DATA ONLY</label><PwaRegistration sessionActive={running} /></div>
          </header>

          {screen === "game" && (
            <div className="content game-home" id="main-content">
              <section className="game-hero" lang="kn-IN">
                <div className="game-hero-copy">
                  <span className="game-kicker">ಕನ್ನಡ ಪದ ಓದು · ಪದLab</span>
                  <h1>ಪದಗಳ ಆಟಕ್ಕೆ <em>ಸ್ವಾಗತ!</em></h1>
                  <p>ಪರದೆಯ ಮೇಲೆ ಒಂದು ಪದ ಕಾಣಿಸುತ್ತದೆ. ಅದು ನಿಜವಾದ ಪದವೇ ಅಥವಾ ಪದವಲ್ಲವೇ ಎಂದು ಆಯ್ಕೆಮಾಡಿ.</p>
                  <div className="game-hero-actions">
                    <button className="game-start" type="button" disabled={launching} onClick={() => void startDemo()}>
                      {launching ? "ಆಟ ಸಿದ್ಧವಾಗುತ್ತಿದೆ…" : "ಆಟ ಪ್ರಾರಂಭಿಸಿ　→"}
                    </button>
                    <span className="voice-pill"><i />{autoAudio ? (voiceReady ? "ಕನ್ನಡ ಧ್ವನಿ ಸಿದ್ಧ" : "ಧ್ವನಿ ಲಭ್ಯತೆ ಪರಿಶೀಲನೆ") : "ಧ್ವನಿ ಆಫ್"}</span>
                  </div>
                  {audioNotice && <p className="audio-notice" role="status">{audioNotice}</p>}
                  {gameError && <p className="warning" role="alert">{gameError}</p>}
                  <p className="game-demo-note">ಇದು ಮಾದರಿ ಆಟ ಮಾತ್ರ. ಸಂಶೋಧನಾ ಅಧ್ಯಯನಕ್ಕಾಗಿ ಬಳಸಬೇಡಿ.</p>
                </div>
                <div className="game-hero-art" aria-hidden="true">
                  <div className="orbit orbit-one">⭐</div><div className="orbit orbit-two">🍭</div>
                  <div className="hero-word-card"><small>ಇಂದಿನ ಆಟ</small><strong>ಮನೆ</strong><span>ನಿಜವಾದ ಪದವೇ?</span></div>
                  <div className="hero-sparkle sparkle-one">✦</div><div className="hero-sparkle sparkle-two">✧</div>
                  <div className="hero-character">😊</div>
                </div>
              </section>

              <div className="game-benefits">
                <article><span>01</span><b>ನೋಡಿ</b><small>ಪದವನ್ನು ಗಮನಿಸಿ</small></article>
                <article><span>02</span><b>ಆಯ್ಕೆಮಾಡಿ</b><small>ಪದ ಅಥವಾ ಪದವಲ್ಲ</small></article>
                <article><span>03</span><b>ನಕ್ಷತ್ರ ಗಳಿಸಿ</b><small>ಪ್ರತಿ ಐದು ಉತ್ತರಗಳ ನಂತರ</small></article>
              </div>

              <section className="game-stage-wrap">
                <div className="game-stage-intro">
                  <div><label>READY WHEN YOU ARE</label><h2>ಆಟಕ್ಕೆ ಸಿದ್ಧವೇ?</h2><p>ಮೊದಲು ಅಭ್ಯಾಸದ ಪದಗಳು ಬರುತ್ತವೆ. ಸೂಚನೆಗಳನ್ನು ಆಟ ಆರಂಭಿಸುವಾಗ ಧ್ವನಿಯಾಗಿ ಕೇಳಿಸುತ್ತೇವೆ.</p></div>
                  <div className="stage-decor" aria-hidden="true">🎈　⭐　🧁</div>
                </div>
                <section className="game-stage">
                  <div className="stage-top"><b>ಕನ್ನಡ ಪದ ಓದು</b><span>DEMO MODE · NOT FOR PARTICIPANTS</span></div>
                  {running && (
                    <div className="game-progress" role="group" aria-label="Assessment progress">
                      <div><span>{phase === "practice" ? "ಅಭ್ಯಾಸ (Practice)" : "ಪರೀಕ್ಷೆ (Test)"}</span><b>{progress} / {progressMax}</b></div>
                      <div className="bar" role="progressbar" aria-label="Trial progress" aria-valuemin={0} aria-valuemax={progressMax} aria-valuenow={progress}>
                        <i style={{ width: `${progress / progressMax * 100}%` }} />
                      </div>
                    </div>
                  )}
                  <div className="game-mount" ref={mount}>
                    {!running && !finished && (
                      <div className="game-intro" lang="kn-IN">
                        <div className="collectibles" aria-hidden="true">🧁　⭐　🍫</div>
                        <h2>ಆಟ ಆಡಲು ಸಿದ್ಧವೇ?</h2>
                        <p>ಮೊದಲು 5 ಅಭ್ಯಾಸ ಪದಗಳು. ನಂತರ ಚಿಕ್ಕ ಮಾದರಿ ಪರೀಕ್ಷೆ.</p>
                        <button className="primary" type="button" disabled={launching} onClick={() => void startDemo()}>
                          {launching ? "ಲೋಡ್ ಆಗುತ್ತಿದೆ…" : "ಆಟ ಪ್ರಾರಂಭಿಸಿ (Start demo) →"}
                        </button>
                      </div>
                    )}
                    {finished && (
                      <div className="game-intro" lang="kn-IN">
                        <div className="collectibles" aria-hidden="true">🧁　⭐　🍫</div>
                        <h2>ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದೀರಿ!</h2><p>ಮಾದರಿ ಆಟ ಮುಗಿದಿದೆ. (Demo complete.)</p>
                        <button className="primary" type="button" onClick={() => void startDemo()}>ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ</button>
                      </div>
                    )}
                  </div>
                  <footer>ಒಂದು ಸಮಯದಲ್ಲಿ ಒಂದು ಪದ · ಸರಿಯಾದ ಉತ್ತರಕ್ಕೆ ಬಹುಮಾನ ಅವಲಂಬಿತವಲ್ಲ</footer>
                </section>
              </section>
              {reward && (
                <div className="reward-layer">
                  <div className="reward-card" role="dialog" aria-modal="true" aria-labelledby="reward-title" lang="kn-IN">
                    <strong>{reward.count % 3 === 0 ? "🧁" : reward.count % 2 === 0 ? "🍫" : "⭐"}</strong>
                    <h2 id="reward-title">ಚೆನ್ನಾಗಿದೆ!</h2><p>ಚಿಕ್ಕ ಬಹುಮಾನ! · You completed {reward.count} demo items.</p>
                    <button className="primary" type="button" disabled={!reward.audioDone} onClick={() => { const resume = reward.resume; setReward(null); resume(); }}>{reward.audioDone ? "ಮುಂದುವರಿಸಿ →" : "ಧ್ವನಿ ಕೇಳಿ… "}</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {screen === "settings" && (
            <div className="content settings-page" id="main-content">
              <div className="settings-heading"><div><label>ASSESSOR WORKSPACE</label><h1>Settings & configuration</h1><p>Everything needed to prepare, run and export a session is organised here.</p></div></div>
              <nav className="settings-tabs" aria-label="Settings sections">
                {settingsTabs.map((tab) => (
                  <button key={tab.id} type="button" aria-current={settingsSection === tab.id ? "page" : undefined}
                    className={settingsSection === tab.id ? "settings-tab active" : "settings-tab"}
                    onClick={() => setSettingsSection(tab.id)}>
                    <b>{tab.title}</b><small>{tab.subtitle}</small>
                  </button>
                ))}
              </nav>

              {settingsSection === "session" && (
                <section className="panel form settings-panel">
                  <label>01 · SESSION SETUP</label><h2>Assessment setup</h2>
                  <p>Enter the study identifiers and select the current visit and block before the approved participant workflow is enabled.</p>
                  <div className="fields">
                    <label>Child study ID<input value={studyId} onChange={(event) => setStudyId(event.target.value)} placeholder="KWR-0001" /></label>
                    <label>Assessor ID<input value={assessorId} onChange={(event) => setAssessorId(event.target.value)} placeholder="ASR-003" /></label>
                    <label>Visit<select value={visit} onChange={(event) => setVisit(event.target.value)}><option value="1">Visit 1</option><option value="2">Visit 2</option><option value="3">Visit 3</option></select></label>
                    <label>Test block<select value={block} onChange={(event) => setBlock(event.target.value)}><option value="1">Test 1 · 90 items</option><option value="2">Test 2 · 90 items</option></select></label>
                    <label className="wide">Assessor notes<textarea rows={4} value={notes} onChange={(event) => setNotes(event.target.value)} placeholder="Session context, interruptions or technical notes" /></label>
                  </div>
                  <p className="warning">These fields are currently a setup preview. They are not yet connected to a full participant-session record. The current Game tab remains a demo.</p>
                </section>
              )}

              {settingsSection === "bank" && (
                <section className="panel form settings-panel">
                  <label>02 · STIMULUS MANAGEMENT</label><h2>Import approved item bank</h2>
                  <p>Upload the study team&apos;s final workbook. It is validated and stored only in this browser.</p>
                  <div className="bank-summary"><b>540</b><span>planned items</span><b>6</b><span>blocks</span><b>45 + 45</b><span>words / non-words per block</span></div>
                  <a className="secondary" href="/templates/kannada-item-bank-template.xlsx" download>Download Excel template ↓</a>
                  <label className="upload">Select approved .xlsx workbook<input type="file" accept=".xlsx" onChange={(event) => void importBank(event.target.files?.[0])} /></label>
                  {fileName && <p role="status" aria-live="polite">{fileName} · {busy ? "Checking…" : bankStatus}</p>}
                  {bankErrors.length > 0 && <ul className="errors">{bankErrors.map((error, index) => <li key={index}>{error}</li>)}</ul>}
                  <p className="warning">Structural validation does not prove a non-word is linguistically invalid. Native Kannada reviewer approval must be genuine and documented. Imported item banks are not yet used by the demo game.</p>
                </section>
              )}

              {settingsSection === "audio" && (
                <section className="panel form settings-panel">
                  <label>03 · VOICE & AUDIO</label><h2>Automatic Kannada instructions</h2>
                  <p>Short instructions and reward messages can be spoken automatically. The voice comes from the Kannada speech engine installed on this device.</p>
                  <div className="audio-setting-row">
                    <div><b>Automatic voice instructions</b><small>Welcome instructions, reward cues and completion message</small></div>
                    <label className="switch-label"><input aria-label="Automatic voice instructions" type="checkbox" checked={autoAudio} onChange={(event) => setAutoAudio(event.target.checked)} /><span>{autoAudio ? "On" : "Off"}</span></label>
                  </div>
                  <div className={voiceReady ? "voice-status available" : "voice-status unavailable"}>
                    <i />{voiceReady ? "A Kannada voice is available on this device." : "No Kannada voice detected yet on this device."}
                  </div>
                  <button className="primary audio-test" type="button" disabled={!autoAudio} onClick={() => void testAudio()}>Test Kannada voice</button>
                  {audioNotice && <p className="audio-notice" role="status">{audioNotice}</p>}
                  <p className="warning">Important: device speech synthesis is a preview fallback, not an approved native female recording. Add the study-approved female Kannada audio files before field use. No voice is played over scored stimuli; stimulus audio could alter reading and reaction-time measurements.</p>
                </section>
              )}

              {settingsSection === "export" && (
                <section className="panel export-panel settings-panel">
                  <label>04 · LOCAL DATA</label><h2>Reports & export</h2>
                  <p>Files are generated inside this browser. Nothing is uploaded and exporting never deletes local records.</p>
                  <label className="export-filter">Optional child study ID filter<input value={exportFilter} onChange={(event) => setExportFilter(event.target.value)} placeholder="Leave blank to export all local records" /></label>
                  <div className="export-actions">
                    <button type="button" className="primary" disabled={exportBusy} onClick={() => void runExport("xlsx")}>{exportBusy ? "Preparing…" : "Download Excel workbook"}</button>
                    <button type="button" className="secondary" disabled={exportBusy} onClick={() => void runExport("csv")}>Download trial CSV</button>
                  </div>
                  {exportStatus && <p className="export-status" role="status" aria-live="polite">{exportStatus}</p>}
                  <div className="stats mini"><article><strong>Local</strong><small>IndexedDB storage</small></article><article><strong>XLSX</strong><small>Trials + sessions</small></article><article><strong>CSV</strong><small>UTF-8 with BOM</small></article></div>
                  <p className="warning">The current Game tab exports synthetic demo records only. Full participant/session workflow and approved REDCap field mapping are still pending. Do not use demo exports as study data.</p>
                </section>
              )}

              {settingsSection === "protocol" && (
                <section className="panel settings-panel">
                  <label>05 · STUDY CONFIGURATION</label><h2>Research protocol reference</h2>
                  <div className="protocol-grid">
                    <article><b>03</b><span>Visits per child</span></article><article><b>06</b><span>Blocks per child</span></article>
                    <article><b>90</b><span>Scored items per block</span></article><article><b>45 / 45</b><span>Words / non-words per block</span></article>
                  </div>
                  <ul className="protocol-list">
                    <li>540 scored items in total: 270 real words and 270 non-words.</li>
                    <li>Reward every five completed scored responses, independent of correctness.</li>
                    <li>Five practice items are proposed before each block. Confirm with the PI whether they are additional to the 90 scored items.</li>
                    <li>REDCap remains the study&apos;s main data system. This app stores trial data locally and exports files for the approved REDCap workflow.</li>
                    <li>No cloud database is required for the current design.</li>
                  </ul>
                  <p className="warning">The live item bank, full 90-trial blocks, session locking/recovery, approved Kannada female recordings, REDCap mapping and real-tablet validation are not yet complete.</p>
                </section>
              )}
            </div>
          )}
        </section>
        <footer className="app-footer">ಪದLab · Research assessment prototype · No live participant data · Build 0.2.0</footer>
      </main>
    </>
  );
}
