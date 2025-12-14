export type UserRole = "user" | "moderator" | "admin";
export type AbBucket = "A" | "B" | "C";
export type SubscriptionTier = "free" | "pro" | "edu";

export interface User {
  uid: string;

  name: string | null;
  email: string | null;
  displayName: string;
  username: string;

  avatarURL: string | null;

  roles: UserRole[];

  preferences: {
    uiTheme: "light" | "dark";
    dailyGoal: number;
    notifications: {
      email: boolean;
      push: boolean;
    };
    studyLang: string;
  };

  gamification: {
    xp: number;
    level: number;
    streakDays: number;
    lastStreakAt: number | null;
    badges: string[];
  };

  studyStats: {
    cardsLearned: number;
    reviewsDone: number;
    avgSessionLen: number;
  };

  abBucket: AbBucket;

  subscription: {
    tier: SubscriptionTier;
    expiresAt: number | null;
  };

  devices: {
    platform: string;
    appVersion: string;
    firstSeen: number;
    lastSeen: number;
  }[];

  flags: {
    shadowBanned: boolean;
    aiAccess: boolean;
  };

  createdAt: number;
  updatedAt: number;
  lastSeenAt: number;
}
