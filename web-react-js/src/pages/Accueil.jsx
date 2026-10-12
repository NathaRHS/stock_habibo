import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  Area,
  ComposedChart,
  Line,
  ResponsiveContainer,
  XAxis,
  YAxis,
} from "recharts";
import {
  ChevronDown,
  Plus,
  Search,
  TrendingDown,
  TrendingUp,
} from "lucide-react";
import Sidebar from "../components/Sidebar";
import {
  NOMS_MOIS,
  PERIODES,
  calculerIndicateurs,
  chargerTableauDeBord,
  etatDuStock,
  serieMensuelle,
} from "../services/tableauDeBord";
import "./css/Accueil.css";

// Mise en forme de la maquette : « 7,265 ».
const nombre = (valeur) => Number(valeur ?? 0).toLocaleString("en-US");

const pourcentage = (valeur) =>
  `${valeur > 0 ? "+" : ""}${valeur.toFixed(2)}%`;

function Variation({ valeur, clair }) {
  if (valeur === null || valeur === undefined) return null;
  const Icone = valeur < 0 ? TrendingDown : TrendingUp;
  return (
    <span className={`kpi-variation ${clair ? "kpi-variation--clair" : ""}`}>
      {pourcentage(valeur)}
      <Icone size={13} aria-hidden="true" />
    </span>
  );
}

// Fait monter un nombre jusqu'à sa valeur, en partant de celle déjà affichée :
// un changement de période anime donc la transition au lieu de sauter.
function useCompteur(cible, duree = 1000) {
  const [valeur, setValeur] = useState(0);
  const depart = useRef(0);

  useEffect(() => {
    const reduit = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dureeEffective = reduit ? 0 : duree;
    const debut = performance.now();
    const origine = depart.current;
    let image;

    const etape = (instant) => {
      const progression = dureeEffective
        ? Math.min(1, (instant - debut) / dureeEffective)
        : 1;
      // Décélération douce : la fin du compte ralentit.
      const adouci = 1 - Math.pow(1 - progression, 4);
      const courant = origine + (cible - origine) * adouci;
      depart.current = courant;
      setValeur(courant);
      if (progression < 1) image = requestAnimationFrame(etape);
    };

    image = requestAnimationFrame(etape);
    return () => cancelAnimationFrame(image);
  }, [cible, duree]);

  return Math.round(valeur);
}

function CarteIndicateur({ ton, titre, valeur, variation, ordre }) {
  const affichee = useCompteur(valeur);

  return (
    <article
      className={`kpi kpi--${ton} apparition`}
      style={{ "--i": ordre }}
    >
      <p className="kpi-titre">{titre}</p>
      <div className="kpi-ligne">
        <strong className="kpi-valeur">{nombre(affichee)}</strong>
        <Variation valeur={variation} clair={ton === "principal"} />
      </div>
    </article>
  );
}

const formaterAxe = (valeur) =>
  valeur >= 1000 ? `${Math.round(valeur / 1000)}K` : String(valeur);

function Graphique({ serie }) {
  return (
    <div className="evolution-graphique">
      <ResponsiveContainer width="100%" height="100%">
        <ComposedChart
          data={serie}
          margin={{ top: 8, right: 16, bottom: 0, left: -8 }}
        >
          <defs>
            <linearGradient id="evolution-degrade" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#bdbdbd" stopOpacity={0.45} />
              <stop offset="100%" stopColor="#bdbdbd" stopOpacity={0} />
            </linearGradient>
          </defs>
          <XAxis
            axisLine={false}
            dataKey="mois"
            tick={{ fill: "#9a9a9a", fontSize: 11 }}
            tickLine={false}
          />
          <YAxis
            axisLine={false}
            tick={{ fill: "#9a9a9a", fontSize: 11 }}
            tickFormatter={formaterAxe}
            tickLine={false}
            width={44}
          />
          {/* Le dégradé se révèle, puis les deux courbes se dessinent. */}
          <Area
            animationBegin={150}
            animationDuration={1500}
            animationEasing="ease-out"
            dataKey="entrees"
            fill="url(#evolution-degrade)"
            stroke="none"
            type="monotone"
          />
          <Line
            animationBegin={300}
            animationDuration={1500}
            animationEasing="ease-out"
            dataKey="sorties"
            dot={false}
            stroke="#7aa6e6"
            strokeDasharray="3 3"
            strokeWidth={1.2}
            type="monotone"
          />
          <Line
            animationBegin={0}
            animationDuration={1500}
            animationEasing="ease-out"
            dataKey="entrees"
            dot={false}
            stroke="var(--color-primary)"
            strokeWidth={3}
            type="monotone"
          />
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  );
}

