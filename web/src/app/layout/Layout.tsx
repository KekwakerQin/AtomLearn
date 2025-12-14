import { Link, Outlet } from "react-router-dom";
import { useSelector } from "react-redux";

import { LogoutButton } from "@features";

import type { RootState } from "@app";

export const Layout = () => {
  const user = useSelector((state: RootState) => state.user.data);

  return (
    <>
      <nav>
        {user ? (
          <>
            <span>Привет, {user.displayName}</span>
            <LogoutButton />
          </>
        ) : (
          <>
            <Link to="/login">Войти</Link>
            <Link to="/register">Регистрация</Link>
          </>
        )}
      </nav>

      <Outlet />
    </>
  );
};
