import { Link, Outlet } from "react-router-dom";

export const Layout = () => {
  return (
    <>
      <nav>
        <Link to="/login">Войти</Link>
        <Link to="/register">Регистрация</Link>
      </nav>

      <Outlet />
    </>
  );
};
