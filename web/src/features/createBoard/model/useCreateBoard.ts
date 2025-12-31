import { useState } from "react";

import { createBoard } from "@features";

export const useCreateBoard = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const create = async (input: Parameters<typeof createBoard>[0]) => {
    setLoading(true);
    setError(null);
    try {
      await createBoard(input);
    } catch (e) {
      setError("Не удалось создать борд");
      throw e;
    } finally {
      setLoading(false);
    }
  };

  return { create, loading, error };
};
