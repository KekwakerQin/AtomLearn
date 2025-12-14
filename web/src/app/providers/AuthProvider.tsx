import { useEffect } from "react";

import { onAuthStateChanged } from "firebase/auth";

import { fetchUser, userCleared } from "@entities";

import { auth, useAppDispatch } from "@shared";

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (fbUser) => {
      if (fbUser) {
        dispatch(fetchUser(fbUser.uid));
      } else {
        dispatch(userCleared());
      }
    });

    return unsubscribe;
  }, [dispatch]);

  return <>{children}</>;
};
