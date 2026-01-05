import {
  doc,
  FirestoreError,
  onSnapshot,
  type Unsubscribe,
} from "firebase/firestore";

import { db, auth } from "@shared";

import type { Board } from "@entities";

type SubscribeBoardParams = {
  boardId: string;
  onSuccess: (board: Board) => void;
  onError?: (error?: string | FirestoreError) => void;
};

export const subscribeBoard = ({
  boardId,
  onSuccess,
  onError,
}: SubscribeBoardParams): Unsubscribe => {
  const ref = doc(db, "boards", boardId);

  const unsubscribe = onSnapshot(
    ref,
    (snap) => {
      if (!snap.exists()) {
        onError?.("Board not found");
        return;
      }

      const data = snap.data();
      const userId = auth.currentUser?.uid;

      if (
        !userId ||
        (data.ownerId !== userId &&
          !data.collaborators?.includes(userId) &&
          data.visibility !== "public")
      ) {
        onError?.("Access denied");
        return;
      }

      onSuccess({
        id: snap.id,
        ...data,
      } as Board);
    },
    (error) => {
      onError?.(error);
    }
  );

  return unsubscribe;
};
