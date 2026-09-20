import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  chargerDonneesAffectation,
  chargerSuggestionEmplacements,
  creerEntreeStock,
} from "../services/affectationStockService";
import Button from "../components/Button";
import Modal from "../components/Modal";
import Sidebar from "../components/Sidebar";
import "./css/AffectationStockMine.css";

function AffectationStockMine() {
  const { journalId } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [donneesFromDatabase, setDonneesFromDatabase] = useState(null);
  const [error, setError] = useState("");
  const [chargement, setChargement] = useState(true);
  const [envoiEnCours, setEnvoiEnCours] = useState(false);
  const [modaleConfirmationOuverte, setModaleConfirmationOuverte] =
    useState(false);
  const [mouvementsCrees, setMouvementsCrees] = useState([]);
  const [affectationTemporaireAll, setAffectationTemporaireAll] = useState([]);
  const [articleSelectionne, setArticleSelectionne] = useState(null);
  const [suggestionProduit, setSuggestionProduit] = useState(null);
  const [suggestionAConfirmer, setSuggestionAConfirmer] = useState(null);
  const [chargementSuggestion, setChargementSuggestion] = useState(false);
  const [rackSelectionne, setRackSelectionne] = useState(null);
  const [pageEmplacements, setPageEmplacements] = useState(1);
  const EMPLACEMENTS_PAR_PAGE = 6;

  const [emplacementSelectionne, setEmplacementSelectionne] = useState(null);
  const [quantite, setQuantite] = useState(1);

  const journal = donneesFromDatabase?.journal;
  const detailsJournal = journal?.details ?? [];
  const emplacements = donneesFromDatabase?.emplacements ?? [];
  const stocks = donneesFromDatabase?.stocks ?? [];
  const palettes = donneesFromDatabase?.palettes ?? [];
  const conditionnements = donneesFromDatabase?.conditionnements ?? [];
  const racks = donneesFromDatabase?.racks ?? [];

  useEffect(() => {
    async function recupererToutesLesDonneesPourLeJournal() {
      try {
        setChargement(true);
        setError("");
        const responseAll = await chargerDonneesAffectation(
          springUrl,
          journalId,
        );
        setDonneesFromDatabase(responseAll);
        setRackSelectionne(
          (rackActuel) => rackActuel ?? responseAll.racks?.[0] ?? null,
        );
      } catch (erreur) {
        setError(erreur.message || "Impossible de charger l'affectation");
      } finally {
        setChargement(false);
      }
    }

    recupererToutesLesDonneesPourLeJournal();
  }, [springUrl, journalId]);

  const totalVolumeDetailJournal = detailsJournal.reduce(
    (total, detail) => total + (detail.quantiteConditionnement ?? 0),
    0,
  );

  const calculerQuantiteRestante = (detail) => {
    if (!detail) return 0;

    const quantiteDejaAffectee = affectationTemporaireAll
      .filter((affectation) => affectation.detailJournalId === detail.id)
      .reduce(
        (total, affectation) => total + affectation.nombreConditionnements,
        0,
      );

    return Math.max(
      (detail.quantiteConditionnement ?? 0) - quantiteDejaAffectee,
      0,
    );
  };

  const calculerQuantiteAffecteeSurEmplacement = (emplacementId) =>
    affectationTemporaireAll
      .filter((affectation) => affectation.emplacementId === emplacementId)
      .reduce(
        (total, affectation) => total + affectation.nombreConditionnements,
        0,
      );

  // La grille et le panneau droit utilisent cette meme source de calcul.
  const calculerInformationsEmplacement = (emplacement) => {
    if (!emplacement) return null;

    const stockEmplacement = stocks.find(
      (stock) => stock.emplacementId === emplacement.id,
    );
    const premiereAffectationTemporaire = affectationTemporaireAll.find(
      (affectation) => affectation.emplacementId === emplacement.id,
    );
    const detailAffecteTemporairement = detailsJournal.find(
      (detail) => detail.id === premiereAffectationTemporaire?.detailJournalId,
    );
    const articleIdPresent =
      stockEmplacement?.articleId ?? detailAffecteTemporairement?.articleId;
    const articleIdPourCapacite =
      articleIdPresent ?? articleSelectionne?.articleId;
    const conditionnementArticle = conditionnements.find(
      (conditionnement) => conditionnement.articleId === articleIdPourCapacite,
    );
    const paletteConditionnement = palettes.find(
      (palette) =>
        palette.articleConditionnementId === conditionnementArticle?.id,
    );
    const stockEnConditionnements =
      conditionnementArticle?.quantitePieceStandard
        ? (stockEmplacement?.quantiteStock ?? 0) /
          conditionnementArticle.quantitePieceStandard
        : 0;
    const quantiteTemporaire = calculerQuantiteAffecteeSurEmplacement(
      emplacement.id,
    );
    const capacite = paletteConditionnement?.quantiteMaximale ?? 0;
    const quantiteOccupee = stockEnConditionnements + quantiteTemporaire;
    const placeRestante = Math.max(capacite - quantiteOccupee, 0);
    const tauxOccupation =
      capacite > 0
        ? Math.min(Math.round((quantiteOccupee / capacite) * 100), 100)
        : 0;
    const incompatible = Boolean(
      articleSelectionne &&
      articleIdPresent &&
      articleIdPresent !== articleSelectionne.articleId,
    );

    return {
      conditionnementArticle,
      articlePresent: Boolean(articleIdPresent),
      capacite,
      quantiteOccupee,
      placeRestante,
      tauxOccupation,
      incompatible,
      memeArticle: Boolean(
        articleSelectionne && articleIdPresent === articleSelectionne.articleId,
      ),
    };
  };

  const obtenirInformationsAffectation = (affectation) => {
    const detail = detailsJournal.find(
      (element) => element.id === affectation.detailJournalId,
    );
    const emplacement = emplacements.find(
      (element) => element.id === affectation.emplacementId,
    );
    const conditionnement = conditionnements.find(
      (element) => element.articleId === detail?.articleId,
    );

    return {
      nomArticle: detail?.nomArticle ?? "Article inconnu",
      nomEmplacement: emplacement?.nomEmplacement ?? "Emplacement inconnu",
      nomRack: emplacement?.nomRack ?? "",
      nomConditionnement:
        conditionnement?.nomConditionnement ?? "conditionnements",
      nombreConditionnements: affectation.nombreConditionnements,
    };
  };

  const supprimerAffectation = (idTemporaire) => {
    setAffectationTemporaireAll((anciennesAffectations) =>
      anciennesAffectations.filter(
        (affectation) => affectation.idTemporaire !== idTemporaire,
      ),
    );
  };

  const demanderSuggestion = async () => {
    if (!articleSelectionne) return;

    try {
      setError("");
      setChargementSuggestion(true);

      const affectationsDesAutresArticles = affectationTemporaireAll.filter(
        (affectation) => affectation.detailJournalId !== articleSelectionne.id,
      );
      const reponse = await chargerSuggestionEmplacements(
        springUrl,
        articleSelectionne.id,
        affectationsDesAutresArticles,
      );

      setSuggestionProduit(reponse);
      setSuggestionAConfirmer(reponse);

      const premiereSuggestion = reponse.suggestions?.[0];
      if (!premiereSuggestion) {
        setEmplacementSelectionne(null);
        return;
      }

      const rackPropose = racks.find(
        (rack) => rack.id === premiereSuggestion.rackId,
      );
      const emplacementPropose = emplacements.find(
        (emplacement) => emplacement.id === premiereSuggestion.emplacementId,
      );

      if (rackPropose) setRackSelectionne(rackPropose);
      if (!emplacementPropose) return;

      setEmplacementSelectionne(emplacementPropose);

      const emplacementsDuNiveau = emplacements
        .filter(
          (emplacement) =>
            emplacement.rackId === premiereSuggestion.rackId &&
            emplacement.numeroEtage === premiereSuggestion.numeroEtage,
        )
        .sort(
          (premier, second) =>
            (premier.ordreDansEtage ?? 0) - (second.ordreDansEtage ?? 0),
        );

      const indexEmplacement = emplacementsDuNiveau.findIndex(
        (emplacement) => emplacement.id === premiereSuggestion.emplacementId,
      );

      setPageEmplacements(
        indexEmplacement >= 0
          ? Math.floor(indexEmplacement / EMPLACEMENTS_PAR_PAGE) + 1
          : 1,
      );
    } catch (erreur) {
      setError(erreur.message || "Impossible de charger la suggestion");
    } finally {
      setChargementSuggestion(false);
    }
  };

  const annulerSuggestion = () => {
    setSuggestionProduit(null);
    setSuggestionAConfirmer(null);
  };

  const confirmerSuggestion = () => {
    if (!articleSelectionne || !suggestionAConfirmer) return;

    setAffectationTemporaireAll((anciennesAffectations) => [
      ...anciennesAffectations.filter(
        (affectation) => affectation.detailJournalId !== articleSelectionne.id,
      ),
      ...(suggestionAConfirmer.suggestions ?? []).map((suggestion) => ({
        idTemporaire: crypto.randomUUID(),
        detailJournalId: articleSelectionne.id,
        emplacementId: suggestion.emplacementId,
        nombreConditionnements: suggestion.quantiteConditionnementsProposee,
      })),
    ]);
    setSuggestionProduit(null);
    setSuggestionAConfirmer(null);
  };

  const handleSubmitTemporaire = (event) => {
    event.preventDefault();
    setError("");

    if (!articleSelectionne || !emplacementSelectionne) {
      setError("Selectionne un article et un emplacement");
      return;
    }

    const quantiteDemandee = Number(quantite);
    if (!Number.isFinite(quantiteDemandee) || quantiteDemandee <= 0) {
      setError("La quantite doit etre strictement positive");
      return;
    }

    const informationsEmplacement = calculerInformationsEmplacement(
      emplacementSelectionne,
    );
    const resteArticle = calculerQuantiteRestante(articleSelectionne);

    if (informationsEmplacement.incompatible) {
      setError("Cet emplacement contient deja un autre article");
      return;
    }
    if (quantiteDemandee > resteArticle) {
      setError(`Il reste seulement ${resteArticle} conditionnements a placer`);
      return;
    }
    if (quantiteDemandee > informationsEmplacement.placeRestante) {
      setError(
        `Cet emplacement accepte encore seulement ${informationsEmplacement.placeRestante} conditionnements`,
      );
      return;
    }

    setAffectationTemporaireAll((anciennesAffectations) => [
      ...anciennesAffectations,
      {
        idTemporaire: crypto.randomUUID(),
        detailJournalId: articleSelectionne.id,
        emplacementId: emplacementSelectionne.id,
        nombreConditionnements: quantiteDemandee,
      },
    ]);
    setQuantite(1);
  };

  const quantiteTotaleAffectee = affectationTemporaireAll.reduce(
    (total, affectation) => total + affectation.nombreConditionnements,
    0,
  );
  const progression =
    totalVolumeDetailJournal > 0
      ? Math.min(
          Math.round((quantiteTotaleAffectee / totalVolumeDetailJournal) * 100),
          100,
        )
      : 0;
  const planComplet =
    detailsJournal.length > 0 &&
    detailsJournal.every((detail) => calculerQuantiteRestante(detail) === 0);

  const creerEntreeEnStockClick = async () => {
    try {
      setError("");
      setEnvoiEnCours(true);
      const affectationsPourBackend = affectationTemporaireAll.map(
        (affectation) => ({
          detailJournalId: affectation.detailJournalId,
          emplacementId: affectation.emplacementId,
          nombreConditionnements: affectation.nombreConditionnements,
        }),
      );
      const mouvements = await creerEntreeStock(
        springUrl,
        journalId,
        affectationsPourBackend,
      );
      setMouvementsCrees(mouvements);
      setModaleConfirmationOuverte(true);
    } catch (erreur) {
      setError(erreur.message || "Impossible de creer l'entree en stock");
    } finally {
      setEnvoiEnCours(false);
    }
  };

  const emplacementsFiltres = emplacements.filter(
    (emplacement) => emplacement.rackId === rackSelectionne?.id,
  );
  const niveaux = Array.from(
    { length: rackSelectionne?.nombreEtages ?? 0 },
    (_, index) => (rackSelectionne?.nombreEtages ?? 0) - index,
  );
  const nombreEmplacementsOccupes = emplacementsFiltres.filter(
    (emplacement) =>
      calculerInformationsEmplacement(emplacement)?.quantiteOccupee > 0,
  ).length;
  const tauxOccupationRack =
    emplacementsFiltres.length > 0
      ? Math.round(
          (nombreEmplacementsOccupes / emplacementsFiltres.length) * 100,
        )
      : 0;
  const informationsEmplacementSelectionne = calculerInformationsEmplacement(
    emplacementSelectionne,
  );
  const suggestionsArticleSelectionne =
    suggestionProduit?.detailJournalId === articleSelectionne?.id
      ? (suggestionProduit?.suggestions ?? [])
      : [];
  const suggestionAConfirmerPourArticle =
    suggestionAConfirmer?.detailJournalId === articleSelectionne?.id
      ? suggestionAConfirmer
      : null;
  const suggestionEmplacementSelectionne = suggestionsArticleSelectionne.find(
    (suggestion) => suggestion.emplacementId === emplacementSelectionne?.id,
  );

  if (chargement) {
    return (
      <div className="affectation-message">Chargement de l'entrepot...</div>
    );
  }

  const nombreMaximumParEtage = Math.max(
    0,
    ...niveaux.map(
      (niveau) =>
        emplacementsFiltres.filter(
          (emplacement) => emplacement.numeroEtage === niveau,
        ).length,
    ),
  );

  const nombrePages = Math.ceil(nombreMaximumParEtage / EMPLACEMENTS_PAR_PAGE);

  return (
    <div className="affectation-shell">
      <Sidebar />
      <section className="affectation-main-section">
        {/* <header className="affectation-global-topbar">
          <p>Réceptions / Affectation du stock</p>
          <label><span className="material-symbols-outlined">search</span><input placeholder="Rechercher" type="search" /></label>
          <div className="affectation-global-user"><span>AR</span><div><strong>Administrateur</strong><small>Responsable entrepôt</small></div></div>
        </header> */}
        <div className="affectation-page main-wrapper">
          <div className="content-container">
            <header className="page-header">
              <div>
                <span className="badge-kicker">Affectation de stock</span>
                {/* <h2>Ou souhaitez-vous ranger ces produits ?</h2> */}
                <p>
                  Selectionnez un produit, puis cliquez sur l'emplacement cible
                  du rack.
                </p>
              </div>
              <button
                type="button"
                className="btn-modern"
                onClick={() => navigate("/journaux-mouvements")}
              >
                Retour aux journaux
              </button>
            </header>

            {error && <div className="affectation-error">{error}</div>}

            <section className="summary-bar">
              <div className="summary-item">
                <span className="label">Journal de reception</span>
                <strong className="val">{journal?.reference ?? "-"}</strong>
              </div>
              <div className="summary-item">
                <span className="label">Etat du document</span>
                <strong className="val">
                  <i className="status-dot" /> {journal?.statut ?? "-"}
                </strong>
              </div>
              <div className="summary-item">
                <span className="label">Volume a ranger</span>
                <strong className="val">
                  {totalVolumeDetailJournal} colis
                </strong>
              </div>
              <div className="summary-item">
                <span className="label">Progression globale</span>
                <strong className="val">{progression}% affectes</strong>
              </div>
            </section>

            <div className="workspace-grid">
              <section className="panel-card products-panel">
                <div className="panel-head">
                  <h2>Articles a placer</h2>
                  <span className="counter">
                    {detailsJournal.length} articles
                  </span>
                </div>
                <div className="product-list">
                  {detailsJournal.map((detail) => {
                    const conditionnement = conditionnements.find(
                      (element) => element.articleId === detail.articleId,
                    );
                    const articleEstSelectionne =
                      articleSelectionne?.id === detail.id;
                    const insuffisanceSuggestion =
                      articleEstSelectionne &&
                      suggestionProduit?.detailJournalId === detail.id &&
                      suggestionProduit?.quantiteConditionnementsNonAffectee >
                        0;

                    return (
                      <div
                        className={`product-card ${articleSelectionne?.id === detail.id ? "active" : ""}`}
                        key={detail.id}
                      >
                        <button
                          type="button"
                          className="product-card-select"
                          onClick={() => {
                            setArticleSelectionne(detail);
                            setEmplacementSelectionne(null);
                            if (suggestionProduit?.detailJournalId !== detail.id) {
                              setSuggestionProduit(null);
                              setSuggestionAConfirmer(null);
                            }
                          }}
                        >
                          <div className="product-card-header">
                            <span className="product-tag">
                              {detail.nomArticle
                                .split(" ")
                                .slice(0, 2)
                                .map((mot) => mot[0])
                                .join("")
                                .toUpperCase()}
                            </span>
                            <div>
                              <h3>{detail.nomArticle}</h3>
                              <p>
                                {conditionnement?.nomConditionnement ??
                                  "Conditionnement"}
                                {conditionnement?.quantitePieceStandard
                                  ? ` de ${conditionnement.quantitePieceStandard} pieces`
                                  : ""}
                              </p>
                            </div>
                          </div>
                          <div className="product-meta">
                            <span>Reste a placer</span>
                            <strong>{calculerQuantiteRestante(detail)}</strong>
                          </div>
                        </button>

                        {articleEstSelectionne && (
                          <button
                            type="button"
                            className="btn-suggestion"
                            disabled={chargementSuggestion}
                            onClick={demanderSuggestion}
                          >
                            {chargementSuggestion
                              ? "Calcul de la suggestion..."
                              : "Voir la suggestion"}
                          </button>
                        )}

                        {insuffisanceSuggestion && (
                          <p className="suggestion-warning">
                            {
                              suggestionProduit.quantiteConditionnementsNonAffectee
                            }{" "}
                            conditionnement(s) restent a placer.
                          </p>
                        )}
                      </div>
                    );
                  })}
                </div>
                <div className="info-box">
                  Les emplacements bleus contiennent le produit selectionne. Les
                  emplacements rouges contiennent un autre article.
                </div>
              </section>

              <section className="panel-card warehouse-panel">
                <div className="warehouse-header-bar">
                  <div>
                    <h2>Entrepot principal</h2>
                  </div>
                </div>
                <div className="legend-row">
                  <span className="legend-item">
                    <i className="legend-indicator" /> Libre
                  </span>
                  <span className="legend-item">
                    <i className="legend-indicator same" /> Meme article
                  </span>
                  <span className="legend-item">
                    <i className="legend-indicator almost" /> Presque plein
                  </span>
                  <span className="legend-item">
                    <i className="legend-indicator blocked" /> Incompatible
                  </span>
                  <span className="legend-item">
                    <i className="legend-indicator suggested" /> Suggestion
                  </span>
                </div>
                <div className="rack-selector-tabs">
                  {racks.map((rack) => (
                    <button
                      type="button"
                      key={rack.id}
                      className={`tab-btn ${rackSelectionne?.id === rack.id ? "active" : ""}`}
                      onClick={() => {
                        setRackSelectionne(rack);
                        setEmplacementSelectionne(null);
                        setPageEmplacements(1);
                      }}
                    >
                      {rack.name}
                    </button>
                  ))}
                </div>
                <div className="rack-content-view">
                  <div className="rack-title-banner">
                    <h3>{rackSelectionne?.name ?? "Selectionnez un rack"}</h3>
                    <span>
                      Taux d'occupation : <b>{tauxOccupationRack}%</b>
                    </span>
                  </div>
                  {suggestionAConfirmerPourArticle && (
                    <section className="suggestion-popover" role="status">
                      <div className="suggestion-popover-heading">
                        <span className="material-symbols-outlined">
                          auto_awesome
                        </span>
                        <div>
                          <strong>Suggestion prête à appliquer</strong>
                          <p>
                            Les cases bleues montrent les emplacements proposés
                            pour {articleSelectionne?.nomArticle}.
                          </p>
                        </div>
                        <button
                          aria-label="Fermer la suggestion"
                          className="suggestion-popover-close"
                          onClick={annulerSuggestion}
                          type="button"
                        >
                          <span className="material-symbols-outlined">close</span>
                        </button>
                      </div>
                      <div className="suggestion-popover-places">
                        {(suggestionAConfirmerPourArticle.suggestions ?? []).map(
                          (suggestion) => (
                            <button
                              className="suggestion-place"
                              key={suggestion.emplacementId}
                              onClick={() => {
                                const emplacement = emplacements.find(
                                  (element) =>
                                    element.id === suggestion.emplacementId,
                                );
                                if (emplacement) setEmplacementSelectionne(emplacement);
                              }}
                              type="button"
                            >
                              <b>{suggestion.nomEmplacement}</b>
                              <span>
                                {suggestion.quantiteConditionnementsProposee} colis
                              </span>
                            </button>
                          ),
                        )}
                      </div>
                      <div className="suggestion-popover-reasons">
                        <strong>Pourquoi cette proposition ?</strong>
                        <ul>
                          {(suggestionAConfirmerPourArticle.suggestions?.[0]
                            ?.raisons ?? []).map((raison) => (
                            <li key={raison}>{raison}</li>
                          ))}
                        </ul>
                      </div>
                      <footer className="suggestion-popover-actions">
                        <button onClick={annulerSuggestion} type="button">
                          Ignorer
                        </button>
                        <button
                          className="suggestion-confirm-button"
                          disabled={
                            !(suggestionAConfirmerPourArticle.suggestions ?? [])
                              .length
                          }
                          onClick={confirmerSuggestion}
                          type="button"
                        >
                          Appliquer la suggestion
                        </button>
                      </footer>
                    </section>
                  )}
                  {nombrePages > 1 && (
                    <div className="rack-pagination">
                      <button
                        type="button"
                        disabled={pageEmplacements === 1}
                        onClick={() => setPageEmplacements((page) => page - 1)}
                      >
                        Précédent
                      </button>

                      <span>
                        Page {pageEmplacements} sur {nombrePages}
                      </span>

                      <button
                        type="button"
                        disabled={pageEmplacements === nombrePages}
                        onClick={() => setPageEmplacements((page) => page + 1)}
                      >
                        Page suivante
                      </button>
                    </div>
                  )}
                  <div className="rack-grid-container">
                    {niveaux.map((niveau) => (
                      <div className="rack-row" key={niveau}>
                        <span className="floor-label">Niveau {niveau}</span>
                        {emplacementsFiltres
                          .filter(
                            (emplacement) => emplacement.numeroEtage === niveau,
                          )
                          .sort(
                            (a, b) =>
                              (a.ordreDansEtage ?? 0) - (b.ordreDansEtage ?? 0),
                          )
                          .slice(
                            (pageEmplacements - 1) * EMPLACEMENTS_PAR_PAGE,
                            pageEmplacements * EMPLACEMENTS_PAR_PAGE,
                          )
                          .map((emplacement) => {
                            const informations =
                              calculerInformationsEmplacement(emplacement);
                            const presquePlein =
                              informations.tauxOccupation >= 75 &&
                              informations.placeRestante > 0;
                            const suggestionEmplacement =
                              suggestionsArticleSelectionne.find(
                                (suggestion) =>
                                  suggestion.emplacementId === emplacement.id,
                              );
                            const classeEtat = [
                              informations.incompatible ? "blocked" : "",
                              informations.memeArticle ? "same" : "",
                              presquePlein ? "almost" : "",
                              suggestionEmplacement ? "suggested" : "",
                            ]
                              .filter(Boolean)
                              .join(" ");
                            return (
                              <button
                                type="button"
                                key={emplacement.id}
                                disabled={informations.incompatible}
                                className={`slot-card ${classeEtat} ${emplacementSelectionne?.id === emplacement.id ? "selected" : ""}`}
                                onClick={() =>
                                  setEmplacementSelectionne(emplacement)
                                }
                              >
                                <span className="slot-head">
                                  <span className="slot-code">
                                    {emplacement.nomEmplacement}
                                  </span>
                                  {suggestionEmplacement && (
                                    <span className="suggestion-badge">
                                      {
                                        suggestionEmplacement.quantiteConditionnementsProposee
                                      }
                                    </span>
                                  )}
                                </span>
                                <span className="slot-desc">
                                  {suggestionEmplacement
                                    ? `Suggestion : ${suggestionEmplacement.quantiteConditionnementsProposee} colis`
                                    : informations.articlePresent
                                      ? informations.conditionnementArticle
                                          .nomArticle
                                      : `Libre - ${informations.placeRestante} places`}
                                </span>
                                <span className="slot-progress-bar">
                                  <i
                                    className="slot-progress-fill"
                                    style={{
                                      width: `${informations.tauxOccupation}%`,
                                    }}
                                  />
                                </span>
                              </button>
                            );
                          })}
                      </div>
                    ))}
                  </div>

                  <div className="aisle-divider">Allee de circulation A</div>
                </div>
              </section>

              <aside className="panel-card assignment-panel">
                <div className="panel-head">
                  <h2>Affectation</h2>
                  <span className="counter">Etape 2/3</span>
                </div>
                <div className="selection-summary">
                  <span className="section-label">Produit selectionne</span>
                  <strong className="selected-item-title">
                    {articleSelectionne?.nomArticle ??
                      "Selectionnez un produit"}
                  </strong>
                  <p>
                    {articleSelectionne
                      ? `${calculerQuantiteRestante(articleSelectionne)} colis a repartir`
                      : "Choisissez un article dans la liste"}
                  </p>
                </div>
                <div className="location-box">
                  <span className="section-label">Emplacement selectionne</span>
                  <strong className="loc-title">
                    {emplacementSelectionne
                      ? `${emplacementSelectionne.nomEmplacement} - ${rackSelectionne?.name}`
                      : "Selectionnez une palette"}
                  </strong>
                  <div className="capacity-info">
                    <div className="capacity-row">
                      <span>Contenu actuel</span>
                      <b>
                        {informationsEmplacementSelectionne?.quantiteOccupee ??
                          0}
                      </b>
                    </div>
                    <div className="capacity-row">
                      <span>Capacite totale</span>
                      <b>{informationsEmplacementSelectionne?.capacite ?? 0}</b>
                    </div>
                    <div className="capacity-row">
                      <span>Place disponible</span>
                      <b className="available-capacity">
                        {informationsEmplacementSelectionne?.placeRestante ?? 0}
                      </b>
                    </div>
                  </div>
                </div>
                {/* {suggestionEmplacementSelectionne && (
                  <section className="suggestion-reasons">
                    <div className="suggestion-reasons-head">
                      <span className="section-label">
                        Pourquoi cette affectation ?
                      </span>
                      <strong>
                        Score{" "}
                        {suggestionEmplacementSelectionne.scoreFinal.toFixed(1)}
                      </strong>
                    </div>
                    <ul>
                      {suggestionEmplacementSelectionne.raisons?.map(
                        (raison) => (
                          <li key={raison}>{raison}</li>
                        ),
                      )}
                    </ul>
                  </section>
                )} */}
                <form className="form-group" onSubmit={handleSubmitTemporaire}>
                  <label
                    className="section-label"
                    htmlFor="quantite-affectation"
                  >
                    Quantite a placer
                  </label>
                  <div className="quantity-control">
                    <button
                      className="qty-btn"
                      type="button"
                      onClick={() =>
                        setQuantite((valeur) => Math.max(Number(valeur) - 1, 1))
                      }
                    >
                      -
                    </button>
                    <input
                      id="quantite-affectation"
                      className="qty-input"
                      value={quantite}
                      onChange={(event) => setQuantite(event.target.value)}
                      type="number"
                      min="1"
                    />
                    <button
                      className="qty-btn"
                      type="button"
                      onClick={() =>
                        setQuantite((valeur) => Number(valeur) + 1)
                      }
                    >
                      +
                    </button>
                  </div>
                  <button
                    className="btn-assign"
                    type="submit"
                    disabled={!articleSelectionne || !emplacementSelectionne}
                  >
                    {emplacementSelectionne
                      ? `Affecter a ${emplacementSelectionne.nomEmplacement}`
                      : "Selectionnez une palette"}
                  </button>
                </form>
                <section className="plan-summary">
                  <div className="plan-header">
                    <b>Planification en cours</b>
                    <span>{affectationTemporaireAll.length} lignes</span>
                  </div>
                  {affectationTemporaireAll.length === 0 ? (
                    <p className="empty-plan">Aucune affectation ajoutee</p>
                  ) : (
                    affectationTemporaireAll.map((affectation) => {
                      const informations =
                        obtenirInformationsAffectation(affectation);
                      return (
                        <div
                          className="plan-row"
                          key={affectation.idTemporaire}
                        >
                          <div className="item-desc">
                            <strong>{informations.nomArticle}</strong>
                            <span>
                              {informations.nomEmplacement}
                              {informations.nomRack
                                ? ` - ${informations.nomRack}`
                                : ""}
                            </span>
                          </div>
                          <b className="item-qty">
                            {informations.nombreConditionnements}{" "}
                            {informations.nomConditionnement}
                          </b>
                          <button
                            type="button"
                            aria-label="Supprimer l'affectation"
                            onClick={() =>
                              supprimerAffectation(affectation.idTemporaire)
                            }
                          >
                            x
                          </button>
                        </div>
                      );
                    })
                  )}
                </section>
                <div className="footer-action-area">
                  <button
                    type="button"
                    className="btn-validate"
                    disabled={!planComplet || envoiEnCours}
                    onClick={creerEntreeEnStockClick}
                  >
                    {envoiEnCours
                      ? "Validation en cours..."
                      : "Valider le plan d'affectation"}
                  </button>
                  <p className="legal-note">
                    Verification automatique des capacites et regles de stock
                    lors de la soumission.
                  </p>
                </div>
              </aside>
            </div>
          </div>

          <Modal
            ouverte={modaleConfirmationOuverte}
            titre="Entree en stock confirmee"
            fermetureAutorisee={false}
            actions={
              <>
                <Button
                  variant="secondary"
                  onClick={() => navigate("/journaux-mouvements")}
                >
                  Retour aux journaux
                </Button>
                <Button
                  variant="primary"
                  onClick={() =>
                    navigate(
                      `/journaux-mouvements/${journalId}/entree-stock/recapitulatif`,
                      {
                        state: {
                          journal,
                          mouvements: mouvementsCrees,
                          emplacements,
                          conditionnements,
                        },
                      },
                    )
                  }
                >
                  Voir le recapitulatif
                </Button>
              </>
            }
          >
            <p>
              Tous les mouvements ont ete enregistres avec succes. Les stocks et
              les emplacements ont ete mis a jour.
            </p>
          </Modal>
        </div>
      </section>
    </div>
  );
}

export default AffectationStockMine;