// Trois pastilles dont la largeur suit la part de la ligne dans l'ensemble.
function Pastilles({ part }) {
  const premiere = Math.max(12, Math.round(part * 64));
  return (
    <span className="etat-pastilles" aria-hidden="true">
      <i style={{ width: premiere, background: "#141414", "--p": 0 }} />
      <i style={{ width: Math.max(9, Math.round(premiere * 0.6)), background: "#8a8a8a", "--p": 1 }} />
      <i style={{ width: Math.max(9, Math.round(premiere * 0.9)), background: "#dcdcdc", "--p": 2 }} />
    </span>
  );
}

function Accueil() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();
  const [donnees, setDonnees] = useState({ mouvements: [], stocks: [], articles: [] });
  const [chargement, setChargement] = useState(true);
  const [periode, setPeriode] = useState("jour");
  const [onglet, setOnglet] = useState("journaux");
  const [recherche, setRecherche] = useState("");

  useEffect(() => {
    let actif = true;
    chargerTableauDeBord(springUrl)
      .then((resultat) => {
        if (actif) setDonnees(resultat);
      })
      .finally(() => {
        if (actif) setChargement(false);
      });
    return () => {
      actif = false;
    };
  }, [springUrl]);

  const maintenant = useMemo(() => new Date(), []);

  const indicateurs = useMemo(
    () => calculerIndicateurs(donnees.mouvements, donnees.stocks, periode, maintenant),
    [donnees, periode, maintenant],
  );
  const serie = useMemo(
    () => serieMensuelle(donnees.mouvements, maintenant.getFullYear(), maintenant),
    [donnees.mouvements, maintenant],
  );
  const etat = useMemo(
    () => etatDuStock(donnees.stocks, donnees.articles),
    [donnees.stocks, donnees.articles],
  );

  const { prefixe, texte } = PERIODES[periode];
  const part = (valeur) => (etat.total ? valeur / etat.total : 0);

  const lignesEtat = [
    { libelle: "Stock normal", valeur: etat.normal },
    { libelle: "Stock faible", valeur: etat.faible },
    { libelle: "Ruptures", valeur: etat.rupture },
  ];

  return (
    <div className="accueil-container">
      <Sidebar />

      <section className="main-section">
        <header className="accueil-entete">
          <p className="accueil-fil">
            Dashboards <span>/</span> <strong>Par défaut</strong>
          </p>
          <label className="accueil-recherche">
            <Search size={15} aria-hidden="true" />
            <input
              aria-label="Rechercher"
              onChange={(event) => setRecherche(event.target.value)}
              placeholder="Rechercher"
              type="search"
              value={recherche}
            />
            <kbd>/</kbd>
          </label>
        </header>

        <main className="accueil-contenu">
          <div className="accueil-titre">
            <div>
              <h1>HABIBO GROUP</h1>
              <p>Statistique réelle sur la situation d’entrée et de sortie</p>
            </div>
            <label className="accueil-periode">
              <select
                aria-label="Période"
                onChange={(event) => setPeriode(event.target.value)}
                value={periode}
              >
                {Object.entries(PERIODES).map(([cle, { libelle }]) => (
                  <option key={cle} value={cle}>
                    {libelle}
                  </option>
                ))}
              </select>
              <ChevronDown size={14} aria-hidden="true" />
            </label>
          </div>

          <section className="kpi-liste" aria-label="Indicateurs">
            <CarteIndicateur
              ton="principal"
              ordre={0}
              titre={
                <>
                  Entrée {prefixe} : <b>{texte}</b>
                </>
              }
              valeur={indicateurs.entrees}
              variation={indicateurs.variationEntrees}
            />
            <CarteIndicateur
              ton="clair"
              ordre={1}
              titre={
                <>
                  Sortie {prefixe} : <b>{texte}</b>
                </>
              }
              valeur={indicateurs.sorties}
              variation={indicateurs.variationSorties}
            />
            <CarteIndicateur
              ton="lavande"
              ordre={2}
              titre="Total des mouvements"
              valeur={indicateurs.total}
              variation={indicateurs.variationTotal}
            />
            <CarteIndicateur
              ton="clair"
              ordre={3}
              titre="Unités disponibles"
              valeur={indicateurs.unitesDisponibles}
            />
          </section>

          <div className="accueil-grille">
            <section className="carte carte-evolution apparition" style={{ "--i": 4 }} aria-label="Évolution des mouvements">
              <header className="evolution-entete">
                <h2>Evolution des mouvements</h2>
                <button
                  className={onglet === "journaux" ? "actif" : ""}
                  onClick={() => setOnglet("journaux")}
                  type="button"
                >
                  Journaux
                </button>
                <button
                  className={onglet === "inventaires" ? "actif" : ""}
                  onClick={() => setOnglet("inventaires")}
                  type="button"
                >
                  Inventaires
                </button>
                <span className="evolution-separateur" aria-hidden="true" />
                <span className="evolution-puce">{NOMS_MOIS[maintenant.getMonth()]}</span>
                <span className="evolution-puce">{maintenant.getFullYear()}</span>
              </header>

              {onglet === "journaux" ? (
                chargement ? (
                  <p className="evolution-vide">Chargement…</p>
                ) : (
                  <Graphique serie={serie} />
                )
              ) : (
                <p className="evolution-vide">
                  Un inventaire compte le stock sans le déplacer : il ne produit
                  pas de mouvement à afficher ici.
                </p>
              )}
            </section>

            <aside className="carte carte-etat apparition" style={{ "--i": 5 }} aria-label="État du stock">
              <Link className="etat-lien" to="/rack">
                VOIR DETAILS STOCK
              </Link>
              <ul>
                {lignesEtat.map((ligne) => (
                  <li key={ligne.libelle}>
                    <span>{ligne.libelle}</span>
                    <Pastilles part={part(ligne.valeur)} />
                  </li>
                ))}
              </ul>
            </aside>
          </div>

          <section className="carte carte-journaux apparition" style={{ "--i": 6 }} aria-label="Liste des journaux">
            <div className="journaux-texte">
              <h2>
                Liste des journaux <span className="journaux-badge">Action récente</span>
              </h2>
              <p>Consultez et gérez les derniers mouvements de stock</p>
            </div>
            <div className="journaux-actions">
              <button
                className="journaux-supprimer"
                onClick={() => navigate("/journaux-mouvements")}
                type="button"
              >
                Supprimer
              </button>
              <button
                aria-label="Ajouter un journal"
                className="journaux-ajouter"
                onClick={() => navigate("/journaux-mouvements")}
                type="button"
              >
                <Plus size={18} aria-hidden="true" />
              </button>
              <label className="accueil-periode accueil-periode--discret">
                <select
                  aria-label="Période de la liste"
                  onChange={(event) => setPeriode(event.target.value)}
                  value={periode}
                >
                  {Object.entries(PERIODES).map(([cle, { libelle }]) => (
                    <option key={cle} value={cle}>
                      {libelle}
                    </option>
                  ))}
                </select>
                <ChevronDown size={14} aria-hidden="true" />
              </label>
            </div>
          </section>
        </main>
      </section>
    </div>
  );
}

export default Accueil;
