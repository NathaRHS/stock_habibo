import "./css/Accueil.css";
import Dashboard from "../components/Dashboard";
import GraphicCard from "../components/GraphicCard";
import Sidebar from "../components/Sidebar";
import ListeSociete from "./ListeSociete";
import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

function Accueil() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [mouvement, setMouvement] = useState([]);
  const [entree, setEntree] = useState([]);
  const [sortie, setSortie] = useState([]);

  const entreeIsa = mouvement.filter(
    (mvt) => mvt.nom_type_mouvement === "ENTREE",
  ).length;
  const sortieIsa = mouvement.filter(
    (mvt) => mvt.nom_type_mouvement === "SORTIE",
  ).length;
  const compterEntreeEtSortie = () => {
    console.log("MOUVV" + mouvement);
  };

  const token = getAccessToken();
  useEffect(() => {
    const charger = async () => {
      await getListeEntrees();
      compterEntreeEtSortie();
    };
    charger();
  }, []);
  const getListeEntrees = async () => {
    try {
      const response = await fetch(`${springUrl}/mouvementStock`, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
      console.log("data" + data[0].date_mouvement);
      setMouvement(data);
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div className="accueil-container">
      <Sidebar />
      <section className="main-section">
        <header className="dashboard-header">
          <p className="dashboard-label">Tableau de bord</p>
          <label className="dashboard-search-wrapper">
            <span className="material-symbols-outlined" aria-hidden="true">
              search
            </span>
            <input
              type="search"
              aria-label="Rechercher"
              placeholder="Rechercher"
            />
          </label>
          <div className="notification-profile-side">
            <button
              className="notification-button"
              type="button"
              aria-label="Notifications"
            >
              <span className="material-symbols-outlined" aria-hidden="true">
                notifications
              </span>
            </button>
            <button className="primary-button" type="button">
              <span className="material-symbols-outlined" aria-hidden="true">
                add
              </span>
              Ajouter
            </button>
          </div>
        </header>

        <main className="dashboard-content">
          <div className="dashboard-title-row">
            <div className="dashboard-introduction">
              <h1>Statistiques générales</h1>
              <p>Statistique réelle sur la situation d’entrée et de sortie</p>
            </div>
            <button
              className="primary-button dashboard-title-action"
              type="button"
            >
              <span className="material-symbols-outlined" aria-hidden="true">
                add
              </span>
              Ajouter un mouvement
            </button>
          </div>

          <section
            className="graphic-card-list"
            aria-label="Statistiques du jour"
          >
            <GraphicCard
              designation="Entrées aujourd’hui"
              valeur_chiffres={entreeIsa}
              valeur_hier={8000}
              valeur_now={1000}
              props_color="var(--color-primary-soft)"
              icon="input"
            />
            <GraphicCard
              designation="Sorties aujourd’hui"
              valeur_chiffres={sortieIsa}
              valeur_hier={18000}
              valeur_now={25000}
              props_color="var(--color-danger-soft)"
              icon="output"
            />
            <GraphicCard
              designation="Total mouvement"
              valeur_chiffres={mouvement.length}
              valeur_hier={10000}
              valeur_now={12000}
              props_color="var(--color-secondary-soft)"
              icon="inventory_2"
            />
          </section>

          <Dashboard />
        </main>
      </section>
    </div>
  );
}

export default Accueil;
