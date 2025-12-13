import { BrowserRouter, Routes, Route } from "react-router-dom";
import { LoginPage, RegisterPage } from "@pages";
import { Layout } from "@app/layout/Layout";

export const RouterProvider = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route path="login" element={<LoginPage />} />
          <Route path="register" element={<RegisterPage />} />
          {/* <Route path="profile" element={<ProfilePage />} /> */}
        </Route>
      </Routes>
    </BrowserRouter>
  );
};
