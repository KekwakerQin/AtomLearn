import { useEffect, useState } from "react";

import { CreateBoardPopUp } from "@features";

import { getUserBoards, useAuth, type Board } from "@entities";

export const BoardsPage = () => {
  const { user } = useAuth();

  const [boards, setBoards] = useState<Board[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!user) return;
    getUserBoards(user.uid).then(setBoards);
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
