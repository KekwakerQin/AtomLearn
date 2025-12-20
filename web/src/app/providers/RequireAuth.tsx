import { Navigate, Outlet } from "react-router-dom";

import { useAuth } from "@entities";

export const RequireAuth = () => {
  const { isAuth, loading } = useAuth();

  if (loading) return null;

  if (!isAuth) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};
