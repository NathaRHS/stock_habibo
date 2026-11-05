import { useEffect, useState } from "react";
import { ArrowDown, ArrowUp } from "lucide-react";
import PageLayout from "../components/PageLayout";
import Button from "../components/Button";
import { requeteJson } from "../services/affectationStockService";
import "./css/ParametrageSuggestion.css";

const springUrl = import.meta.env.VITE_SPRING_URL;

// Les quatre critères du score. `cle` est le nom du réglage côté serveur.
const CRITERES = [
  {
    cle: "poids_proximite",
    libelle: "Proximité de la sortie",
    aide: "Favorise les emplacements proches de la sortie.",
  },
  {
    cle: "poids_capacite",
    libelle: "Capacité disponible",
    aide: "Favorise les emplacements qui peuvent recevoir toute la quantité.",
  },
  {
    cle: "poids_regroupement",
    libelle: "Regroupement",
    aide: "Favorise les emplacements qui contiennent déjà le même article.",
  },
  {
    cle: "poids_fiabilite",
    libelle: "Fiabilité",
    aide: "Neutre pour l'instant : les anomalies d'inventaire ne sont pas encore prises en compte, tous les emplacements ont la même note.",
  },
];

// Cherche la valeur d'un réglage dans la liste envoyée par le serveur.
function trouverValeur(liste, cle) {
  const reglage = liste.find((element) => element.cle === cle);
  return Number(reglage.valeur);
}

// Les racks sans ordre (ordre vide) passent à la fin.
function trierParOrdre(racks) {
  return [...racks].sort((a, b) => (a.ordre ?? 9999) - (b.ordre ?? 9999));
}

