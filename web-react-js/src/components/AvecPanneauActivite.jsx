import { Outlet } from "react-router-dom";
import PanneauActivite from "./PanneauActivite";
import "./AvecPanneauActivite.css";

/**
 * Mise en page commune des pages connectées : la page à gauche, le panneau
 * d'activité à droite. Placée une seule fois dans le routage (main.jsx), elle
 * évite de répéter le panneau dans chaque page. La page de connexion n'en
 * fait pas partie.
 */
function AvecPanneauActivite() {
  return (
    <div className="avec-panneau">
      <div className="avec-panneau-page">
        <Outlet />
      </div>
      {/* Les activités viendront du journal d'activité (pas encore enregistré
          côté serveur) : la liste reste vide en attendant. */}
      <PanneauActivite activites={[]} />
    </div>
  );
}

export default AvecPanneauActivite;
