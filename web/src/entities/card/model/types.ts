export type CardStatus = "draft" | "published" | "archived" | "flagged";
export type CardType = "text" | "image" | "audio" | "video" | "mixed";
export type CardSource = "manual" | "ai" | "import";
export type CardVisibility = "private" | "unlisted" | "public";

export interface CardMedia {
  imageURL?: string;
  audioURL?: string;
  thumbURL?: string;
  duration?: number;
}

export interface CardReviewStats {
  correct: number;
  wrong: number;
  lastReviewedAt?: string;
}

export interface SpacedRepetition {
  ease: number;
  interval: number;
  dueAt: string;
}

export interface CardACL {
  visibility: CardVisibility;
  sharedWith: string[];
}

export interface CardSourceInfo {
  type: CardSource;
  sourceRef?: string;
}

export interface Card {
  id: string;

  boardId: string;
  ownerId: string;

  front: string;
  back: string;

  type: CardType;
  language: string;
  tags: string[];

  status: CardStatus;
  difficulty: 1 | 2 | 3 | 4 | 5;
  hints: string[];

  media?: CardMedia;

  createdAt: string;
  updatedAt: string;
  isDeleted: boolean;
  version: number;

  views: number;

  checksum?: string;
  etag?: string;

  source: CardSourceInfo;

  qualityScore?: number;
  reportedCount: number;

  ratingAvg?: number;
  ratingCount?: number;

  reviewStats: CardReviewStats;
  spacedRepetition?: SpacedRepetition;

  acl: CardACL;
}
