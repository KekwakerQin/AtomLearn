import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

import type { User } from "@entities";

interface UserState {
  data: User | null;
  loading: boolean;
  initialized: boolean;
  error?: string;
}

const initialState: UserState = {
  data: null,
  loading: false,
  initialized: false,
};

const userSlice = createSlice({
  name: "user",
  initialState,
  reducers: {
    userRequested(state) {
      state.loading = true;
      state.error = undefined;
    },
    userReceived(state, action: PayloadAction<User>) {
      state.data = action.payload;
      state.loading = false;
    },
    userRequestFailed(state, action: PayloadAction<string>) {
      state.loading = false;
      state.error = action.payload;
    },
    userCleared(state) {
      state.data = null;
      state.loading = false;
    },
    userInitialized(state) {
      state.initialized = true;
    },
  },
});

export const {
  userRequested,
  userReceived,
  userRequestFailed,
  userCleared,
  userInitialized,
} = userSlice.actions;

export default userSlice.reducer;
