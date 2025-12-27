import { useSelector } from "react-redux";

import { selectUser, selectUserInitialized } from "./selectors";

export const useAuth = () => {
  const user = useSelector(selectUser);
  const initialized = useSelector(selectUserInitialized);

  return {
    isAuth: Boolean(user),
    loading: !initialized,
  };
};
