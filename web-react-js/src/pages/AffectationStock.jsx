import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Button from "../components/Button";
import {
  chargerDonneesAffectation,
  creerEntreeStock,
} from "../services/affectationStockService";
import { getAccessToken } from "../services/authService";
import styles from "./css/AffectationStock.module.css";

const cx = (...classes) => classes.filter(Boolean).join(" ");
const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toUpperCase();

function AffectationStock() {
  const { journalId } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [donnees, setDonnees] = useState(null);
  const [articleSelectionne, setArticleSelectionne] = useState(null);
  const [rackSelectionne, setRackSelectionne] = useState(null);
  const [emplacementSelectionne, setEmplacementSelectionne] = useState(null);
  const [quantite, setQuantite] = useState(1);
  const [affectations, setAffectations] = useState([]);
  const [recherche, setRecherche] = useState("");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    const loadingClass = styles["is-loading"];
    const revealingClass = styles["is-revealing"];
    document.body.classList.toggle(loadingClass, loading);
    if (!loading) {
      document.body.classList.add(revealingClass);
      const timer = window.setTimeout(
        () => document.body.classList.remove(revealingClass),
        800,
      );
      return () => window.clearTimeout(timer);
    }
    return () => document.body.classList.remove(loadingClass);
  }, [loading]);

  useEffect(() => {
    let actif = true;
    async function charger() {
      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        setLoading(false);
        return;
      }
      try {
        const resultat = await chargerDonneesAffectation(springUrl, journalId);
        if (!actif) return;
        setDonnees(resultat);
        const premierDetail = resultat.journal.details?.[0];
        const premierRack = resultat.racks?.[0];
        setArticleSelectionne(premierDetail?.articleId ?? null);
        setRackSelectionne(premierRack?.id ?? null);
      } catch (erreur) {
        if (actif) setError(erreur.message || "Chargement impossible.");
      } finally {
        if (actif) setLoading(false);
      }
    }
    charger();
    return () => {
      actif = false;
    };
  }, [journalId, springUrl, token]);

  const modele = useMemo(() => {
    if (!donnees) return null;
    const conditionnementParArticle = new Map();
    donnees.conditionnements.forEach((conditionnement) => {
      if (!conditionnementParArticle.has(conditionnement.articleId))
        conditionnementParArticle.set(
          conditionnement.articleId,
          conditionnement,
        );
    });
    const paletteParConditionnement = new Map(
      donnees.palettes.map((palette) => [
        palette.articleConditionnementId,
        palette,
      ]),
    );
    const stockParEmplacement = new Map();
    donnees.stocks
      .filter((stock) => stock.emplacementId != null && stock.quantiteStock > 0)
      .forEach((stock) => stockParEmplacement.set(stock.emplacementId, stock));
    return {
      conditionnementParArticle,
      paletteParConditionnement,
      stockParEmplacement,
    };
  }, [donnees]);

  const details = donnees?.journal?.details ?? [];
  const detailActuel = details.find((d) => d.articleId === articleSelectionne);
  const conditionnementActuel =
    modele?.conditionnementParArticle.get(articleSelectionne);
  const paletteActuelle = conditionnementActuel
    ? modele?.paletteParConditionnement.get(conditionnementActuel.id)
    : null;
  const uniteActuelle =
    conditionnementActuel?.nomConditionnement || "conditionnements";
  const capaciteActuelle = paletteActuelle?.quantiteMaximale ?? 0;
  const racks = donnees?.racks ?? [];
  const emplacementsRack = (donnees?.emplacements ?? [])
    .filter((e) => e.rackId === rackSelectionne)
    .filter((e) => normaliser(e.nomEmplacement).includes(normaliser(recherche)))
    .sort(
      (a, b) =>
        b.numeroEtage - a.numeroEtage ||
        a.nomEmplacement.localeCompare(b.nomEmplacement),
    );
  const rackActuel = racks.find((rack) => rack.id === rackSelectionne);
  const maxColonnes = Math.max(
    6,
    ...Object.values(
      emplacementsRack.reduce((groupes, emplacement) => {
        groupes[emplacement.numeroEtage] =
          (groupes[emplacement.numeroEtage] || 0) + 1;
        return groupes;
      }, {}),
    ),
  );

  function conditionnementArticle(articleId) {
    return modele?.conditionnementParArticle.get(articleId);
  }

  function stockEmplacement(emplacementId) {
    return modele?.stockParEmplacement.get(emplacementId) ?? null;
  }

  function capaciteArticle(articleId) {
    const conditionnement = conditionnementArticle(articleId);
    return conditionnement
      ? (modele?.paletteParConditionnement.get(conditionnement.id)
          ?.quantiteMaximale ?? 0)
      : 0;
  }

  function nombreConditionnementsStockes(stock) {
    if (!stock) return 0;
    const conditionnement = conditionnementArticle(stock.articleId);
    if (!conditionnement?.quantitePieceStandard) return 0;
    return Math.ceil(
      stock.quantiteStock / conditionnement.quantitePieceStandard,
    );
  }

  function quantitePlanifiee(emplacementId) {
    const demandee = affectations
      .filter(
        (a) =>
          a.emplacementId === emplacementId &&
          a.articleId === articleSelectionne,
      )
      .reduce((total, a) => total + a.nombreConditionnements, 0);
    const stock = stockEmplacement(emplacementId);
    const actuelle = nombreConditionnementsStockes(stock);
    return Math.min(demandee, Math.max(capaciteActuelle - actuelle, 0));
  }

  function reservePrevuePourLigne(affectation, index) {
    const capacite = capaciteArticle(affectation.articleId);
    const stock = stockEmplacement(affectation.emplacementId);
    const quantiteExistante = nombreConditionnementsStockes(stock);
    const demandesPrecedentes = affectations
      .slice(0, index)
      .filter(
        (a) =>
          a.articleId === affectation.articleId &&
          a.emplacementId === affectation.emplacementId,
      )
      .reduce((total, a) => total + a.nombreConditionnements, 0);
    const dejaPlacee = Math.min(
      demandesPrecedentes,
      Math.max(capacite - quantiteExistante, 0),
    );
    const placeRestante = Math.max(
      capacite - quantiteExistante - dejaPlacee,
      0,
    );
    return Math.max(affectation.nombreConditionnements - placeRestante, 0);
  }

  function quantiteAffectee(detailJournalId) {
    return affectations
      .filter((a) => a.detailJournalId === detailJournalId)
      .reduce((total, a) => total + a.nombreConditionnements, 0);
  }

  function informationsEmplacement(emplacement) {
    const stock = stockEmplacement(emplacement.id);
    const compatible = !stock || stock.articleId === articleSelectionne;
    const actuel = nombreConditionnementsStockes(stock);
    const planifie = compatible ? quantitePlanifiee(emplacement.id) : 0;
    const occupe = actuel + planifie;
    const disponible = Math.max(capaciteActuelle - occupe, 0);
    const articleStocke = details.find(
      (d) => d.articleId === stock?.articleId,
    )?.nomArticle;
    const taux = capaciteActuelle
      ? Math.min((occupe / capaciteActuelle) * 100, 100)
      : 0;
    return {
      stock,
      compatible,
      actuel,
      planifie,
      occupe,
      disponible,
      articleStocke,
      taux,
    };
  }

  const emplacementActuel = emplacementsRack.find(
    (e) => e.id === emplacementSelectionne,
  );
  const infoActuelle = emplacementActuel
    ? informationsEmplacement(emplacementActuel)
    : null;
  const restantActuel = detailActuel
    ? detailActuel.quantiteConditionnement - quantiteAffectee(detailActuel.id)
    : 0;

  function choisirArticle(articleId) {
    setArticleSelectionne(articleId);
    setEmplacementSelectionne(null);
    setQuantite(1);
    setError("");
  }

  function choisirRack(rackId) {
    setRackSelectionne(rackId);
    setEmplacementSelectionne(null);
  }

  function choisirEmplacement(emplacement) {
    const info = informationsEmplacement(emplacement);
    if (!info.compatible || !capaciteActuelle) return;
    setEmplacementSelectionne(emplacement.id);
    setQuantite(
      Math.max(1, Math.min(restantActuel, info.disponible || restantActuel)),
    );
    setError("");
  }

  function ajouterAffectation() {
    const valeur = Number(quantite);
    if (
      !detailActuel ||
      !emplacementActuel ||
      !Number.isInteger(valeur) ||
      valeur <= 0
    ) {
      setError("La quantité doit être un nombre entier strictement positif.");
      return;
    }
    if (valeur > restantActuel) {
      setError(
        `Il reste seulement ${restantActuel} ${uniteActuelle} à affecter.`,
      );
      return;
    }
    setAffectations((actuelles) => {
      const index = actuelles.findIndex(
        (a) =>
          a.detailJournalId === detailActuel.id &&
          a.emplacementId === emplacementActuel.id,
      );
      if (index === -1)
        return [
          ...actuelles,
          {
            detailJournalId: detailActuel.id,
            articleId: detailActuel.articleId,
            nomArticle: detailActuel.nomArticle,
            emplacementId: emplacementActuel.id,
            nomEmplacement: emplacementActuel.nomEmplacement,
            nombreConditionnements: valeur,
            unite: uniteActuelle,
          },
        ];
      return actuelles.map((a, i) =>
        i === index
          ? { ...a, nombreConditionnements: a.nombreConditionnements + valeur }
          : a,
      );
    });
    setEmplacementSelectionne(null);
    setQuantite(1);
  }

  function retirerAffectation(index) {
    setAffectations((actuelles) => actuelles.filter((_, i) => i !== index));
  }

  const planComplet =
    details.length > 0 &&
    details.every(
      (detail) =>
        quantiteAffectee(detail.id) === detail.quantiteConditionnement,
    );
  const totalAffecte = affectations.reduce(
    (total, affectation) => total + affectation.nombreConditionnements,
    0,
  );
  const totalAPlacer = details.reduce(
    (total, detail) => total + (detail.quantiteConditionnement || 0),
    0,
  );
  const totalReservePrevue = affectations.reduce(
    (total, affectation, index) =>
      total + reservePrevuePourLigne(affectation, index),
    0,
  );

  async function validerPlan() {
    if (!planComplet) {
      setError(
        "Tous les articles doivent être entièrement affectés avant la validation.",
      );
      return;
    }
    if (!window.confirm("Confirmer définitivement la mise en stock ?")) return;
    try {
      setSubmitting(true);
      setError("");
      const resultat = await creerEntreeStock(
        springUrl,
        journalId,
        affectations.map(
          ({ detailJournalId, emplacementId, nombreConditionnements }) => ({
            detailJournalId,
            emplacementId,
            nombreConditionnements,
          }),
        ),
      );
      setSuccess(
        `${resultat.length} mouvement(s) de stock créé(s) avec succès.`,
      );
    } catch (erreur) {
      setError(erreur.message || "La mise en stock a échoué.");
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) return <LoadingScreen styles={styles} />;
  if (!donnees)
    return (
      <main className={styles["content-container"]}>
        <p role="alert">{error || "La page d'affectation est indisponible."}</p>
      </main>
    );

  const journalValide = normaliser(donnees.journal.statut) === "VALIDE";

  return (
    <div className={styles["app-layout"]}>
      <AffectationSidebar styles={styles} />
      <main className={styles["main-wrapper"]}>
        <header className={styles["top-navbar"]}>
          <div className={styles.breadcrumbs}>
            <span>Entrées</span>
            <span>/</span>
            <span>Journaux validés</span>
            <span>/</span>
            <span className={styles.current}>{donnees.journal.reference}</span>
          </div>
          <div className={styles["top-actions"]}>
            <Button
              variant="secondary"
              icon={<SmallInfoIcon styles={styles} />}
            >
              Aide
            </Button>
          </div>
          <div className={styles["load-progress"]} aria-hidden="true" />
        </header>
        <div className={styles["content-container"]}>
          <header className={styles["page-header"]}>
            <div>
              <span className={styles["badge-kicker"]}>
                Affectation spatiale
              </span>
              <h1>Planifier la mise en stock</h1>
              <p>
                Sélectionnez un article, puis cliquez directement sur une
                palette du rack.
              </p>
            </div>
            <div className={styles["action-group"]}>
              <Button
                variant="secondary"
                onClick={() => navigate(`/journaux-mouvements/${journalId}`)}
              >
                Retour au journal
              </Button>
              <Button
                disabled={!planComplet || submitting || Boolean(success)}
                loading={submitting}
                onClick={validerPlan}
              >
                Valider le plan
              </Button>
            </div>
          </header>
          <section className={styles["summary-bar"]}>
            <Summary
              styles={styles}
              label="Journal de réception"
              value={donnees.journal.reference}
            />
            <Summary
              styles={styles}
              label="État du document"
              value={donnees.journal.statut}
              status
            />
            <Summary
              styles={styles}
              label="Volume à ranger"
              value={`${totalAPlacer} conditionnements`}
            />
            <Summary
              styles={styles}
              label="Progression globale"
              value={`${totalAffecte} / ${totalAPlacer} affectés`}
            />
          </section>
          {!journalValide && (
            <p className={styles["info-box"]} role="alert">
              Ce journal doit être au statut VALIDE avant sa mise en stock.
            </p>
          )}
          {error && (
            <p className={styles["info-box"]} role="alert">
              {error}
            </p>
          )}
          {success && (
            <p className={styles["info-box"]} role="status">
              {success}
            </p>
          )}
          <div className={styles["workspace-grid"]}>
            <section className={styles["panel-card"]}>
              <PanelHead
                styles={styles}
                title="Articles à placer"
                counter={`${details.length} articles`}
              />
              <div className={styles["product-list"]}>
                {details.map((detail) => {
                  const conditionnement = conditionnementArticle(
                    detail.articleId,
                  );
                  const restant =
                    detail.quantiteConditionnement -
                    quantiteAffectee(detail.id);
                  return (
                    <button
                      key={detail.id}
                      className={cx(
                        styles["product-card"],
                        detail.articleId === articleSelectionne &&
                          styles.active,
                      )}
                      onClick={() => choisirArticle(detail.articleId)}
                      type="button"
                    >
                      <div className={styles["product-card-header"]}>
                        <span className={styles["product-tag"]}>
                          {detail.nomArticle.slice(0, 2).toUpperCase()}
                        </span>
                        <div>
                          <h3>{detail.nomArticle}</h3>
                          <p>
                            {conditionnement?.nomConditionnement ||
                              "Conditionnement non configuré"}
                          </p>
                        </div>
                      </div>
                      <div className={styles["product-meta"]}>
                        <span>Reste à placer</span>
                        <b>{restant}</b>
                      </div>
                    </button>
                  );
                })}
              </div>
              <div className={styles["info-box"]}>
                Les palettes bleues contiennent le même article. Les palettes
                rouges contiennent un article incompatible.
              </div>
            </section>
            <section
              className={cx(styles["panel-card"], styles["warehouse-panel"])}
            >
              <div className={styles["warehouse-header-bar"]}>
                <div>
                  <h2>Entrepôt principal</h2>
                  <p>Vue frontale du rack</p>
                </div>
                <label className={styles["search-input-group"]}>
                  <span>⌕</span>
                  <input
                    value={recherche}
                    onChange={(e) => setRecherche(e.target.value)}
                    placeholder="Rechercher un emplacement..."
                  />
                </label>
              </div>
              <div className={styles["legend-row"]}>
                <Legend styles={styles} label="Libre" />
                <Legend styles={styles} label="Même article" state="same" />
                <Legend styles={styles} label="Presque plein" state="almost" />
                <Legend
                  styles={styles}
                  label="Incompatible / Occupé"
                  state="blocked"
                />
              </div>
              <div className={styles["rack-selector-tabs"]}>
                {racks.map((rack) => (
                  <button
                    key={rack.id}
                    className={cx(
                      styles["tab-btn"],
                      rack.id === rackSelectionne && styles.active,
                    )}
                    onClick={() => choisirRack(rack.id)}
                    type="button"
                  >
                    {rack.name}
                  </button>
                ))}
              </div>
              <div className={styles["rack-content-view"]}>
                <div className={styles["rack-title-banner"]}>
                  <h3>{rackActuel?.name || "RACK"}</h3>
                  <span>{rackActuel?.nombreEtages || 0} niveaux</span>
                </div>
                <div className={styles["rack-grid-container"]}>
                  {Array.from(
                    { length: rackActuel?.nombreEtages || 0 },
                    (_, index) => rackActuel.nombreEtages - index,
                  ).map((niveau) => {
                    const ligne = emplacementsRack.filter(
                      (e) => e.numeroEtage === niveau,
                    );
                    return (
                      <div
                        className={styles["rack-row"]}
                        style={{
                          gridTemplateColumns: `60px repeat(${maxColonnes}, 1fr)`,
                        }}
                        key={niveau}
                      >
                        <div className={styles["floor-label"]}>
                          Niveau {niveau}
                        </div>
                        {ligne.map((emplacement) => {
                          const info = informationsEmplacement(emplacement);
                          const presquePlein =
                            info.compatible && info.taux >= 75;
                          return (
                            <button
                              key={emplacement.id}
                              disabled={
                                !info.compatible ||
                                !capaciteActuelle ||
                                Boolean(success)
                              }
                              className={cx(
                                styles["slot-card"],
                                info.stock && info.compatible && styles.same,
                                presquePlein && styles.almost,
                                !info.compatible && styles.blocked,
                                emplacement.id === emplacementSelectionne &&
                                  styles.selected,
                              )}
                              onClick={() => choisirEmplacement(emplacement)}
                              type="button"
                            >
                              <div className={styles["slot-head"]}>
                                <span className={styles["slot-code"]}>
                                  {emplacement.nomEmplacement}
                                </span>
                              </div>
                              <div className={styles["slot-desc"]}>
                                {info.stock
                                  ? `${info.articleStocke || "Autre article"} · ${info.occupe}`
                                  : `Libre · ${capaciteActuelle || "—"} places`}
                              </div>
                              <div className={styles["slot-progress-bar"]}>
                                <div
                                  className={styles["slot-progress-fill"]}
                                  style={{ width: `${info.taux}%` }}
                                />
                              </div>
                            </button>
                          );
                        })}
                      </div>
                    );
                  })}
                </div>
                <div className={styles["aisle-divider"]}>
                  Allée de circulation
                </div>
              </div>
            </section>
            <aside
              className={cx(styles["panel-card"], styles["assignment-panel"])}
            >
              <PanelHead
                styles={styles}
                title="Affectation"
                counter="Plan temporaire"
              />
              <div className={styles["selection-summary"]}>
                <span className={styles["section-label"]}>
                  Article sélectionné
                </span>
                <div className={styles["selected-item-title"]}>
                  {detailActuel?.nomArticle || "Aucun article"}
                </div>
                <p>
                  {restantActuel} {uniteActuelle} à répartir
                </p>
              </div>
              <div className={styles["location-box"]}>
                <span className={styles["section-label"]}>
                  Palette sélectionnée
                </span>
                <div className={styles["loc-title"]}>
                  {emplacementActuel
                    ? `${emplacementActuel.nomEmplacement} · ${rackActuel?.name}`
                    : "Sélectionnez une palette"}
                </div>
                {infoActuelle && (
                  <div className={styles["capacity-info"]}>
                    <Capacity
                      styles={styles}
                      label="Contenu actuel"
                      value={`${infoActuelle.occupe} ${uniteActuelle}`}
                    />
                    <Capacity
                      styles={styles}
                      label="Capacité totale"
                      value={`${capaciteActuelle} ${uniteActuelle}`}
                    />
                    <Capacity
                      styles={styles}
                      label="Place disponible"
                      value={`${infoActuelle.disponible} ${uniteActuelle}`}
                    />
                  </div>
                )}
              </div>
              <div className={styles["form-group"]}>
                <span className={styles["section-label"]}>
                  Quantité à affecter
                </span>
                <div className={styles["quantity-control"]}>
                  <button
                    className={styles["qty-btn"]}
                    onClick={() =>
                      setQuantite((q) => Math.max(1, Number(q) - 1))
                    }
                    type="button"
                  >
                    −
                  </button>
                  <input
                    className={styles["qty-input"]}
                    min="1"
                    onChange={(e) => setQuantite(e.target.value)}
                    type="number"
                    value={quantite}
                  />
                  <button
                    className={styles["qty-btn"]}
                    onClick={() => setQuantite((q) => Number(q) + 1)}
                    type="button"
                  >
                    +
                  </button>
                </div>
                {infoActuelle && Number(quantite) > infoActuelle.disponible && (
                  <p className={styles["legal-note"]}>
                    {Number(quantite) - infoActuelle.disponible} {uniteActuelle}{" "}
                    seront dirigés vers la réserve.
                  </p>
                )}
                <Button
                  variant="assign"
                  disabled={
                    !emplacementActuel ||
                    restantActuel <= 0 ||
                    !journalValide ||
                    Boolean(success)
                  }
                  onClick={ajouterAffectation}
                >
                  Affecter à{" "}
                  {emplacementActuel?.nomEmplacement || "une palette"}
                </Button>
              </div>
              <div className={styles["plan-summary"]}>
                <div className={styles["plan-header"]}>
                  <b>Planification en cours</b>
                  <span>{affectations.length} lignes</span>
                </div>
                {affectations.length ? (
                  affectations.map((a, index) => {
                    const reserve = reservePrevuePourLigne(a, index);
                    return (
                      <div
                        className={styles["plan-row"]}
                        key={`${a.detailJournalId}-${a.emplacementId}`}
                      >
                        <div className={styles["item-desc"]}>
                          <b>{a.nomArticle}</b>
                          <br />
                          <span>
                            {a.nomEmplacement}
                            {reserve > 0 ? ` · ${reserve} en réserve` : ""}
                          </span>
                        </div>
                        <div className={styles["item-qty"]}>
                          {a.nombreConditionnements} {a.unite}
                        </div>
                        <button
                          aria-label="Retirer"
                          onClick={() => retirerAffectation(index)}
                          type="button"
                        >
                          ×
                        </button>
                      </div>
                    );
                  })
                ) : (
                  <p className={styles["legal-note"]}>
                    Aucune affectation ajoutée.
                  </p>
                )}
                {totalReservePrevue > 0 && (
                  <p className={styles["info-box"]}>
                    {totalReservePrevue} conditionnement(s) prévus en réserve.
                  </p>
                )}
              </div>
              <div className={styles["footer-action-area"]}>
                <Button
                  variant="validate"
                  disabled={!planComplet || Boolean(success)}
                  loading={submitting}
                  onClick={validerPlan}
                >
                  Valider le plan d'affectation
                </Button>
                <div className={styles["legal-note"]}>
                  Vérification automatique des capacités et règles de stock lors
                  de la soumission.
                </div>
              </div>
            </aside>
          </div>
        </div>
      </main>
    </div>
  );
}

