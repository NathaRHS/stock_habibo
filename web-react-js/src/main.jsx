import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./index.css";
import Accueil from "./pages/Accueil";
import Login from "./pages/Login";
import Animate from "./pages/Animate";
import CrudElement from "./pages/CrudElement";
import ListeArticle from "./pages/ListeArticle";
import ListeJournal from "./pages/ListeJournal";
import ListeUtilisateur from "./pages/ListeUtilisateur";
import CreateArticle from "./pages/CreateArticle";
import CreateTypeConditionnement from "./pages/CreateTypeConditionnement";
import ListeTypeConditionnement from "./pages/ListeTypeConditionnement";
import ListeArticleConditionnement from "./pages/ListeArticleConditionnement";
import CreateArticleConditionnement from "./pages/CreateArticleConditionnement";
import CreateTypeMouvementJournal from "./pages/CreateTypeMouvementJournal";
import ListeTypeMouvementJournal from "./pages/ListeTypeMouvementJournal";
import UploadFile from "./pages/UploadFile";
import CreateJournal from "./pages/CreateJournal";
import ControleJournal from "./pages/ControleJournal";
import CreateUtilisateur from "./pages/CreateUtilisateur";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        {/* <Route path="/animate" element={<Animate />} /> */}
        {/* <Route path="/crud" element={<CrudElement />} /> */}
        <Route path="/" element={<Login />} />
        <Route path="/accueil" element={<Accueil />} />
        <Route path="/login" element={<Login />} />
        <Route path="/article" element={<ListeArticle />} />
        <Route path="/article/create" element={<CreateArticle />} />
        <Route path="/users" element={<ListeUtilisateur />} />
        <Route path="/users/create" element={<CreateUtilisateur />} />
        <Route path="/type-conditionnement/create" element={<CreateTypeConditionnement />} />
        <Route path="/type-conditionnement" element={<ListeTypeConditionnement />} />
        <Route path="/article-conditionnements" element={<ListeArticleConditionnement />} />
        <Route path="/article-conditionnements/create" element={<CreateArticleConditionnement />} />
        <Route path="/types-mouvements-journal" element={<ListeTypeMouvementJournal />} />
        <Route path="/types-mouvements-journal/create" element={<CreateTypeMouvementJournal />} />
        <Route path="/journaux-mouvements" element={<ListeJournal />} />
        <Route path="/journaux-mouvements/create" element={<CreateJournal />} />
        <Route path="/journaux-mouvements/:id" element={<ControleJournal />} />
        <Route path="/upload" element={<UploadFile />} />

      </Routes>
    </BrowserRouter>
  </StrictMode>,
);


