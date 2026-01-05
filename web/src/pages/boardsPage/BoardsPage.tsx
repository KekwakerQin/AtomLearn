import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";

import { CreateBoardPopUp } from "@features";

import { subscribeUserBoards, useAuth, type Board } from "@entities";

import s from "./boardsPage.module.scss";

export const BoardsPage = () => {
  const { userId } = useParams();

  const { user } = useAuth();

  const ownerId = userId ?? user?.uid;

  const [boards, setBoards] = useState<Board[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!ownerId) return;

    const unsubscribe = subscribeUserBoards(ownerId, setBoards);

    return unsubscribe;
  }, [ownerId]);

  if (!user) {
    return null; // Loader
  }

  return (
    <div>
      <button onClick={() => setIsOpen(true)}>создать</button>

      <div className={s.boardsContainer}>
        {boards.map((board) => (
          <div key={board.id} className={s.board}>
            <h4>{board.title}</h4>
            <p>{board.description}</p>
          </div>
        ))}
      </div>

      <CreateBoardPopUp
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        ownerUID={user.uid}
      />
    </div>
  );
};
