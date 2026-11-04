import Dexie, { type EntityTable } from "dexie";
import type { TrialResponse } from "@/lib/protocol";
export interface LocalSession {
  sessionId: string; childStudyId: string; assessorId: string; visitNo: number; blockNo: number;
  bankVersion: string; startedAt: string; completedAt?: string;
  status: "in_progress" | "completed" | "interrupted"; isDemo: boolean;
}
export interface StoredTrial extends TrialResponse { localId?: number; }
export interface LocalBank {
  bankVersion: string; importedAt: string; itemCount: number;
  approvedBy: string; approvalReference: string; payload: string;
}
class AssessmentDatabase extends Dexie {
  sessions!: EntityTable<LocalSession, "sessionId">;
  trials!: EntityTable<StoredTrial, "localId">;
  banks!: EntityTable<LocalBank, "bankVersion">;
  constructor() {
    super("padalab-local-assessment");
    this.version(1).stores({
      sessions: "&sessionId, childStudyId, assessorId, visitNo, blockNo, status, startedAt",
      trials: "++localId, sessionId, trialNo, itemId, visitNo, blockNo, respondedAt, isDemo",
      banks: "&bankVersion, importedAt"
    });
  }
}
export const localDb = new AssessmentDatabase();
export async function persistTrial(trial: TrialResponse): Promise<void> {
  await localDb.transaction("rw", localDb.trials, async () => { await localDb.trials.add(trial); });
}
export async function saveBank(bank: LocalBank): Promise<void> {
  await localDb.banks.put(bank);
}
