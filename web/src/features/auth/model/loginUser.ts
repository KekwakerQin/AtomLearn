import { FirebaseError } from "firebase/app";
import { doc, updateDoc } from "firebase/firestore";
import { signInWithEmailAndPassword } from "firebase/auth";

import { auth, db } from "@shared";

export async function loginUser(email: string, password: string) {
  try {
    const cred = await signInWithEmailAndPassword(auth, email, password);
    const fbUser = cred.user;

    await updateDoc(doc(db, "users", fbUser.uid), {
      lastSeenAt: Date.now(),
      updatedAt: Date.now(),
    });

    return { ok: true, user: fbUser };
  } catch (error) {
    const err = error as FirebaseError;
    return { ok: false, error: err.message, code: err.code };
  }
}
