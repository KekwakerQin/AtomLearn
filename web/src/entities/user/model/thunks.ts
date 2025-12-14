import type { AppThunk } from "@app";

import {
  userReceived,
  userRequested,
  userRequestFailed,
  getUserById,
} from "@entities";

export const fetchUser =
  (uid: string): AppThunk =>
  async (dispatch) => {
    try {
      dispatch(userRequested());
      const user = await getUserById(uid);
      dispatch(userReceived(user));
    } catch (e) {
      dispatch(userRequestFailed((e as Error).message));
    }
  };
