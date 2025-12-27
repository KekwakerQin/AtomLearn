import { signOut } from "firebase/auth";

import { auth } from "@shared";

export async function logoutUser() {
  try {
    await signOut(auth);
    return { ok: true };
  } catch (e) {
    return { ok: false, error: (e as Error).message };
  }
}
