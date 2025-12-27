import { doc, getDoc } from "firebase/firestore";

import { db } from "@shared";

import type { User } from "@entities";

export async function getUserById(uid: string): Promise<User> {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);

  if (!snap.exists()) {
    throw new Error("User not found");
  }

  return snap.data() as User;
}
