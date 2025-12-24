import { useState } from "react";

import { PopUp } from "@widgets/index";

export const BoardsPage = () => {
  const [isOpen, isOpenHandler] = useState(false);

  const onClose = () => {
    isOpenHandler((prev) => !prev);
  };

  return (
    <div>
      <button onClick={onClose}>создать</button>
      <PopUp onClose={onClose} isOpen={isOpen}>
        <h2>Создать</h2>
      </PopUp>
    </div>
  );
};
