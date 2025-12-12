import { createUserWithEmailAndPassword } from "firebase/auth";
import { FirebaseError } from "firebase/app";

import { auth } from "@shared";

export async function registerUser(email: string, password: string) {
  try {
    const userCredential = await createUserWithEmailAndPassword(
      auth,
      email,
      password
    );

    return {
      ok: true,
      user: userCredential.user,
    };
  } catch (error) {
    const err = error as FirebaseError;

    return {
      ok: false,
      error: err.message,
      code: err.code,
    };
  }
}
