import { useEffect, useState } from "react";

import { CreateBoardPopUp } from "@features";

import { subscribeUserBoards, useAuth, type Board } from "@entities";

export const BoardsPage = () => {
  const { user } = useAuth();

  const [boards, setBoards] = useState<Board[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!user) return;

    const unsubscribe = subscribeUserBoards(user.uid, setBoards);

    return unsubscribe;
  }, [user]);

  if (!user) {
    return null; // Loader
  }

  return (
    <div>
      <button onClick={() => setIsOpen(true)}>создать</button>

      <ul>
        {boards.map((board) => (
          <li key={board.id}>{board.title}</li>
        ))}
      </ul>

      <CreateBoardPopUp
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        ownerUID={user.uid}
      />
    </div>
  );
};
