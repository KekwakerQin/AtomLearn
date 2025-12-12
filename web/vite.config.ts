import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@app": path.resolve(__dirname, "src/app"),
      "@widgets": path.resolve(__dirname, "src/widgets"),
      "@features": path.resolve(__dirname, "src/features"),
      "@entities": path.resolve(__dirname, "src/entities"),
      "@shared": path.resolve(__dirname, "src/shared"),

      "@assets": path.resolve(__dirname, "src/shared/assets"),
      // "@types": path.resolve(__dirname, "src/shared/types"),
      // "@styles": path.resolve(__dirname, "src/shared/styles"),
    },
  },
});
