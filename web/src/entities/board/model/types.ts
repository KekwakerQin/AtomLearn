import { Timestamp } from "firebase/firestore";

export type BoardVisibility = "private" | "unlisted" | "public";

export type LearningIntent = "study" | "teach";
export type RepetitionModel = "fsrs" | "sm2";

export interface BoardCounts {
  cards: number;
  learnableNow: number;
  learners: number;
  reviews: number;
}

export interface BoardLearning {
  intent: LearningIntent;
  repetitionModel: RepetitionModel;
}

export interface BoardRating {
  avg: number;
  count: number;
}

export interface BoardAnalytics {
  createdFromUID?: string;
}

export interface Board {
  id: string;

  title: string;
  description?: string;

  ownerUID: string;

  createdFromUID?: string;

  visibility: BoardVisibility;

  collaboratorUIDs: string[];

  counts: BoardCounts;

  learning: BoardLearning;

  lang: string;

  subject?: string;

  tags: string[];

  shareSlug?: string;

  rating: BoardRating;

  isOfficial: boolean;
  isTemplate: boolean;
  isArchived: boolean;

  analytics?: BoardAnalytics;

  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActivityAt: Timestamp;
}
