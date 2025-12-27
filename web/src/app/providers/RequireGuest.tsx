import { Navigate, Outlet } from "react-router-dom";

import { useAuth } from "@entities";

export const RequireGuest = () => {
  const { isAuth, loading } = useAuth();

  if (loading) {
    return <div>Загрузка...</div>; // Loader
  }

  if (isAuth) {
    return <Navigate to="/profile" replace />;
  }

  return <Outlet />;
};
