import { auth } from "./config";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";

export const firebaseAuthApi = {
  signup: (email: string, password: string) =>
    createUserWithEmailAndPassword(auth, email, password),

  signin: (email: string, password: string) =>
    signInWithEmailAndPassword(auth, email, password),

  logout: () => signOut(auth),
};
