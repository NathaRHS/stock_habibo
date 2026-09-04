import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import Sidebar from "../components/Sidebar";
import { getAccessToken } from "../services/authService";
import "./css/Inventaire.css";

function Inventaire() {
  const { id } = useParams();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [inventaire, setInventaire] = useState(null);
  const [racks, setRacks] = useState([]);
  const [emplacements, setEmplacements] = useState([]);
  const [rackSelectionne, setRackSelectionne] = useState(null);
  const [ligneSelectionnee, setLigneSelectionnee] = useState(null);
  const [recherche, setRecherche] = useState("");
  const [filtre, setFiltre] = useState("TOUS");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function charger() {
      try {
        const headers = {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        };
        const responseInventaire = await fetch(
          `${springUrl}/inventaire/${id}`,
          { headers },
        );
        const responseRacks = await fetch(`${springUrl}/rack`, { headers });
        const responseEmplacements = await fetch(`${springUrl}/emplacements`, {
          headers,
        });
        if (!responseInventaire.ok)
          throw new Error("Impossible de récupérer cet inventaire");
        if (!responseRacks.ok || !responseEmplacements.ok)
          throw new Error("Impossible de récupérer la structure de l'entrepôt");

        const dataInventaire = await responseInventaire.json();
        const dataRacks = await responseRacks.json();
        const dataEmplacements = await responseEmplacements.json();
        const lignes = (dataInventaire.details || []).map((ligne) => ({
          emplacementId: ligne.emplacementId ?? ligne.EmplacementId,
          nomEmplacement: ligne.nomEmplacement,
          nomRack: ligne.nomRack,
          numeroEtage: ligne.numeroEtage,
          articleId: ligne.articleId ?? ligne.ArticleId,
          nomArticle: ligne.nomArticle,
          quantiteTheorique: ligne.quantiteTheorique ?? 0,
          quantiteComptee:
            ligne.quantiteComptee ?? ligne.quanantiteComptee ?? 0,
          ecart: ligne.ecart ?? 0,
        }));
        setInventaire({ ...dataInventaire, details: lignes });
        setRacks(dataRacks);
        setEmplacements(dataEmplacements);
        setRackSelectionne(dataRacks[0] || null);
        setLigneSelectionnee(lignes[0] || null);
      } catch (erreur) {
        setError(erreur.message);
      } finally {
        setLoading(false);
      }
    }
    charger();
  }, [id, springUrl, token]);

  const lignes = inventaire?.details || [];
  const lignesAvecEcart = lignes.filter((ligne) => ligne.ecart !== 0);
  const emplacementsDuRack = emplacements.filter(
    (emplacement) => emplacement.rackId === rackSelectionne?.id,
  );
  const lignesAffichees = lignesAvecEcart.filter((ligne) => {
    const texte = recherche.toLowerCase();
    const rechercheOk =
      ligne.nomArticle?.toLowerCase().includes(texte) ||
      ligne.nomEmplacement?.toLowerCase().includes(texte) ||
      ligne.nomRack?.toLowerCase().includes(texte);
    const filtreOk =
      filtre === "TOUS" ||
      (filtre === "MANQUE" && ligne.ecart < 0) ||
      (filtre === "SURPLUS" && ligne.ecart > 0);
    return rechercheOk && filtreOk;
  });

  function trouverLigne(emplacementId) {
    return lignes.find((ligne) => ligne.emplacementId === emplacementId);
  }

  function classeEmplacement(ligne) {
    if (!ligne) return "slot-pending";
    if (ligne.ecart < 0) return "slot-missing";
    if (ligne.ecart > 0) return "slot-surplus";
    return "slot-ok";
  }

  function texteEmplacement(ligne) {
    if (!ligne) return "Non compté";
    if (ligne.ecart === 0) return "Conforme";
    return `${ligne.ecart > 0 ? "+" : ""}${ligne.ecart} pièces`;
  }

  function selectionnerEmplacement(emplacement) {
    const ligne = trouverLigne(emplacement.id);
    setLigneSelectionnee(
      ligne || {
        emplacementId: emplacement.id,
        nomEmplacement: emplacement.nomEmplacement,
        nomRack: emplacement.nomRack,
        numeroEtage: emplacement.numeroEtage,
        nomArticle: "Aucun comptage enregistré",
        quantiteTheorique: null,
        quantiteComptee: null,
        ecart: null,
      },
    );
  }

  function resultatLigne(ligne) {
    if (!ligne || ligne.ecart === null) return "Non compté";
    if (ligne.ecart < 0) return "Manque détecté";
    if (ligne.ecart > 0) return "Surplus détecté";
    return "Conforme";
  }

  async function changerStatut(action) {
    try {
      setError("");
      const response = await fetch(
        `${springUrl}/journaux-mouvements/${id}/${action}`,
        {
          method: "POST",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        },
      );
      if (!response.ok) {
        const erreur = await response.json().catch(() => null);
        throw new Error(
          erreur?.detail || erreur?.message || "L'action a échoué",
        );
      }
      const journal = await response.json();
      setInventaire({ ...inventaire, statut: journal.statut });
    } catch (erreur) {
      setError(erreur.message);
    }
  }

  if (loading) return <div className="inventory-message">Chargement…</div>;
  if (!inventaire) return <div className="inventory-message">{error}</div>;

  return (
    <div className="inventory-page">
      <Sidebar />
      <section className="inventory-main">
        <header className="inventory-topbar">
          <p>Inventaires / {inventaire.reference}</p>
          <label>
            <span className="material-symbols-outlined">search</span>
            <input
              value={recherche}
              onChange={(e) => setRecherche(e.target.value)}
              placeholder="Article, rack ou emplacement"
            />
          </label>
          <div className="inventory-user">
            <span>AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="inventory-content">
          <header className="inventory-heading">
            <div>
              <h1>Contrôle visuel de l’inventaire</h1>
              <p>
                Localisez les écarts et examinez les comptages avant validation.
              </p>
            </div>
            <div className="inventory-actions">
              <Link to="/inventaires">
                <span className="material-symbols-outlined">arrow_back</span>
                Retour
              </Link>
              {inventaire.statut !== "VALIDE" && (
                <button onClick={() => changerStatut("valider")}>
                  <span className="material-symbols-outlined">check</span>
                  Valider l’inventaire
                </button>
              )}
            </div>
          </header>
          {error && <div className="inventory-error">{error}</div>}

          <section className="inventory-summary">
            <div>
              <span>Journal</span>
              <strong>{inventaire.reference}</strong>
            </div>
            <div>
              <span>État</span>
              <strong>{inventaire.statut}</strong>
            </div>
            <div>
              <span>Participants</span>
              <strong>{inventaire.nombreParticipants}</strong>
            </div>
            <div>
              <span>Emplacements comptés</span>
              <strong>
                {lignes.length} / {emplacements.length}
              </strong>
            </div>
            <div>
              <span>Écarts détectés</span>
              <strong className="danger-number">
                {lignesAvecEcart.length}
              </strong>
            </div>
          </section>

          <div className="inventory-control">
            <section className="inventory-panel">
              <header className="inventory-panel-head">
                <div>
                  <h2>Cartographie du comptage</h2>
                  <p>
                    Sélectionnez un emplacement pour consulter son résultat.
                  </p>
                </div>
                <div className="rack-tabs">
                  {racks.map((rack) => (
                    <button
                      className={
                        rackSelectionne?.id === rack.id ? "active" : ""
                      }
                      key={rack.id}
                      onClick={() => setRackSelectionne(rack)}
                    >
                      {rack.name}
                    </button>
                  ))}
                </div>
              </header>
              <div className="inventory-legend">
                <span>
                  <i className="ok" />
                  Conforme
                </span>
                <span>
                  <i className="missing" />
                  Manque
                </span>
                <span>
                  <i className="surplus" />
                  Surplus
                </span>
                <span>
                  <i />
                  Non compté
                </span>
              </div>
              <div className="rack-heading">
                <strong>{rackSelectionne?.name}</strong>
                <span>
                  {rackSelectionne?.nombreEtages || 0} étages ·{" "}
                  {emplacementsDuRack.length} emplacements
                </span>
              </div>
              <div className="rack-map">
                {[5, 4, 3, 2, 1].map((etage) => (
                  <div className="rack-level" key={etage}>
                    <span>Étage {etage}</span>
                    {emplacementsDuRack
                      .filter((emp) => emp.numeroEtage === etage)
                      .sort((a, b) =>
                        a.nomEmplacement.localeCompare(b.nomEmplacement),
                      )
                      .map((emp) => {
                        const ligne = trouverLigne(emp.id);
                        return (
                          <button
                            className={`inventory-slot ${classeEmplacement(ligne)} ${ligneSelectionnee?.emplacementId === emp.id ? "selected" : ""}`}
                            key={emp.id}
                            onClick={() => selectionnerEmplacement(emp)}
                          >
                            <strong>{emp.nomEmplacement}</strong>
                            <span>{texteEmplacement(ligne)}</span>
                            <i />
                          </button>
                        );
                      })}
                  </div>
                ))}
                <div className="rack-aisle">
                  Allée de circulation · vue frontale
                </div>
              </div>
            </section>

            <aside className="inventory-panel inventory-detail">
              <header className="inventory-panel-head">
                <div>
                  <h2>Détail de l’emplacement</h2>
                  <p>Résultat du comptage sélectionné</p>
                </div>
              </header>
              {ligneSelectionnee ? (
                <>
                  <div className="selected-location">
                    <div>
                      <strong>{ligneSelectionnee.nomEmplacement}</strong>
                      <small>
                        {ligneSelectionnee.nomRack} · Étage{" "}
                        {ligneSelectionnee.numeroEtage}
                      </small>
                    </div>
                    <span>{resultatLigne(ligneSelectionnee)}</span>
                  </div>
                  <div className="selected-article">
                    <span>Article compté</span>
                    <strong>{ligneSelectionnee.nomArticle}</strong>
                  </div>
                  <div className="inventory-comparison">
                    <div>
                      <span>Théorique</span>
                      <strong>
                        {ligneSelectionnee.quantiteTheorique ?? "—"}
                      </strong>
                    </div>
                    <div>
                      <span>Comptée</span>
                      <strong>
                        {ligneSelectionnee.quantiteComptee ?? "—"}
                      </strong>
                    </div>
                    <div>
                      <span>Écart</span>
                      <strong>
                        {ligneSelectionnee.ecart > 0 ? "+" : ""}
                        {ligneSelectionnee.ecart ?? "—"}
                      </strong>
                    </div>
                  </div>
                  <p className="inventory-note">
                    {ligneSelectionnee.ecart === null
                      ? "Cet emplacement n’a pas encore été compté."
                      : ligneSelectionnee.ecart === 0
                        ? "Le comptage correspond au stock informatique."
                        : "Le stock physique diffère du stock informatique. Une décision est nécessaire."}
                  </p>
                </>
              ) : (
                <p className="inventory-note">Sélectionnez un emplacement.</p>
              )}
            </aside>
          </div>

          <section className="inventory-panel inventory-issues">
            <header className="inventory-panel-head">
              <div>
                <h2>Écarts nécessitant une décision</h2>
                <p>Comparaison entre le stock informatique et le comptage.</p>
              </div>
              <select
                value={filtre}
                onChange={(e) => setFiltre(e.target.value)}
              >
                <option value="TOUS">Tous les écarts</option>
                <option value="MANQUE">Manques</option>
                <option value="SURPLUS">Surplus</option>
              </select>
            </header>
            <table>
              <thead>
                <tr>
                  <th>Emplacement</th>
                  <th>Article</th>
                  <th>Rack / étage</th>
                  <th>Théorique</th>
                  <th>Comptée</th>
                  <th>Écart</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {lignesAffichees.map((ligne) => (
                  <tr key={`${ligne.emplacementId}-${ligne.articleId}`}>
                    <td>
                      <strong>{ligne.nomEmplacement}</strong>
                    </td>
                    <td>{ligne.nomArticle}</td>
                    <td>
                      {ligne.nomRack} · Étage {ligne.numeroEtage}
                    </td>
                    <td>{ligne.quantiteTheorique}</td>
                    <td>{ligne.quantiteComptee}</td>
                    <td className={ligne.ecart < 0 ? "negative" : "positive"}>
                      {ligne.ecart > 0 ? "+" : ""}
                      {ligne.ecart}
                    </td>
                    <td>
                      <button
                        onClick={() => {
                          setRackSelectionne(
                            racks.find((rack) => rack.name === ligne.nomRack),
                          );
                          setLigneSelectionnee(ligne);
                          window.scrollTo({ top: 160, behavior: "smooth" });
                        }}
                      >
                        Examiner
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {lignesAffichees.length === 0 && (
              <div className="no-issues">
                Aucun écart ne correspond à ce filtre.
              </div>
            )}
            {inventaire.statut !== "VALIDE" && (
              <footer className="review-footer">
                <div>
                  <strong>Le comptage doit être repris ?</strong>
                  <small>Le journal passera à l’état MODIFIE.</small>
                </div>
                <button onClick={() => changerStatut("demander-modification")}>
                  Demander une modification
                </button>
              </footer>
            )}
          </section>
        </main>
      </section>
    </div>
  );
}

export default Inventaire;
