import { doc, setDoc, getDoc } from "firebase/firestore";

import { db } from "@shared";

export const firebaseFirestoreApi = {
  set: <T extends object>(collection: string, id: string, data: T) =>
    setDoc(doc(db, collection, id), data),

  get: async (collection: string, id: string) => {
    const snap = await getDoc(doc(db, collection, id));
    return snap.data();
  },
};
