import { collection, getDocs, query, where } from "firebase/firestore";

import { db } from "@shared";

import type { Board } from "@entities";

export const getBoardsByOwner = async (uid: string) => {
  const q = query(collection(db, "boards"), where("ownerUID", "==", uid));

  const snap = await getDocs(q);

  return snap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as Board[];
};
