import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";

import { subscribeBoard, useAuth, type Board } from "@entities";

export const BoardPage = () => {
  const { boardId } = useParams<{ boardId: string }>();
  const { user } = useAuth();

  const [board, setBoard] = useState<Board | null>(null);
  const [loading, setLoading] = useState(true);
  const [accessDenied, setAccessDenied] = useState(false);

  useEffect(() => {
    if (!boardId || !user) return;

    const unsubscribe = subscribeBoard({
      boardId,
      onSuccess: (board) => {
        setBoard(board);
        setLoading(false);
      },
      onError: () => {
        setAccessDenied(true);
        setLoading(false);
      },
    });

    return () => unsubscribe();
  }, [boardId, user]);

  if (loading) {
    return <div>Загрузка борда...</div>; //Loader
  }

  if (accessDenied || !board) {
    return <div>Нет доступа или борд не найден</div>; // ошибка
  }

  return (
    <div>
      <h1>{board.title}</h1>
      {board.description && <p>{board.description}</p>}

      <div>
        <strong>Владелец:</strong> {board.ownerUID}
      </div>

      <div>
        <strong>Видимость:</strong> {board.visibility}
      </div>
    </div>
  );
};
