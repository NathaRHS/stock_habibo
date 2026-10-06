import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { AlertCircle, ArrowLeft, X } from "lucide-react";
import {
  chargerDonneesAffectation,
  chargerSuggestionEmplacements,
  creerEntreeStock,
} from "../../services/affectationStockService";
import Button from "../../components/Button";
import Modal from "../../components/Modal";
import Sidebar from "../../components/Sidebar";
import ProductList from "./ProductList";
import RackView from "./RackView";
import AssignmentPanel from "./AssignmentPanel";
import styles from "./AffectationStock.module.css";

const somme = (liste, valeur) =>
  liste.reduce((total, element) => total + (valeur(element) ?? 0), 0);

function AffectationStock() {
  const { journalId } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [ToutesLesDonnees, setToutesLesDonnees] = useState(null);
  const [chargement, setChargement] = useState(true);
  const [error, setError] = useState("");
  const [affectations, setAffectations] = useState([]);
  const [articleSelectionne, setArticleSelectionne] = useState(null);
  const [emplacementSelectionne, setEmplacementSelectionne] = useState(null);
  const [rackSelectionne, setRackSelectionne] = useState(null);
  const [quantite, setQuantite] = useState(1);
  const [suggestion, setSuggestion] = useState(null);
  const [chargementSuggestion, setChargementSuggestion] = useState(false);
  const [envoiEnCours, setEnvoiEnCours] = useState(false);
  const [mouvementsCrees, setMouvementsCrees] = useState(null);

  useEffect(() => {
    let annule = false;
    async function charger() {
      try {
        setChargement(true);
        setError("");
        const reponse = await chargerDonneesAffectation(springUrl, journalId);
        if (annule) return;
        setToutesLesDonnees(reponse);
        setRackSelectionne((actuel) => actuel ?? reponse.racks?.[0] ?? null);
      } catch (erreur) {
        if (!annule) setError(erreur.message || "Impossible de charger l'affectation.");
      } finally {
        if (!annule) setChargement(false);
      }
    }
    charger();
    return () => {
      annule = true;
    };
  }, [springUrl, journalId]);

  const journal = ToutesLesDonnees?.journal;
  const details = journal?.details ?? [];
  const emplacements = ToutesLesDonnees?.emplacements ?? [];
  const stocks = ToutesLesDonnees?.stocks ?? [];
  const palettes = ToutesLesDonnees?.palettes ?? [];
  const conditionnements = ToutesLesDonnees?.conditionnements ?? [];
  const racks = ToutesLesDonnees?.racks ?? [];

  const conditionnementDe = (articleId) =>
    conditionnements.find((conditionnement) => conditionnement.articleId === articleId);

  const quantitePlanifieeArticle = (detailId) =>
    somme(
      affectations.filter((affectation) => affectation.detailJournalId === detailId),
      (affectation) => affectation.nombreConditionnements,
    );

  const resteArticle = (detail) =>
    detail
      ? Math.max((detail.quantiteConditionnement ?? 0) - quantitePlanifieeArticle(detail.id), 0)
      : 0;

  const quantitePlanifieeEmplacement = (emplacementId) =>
    somme(
      affectations.filter((affectation) => affectation.emplacementId === emplacementId),
      (affectation) => affectation.nombreConditionnements,
    );

  const infosEmplacement = (emplacement) => {
    if (!emplacement) return null;

    const stock = stocks.find((element) => element.emplacementId === emplacement.id);
    const premiereAffectation = affectations.find(
      (affectation) => affectation.emplacementId === emplacement.id,
    );
    const detailPlanifie = details.find(
      (detail) => detail.id === premiereAffectation?.detailJournalId,
    );
    const articleIdPresent = stock?.articleId ?? detailPlanifie?.articleId;
    const conditionnement = conditionnementDe(articleIdPresent ?? articleSelectionne?.articleId);
    const palette = palettes.find(
      (element) => element.articleConditionnementId === conditionnement?.id,
    );
    const stockEnColis = conditionnement?.quantitePieceStandard
      ? (stock?.quantiteStock ?? 0) / conditionnement.quantitePieceStandard
      : 0;
    const planifie = quantitePlanifieeEmplacement(emplacement.id);
    const capacite = palette?.quantiteMaximale ?? 0;
    const occupe = stockEnColis + planifie;

    return {
      nomArticle: articleIdPresent ? conditionnementDe(articleIdPresent)?.nomArticle : null,
      capacite,
      occupe,
      planifie,
      placeRestante: Math.max(capacite - occupe, 0),
      tauxOccupation: capacite > 0 ? Math.min(Math.round((occupe / capacite) * 100), 100) : 0,
      incompatible: Boolean(
        articleSelectionne && articleIdPresent && articleIdPresent !== articleSelectionne.articleId,
      ),
      memeArticle: Boolean(articleSelectionne && articleIdPresent === articleSelectionne.articleId),
    };
  };

  const quantiteMaxPour = (emplacement) => {
    const infos = infosEmplacement(emplacement);
    if (!articleSelectionne || !infos || infos.incompatible) return 0;
    return Math.min(resteArticle(articleSelectionne), infos.placeRestante);
  };

  const selectionnerArticle = (detail) => {
    setArticleSelectionne(detail);
    setEmplacementSelectionne(null);
    setError("");
    if (suggestion?.detailJournalId !== detail.id) setSuggestion(null);
  };

  const selectionnerEmplacement = (emplacement) => {
    setEmplacementSelectionne(emplacement);
    setQuantite(Math.max(quantiteMaxPour(emplacement), 1));
    setError("");
  };

  const choisirRack = (rack) => {
    setRackSelectionne(rack);
    setEmplacementSelectionne(null);
  };

  const quantiteMax = quantiteMaxPour(emplacementSelectionne);

  const ajouterAuPlan = () => {
    const nombre = Number(quantite);
    if (!Number.isInteger(nombre) || nombre < 1 || nombre > quantiteMax) {
      setError(`Saisissez un nombre entier entre 1 et ${quantiteMax}.`);
      return;
    }
    setAffectations((actuelles) => [
      ...actuelles,
      {
        idTemporaire: crypto.randomUUID(),
        detailJournalId: articleSelectionne.id,
        emplacementId: emplacementSelectionne.id,
        nombreConditionnements: nombre,
      },
    ]);
    setQuantite(Math.max(quantiteMax - nombre, 1));
    setError("");
  };

  const retirerDuPlan = (idTemporaire) =>
    setAffectations((actuelles) =>
      actuelles.filter((affectation) => affectation.idTemporaire !== idTemporaire),
    );

  const demanderSuggestion = async () => {
    if (!articleSelectionne) return;
    try {
      setError("");
      setChargementSuggestion(true);
      const reponse = await chargerSuggestionEmplacements(
        springUrl,
        articleSelectionne.id,
        affectations.filter((affectation) => affectation.detailJournalId !== articleSelectionne.id),
      );
      setSuggestion(reponse);

      const premiere = reponse.suggestions?.[0];
      if (!premiere) {
        setEmplacementSelectionne(null);
        return;
      }
      const rack = racks.find((element) => element.id === premiere.rackId);
      if (rack) setRackSelectionne(rack);
      const emplacement = emplacements.find((element) => element.id === premiere.emplacementId);
      if (emplacement) selectionnerEmplacement(emplacement);
    } catch (erreur) {
      setError(erreur.message || "Impossible de calculer une suggestion.");
    } finally {
      setChargementSuggestion(false);
    }
  };

  const appliquerSuggestion = () => {
    if (!articleSelectionne || !suggestion) return;
    setAffectations((actuelles) => [
      ...actuelles.filter((affectation) => affectation.detailJournalId !== articleSelectionne.id),
      ...(suggestion.suggestions ?? []).map((element) => ({
        idTemporaire: crypto.randomUUID(),
        detailJournalId: articleSelectionne.id,
        emplacementId: element.emplacementId,
        nombreConditionnements: element.quantiteConditionnementsProposee,
      })),
    ]);
    setSuggestion(null);
  };

  const validerPlan = async () => {
    try {
      setError("");
      setEnvoiEnCours(true);
      const mouvements = await creerEntreeStock(
        springUrl,
        journalId,
        affectations.map(({ detailJournalId, emplacementId, nombreConditionnements }) => ({
          detailJournalId,
          emplacementId,
          nombreConditionnements,
        })),
      );
      setMouvementsCrees(mouvements ?? []);
    } catch (erreur) {
      setError(erreur.message || "Impossible de créer l'entrée en stock.");
    } finally {
      setEnvoiEnCours(false);
    }
  };

  const totalColis = somme(details, (detail) => detail.quantiteConditionnement);
  const colisPlanifies = somme(affectations, (affectation) => affectation.nombreConditionnements);
  const resteTotal = somme(details, resteArticle);
  const progression = totalColis > 0 ? Math.min(Math.round((colisPlanifies / totalColis) * 100), 100) : 0;
  const planComplet = details.length > 0 && resteTotal === 0;

  const suggestionActive =
    suggestion && suggestion.detailJournalId === articleSelectionne?.id ? suggestion : null;

  const emplacementsRack = emplacements.filter(
    (emplacement) => emplacement.rackId === rackSelectionne?.id,
  );
  const niveaux = Array.from(
    { length: rackSelectionne?.nombreEtages ?? 0 },
    (_, index) => rackSelectionne.nombreEtages - index,
  ).map((niveau) => ({
    niveau,
    cases: emplacementsRack
      .filter((emplacement) => emplacement.numeroEtage === niveau)
      .sort((a, b) => (a.ordreDansEtage ?? 0) - (b.ordreDansEtage ?? 0))
      .map((emplacement) => ({
        emplacement,
        infos: infosEmplacement(emplacement),
        suggestion: suggestionActive?.suggestions?.find(
          (element) => element.emplacementId === emplacement.id,
        ),
      })),
  }));
/*
niveau : 1,
cases : [
{

}
]


*/ 


  const casesRack = niveaux.flatMap((niveau) => niveau.cases);
  const occupationRack =
    casesRack.length > 0
      ? Math.round((casesRack.filter((element) => element.infos.occupe > 0).length / casesRack.length) * 100)
      : 0;

  const articles = details.map((detail) => ({
    detail,
    conditionnement: conditionnementDe(detail.articleId),
    total: detail.quantiteConditionnement ?? 0,
    reste: resteArticle(detail),
  }));

  const articleSuivant = (() => {
    if (!articleSelectionne) return null;
    const index = details.findIndex((detail) => detail.id === articleSelectionne.id);
    const ordre = [...details.slice(index + 1), ...details.slice(0, index)];
    return ordre.find((detail) => resteArticle(detail) > 0) ?? null;
  })();

  const lignesPlan = affectations.map((affectation) => {
    const detail = details.find((element) => element.id === affectation.detailJournalId);
    const emplacement = emplacements.find((element) => element.id === affectation.emplacementId);
    return {
      id: affectation.idTemporaire,
      nomArticle: detail?.nomArticle ?? "Article inconnu",
      nomEmplacement: emplacement?.nomEmplacement ?? "Emplacement inconnu",
      nomRack: racks.find((rack) => rack.id === emplacement?.rackId)?.name ?? emplacement?.nomRack ?? "",
      nomConditionnement: conditionnementDe(detail?.articleId)?.nomConditionnement ?? "colis",
      nombre: affectation.nombreConditionnements,
    };
  });

  return (
    <div className={styles.shell}>
      <Sidebar />
      
      <main className={styles.page}>
        <header className={styles.header}>
          <Link className={styles.back} to="/journaux-mouvements">
            <ArrowLeft size={16} aria-hidden="true" />
            Journaux
          </Link>
          <div className={styles.titleRow}>
            <div>
             {journal?.statut !== "AFFECTEE" ? <h1>Affectation du stock</h1> : <h1>Résumé de l'affectation </h1>} 
              <p>
                {journal ? (
                  <>
                    Journal <strong>{journal.reference}</strong>
                    {journal.statut && <span className={styles.status}>{journal.statut}</span>}
                  </>
                ) : (
                  "Rangez les colis reçus dans les emplacements du rack."
                )}
              </p>
            </div>
            {!chargement && details.length > 0 && (
              <div className={styles.progress} aria-label={`${progression} % des colis planifiés`}>
                <div className={styles.progressNumbers}>
                  <strong>{colisPlanifies}</strong>
                  <span>/ {totalColis} colis planifiés</span>
                </div>
                <div className={styles.progressTrack}>
                  <span style={{ width: `${progression}%` }} />
                </div>
              </div>
            )}
          </div>
        </header>

        {error && (
          <p className={styles.error} role="alert">
            <AlertCircle size={18} aria-hidden="true" />
            {error}
            <button aria-label="Fermer le message" onClick={() => setError("")} type="button">
              <X size={16} aria-hidden="true" />
            </button>
          </p>
        )}

        {chargement ? (
          <p className={styles.placeholder}>Chargement de l’entrepôt…</p>
        ) : !ToutesLesDonnees ? null : (
          <div className={styles.workspace}>
            
            <ProductList
              articles={articles}
              articleSelectionneId={articleSelectionne?.id}
              onSelect={selectionnerArticle}
              onSuggest={demanderSuggestion}
              chargementSuggestion={chargementSuggestion}
              suggestion={suggestionActive}
              
            />

            <RackView
              racks={racks}
              rackSelectionne={rackSelectionne}
              onRackChange={choisirRack}
              niveaux={niveaux}
              occupation={occupationRack}
              emplacementSelectionneId={emplacementSelectionne?.id}
              onSelect={selectionnerEmplacement}
              articleSelectionne={articleSelectionne}
              suggestion={suggestionActive}
              lignesExistantes={articleSelectionne ? quantitePlanifieeArticle(articleSelectionne.id) : 0}
              onApplySuggestion={appliquerSuggestion}
              onDismissSuggestion={() => setSuggestion(null)}
              onFocusEmplacement={(emplacementId) => {
                const emplacement = emplacements.find((element) => element.id === emplacementId);
                if (emplacement) selectionnerEmplacement(emplacement);
              }}
            />

            <AssignmentPanel
              article={articleSelectionne}
              resteArticle={resteArticle(articleSelectionne)}
              emplacement={emplacementSelectionne}
              nomRack={rackSelectionne?.name}
              infosEmplacement={infosEmplacement(emplacementSelectionne)}
              quantite={quantite}
              quantiteMax={quantiteMax}
              onQuantiteChange={setQuantite}
              onAjouter={ajouterAuPlan}
              articleSuivant={articleSuivant}
              onArticleSuivant={() => articleSuivant && selectionnerArticle(articleSuivant)}
              lignesPlan={lignesPlan}
              onRetirer={retirerDuPlan}
              resteTotal={resteTotal}
              planComplet={planComplet}
              envoiEnCours={envoiEnCours}
              onValider={validerPlan}
            />
          </div>
        )}
      </main>

      <Modal
        ouverte={mouvementsCrees !== null}
        titre="Entrée en stock confirmée"
        fermetureAutorisee={false}
        actions={
          <>
            <Button variant="secondary" onClick={() => navigate("/journaux-mouvements")}>
              Retour aux journaux
            </Button>
            <Button
              variant="primary"
              onClick={() =>
                navigate(`/journaux-mouvements/${journalId}/entree-stock/recapitulatif`, {
                  state: { journal, mouvements: mouvementsCrees, emplacements, conditionnements },
                })
              }
            >
              Voir le récapitulatif
            </Button>
          </>
        }
      >
        <p>
          Tous les mouvements ont été enregistrés. Les stocks et les emplacements ont été mis à
          jour.
        </p>
      </Modal>
    </div>
  );
}

export default AffectationStock;
