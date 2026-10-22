import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { creerRackComplet } from "../services/entrepotService";
import "./css/CreateRack.css";

function CreationRack() {
  const { lastRack } = useParams();
  const [niveaux, setNiveaux] = useState(1);
  const [parNiveau, setParNiveau] = useState(1);
  const prochainNom = lettrePlusUn(lastRack.slice(-1));
  const total = niveaux * parNiveau;
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();
  const [enCours, setEnCours] = useState(false);
  const [erreur, setErreur] = useState("");

  function lettrePlusUn(lettre) {
    return String.fromCharCode(lettre.charCodeAt(0) + 1);
  }

  // Même règle que l'aperçu : D001, D002... réparties par niveau.
  function construireEmplacements() {
    return Array.from({ length: total }, (_, i) => ({
      nomEmplacement: `${prochainNom}${String(i + 1).padStart(3, "0")}`,
      numeroEtage: Math.floor(i / parNiveau) + 1,
    }));
  }

  async function creer(e) {
    e.preventDefault();
    setEnCours(true);
    setErreur("");
    try {
      await creerRackComplet(springUrl, {
        name: `RACK ${prochainNom}`,
        nombreEtages: niveaux,
        emplacements: construireEmplacements(),
      });
      navigate("/rack");
    } catch (err) {
      setErreur(err.message || "Création impossible.");
    } finally {
      setEnCours(false);
    }
  }

  return (
    <>
      <div className="resume">
        <h1>Nom du rack bientôt créé : rack {prochainNom}</h1>
      </div>
      <form onSubmit={creer}>
        <input
          type="number"
          min="1"
          max="20"
          value={niveaux}
          placeholder="nombre de niveau"
          onChange={(e) => setNiveaux(Number(e.target.value))}
        />
        <input
          type="number"
          min="1"
          max="30"
          onChange={(e) => setParNiveau(Number(e.target.value))}
          value={parNiveau}
          placeholder="nombre d'emplacement par niveau"
        />
        <button type="submit" disabled={enCours}>
          {enCours ? "Création…" : "Créer le rack"}
        </button>
        {erreur && <p role="alert">{erreur}</p>}
      </form>
      <div>
        <p>Prévisualisation des racks  : {total}</p>
        <div className="listes" style={{ "--colonnes": parNiveau }}>
          {Array.from({ length: total }, (_, i) => (
            <div className="case" key={i}>
              {prochainNom}
              {String(i + 1).padStart(3, "0")}
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
export default CreationRack;
