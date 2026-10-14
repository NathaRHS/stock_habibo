import { useState } from "react";
import { Outlet } from "react-router-dom";
import { PanelRightClose, PanelRightOpen } from "lucide-react";
import PanneauActivite from "./PanneauActivite";
import "./AvecPanneauActivite.css";

const CLE_REPLIE = "panneauActiviteReplie";

// Lecture tolérante : le stockage du navigateur peut être indisponible.
const lireEtatInitial = () => {
  try {
    return window.localStorage.getItem(CLE_REPLIE) === "1";
  } catch {
    return false;
  }
};

/**
 * Mise en page commune des pages connectées : la page à gauche, le panneau
 * d'activité à droite, repliable. Placée une seule fois dans le routage
 * (main.jsx), elle évite de répéter le panneau dans chaque page. La page de
 * connexion n'en fait pas partie.
 */
function AvecPanneauActivite() {
  const [replie, setReplie] = useState(lireEtatInitial);

  const basculer = () => {
    setReplie((valeur) => {
      const suivante = !valeur;
      try {
        window.localStorage.setItem(CLE_REPLIE, suivante ? "1" : "0");
      } catch {
        // Sans stockage, l'état ne survit simplement pas au rechargement.
      }
      return suivante;
    });
  };

  return (
    <div className="avec-panneau">
      <div className="avec-panneau-page">
        <Outlet />
      </div>

      <div
        className={
          replie ? "avec-panneau-cote avec-panneau-cote--replie" : "avec-panneau-cote"
        }
      >
        <button
          aria-expanded={!replie}
          aria-label={replie ? "Déplier le panneau" : "Replier le panneau"}
          className="avec-panneau-bascule"
          onClick={basculer}
          title={replie ? "Déplier le panneau" : "Replier le panneau"}
          type="button"
        >
          {replie ? (
            <PanelRightOpen size={18} aria-hidden="true" />
          ) : (
            <PanelRightClose size={18} aria-hidden="true" />
          )}
        </button>

        {/* Le panneau charge lui-même ses notifications et ses activités. */}
        <PanneauActivite />
      </div>
    </div>
  );
}

export default AvecPanneauActivite;
