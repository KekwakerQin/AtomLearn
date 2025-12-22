import React from "react";

import s from "./popUp.module.scss";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
};

export const PopUp = ({ isOpen, onClose, children }: Props) => {
  if (!isOpen) return null;

  return (
    <div className={s.overlay} onClick={onClose}>
      <div className={s.container} onClick={(e) => e.stopPropagation()}>
        <button className={s.close} onClick={onClose}>
          X
        </button>
        {children}
      </div>
    </div>
  );
};
