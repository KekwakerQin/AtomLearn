import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";

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
        {boards
          .filter(
            (board) =>
              board.ownerUID === user.uid ||
              board.collaboratorUIDs.includes(user.uid) ||
              board.visibility === "public"
          )
          .map((board) => (
            <Link key={board.id} className={s.board} to={`/boards/${board.id}`}>
              <h4>{board.title}</h4>
              <p>{board.description}</p>
            </Link>
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
