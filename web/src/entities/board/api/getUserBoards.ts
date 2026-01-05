import { collection, onSnapshot, query, where, or } from "firebase/firestore";
import { db } from "@shared";
import type { Board } from "@entities";

export const subscribeUserBoards = (
  uid: string,
  cb: (boards: Board[]) => void
) => {
  const q = query(
    collection(db, "boards"),
    or(
      where("ownerUID", "==", uid),
      where("collaboratorUIDs", "array-contains", uid)
    )
  );

  return onSnapshot(q, (snap) => {
    const boards = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Board[];

    cb(boards);
  });
};
