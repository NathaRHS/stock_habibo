import { useEffect, useMemo, useState } from "react";
import Sidebar from "../components/Sidebar";
import { chargerActiviteEntrepot, chargerEntrepot } from "../services/entrepotService";
import { construireNiveaux } from "../utils/rack";
import NewRackview from "../new-pages/rackview/NewRackView";
import styles from "./css/Rackview.module.css";

const formaterNombre = (valeur) => (valeur ?? 0).toLocaleString("fr-FR");
const formaterVariation = (valeur) => (valeur > 0 ? `+${formaterNombre(valeur)}` : formaterNombre(valeur));
const formaterJour = (jour) => new Date(`${jour}T00:00:00`).toLocaleDateString("fr-FR");

function RackView() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  // Structure (une seule fois) et activité (à chaque changement de date).
  const [allData, setAllData] = useState(null);
  const [activite, setActivite] = useState([]);
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

  // Les chiffres dépendent de la période choisie.
  useEffect(() => {
    if (periodeInvalide) return undefined;
    let annule = false;
    chargerActiviteEntrepot(springUrl, dateDebut || dateFin, dateFin)
      .then((lignes) => {
        if (annule) return;
        setActivite(lignes ?? []);
        setErreurActivite("");
      })
      .catch((e) => {
        if (!annule) setErreurActivite(e.message || "Impossible de charger les chiffres.");
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

  const activiteParEmplacement = useMemo(
    () => new Map(activite.map((ligne) => [ligne.emplacementId, ligne])),
    [activite],
  );

  const infosStockEmplacement = (emplacement) => {
    const ligne = activiteParEmplacement.get(emplacement.id);
    return {
      stock: ligne?.stockFin ?? 0,
      variation: ligne?.variation ?? 0,
      nbMouvements: ligne?.nbMouvements ?? 0,
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

  const niveaux = construireNiveaux(rackSelectionne, emplacements, (emplacement) => ({
    infos: infosStockEmplacement(emplacement),
  }));

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
                    <span className={styles.etat}>{formaterNombre(infos.stock)} pcs</span>
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
              <div className={styles.detail}>
                <strong>{emplacementSelectionne.nomEmplacement}</strong>{" "}
                <span>
                  · {rackSelectionne?.name} · Niveau {emplacementSelectionne.numeroEtage} ·{" "}
                  {formaterNombre(infosSelection.stock)} pièces en stock · variation{" "}
                  {formaterVariation(infosSelection.variation)} ·{" "}
                  {formaterNombre(infosSelection.nbMouvements)} mouvement
                  {infosSelection.nbMouvements > 1 ? "s" : ""}
                </span>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}
export default RackView;
