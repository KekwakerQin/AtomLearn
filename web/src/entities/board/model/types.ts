export type BoardVisibility = "private" | "unlisted" | "public";
export type BoardRole = "editor" | "viewer";

export interface BoardCollaborator {
  uid: string;
  role: BoardRole;
}

export interface BoardCounts {
  cards: number;
  learners: number;
  reviews: number;
}

export interface BoardRating {
  ratingAvg?: number;
  ratingCount?: number;
}

export interface Board {
  id: string;

  title: string;
  description?: string;

  ownerUID: string;

  createdAt: string;
  lastActivityAt?: string;

  visibility: BoardVisibility;

  collaborators: BoardCollaborator[];

  category?: string;
  subject?: string;
  level?: string;

  coverURL?: string;
  profilePictures?: string[];

  lang: string;

  counts: BoardCounts;

  ratingAvg?: number;
  ratingCount?: number;

  tags: string[];

  shareSlug?: string;

  pinRank?: number;

  isOfficial: boolean;
}
