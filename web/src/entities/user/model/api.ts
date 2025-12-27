import { doc, getDoc } from "firebase/firestore";

import type { User } from "@entities";

import { db } from "@shared";

export async function getUserById(uid: string): Promise<User> {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);

  if (!snap.exists()) {
    throw new Error("User not found");
  }

  return snap.data() as User;
}