function Summary({ styles, label, value, status = false }) {
  return (
    <div className={styles["summary-item"]}>
      <span className={styles.label}>{label}</span>
      <div className={styles.val}>
        {status && <i className={styles["status-dot"]} />}
        {value}
      </div>
    </div>
  );
}
function PanelHead({ styles, title, counter }) {
  return (
    <div className={styles["panel-head"]}>
      <h2>{title}</h2>
      <span className={styles.counter}>{counter}</span>
    </div>
  );
}
function Legend({ styles, label, state = "" }) {
  return (
    <div className={styles["legend-item"]}>
      <span
        className={cx(styles["legend-indicator"], state && styles[state])}
      />
      {label}
    </div>
  );
}
function Capacity({ styles, label, value }) {
  return (
    <div className={styles["capacity-row"]}>
      <span>{label}</span>
      <b>{value}</b>
    </div>
  );
}
function AffectationSidebar({ styles }) {
  return (
    <aside className={styles.sidebar}>
      <div className={styles["brand-header"]}>
        <div className={styles["brand-logo"]}>H</div>
        <div>
          <div className={styles["brand-title"]}>WMS Habibo</div>
          <div className={styles["brand-subtitle"]}>Entrepôt principal</div>
        </div>
      </div>
      <nav className={styles["nav-section"]}>
        <div className={styles["nav-label"]}>Opérations</div>
        <a className={styles["nav-item"]} href="/accueil">
          <HomeIcon styles={styles} />
          Vue d'ensemble
        </a>
        <a
          className={cx(styles["nav-item"], styles.active)}
          href="/journaux-mouvements"
        >
          <ChevronIcon styles={styles} />
          Entrées en stock
        </a>
        <a className={styles["nav-item"]} href="#sorties">
          <ChevronIcon styles={styles} reverse />
          Sorties
        </a>
        <a className={styles["nav-item"]} href="#inventaires">
          <CubeIcon styles={styles} />
          Inventaires
        </a>
        <div className={styles["nav-label"]} style={{ marginTop: 24 }}>
          Stockage
        </div>
        <a className={styles["nav-item"]} href="#plan">
          <GridIcon styles={styles} />
          Plan de l'entrepôt
        </a>
        <a className={styles["nav-item"]} href="#emplacements">
          <MenuIcon styles={styles} />
          Emplacements
        </a>
      </nav>
      <div className={styles["user-footer"]}>
        <span className={styles["user-avatar"]}>RA</span>
        <div className={styles["user-info"]}>
          <b>Responsable Admin</b>
          <span>Gestionnaire de stock</span>
        </div>
      </div>
    </aside>
  );
}

