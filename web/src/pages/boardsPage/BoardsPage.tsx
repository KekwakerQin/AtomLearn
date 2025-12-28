import { useEffect, useState } from "react";
import { getUserBoards, useAuth, type Board } from "@entities";
import { PopUp } from "@widgets";

export const BoardsPage = () => {
  const { user } = useAuth();
  const [boards, setBoards] = useState<Board[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (!user) return;

    getUserBoards(user.uid).then(setBoards);
  }, [user]);

  return (
    <div>
      <button onClick={() => setIsOpen(true)}>создать</button>

      <ul>
        {boards.map((board) => (
          <li key={board.id}>{board.title}</li>
        ))}
      </ul>

      <PopUp isOpen={isOpen} onClose={() => setIsOpen(false)}>
        <h2>Создать</h2>
      </PopUp>
    </div>
  );
};
