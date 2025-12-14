import { useNavigate } from "react-router-dom";

import { logoutUser } from "@features";

export const LogoutButton = () => {
  const navigate = useNavigate();

  const handleLogout = async () => {
    const res = await logoutUser();
    if (res.ok) {
      navigate("/login");
    } else {
      console.error("Ошибка выхода:", res.error);
    }
  };

  return <button onClick={handleLogout}>Выйти</button>;
};
