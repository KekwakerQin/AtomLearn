import { useSelector } from "react-redux";

import { selectUser, selectIsAuth, selectUserLoading } from "./selectors";

export const useAuth = () => {
  const user = useSelector(selectUser);
  const isAuth = useSelector(selectIsAuth);
  const loading = useSelector(selectUserLoading);

  return { user, isAuth, loading };
};
