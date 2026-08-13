import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import Accueil from "./pages/Accueil.tsx";
import Login from "./pages/Login.tsx";
import Animate from "./pages/Animate.tsx";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Accueil />} />
        <Route path="/login" element={<Login />} />
        <Route path="/animate" element={<Animate />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
