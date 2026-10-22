import { useEffect, useMemo, useState } from "react";
import Sidebar from "../components/Sidebar";
import {
  chargerActiviteEntrepot,
  chargerCapacitesEntrepot,
  chargerEntrepot,
} from "../services/entrepotService";
import { construireNiveaux } from "../utils/rack";
import NewRackview from "../new-pages/rackview/NewRackView";
import styles from "./css/Rackview.module.css";
import { useNavigate } from "react-router-dom";

// Ligne qui résume le stock d'un (emplacement, article) avant la période.
const SOLDE_INITIAL = "SOLDE_INITIAL";

const formaterNombre = (valeur) => (valeur ?? 0).toLocaleString("fr-FR");
const formaterVariation = (valeur) => (valeur > 0 ? `+${formaterNombre(valeur)}` : formaterNombre(valeur));
const formaterJour = (jour) => new Date(`${jour}T00:00:00`).toLocaleDateString("fr-FR");
const formaterDateHeure = (valeur) =>
  new Date(valeur).toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

// ENTREE -> « Entree », AJUSTEMENT_POSITIF -> « Ajustement positif »
const libelleType = (type) => {
  const texte = String(type ?? "").replaceAll("_", " ").toLowerCase();
  return texte.charAt(0).toUpperCase() + texte.slice(1);
};

