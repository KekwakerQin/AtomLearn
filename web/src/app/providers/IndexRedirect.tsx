import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "@entities";

export const IndexRedirect = () => {
  const { isAuth, loading } = useAuth();
  const location = useLocation();

  if (location.pathname !== "/") {
    return null;
  }

  if (loading) return null;

  return isAuth ? (
    <Navigate to="/profile" replace />
  ) : (
    <Navigate to="/login" replace />
  );
};
