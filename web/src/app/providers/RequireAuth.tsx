import { Navigate, Outlet } from "react-router-dom";

import { useAuth } from "@entities";

export const RequireAuth = () => {
  const { isAuth, loading } = useAuth();

  if (loading) {
    return <div>Загрузка...</div>; // Loader
  }

  if (!isAuth) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};
