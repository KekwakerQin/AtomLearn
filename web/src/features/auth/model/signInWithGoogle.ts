import { FirebaseError } from "firebase/app";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { signInWithPopup, GoogleAuthProvider } from "firebase/auth";

import type { User } from "@entities";

import {
  getDisplayNameFromEmail,
  generateUsername,
  randomAbBucket,
  auth,
  db,
} from "@shared";

const provider = new GoogleAuthProvider();

export async function signInWithGoogle() {
  try {
    const result = await signInWithPopup(auth, provider);
    const fbUser = result.user;

    const userRef = doc(db, "users", fbUser.uid);
    const snapshot = await getDoc(userRef);

    if (!snapshot.exists()) {
      const now = Date.now();

      const displayName = getDisplayNameFromEmail(fbUser.email);

      const user: User = {
        uid: fbUser.uid,

        name: fbUser.displayName, // ФИО из Google
        email: fbUser.email,
        displayName,
        username: generateUsername(displayName),

        avatarURL: fbUser.photoURL,

        roles: ["user"],

        preferences: {
          uiTheme: "light",
          dailyGoal: 10,
          notifications: {
            email: true,
            push: true,
          },
          studyLang: "en",
        },

        gamification: {
          xp: 0,
          level: 1,
          streakDays: 0,
          lastStreakAt: null,
          badges: [],
        },

        studyStats: {
          cardsLearned: 0,
          reviewsDone: 0,
          avgSessionLen: 0,
        },

        abBucket: randomAbBucket(),

        subscription: {
          tier: "free",
          expiresAt: null,
        },

        devices: [],

        flags: {
          shadowBanned: false,
          aiAccess: false,
        },

        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      };

      await setDoc(userRef, user);
    }

    return { ok: true, user: fbUser };
  } catch (error) {
    const err = error as FirebaseError;
    return { ok: false, message: err.message, code: err.code };
  }
}
