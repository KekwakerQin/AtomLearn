import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "./index.css";
import { RouterProvider } from "@app";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <RouterProvider />
  </StrictMode>
);
