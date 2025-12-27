import { configureStore } from "@reduxjs/toolkit";

import { userReducer } from "@entities";

export const store = configureStore({
  reducer: {
    user: userReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export type AppThunk = (
  dispatch: AppDispatch,
  getState: () => RootState
) => Promise<void>;