function RackView() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();


  // Structure (une seule fois), mouvements (à chaque changement de date) et
  // règles de capacité (une seule fois).
  const [allData, setAllData] = useState(null);
  const [activites, setActivites] = useState([]);
  const [listesCapacite, setListesCapacite] = useState({ conditionnements: [], palettes: [] });
  const [rackSelectionne, setRackSelectionne] = useState(null);
  const [emplacementSelectionne, setEmplacementSelectionne] = useState(null);
  const [dateDebut, setDateDebut] = useState(""); // vide = aujourd'hui
  const [dateFin, setDateFin] = useState("");
  const [chargement, setChargement] = useState(true);
  const [periodeChargee, setPeriodeChargee] = useState(null);
  const [erreur, setErreur] = useState("");
  const [erreurActivite, setErreurActivite] = useState("");

  const periodeInvalide = Boolean(dateDebut && dateFin && dateFin < dateDebut);
  // Identifie la période demandée : les chiffres affichés sont à jour quand
  // periodeChargee la rejoint.
  const periodeDemandee = `${dateDebut || dateFin}|${dateFin}`;
  const chargementActivite = !periodeInvalide && periodeChargee !== periodeDemandee;

  useEffect(() => {
    let annule = false;
    async function charger() {
      try {
        const response = await chargerEntrepot(springUrl);
        if (annule) return;
        setAllData(response);
        // On lit la réponse, pas allData : allData n'est pas encore à jour ici.
        setRackSelectionne(response.racks?.[0] ?? null);
      } catch (e) {
        if (!annule) setErreur(e.message || "Impossible de charger l'entrepôt.");
      } finally {
        if (!annule) setChargement(false);
      }
    }
    charger();
    return () => {
      annule = true;
    };
  }, [springUrl]);

  // Capacités : sans elles, la page s'affiche simplement sans niveau d'eau.
  useEffect(() => {
    let annule = false;
    chargerCapacitesEntrepot(springUrl)
      .then((listes) => {
        if (!annule) setListesCapacite(listes);
      })
      .catch(() => {});
    return () => {
      annule = true;
    };
  }, [springUrl]);

  // Les mouvements dépendent de la période choisie.
  useEffect(() => {
    if (periodeInvalide) return undefined;
    let annule = false;
    chargerActiviteEntrepot(springUrl, dateDebut || dateFin, dateFin)
      .then((lignes) => {
        if (annule) return;
        setActivites(Array.isArray(lignes) ? lignes : []);
        setErreurActivite("");
      })
      .catch((e) => {
        if (!annule) setErreurActivite(e.message || "Impossible de charger les mouvements.");
      })
      .finally(() => {
        if (!annule) setPeriodeChargee(`${dateDebut || dateFin}|${dateFin}`);
      });
    return () => {
      annule = true;
    };
  }, [springUrl, dateDebut, dateFin, periodeInvalide]);

  const racks = useMemo(() => allData?.racks ?? [], [allData]);
  const emplacements = useMemo(() => allData?.emplacements ?? [], [allData]);

  // Cœur de la page : la liste de base, regroupée par emplacement.
  // stockFin = somme de toutes les quantités (solde initial compris) ;
  // variation et nbMouvements ne comptent que les vrais mouvements.
  const parEmplacement = useMemo(() => {
    const resultat = new Map();

    activites.forEach((ligne) => {
      const element = resultat.get(ligne.emplacementId) ?? {
        stockFin: 0,
        variation: 0,
        nbMouvements: 0,
        articles: new Map(),
        lignes: [],
      };

      element.stockFin += ligne.quantite;
      if (ligne.typeMouvement !== SOLDE_INITIAL) {
        element.variation += ligne.quantite;
        element.nbMouvements += 1;
      }

      const article = element.articles.get(ligne.articleId) ?? {
        nomArticle: ligne.nomArticle,
        stock: 0,
      };
      article.stock += ligne.quantite;
      element.articles.set(ligne.articleId, article);

      element.lignes.push(ligne);
      resultat.set(ligne.emplacementId, element);
    });

    return resultat;
  }, [activites]);

  // Une ligne par emplacement : stock, variation, mouvements, article présent.
  const activiteParEmplacement = useMemo(() => {
    const resultat = new Map();

    parEmplacement.forEach((element, emplacementId) => {
      const presents = [...element.articles.values()]
        .filter((article) => article.stock > 0)
        .sort((a, b) => b.stock - a.stock);

      resultat.set(emplacementId, {
        emplacementId,
        stockFin: element.stockFin,
        variation: element.variation,
        nbMouvements: element.nbMouvements,
        nomArticle: presents[0]?.nomArticle ?? null,
        nbArticles: presents.length,
      });
    });

    return resultat;
  }, [parEmplacement]);

  // Capacité en pièces d'un emplacement : unités par palette × pièces par unité,
  // pour l'article qui s'y trouve à la date de fin (donc valable aussi pour le
  // passé).
  const capaciteParEmplacement = useMemo(() => {
    const capacites = new Map();

    parEmplacement.forEach((element, emplacementId) => {
      let meilleure = 0;

      element.articles.forEach((infos, articleId) => {
        if (infos.stock <= 0) return;
        const conditionnement = listesCapacite.conditionnements.find(
          (candidat) => candidat.articleId === articleId,
        );
        const palette = listesCapacite.palettes.find(
          (candidat) => candidat.articleConditionnementId === conditionnement?.id,
        );
        if (!conditionnement?.quantitePieceStandard || !palette?.quantiteMaximale) return;

        meilleure = Math.max(
          meilleure,
          palette.quantiteMaximale * conditionnement.quantitePieceStandard,
        );
      });

      if (meilleure > 0) capacites.set(emplacementId, meilleure);
    });

    return capacites;
  }, [parEmplacement, listesCapacite]);

  const infosStockEmplacement = (emplacement) => {
    const ligne = activiteParEmplacement.get(emplacement.id);
    const stock = ligne?.stockFin ?? 0;
    const capacite = capaciteParEmplacement.get(emplacement.id) ?? 0;
    return {
      stock,
      capacite,
      // De 0 à 100 ; 0 quand la capacité est inconnue (emplacement vide).
      taux: capacite > 0 ? Math.min(100, Math.round((Math.max(stock, 0) / capacite) * 100)) : 0,
      variation: ligne?.variation ?? 0,
      nbMouvements: ligne?.nbMouvements ?? 0,
      nomArticle: ligne?.nomArticle ?? null,
      nbArticles: ligne?.nbArticles ?? 0,
    };
  };

  // Totaux par rack : on additionne les lignes de ses emplacements.
  const totauxParRack = useMemo(() => {
    const totaux = {};
    emplacements.forEach((emplacement) => {
      const ligne = activiteParEmplacement.get(emplacement.id);
      const total = (totaux[emplacement.rackId] ??= {
        stock: 0,
        variation: 0,
        nbMouvements: 0,
        emplacements: 0,
        occupes: 0,
      });
      total.emplacements += 1;
      total.stock += ligne?.stockFin ?? 0;
      total.variation += ligne?.variation ?? 0;
      total.nbMouvements += ligne?.nbMouvements ?? 0;
      if ((ligne?.stockFin ?? 0) > 0) total.occupes += 1;
    });
    return totaux;
  }, [emplacements, activiteParEmplacement]);

  const totalRack = totauxParRack[rackSelectionne?.id] ?? {
    stock: 0,
    variation: 0,
    nbMouvements: 0,
    emplacements: 0,
    occupes: 0,
  };
  const totalGeneral = Object.values(totauxParRack).reduce(
    (somme, total) => ({
      stock: somme.stock + total.stock,
      nbMouvements: somme.nbMouvements + total.nbMouvements,
    }),
    { stock: 0, nbMouvements: 0 },
  );

  // Remplissage des emplacements occupés du rack : stock ÷ capacité, en pièces.
  // Un emplacement vide n'a pas de capacité connue : il n'entre pas dans le calcul.
  const remplissageRack = useMemo(() => {
    let stock = 0;
    let capacite = 0;

    emplacements.forEach((emplacement) => {
      if (emplacement.rackId !== rackSelectionne?.id) return;
      const capaciteEmplacement = capaciteParEmplacement.get(emplacement.id) ?? 0;
      if (!(capaciteEmplacement > 0)) return;

      const ligne = activiteParEmplacement.get(emplacement.id);
      stock += Math.min(Math.max(ligne?.stockFin ?? 0, 0), capaciteEmplacement);
      capacite += capaciteEmplacement;
    });

    return capacite > 0 ? Math.round((stock / capacite) * 100) : null;
  }, [emplacements, activiteParEmplacement, capaciteParEmplacement, rackSelectionne]);

  // Chaque case porte ses chiffres et son niveau d'eau.
  const niveaux = construireNiveaux(rackSelectionne, emplacements, (emplacement) => {
    const infos = infosStockEmplacement(emplacement);
    return { infos, taux: infos.taux };
  });

  const occupation =
    totalRack.emplacements > 0
      ? Math.round((totalRack.occupes / totalRack.emplacements) * 100)
      : 0;

  const libellePeriode = (() => {
    if (!dateDebut && !dateFin) return "Aujourd'hui";
    const debut = dateDebut || dateFin;
    if (!dateFin || dateFin === debut) return formaterJour(debut);
    return `Du ${formaterJour(debut)} au ${formaterJour(dateFin)}`;
  })();

  const choisirRack = (rack) => {
    setRackSelectionne(rack);
    setEmplacementSelectionne(null);
  };

  const revenirAujourdhui = () => {
    setDateDebut("");
    setDateFin("");
  };

  const infosSelection = emplacementSelectionne
    ? infosStockEmplacement(emplacementSelectionne)
    : null;

  // Détail de l'emplacement cliqué : ses mouvements, du plus récent au plus
  // ancien, avec le solde de l'article après chacun.
  const detailSelection = useMemo(() => {
    if (!emplacementSelectionne) return { lignes: [], stockDebut: 0 };

    const lignesBrutes = parEmplacement.get(emplacementSelectionne.id)?.lignes ?? [];
    const soldes = new Map();
    let stockDebut = 0;
    const lignes = [];

    lignesBrutes.forEach((ligne) => {
      const solde = (soldes.get(ligne.articleId) ?? 0) + ligne.quantite;
      soldes.set(ligne.articleId, solde);

      if (ligne.typeMouvement === SOLDE_INITIAL) {
        stockDebut += ligne.quantite;
      } else {
        lignes.push({ ...ligne, soldeApres: solde });
      }
    });

    return { lignes: lignes.reverse(), stockDebut };
  }, [emplacementSelectionne, parEmplacement]);

  return (
    <div className={styles.shell}>
      <Sidebar />

      <main className={styles.page}>
        <header className={styles.header}>
          <h1>Entrepôt</h1>
          <p>
            {racks.length} rack{racks.length > 1 ? "s" : ""} · {emplacements.length} emplacement
            {emplacements.length > 1 ? "s" : ""}
          </p>
        </header>

        <section className={styles.filtre} aria-label="Période">
          <label>
            <span>Du</span>
            <input
              max={dateFin || undefined}
              onChange={(event) => setDateDebut(event.target.value)}
              type="date"
              value={dateDebut}
            />
          </label>
          <label>
            <span>Au</span>
            <input
              min={dateDebut || undefined}
              onChange={(event) => setDateFin(event.target.value)}
              type="date"
              value={dateFin}
            />
          </label>
          <button
            className={styles.bouton}
            disabled={!dateDebut && !dateFin}
            onClick={revenirAujourdhui}
            type="button"
          >
            Aujourd’hui
          </button>
          <p className={styles.periode}>
            {libellePeriode}
            {chargementActivite && <em> · Chargement…</em>}
          </p>
        </section>

        {periodeInvalide && (
          <p className={styles.error} role="alert">
            La date de fin doit être postérieure ou égale à la date de début.
          </p>
        )}
        {erreur && <p className={styles.error} role="alert">{erreur}</p>}
        {erreurActivite && <p className={styles.error} role="alert">{erreurActivite}</p>}

        {chargement ? (
          <p className={styles.message}>Chargement de l’entrepôt…</p>
        ) : racks.length === 0 ? (
          <p className={styles.message}>Aucun rack pour le moment.</p>
        ) : (
          <>
            <section className={styles.bande} aria-label="Chiffres du rack">
              <div>
                <span>Stock du rack</span>
                <strong>{formaterNombre(totalRack.stock)} pcs</strong>
              </div>
              <div>
                <span>Remplissage</span>
                <strong>{remplissageRack === null ? "—" : `${remplissageRack} %`}</strong>
              </div>
              <div>
                <span>Variation</span>
                <strong
                  className={
                    totalRack.variation > 0
                      ? styles.hausse
                      : totalRack.variation < 0
                        ? styles.baisse
                        : undefined
                  }
                >
                  {formaterVariation(totalRack.variation)} pcs
                </strong>
              </div>
              <div>
                <span>Mouvements</span>
                <strong>{formaterNombre(totalRack.nbMouvements)}</strong>
              </div>
              <div>
                <span>Entrepôt entier</span>
                <strong>
                  {formaterNombre(totalGeneral.stock)} pcs · {formaterNombre(totalGeneral.nbMouvements)} mvts
                </strong>
              </div>
            </section>
            <div style={{width:"100%",display:"flex",justifyContent:"end",margin:"20px"} } className="ajout">
              <button style={{width:"20%",height:"40px"}} onClick={() =>  navigate(`/rack/create/lastRack=${racks?.[racks.length - 1]?.name}`)} >ajouter un rack</button>
              <button style={{width:"20%",height:"40px"}} >ajouter un emplacement</button>
            </div>

            <NewRackview
              racks={racks}
              rackSelectionne={rackSelectionne}
              onRackChange={choisirRack}
              niveaux={niveaux}
              occupation={occupation}
              emplacementSelectionneId={emplacementSelectionne?.id}
              onSelect={setEmplacementSelectionne}
              renderCase={({ emplacement, infos }) => (
                <>
                  <span className={styles.code}>{emplacement.nomEmplacement}</span>
                  {infos.stock > 0 ? (
                    <>
                      {infos.nomArticle && (
                        <span className={styles.article}>
                          {infos.nbArticles > 1 ? `${infos.nbArticles} articles` : infos.nomArticle}
                        </span>
                      )}
                      <span className={styles.etat}>{formaterNombre(infos.stock)} pcs</span>
                    </>
                  ) : (
                    <span className={styles.vide}>Vide</span>
                  )}
                  {infos.variation !== 0 && (
                    <span
                      className={`${styles.variation} ${infos.variation > 0 ? styles.hausse : styles.baisse}`}
                    >
                      {formaterVariation(infos.variation)}
                    </span>
                  )}
                </>
              )}
            />

            {emplacementSelectionne && infosSelection && (
              <>
                <div className={styles.detail}>
                  <strong>{emplacementSelectionne.nomEmplacement}</strong>{" "}
                  <span>
                    · {rackSelectionne?.name} · Niveau {emplacementSelectionne.numeroEtage} ·{" "}
                    {formaterNombre(infosSelection.stock)} pièces en stock
                    {infosSelection.capacite > 0 && (
                      <> sur {formaterNombre(infosSelection.capacite)} ({infosSelection.taux} %)</>
                    )}{" "}
                    · variation {formaterVariation(infosSelection.variation)} ·{" "}
                    {formaterNombre(infosSelection.nbMouvements)} mouvement
                    {infosSelection.nbMouvements > 1 ? "s" : ""}
                  </span>
                </div>

                <section className={styles.historique} aria-label="Mouvements de l'emplacement">
                  <header className={styles.historiqueEntete}>
                    <h3>Mouvements · {emplacementSelectionne.nomEmplacement}</h3>
                    <p>
                      Stock au début : <strong>{formaterNombre(detailSelection.stockDebut)} pcs</strong>
                      {" · "}
                      à la fin : <strong>{formaterNombre(infosSelection.stock)} pcs</strong>
                    </p>
                  </header>

                  {detailSelection.lignes.length === 0 ? (
                    <p className={styles.message}>Aucun mouvement sur cette période.</p>
                  ) : (
                    <div className={styles.tableDefile}>
                      <table className={styles.tableHistorique}>
                        <thead>
                          <tr>
                            <th>Date</th>
                            <th>Article</th>
                            <th>Mouvement</th>
                            <th>Quantité</th>
                            <th>Solde</th>
                            <th>Journal</th>
                            <th>Opérateur</th>
                          </tr>
                        </thead>
                        <tbody>
                          {detailSelection.lignes.map((ligne) => (
                            <tr key={ligne.id}>
                              <td>{formaterDateHeure(ligne.date)}</td>
                              <td>{ligne.nomArticle}</td>
                              <td>{libelleType(ligne.typeMouvement)}</td>
                              <td className={ligne.quantite > 0 ? styles.hausse : styles.baisse}>
                                {formaterVariation(ligne.quantite)}
                              </td>
                              <td>{formaterNombre(ligne.soldeApres)}</td>
                              <td>{ligne.journalReference ?? "—"}</td>
                              <td>{ligne.matricule ?? "—"}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </section>
              </>
            )}
          </>
        )}
      </main>
    </div>
  );
}
export default RackView;
