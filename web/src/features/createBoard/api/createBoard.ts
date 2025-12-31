import { addDoc, collection, serverTimestamp } from "firebase/firestore";

import { db } from "@shared";

import type { Board } from "@entities";

type CreateBoardInput = {
  title: string;
  description?: string;
  ownerUID: string;
  lang: string;
};

export const createBoard = async ({
  title,
  description,
  ownerUID,
  lang,
}: CreateBoardInput): Promise<Board> => {
  const ref = await addDoc(collection(db, "boards"), {
    title: title,
    description: description ?? "",

    ownerUID: ownerUID,
    createdFromUID: ownerUID,

    visibility: "private",

    collaboratorUIDs: [],

    counts: {
      cards: 0,
      learnableNow: 0,
      learners: 1,
      reviews: 0,
    },

    learning: {
      intent: "study",
      repetitionModel: "fsrs",
    },

    lang: lang,

    tags: [],
    rating: {
      avg: 0,
      count: 0,
    },

    isOfficial: false,
    isTemplate: false,
    isArchived: false,

    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    lastActivityAt: serverTimestamp(),
  });

  return {
    id: ref.id,
    title,
    description,
    ownerUID,
    lang,
  } as Board;
};
