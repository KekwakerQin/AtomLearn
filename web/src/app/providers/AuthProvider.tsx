import { useEffect } from "react";

import { onAuthStateChanged } from "firebase/auth";

import { fetchUser, userCleared, userInitialized } from "@entities";

import { auth, useAppDispatch } from "@shared";

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        await dispatch(fetchUser(fbUser.uid));
      } else {
        dispatch(userCleared());
      }

      dispatch(userInitialized());
    });

    return unsubscribe;
  }, [dispatch]);

  return <>{children}</>;
};
