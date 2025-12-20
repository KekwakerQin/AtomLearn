import { Navigate } from "react-router-dom";
import { useAuth } from "@entities";

export const IndexRedirect = () => {
  const { isAuth, loading } = useAuth();

  if (loading) return null;

  return isAuth ? (
    <Navigate to="/profile" replace />
  ) : (
    <Navigate to="/login" replace />
  );
};
