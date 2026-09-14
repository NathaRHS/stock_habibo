import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import Sidebar from "../components/Sidebar";
import { chargerJournauxInventaire } from "../services/inventaireService";
import "./css/ListeInventaire.css";

function ListeInventaire() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [journaux, setJournaux] = useState([]);
  const [recherche, setRecherche] = useState("");
  const [statutSelectionne, setStatutSelectionne] = useState("TOUS");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function recupererJournaux() {
      try {
        const data = await chargerJournauxInventaire(springUrl);
        setJournaux(data);
      } catch (erreur) {
        setError(erreur.message);
      } finally {
        setLoading(false);
      }
    }

    recupererJournaux();
  }, [springUrl]);

  // On garde uniquement les journaux dont le type est INVENTAIRE.
  const journauxInventaire = journaux.filter(
    (journal) => journal.typeMouvementJournal === "INVENTAIRE",
  );

  // Ces listes servent aux indicateurs affichés en haut de la page.
  const inventairesEnCours = journauxInventaire.filter(
    (journal) => journal.statut === "EN COURS",
  );
  const inventairesEnAttente = journauxInventaire.filter(
    (journal) => journal.statut === "EN ATTENTE",
  );
  const inventairesValides = journauxInventaire.filter(
    (journal) => journal.statut === "VALIDE",
  );
  const inventairesModifies = journauxInventaire.filter(
    (journal) => journal.statut === "MODIFIE",
  );

  // Filtrage simple par statut et par référence.
  const journauxAffiches = journauxInventaire.filter((journal) => {
    const correspondAuStatut =
      statutSelectionne === "TOUS" || journal.statut === statutSelectionne;

    const reference = journal.reference?.toLowerCase() || "";
    const correspondARecherche = reference.includes(recherche.toLowerCase());

    return correspondAuStatut && correspondARecherche;
  });

  function calculerQuantiteComptee(journal) {
    let total = 0;

    for (const detail of journal.details || []) {
      total = total + (detail.quantite || 0);
    }

    return total;
  }

  function libelleAction(statut) {
    if (statut === "EN COURS") return "Suivre le comptage";
    if (statut === "EN ATTENTE") return "Contrôler";
    if (statut === "MODIFIE") return "Reprendre le contrôle";
    return "Voir le résumé";
  }

  function classeStatut(statut) {
    if (statut === "VALIDE") return "inventaire-status-success";
    if (statut === "MODIFIE") return "inventaire-status-danger";
    if (statut === "EN ATTENTE") return "inventaire-status-warning";
    return "inventaire-status-progress";
  }

  return (
    <div className="inventaire-page-container">
      <Sidebar />

      <section className="inventaire-main-section">
        <header className="inventaire-topbar">
          <p>Opérations / Inventaires</p>

          <label className="inventaire-topbar-search">
            <span className="material-symbols-outlined">search</span>
            <input
              onChange={(event) => setRecherche(event.target.value)}
              placeholder="Rechercher une référence"
              type="search"
              value={recherche}
            />
          </label>

          <div className="inventaire-user">
            <span className="inventaire-avatar">AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="inventaire-content">
          <header className="inventaire-heading">
            <div>
              <h1>Sessions d’inventaire</h1>
              <p>
                Suivez les comptages physiques et ouvrez les contrôles qui
                nécessitent une décision.
              </p>
            </div>

            <Link
              className="inventaire-create-button"
              to="/journaux-mouvements/create"
            >
              <span className="material-symbols-outlined">add</span>
              Nouvel inventaire
            </Link>
          </header>

          <section className="inventaire-summary">
            <div>
              <span>En cours</span>
              <strong>{inventairesEnCours.length}</strong>
              <small>comptages actifs sur le terrain</small>
            </div>
            <div>
              <span>À contrôler</span>
              <strong>{inventairesEnAttente.length}</strong>
              <small>sessions terminées par les opérateurs</small>
            </div>
            <div>
              <span>Validés</span>
              <strong>{inventairesValides.length}</strong>
              <small>inventaires clôturés</small>
            </div>
            <div>
              <span>À reprendre</span>
              <strong>{inventairesModifies.length}</strong>
              <small>sessions renvoyées pour modification</small>
            </div>
          </section>

          <section className="inventaire-list-panel">
            <header className="inventaire-list-header">
              <div>
                <h2>Liste des sessions</h2>
                <p>{journauxInventaire.length} inventaires enregistrés</p>
              </div>

              <div className="inventaire-filters">
                <label>
                  <span className="material-symbols-outlined">search</span>
                  <input
                    onChange={(event) => setRecherche(event.target.value)}
                    placeholder="Référence de l’inventaire"
                    type="search"
                    value={recherche}
                  />
                </label>

                <select
                  onChange={(event) =>
                    setStatutSelectionne(event.target.value)
                  }
                  value={statutSelectionne}
                >
                  <option value="TOUS">Tous les statuts</option>
                  <option value="EN COURS">En cours</option>
                  <option value="EN ATTENTE">En attente</option>
                  <option value="VALIDE">Validé</option>
                  <option value="MODIFIE">Modifié</option>
                </select>
              </div>
            </header>

            {error && (
              <div className="inventaire-error" role="alert">
                {error}
              </div>
            )}

            {loading ? (
              <div className="inventaire-message">
                Chargement des inventaires…
              </div>
            ) : (
              <div className="inventaire-table-wrapper">
                <table className="inventaire-table">
                  <thead>
                    <tr>
                      <th>Référence</th>
                      <th>État de la session</th>
                      <th>Lignes comptées</th>
                      <th>Quantité comptée</th>
                      <th>Document</th>
                      <th>Action</th>
                    </tr>
                  </thead>

                  <tbody>
                    {journauxAffiches.map((journal) => (
                      <tr key={journal.id}>
                        <td>
                          <div className="inventaire-reference">
                            <span className="material-symbols-outlined">
                              fact_check
                            </span>
                            <div>
                              <strong>{journal.reference}</strong>
                              <small>Session #{journal.id}</small>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span
                            className={`inventaire-status ${classeStatut(
                              journal.statut,
                            )}`}
                          >
                            <i />
                            {journal.statut}
                          </span>
                        </td>
                        <td>
                          <strong>{journal.details?.length || 0}</strong>
                          <small className="inventaire-cell-note">
                            articles comptés
                          </small>
                        </td>
                        <td>
                          <strong>{calculerQuantiteComptee(journal)}</strong>
                          <small className="inventaire-cell-note">pièces</small>
                        </td>
                        <td>
                          {journal.urlPieceJointe ? (
                            <span className="inventaire-document">
                              <span className="material-symbols-outlined">
                                description
                              </span>
                              Disponible
                            </span>
                          ) : (
                            <span className="inventaire-no-document">
                              Aucun rapport
                            </span>
                          )}
                        </td>
                        <td>
                          <Link
                            className="inventaire-open-link"
                            to={`/inventaire/${journal.id}`}
                          >
                            {libelleAction(journal.statut)}
                            <span className="material-symbols-outlined">
                              arrow_forward
                            </span>
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {!loading && journauxAffiches.length === 0 && !error && (
              <div className="inventaire-message">
                Aucun inventaire ne correspond à la recherche.
              </div>
            )}

            <footer className="inventaire-list-footer">
              <span>{journauxAffiches.length} session(s) affichée(s)</span>
              <span>{journauxInventaire.length} au total</span>
            </footer>
          </section>
        </main>
      </section>
    </div>
  );
}

export default ListeInventaire;
