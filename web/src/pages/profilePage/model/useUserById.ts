import { useEffect, useState } from "react";

import { getUserById, type User } from "@entities";

export const useUserById = (userId?: string) => {
  const [data, setData] = useState<User | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loading = !!userId && data === null && error === null;

  useEffect(() => {
    if (!userId) return;

    let cancelled = false;

    getUserById(userId)
      .then((user) => {
        if (!cancelled) setData(user);
      })
      .catch(() => {
        if (!cancelled) setError("User not found");
      });

    return () => {
      cancelled = true;
    };
  }, [userId]);

  return { data, loading, error };
};
