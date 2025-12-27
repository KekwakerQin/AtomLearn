import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";

import { auth } from "@shared";

export const firebaseAuthApi = {
  signup: (email: string, password: string) =>
    createUserWithEmailAndPassword(auth, email, password),

  signin: (email: string, password: string) =>
    signInWithEmailAndPassword(auth, email, password),

  logout: () => signOut(auth),
};
