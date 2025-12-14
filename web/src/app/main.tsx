import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { RouterProvider } from "@app";

import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <RouterProvider />
  </StrictMode>
);