function LoadingScreen({ styles }) {
  const sk = (...noms) => cx(styles.sk, ...noms.map((nom) => styles[nom]));
  return (
    <div className={styles["app-layout"]}>
      <AffectationSidebar styles={styles} />
      <main className={styles["main-wrapper"]}>
        <header className={styles["top-navbar"]}>
          <div className={styles["breadcrumbs-skeleton"]}>
            {[54, 8, 108, 8, 94].map((width, index) => (
              <i
                className={sk("sk-line", "xs", index === 4 && "sk-strong")}
                style={{ width }}
                key={index}
              />
            ))}
          </div>
          <div className={styles["top-actions"]}>
            <div className={styles["sync-status"]}>
              <span className={styles["pulse-dot"]} />
              Chargement du plan d'affectation…
            </div>
          </div>
          <div className={styles["load-progress"]} />
        </header>
        <div className={styles["content-container"]}>
          <div className={styles["skeleton-screen"]}>
            <div className={styles["page-header"]}>
              <div>
                <i
                  className={sk("sk-pill")}
                  style={{ width: 158, marginBottom: 10 }}
                />
                <i
                  className={sk("sk-line", "xl", "sk-strong")}
                  style={{ width: 420, marginBottom: 10 }}
                />
                <i className={sk("sk-line", "sm")} style={{ width: 312 }} />
              </div>
              <div className={styles["action-group"]}>
                <i className={sk("sk-btn")} style={{ width: 108 }} />
                <i
                  className={sk("sk-btn", "sk-strong")}
                  style={{ width: 172 }}
                />
              </div>
            </div>
            <div className={styles["summary-bar"]}>
              {[128, 104, 96, 116].map((width, index) => (
                <div className={styles["summary-item"]} key={index}>
                  <i
                    className={sk("sk-line", "xs")}
                    style={{ width, marginBottom: 8 }}
                  />
                  <i
                    className={sk("sk-line", "md", "sk-strong")}
                    style={{ width: 80 + index * 10 }}
                  />
                </div>
              ))}
            </div>
            <div className={styles["workspace-grid"]}>
              <section className={styles["panel-card"]}>
                <SkeletonPanelHead styles={styles} sk={sk} />
                <div className={styles["product-list"]}>
                  {[0, 1].map((item) => (
                    <div className={styles["sk-product-card"]} key={item}>
                      <div className={styles["sk-product-head"]}>
                        <i
                          className={sk("sk-square")}
                          style={{ width: 32, height: 32 }}
                        />
                        <div className={styles["sk-stack"]}>
                          <i
                            className={sk("sk-line", "md", "sk-strong")}
                            style={{ width: 110 }}
                          />
                          <i
                            className={sk("sk-line", "xs")}
                            style={{ width: 86 }}
                          />
                        </div>
                      </div>
                      <div className={styles["sk-product-meta"]}>
                        <i
                          className={sk("sk-line", "xs")}
                          style={{ width: 78 }}
                        />
                        <i
                          className={sk("sk-line", "lg", "sk-strong")}
                          style={{ width: 34 }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </section>
              <section
                className={cx(styles["panel-card"], styles["warehouse-panel"])}
              >
                <div className={styles["warehouse-header-bar"]}>
                  <div>
                    <i
                      className={sk("sk-line", "md", "sk-strong")}
                      style={{ width: 145 }}
                    />
                    <i
                      className={sk("sk-line", "xs")}
                      style={{ width: 120, marginTop: 7 }}
                    />
                  </div>
                  <i className={sk("sk-btn")} style={{ width: 200 }} />
                </div>
                <div className={styles["sk-legend-row"]}>
                  {[0, 1, 2, 3].map((i) => (
                    <i
                      className={sk("sk-line", "xs")}
                      style={{ width: 80 }}
                      key={i}
                    />
                  ))}
                </div>
                <div className={styles["sk-tabs"]}>
                  {[0, 1, 2, 3].map((i) => (
                    <i className={sk("sk-btn")} style={{ width: 70 }} key={i} />
                  ))}
                </div>
                <div className={styles["rack-content-view"]}>
                  <i
                    className={sk("sk-btn", "sk-invert")}
                    style={{ width: "100%", height: 44 }}
                  />
                  <div className={styles["rack-grid-container"]}>
                    {[0, 1, 2].map((level) => (
                      <div className={styles["rack-row"]} key={level}>
                        <div className={styles["floor-label"]}>
                          <i
                            className={sk("sk-line", "xs")}
                            style={{ width: 46 }}
                          />
                        </div>
                        {[0, 1, 2, 3, 4, 5].map((slot) => (
                          <div className={styles["sk-slot"]} key={slot}>
                            <i
                              className={sk("sk-line", "sm", "sk-strong")}
                              style={{ width: 38 }}
                            />
                            <i
                              className={sk("sk-line", "xs")}
                              style={{
                                width: `${55 + slot * 4}%`,
                                marginTop: 6,
                              }}
                            />
                            <i
                              className={sk("sk-soft")}
                              style={{ height: 4, marginTop: 8 }}
                            />
                          </div>
                        ))}
                      </div>
                    ))}
                  </div>
                </div>
              </section>
              <aside
                className={cx(styles["panel-card"], styles["assignment-panel"])}
              >
                <SkeletonPanelHead styles={styles} sk={sk} />
                <div className={styles["selection-summary"]}>
                  <i className={sk("sk-line", "xs")} style={{ width: 105 }} />
                  <i
                    className={sk("sk-line", "md", "sk-strong")}
                    style={{ width: 150, marginTop: 9 }}
                  />
                </div>
                <div className={styles["location-box"]}>
                  <i className={sk("sk-line", "xs")} style={{ width: 115 }} />
                  <i
                    className={sk("sk-line", "lg", "sk-strong")}
                    style={{ width: 130, marginTop: 10 }}
                  />
                  {[0, 1, 2].map((i) => (
                    <div className={styles["sk-capacity-row"]} key={i}>
                      <i
                        className={sk("sk-line", "xs")}
                        style={{ width: 82 }}
                      />
                      <i
                        className={sk("sk-line", "xs", "sk-strong")}
                        style={{ width: 54 }}
                      />
                    </div>
                  ))}
                </div>
              </aside>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

function SkeletonPanelHead({ styles, sk }) {
  return (
    <div className={styles["panel-head"]}>
      <i className={sk("sk-line", "md")} style={{ width: 104 }} />
      <i className={sk("sk-pill")} style={{ width: 62 }} />
    </div>
  );
}
function HomeIcon({ styles }) {
  return (
    <svg className={styles.icon} viewBox="0 0 24 24">
      <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}
function ChevronIcon({ styles, reverse = false }) {
  return (
    <svg className={styles.icon} viewBox="0 0 24 24">
      <polyline points={reverse ? "15 18 9 12 15 6" : "9 18 15 12 9 6"} />
    </svg>
  );
}
function CubeIcon({ styles }) {
  return (
    <svg className={styles.icon} viewBox="0 0 24 24">
      <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z" />
    </svg>
  );
}
function GridIcon({ styles }) {
  return (
    <svg className={styles.icon} viewBox="0 0 24 24">
      <rect width="7" height="7" x="3" y="3" rx="1" />
      <rect width="7" height="7" x="14" y="3" rx="1" />
      <rect width="7" height="7" x="14" y="14" rx="1" />
      <rect width="7" height="7" x="3" y="14" rx="1" />
    </svg>
  );
}
function MenuIcon({ styles }) {
  return (
    <svg className={styles.icon} viewBox="0 0 24 24">
      <path d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  );
}
function SmallInfoIcon({ styles }) {
  return (
    <svg className={cx(styles.icon, styles["icon-sm"])} viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="8" x2="12" y2="12" />
      <line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}

export default AffectationStock;
