import { BrowserRouter, Routes, Route } from "react-router-dom";

import { IndexRedirect, Layout, RequireAuth, RequireGuest } from "@app";

import {
  BoardPage,
  BoardsPage,
  LoginPage,
  ProfilePage,
  RegisterPage,
} from "@pages";

export const RouterProvider = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<IndexRedirect />} />

          <Route element={<RequireGuest />}>
            <Route path="login" element={<LoginPage />} />
            <Route path="register" element={<RegisterPage />} />
          </Route>

          <Route element={<RequireAuth />}>
            <Route path="profile" element={<ProfilePage />} />
            <Route path="profile/:profileId" element={<ProfilePage />} />
            <Route path="boards" element={<BoardsPage />} />
            <Route path="boards/:boardsId" element={<BoardPage />} />
            {/*  <Route path="cards/:cardId" element={<CardPage />} /> */}
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
};
