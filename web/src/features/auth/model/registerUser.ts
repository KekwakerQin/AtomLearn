import { FirebaseError } from "firebase/app";
import { doc, setDoc } from "firebase/firestore";
import { createUserWithEmailAndPassword } from "firebase/auth";

import type { User } from "@entities";

import { auth, db, generateUsername, randomAbBucket } from "@shared";

interface RegisterUserInput {
  email: string;
  password: string;
  name: string;
  displayName: string;
}

export async function registerUser(input: RegisterUserInput) {
  try {
    const { email, password, name, displayName } = input;

    const cred = await createUserWithEmailAndPassword(auth, email, password);
    const fbUser = cred.user;

    const now = Date.now();

    const user: User = {
      uid: fbUser.uid,

      name,
      email,
      displayName,
      username: generateUsername(displayName),

      avatarURL: null,

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

    await setDoc(doc(db, "users", fbUser.uid), user);

    return { ok: true, user: fbUser };
  } catch (error) {
    const err = error as FirebaseError;
    return { ok: false, error: err.message, code: err.code };
  }
}
