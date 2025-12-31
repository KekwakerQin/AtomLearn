import { useState } from "react";

import { PopUp } from "@widgets";

import { useCreateBoard } from "@features";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  ownerUID: string;
};

export const CreateBoardPopUp = ({ isOpen, onClose, ownerUID }: Props) => {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [lang, setLang] = useState("en");

  const { create, loading, error } = useCreateBoard();

  const onSubmit = async () => {
    if (!title.trim()) return;

    await create({
      title,
      description,
      ownerUID,
      lang,
    });

    setTitle("");
    setDescription("");
    onClose();
  };

  return (
    <PopUp isOpen={isOpen} onClose={onClose}>
      <h2>Создать борд</h2>

      <input
        placeholder="Название"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />

      <textarea
        placeholder="Описание"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />

      <select value={lang} onChange={(e) => setLang(e.target.value)}>
        <option value="en">English</option>
        <option value="ru">Русский</option>
      </select>

      {error && <p>{error}</p>}

      <button onClick={onSubmit} disabled={loading}>
        {loading ? "Создание..." : "Создать"}
      </button>
    </PopUp>
  );
};
