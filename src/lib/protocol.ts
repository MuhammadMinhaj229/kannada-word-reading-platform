export const PROTOCOL = {
  visitCount: 3, blocksPerVisit: 2, totalBlocks: 6,
  scoredItemsPerBlock: 90, realWordsPerBlock: 45, nonWordsPerBlock: 45,
  practiceItemsPerBlock: 5, rewardInterval: 5, provisionalResponseWindowMs: 10_000
} as const;
export type ItemKind = "word" | "nonword";
export type TrialPhase = "practice" | "scored";
export interface StimulusItem {
  itemId: string; text: string; itemKind: ItemKind | "invalid";
  visitNo: 1 | 2 | 3; blockNo: 1 | 2; order: number; bankVersion: string;
  approved: boolean; nonwordMethod?: string; reviewerId?: string; reviewedAt?: string;
}
export interface TrialResponse {
  sessionId: string; childStudyId: string; assessorId: string; visitNo: number; blockNo: number;
  itemId: string; stimulusText: string; itemKind: ItemKind; phase: TrialPhase; trialNo: number;
  response: ItemKind | "none"; correct: boolean | null; rtMs: number | null;
  startedAt: string; respondedAt: string; appVersion: string; bankVersion: string; isDemo: boolean;
}
