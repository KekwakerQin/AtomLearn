import { collection, getDocs, query, where } from "firebase/firestore";

import { db } from "@shared";

import type { Board } from "@entities";

export const getBoardsByCollaborator = async (uid: string) => {
  const q = query(
    collection(db, "boards"),
    where("collaboratorUIDs", "array-contains", uid)
  );

  const snap = await getDocs(q);

  return snap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as Board[];
};
