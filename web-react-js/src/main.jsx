import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import "./index.css";
import Accueil from "./pages/Accueil";
import Login from "./pages/Login";
import ListeArticle from "./pages/ListeArticle";
import ListeJournal from "./pages/ListeJournal";
import ListeUtilisateur from "./pages/ListeUtilisateur";
import ListeActivite from "./pages/ListeActivite";
import ListeTypeConditionnement from "./pages/ListeTypeConditionnement";
import ListeArticleConditionnement from "./pages/ListeArticleConditionnement";
import CreateTypeMouvementJournal from "./pages/CreateTypeMouvementJournal";
import ListeTypeMouvementJournal from "./pages/ListeTypeMouvementJournal";
import UploadFile from "./pages/UploadFile";
import CreateJournal from "./pages/CreateJournal";
import ControleJournal from "./pages/ControleJournal";
import CreateUtilisateur from "./pages/CreateUtilisateur";
import CreatePaletteConditionnement from "./pages/CreatePaletteConditionnement";
import AffectationStockMine from "./pages/AffectationStockMine";
import RecapitulatifEntreeStock from "./pages/RecapitulatifEntreeStock";
import Inventaire from "./pages/Inventaire";
import ListeInventaire from "./pages/ListeInventaire";
import Recapitulatif from "./pages/Recapitulatif";
import CreateCommande from "./pages/CreateCommande";
import AffectationSortie from "./pages/AffectationSortie";
// import AffectationStock from "./pages/AffectationStock";
// Nouvelles versions en cours de validation (src/new-pages), servies sous /new/...
import NewListeJournal from "./new-pages/ListeJournal/ListeJournal";
import NewAffectationStock from "./new-pages/AffectationStock/AffectationStock";
import NewListeArticle from "./new-pages/ListeArticle/ListeArticle";
import NewProfil from "./new-pages/Profil/Profil";
import NewJournaux from "./new-pages/Journaux/Journaux";
import NewActivites from "./new-pages/Activites/Activites";
import NewListeArticle2 from "./new-pages/ListeArticle2/ListeArticle2";
import NewListeConditionnement2 from "./new-pages/ListeConditionnement2/ListeConditionnement2";
import NewReferentiels from "./new-pages/Referentiels/Referentiels";
import { User } from "lucide-react";
import UserPage from "./pages/UserPage";
import RackView from "./pages/Rackview";
import AvecPanneauActivite from "./components/AvecPanneauActivite";
import FicheProduit from "./pages/FicheProduit";
import GenererBon from "./pages/GenererBon";
import CreationRack from "./pages/CreationRack";
import Referentiels from "./pages/Referentiels";
import ParametrageSuggestion from "./pages/ParametrageSuggestion";
import ReinitialisationMotDePasse from "./pages/ReinitialisationMotDePasse";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        {/* <Route path="/animate" element={<Animate />} /> */}
        {/* <Route path="/crud" element={<CrudElement />} /> */}
        <Route path="/" element={<Login />} />
        <Route path="/rack/create/:lastRack" element={<CreationRack />} />
        <Route path="/login" element={<Login />} />
            <Route
          path="/journaux-mouvements/:journalId/affectation-stock"
          element={<NewAffectationStock />}
        />

        {/* Pages connectées : elles reçoivent toutes le panneau d'activité. */}
        <Route element={<AvecPanneauActivite />}>
        <Route path="/accueil" element={<Accueil />} />
        <Route path="/article" element={<ListeArticle />} />
        <Route
          path="/article/create"
          element={<Navigate to="/article" replace />}
        />
        <Route path="/users" element={<ListeUtilisateur />} />
        <Route path="/activites" element={<ListeActivite />} />
        <Route path="/users/create" element={<CreateUtilisateur />} />
        <Route
          path="/type-conditionnement/create"
          element={<Navigate to="/type-conditionnement" replace />}
        />
        <Route
          path="/type-conditionnement"
          element={<ListeTypeConditionnement />}
        />
        <Route
          path="/article-conditionnements"
          element={<ListeArticleConditionnement />}
        />
        <Route
          path="/article-conditionnements/create"
          element={<Navigate to="/article-conditionnements" replace />}
        />
        <Route
          path="/palettes-conditionnements/create"
          element={<CreatePaletteConditionnement />}
        />
        <Route
          path="/types-mouvements-journal"
          element={<ListeTypeMouvementJournal />}
        />
        <Route
          path="/types-mouvements-journal/create"
          element={<CreateTypeMouvementJournal />}
        />
        <Route path="/journaux-mouvements" element={<NewListeJournal />} />
        <Route path="/journaux-mouvements/create" element={<CreateJournal />} />
        <Route path="/journaux-mouvements/:id" element={<ControleJournal />} />
        <Route path="/inventaire/:id" element={<Inventaire />} />
        <Route path="/inventaires" element={<ListeInventaire />} />
        <Route path="/recapitulatif/:id" element={<Recapitulatif />} />
        <Route path="/createListeArticle/:id" element={<CreateCommande />} />
        <Route path="/sortie/:id" element={<AffectationSortie />} />
        <Route path="/rack" element={<RackView/>} />
        <Route path="/referentiels" element={<Referentiels />} />
        <Route path="/parametrage-suggestion" element={<ParametrageSuggestion />} />
        <Route path="/users/reinitialisation/:id" element={<ReinitialisationMotDePasse />} />

        <Route path="/user/:id" element={<UserPage/>} />

    
        <Route
          path="/journaux-mouvements/:journalId/entree-stock/recapitulatif"
          element={<RecapitulatifEntreeStock />}
        />
        {/* <Route
          path="/journaux-mouvementss/:journalId/affectation-stock"
          element={<AffectationStock />}
        /> */}
        <Route path="/upload" element={<UploadFile />} />

        <Route path="/new/journaux-mouvements" element={<NewListeJournal />} />
        {/* Refonte de la liste des articles (maquette du designer), en test. */}
        <Route path="/new/articles" element={<NewListeArticle />} />
        {/* Refonte du profil (maquette du designer), en test : le sien, ou celui d'un utilisateur. */}
        {/* Refonte de la liste des journaux (maquette du designer), en test. */}
        <Route path="/new/journaux" element={<NewJournaux />} />
        <Route path="/new/activites" element={<NewActivites />} />
        {/* Liste des articles avec la mise en page de la liste des journaux, en test. */}
        <Route path="/new/2/articles" element={<NewListeArticle2 />} />
        <Route path="/new/2/conditionnements" element={<NewListeConditionnement2 />} />
        {/* Refonte des référentiels : menu à gauche, liste à droite, en test. */}
        <Route path="/new/referentiels" element={<NewReferentiels />} />
        <Route path="/new/profil" element={<NewProfil />} />
        <Route path="/new/user/:id" element={<NewProfil />} />
        <Route
          path="/new/journaux-mouvements/:journalId/affectation-stock"
          element={<NewAffectationStock />}
        />

        <Route  path="/ficheProduit/:id" element={<FicheProduit/>}/>
        <Route path="/bons" element={<GenererBon />} />

        </Route>
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