function ParametrageSuggestion() {
  // Réglages du score : { poids_proximite: 25, ... } et score d'un emplacement vide.
  const [poids, setPoids] = useState({});
  const [scoreVide, setScoreVide] = useState(60);
  // Racks, du plus proche de la sortie au plus loin.
  const [racks, setRacks] = useState([]);
  const [chargement, setChargement] = useState(true);
  const [message, setMessage] = useState("");
  const [erreur, setErreur] = useState("");

  // Chargement de la page : les réglages, puis les racks.
  useEffect(() => {
    async function charger() {
      try {
        const reglages = await requeteJson(`${springUrl}/optimisation/parametres`);
        const listeRacks = await requeteJson(`${springUrl}/rack`);

        const poidsLus = {};
        for (const critere of CRITERES) {
          poidsLus[critere.cle] = trouverValeur(reglages, critere.cle);
        }
        setPoids(poidsLus);
        setScoreVide(trouverValeur(reglages, "score_emplacement_vide"));
        setRacks(trierParOrdre(listeRacks));
      } catch (e) {
        setErreur(e.message);
      } finally {
        setChargement(false);
      }
    }
    charger();
  }, []);

  // Somme des quatre poids : elle doit faire exactement 100 pour enregistrer.
  let total = 0;
  for (const critere of CRITERES) {
    total += poids[critere.cle] ?? 0;
  }
  const reste = 100 - total;

  // Garde une valeur saisie entre 0 et 100 (le champ accepte n'importe quoi au clavier).
  function limiter(valeur) {
    return Math.min(100, Math.max(0, Number(valeur)));
  }

  function changerPoids(cle, valeur) {
    setPoids({ ...poids, [cle]: limiter(valeur) });
  }

  async function enregistrerReglages() {
    setMessage("");
    setErreur("");
    try {
      const demandes = CRITERES.map((critere) => ({
        cle: critere.cle,
        valeur: poids[critere.cle],
      }));
      demandes.push({ cle: "score_emplacement_vide", valeur: scoreVide });

      await requeteJson(`${springUrl}/optimisation/parametres`, {
        method: "PUT",
        body: JSON.stringify(demandes),
      });
      setMessage("Réglages enregistrés.");
    } catch (e) {
      setErreur(e.message);
    }
  }

  // Échange un rack avec son voisin (decalage = -1 pour monter, +1 pour descendre).
  function deplacerRack(index, decalage) {
    const cible = index + decalage;
    if (cible < 0 || cible >= racks.length) return;

    const nouvelleListe = [...racks];
    const rackDeplace = nouvelleListe[index];
    nouvelleListe[index] = nouvelleListe[cible];
    nouvelleListe[cible] = rackDeplace;
    setRacks(nouvelleListe);
  }

  async function enregistrerOrdre() {
    setMessage("");
    setErreur("");
    try {
      const ids = racks.map((rack) => rack.id);
      const resultat = await requeteJson(`${springUrl}/rack/ordre`, {
        method: "PUT",
        body: JSON.stringify(ids),
      });
      setRacks(trierParOrdre(resultat));
      setMessage("Ordre des racks enregistré.");
    } catch (e) {
      setErreur(e.message);
    }
  }

  return (
    <PageLayout
      breadcrumb="Administration / Paramétrage de la suggestion"
      kicker="Administration"
      title="Paramétrage de la suggestion"
      description="Réglez la façon dont l'application propose les emplacements de stockage."
    >
      {message && <p className="layout-message layout-message--success">{message}</p>}
      {erreur && (
        <p className="layout-message layout-message--error" role="alert">
          {erreur}
        </p>
      )}

      {chargement ? (
        <p className="layout-message layout-message--info">Chargement…</p>
      ) : (
        <>
          {/* ---------- 1. Importance des critères ---------- */}
          <section className="layout-panel">
            <header className="layout-panel-header">
              <div>
                <h2>Importance des critères</h2>
                <p>Le total des quatre critères doit faire 100 %.</p>
              </div>
            </header>

            <div className="param-contenu">
              {CRITERES.map((critere) => (
                <div className="param-ligne" key={critere.cle}>
                  <div>
                    <strong>{critere.libelle}</strong>
                    <p>{critere.aide}</p>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={poids[critere.cle] ?? 0}
                    onChange={(e) => changerPoids(critere.cle, e.target.value)}
                  />
                  <label className="param-saisie">
                    <input
                      type="number"
                      min="0"
                      max="100"
                      value={poids[critere.cle] ?? 0}
                      onChange={(e) => changerPoids(critere.cle, e.target.value)}
                    />
                    <span>%</span>
                  </label>
                </div>
              ))}

              <p className={total === 100 ? "param-total param-total--ok" : "param-total"}>
                Total : {total} %
                {reste > 0 && ` — il reste ${reste} % à répartir`}
                {reste < 0 && ` — ${-reste} % de trop`}
              </p>
            </div>
          </section>

          {/* ---------- 2. Emplacement vide ---------- */}
          <section className="layout-panel">
            <header className="layout-panel-header">
              <div>
                <h2>Emplacement vide</h2>
                <p>Note donnée à un emplacement qui ne contient encore aucun article (de 0 à 100).</p>
              </div>
            </header>

            <div className="param-contenu">
              <div className="param-ligne">
                <div>
                  <strong>Note d'un emplacement vide</strong>
                  <p>Un emplacement qui contient déjà le même article a toujours 100.</p>
                </div>
                <input
                  type="range"
                  min="0"
                  max="100"
                  value={scoreVide}
                  onChange={(e) => setScoreVide(limiter(e.target.value))}
                />
                <label className="param-saisie">
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={scoreVide}
                    onChange={(e) => setScoreVide(limiter(e.target.value))}
                  />
                </label>
              </div>
            </div>

            <div className="param-actions">
              <Button onClick={enregistrerReglages} disabled={total !== 100}>
                Enregistrer les réglages
              </Button>
            </div>
          </section>

          {/* ---------- 3. Ordre des racks ---------- */}
          <section className="layout-panel">
            <header className="layout-panel-header">
              <div>
                <h2>Ordre des racks</h2>
                <p>Du plus proche de la sortie (en haut) au plus éloigné (en bas).</p>
              </div>
            </header>

            {racks.length === 0 ? (
              <p className="param-vide">Aucun rack pour le moment.</p>
            ) : (
              <ul className="param-racks">
                {racks.map((rack, index) => (
                  <li key={rack.id}>
                    <span className="param-rang">{index + 1}</span>
                    <div>
                      <strong>{rack.name}</strong>
                      <p>
                        {rack.nombreEtages} niveau{rack.nombreEtages > 1 ? "x" : ""}
                        {rack.ordre == null && " · ordre non défini"}
                      </p>
                    </div>
                    <div className="param-fleches">
                      <button
                        type="button"
                        onClick={() => deplacerRack(index, -1)}
                        disabled={index === 0}
                        aria-label={`Monter ${rack.name}`}
                      >
                        <ArrowUp size={16} />
                      </button>
                      <button
                        type="button"
                        onClick={() => deplacerRack(index, 1)}
                        disabled={index === racks.length - 1}
                        aria-label={`Descendre ${rack.name}`}
                      >
                        <ArrowDown size={16} />
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            )}

            <div className="param-actions">
              <Button onClick={enregistrerOrdre} disabled={racks.length === 0}>
                Enregistrer l'ordre
              </Button>
            </div>
          </section>
        </>
      )}
    </PageLayout>
  );
}

export default ParametrageSuggestion;
