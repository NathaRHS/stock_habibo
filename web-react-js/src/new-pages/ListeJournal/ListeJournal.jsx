import { useEffect, useMemo, useRef, useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { getAccessToken } from "../../services/authService";
import Sidebar from "../../components/Sidebar";
import CreateJournalModal from "../../components/CreateJournalModal";
import styles from "./ListeJournal.module.css";

const PAGE = 10;

const STATUTS = {
  VALIDE: { label: "Validé", icon: "check", tone: "success" },
  "EN COURS": { label: "En cours", icon: "sync", tone: "progress" },
  "EN ATTENTE": { label: "En attente", icon: "schedule", tone: "warning" },
  MODIFIE: { label: "Modifié", icon: "edit", tone: "danger" },
};

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[_-]+/g, " ")
    .trim()
    .toUpperCase();

const nomFichier = (url) =>
  String(url ?? "")
    .replaceAll("\\", "/")
    .split("/")
    .filter(Boolean)
    .at(-1);

const lignes = (journal) => journal.details ?? [];
const quantiteTotale = (journal) =>
  lignes(journal).reduce((total, ligne) => total + (ligne.quantite ?? 0), 0);

const TRIS = {
  reference: (journal) => normaliser(journal.reference),
  partenaire: (journal) => normaliser(journal.fournisseur || journal.nomClient),
  articles: (journal) => lignes(journal).length,
  quantite: quantiteTotale,
};

function ListeJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journaux, setJournaux] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [type, setType] = useState("TOUS");
  const [statut, setStatut] = useState("");
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: null, sens: 1 });
  const [visibles, setVisibles] = useState(PAGE);
  const [modalOuverte, setModalOuverte] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    async function charger() {
      if (!token) {
        setError("Connectez-vous pour consulter les journaux.");
        setLoading(false);
        return;
      }
      try {
        const response = await fetch(`${springUrl}/journaux-mouvements`, {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        });
        if (!response.ok)
          throw new Error(`Impossible de récupérer les journaux (${response.status}).`);
        setJournaux(await response.json());
      } catch (erreur) {
        if (erreur.name !== "AbortError") setError(erreur.message || "Chargement impossible.");
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }
    charger();
    return () => controller.abort();
  }, [springUrl, token]);

  const types = useMemo(() => {
    const compte = new Map();
    journaux.forEach((journal) => {
      const cle = normaliser(journal.typeMouvementJournal) || "AUTRE";
      compte.set(cle, (compte.get(cle) ?? 0) + 1);
    });
    return [...compte.entries()];
  }, [journaux]);

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtres = journaux.filter((journal) => {
      if (type !== "TOUS" && (normaliser(journal.typeMouvementJournal) || "AUTRE") !== type)
        return false;
      if (statut && normaliser(journal.statut) !== statut) return false;
      if (!texte) return true;
      return normaliser(
        [journal.reference, journal.nomClient, journal.fournisseur, nomFichier(journal.urlPieceJointe)].join(" "),
      ).includes(texte);
    });
    if (!tri.cle) return filtres;
    const valeur = TRIS[tri.cle];
    return [...filtres].sort((a, b) => {
      const va = valeur(a);
      const vb = valeur(b);
      return (va > vb ? 1 : va < vb ? -1 : 0) * tri.sens;
    });
  }, [journaux, type, statut, recherche, tri]);

  const trier = (cle) => {
    setTri((actuel) =>
      actuel.cle !== cle
        ? { cle, sens: 1 }
        : actuel.sens === 1
          ? { cle, sens: -1 }
          : { cle: null, sens: 1 },
    );
  };

  const avecReset = (setter) => (valeur) => {
    setter(valeur);
    setVisibles(PAGE);
  };
  const choisirType = avecReset(setType);
  const choisirStatut = avecReset(setStatut);
  const rechercher = avecReset(setRecherche);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Journaux</h1>
          <button className={styles.primary} onClick={() => setModalOuverte(true)} type="button">
            Nouveau journal
          </button>
        </header>

        <nav className={styles.tabs} aria-label="Sections">
          <NavLink end to="/new/journaux-mouvements">Tous les journaux</NavLink>
          <NavLink to="/types-mouvements-journal">Types de mouvement</NavLink>
          <NavLink to="/inventaires">Inventaires</NavLink>
        </nav>

        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.segmented} role="group" aria-label="Type de mouvement">
              <button
                className={type === "TOUS" ? styles.segmentActive : undefined}
                onClick={() => choisirType("TOUS")}
                type="button"
              >
                Tous <span>{journaux.length}</span>
              </button>
              {types.map(([cle, nombre]) => (
                <button
                  className={type === cle ? styles.segmentActive : undefined}
                  key={cle}
                  onClick={() => choisirType(cle)}
                  type="button"
                >
                  {cle.charAt(0) + cle.slice(1).toLowerCase()} <span>{nombre}</span>
                </button>
              ))}
            </div>

            <label className={styles.select}>
              <span className={styles.srOnly}>Filtrer par statut</span>
              <select
                onChange={(event) => choisirStatut(event.target.value)}
                value={statut}
              >
                <option value="">Statut</option>
                {Object.entries(STATUTS).map(([cle, { label }]) => (
                  <option key={cle} value={cle}>{label}</option>
                ))}
              </select>
              <span className="material-symbols-outlined" aria-hidden="true">expand_more</span>
            </label>
          </div>

          <label className={styles.search}>
            <span className="material-symbols-outlined" aria-hidden="true">search</span>
            <input
              aria-label="Rechercher un journal"
              onChange={(event) => rechercher(event.target.value)}
              placeholder="Rechercher"
              type="search"
              value={recherche}
            />
          </label>
        </div>

        {error && <p className={styles.error} role="alert">{error}</p>}

        <div className={styles.tableScroll}>
          <table className={styles.table}>
            <thead>
              <tr>
                <EnTeteTriable cle="reference" tri={tri} onTri={trier}>Journal</EnTeteTriable>
                <EnTeteTriable cle="partenaire" tri={tri} onTri={trier}>Partenaire</EnTeteTriable>
                <th>Statut</th>
                <EnTeteTriable cle="articles" tri={tri} onTri={trier}>Articles</EnTeteTriable>
                <EnTeteTriable cle="quantite" tri={tri} onTri={trier}>Quantité</EnTeteTriable>
                <th>Pièce jointe</th>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td className={styles.empty} colSpan={7}>Chargement des journaux…</td></tr>
              ) : resultats.length === 0 ? (
                <tr>
                  <td className={styles.empty} colSpan={7}>
                    Aucun journal ne correspond à ces filtres.
                  </td>
                </tr>
              ) : (
                resultats.slice(0, visibles).map((journal) => (
                  <LigneJournal journal={journal} key={journal.id} />
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && resultats.length > visibles && (
          <button className={styles.loadMore} onClick={() => setVisibles((n) => n + PAGE)} type="button">
            Afficher plus
            <span className="material-symbols-outlined" aria-hidden="true">expand_more</span>
          </button>
        )}
      </main>

      <CreateJournalModal
        isOpen={modalOuverte}
        onClose={() => setModalOuverte(false)}
        onCreated={(journalCree) => {
          if (journalCree) setJournaux((actuels) => [journalCree, ...actuels]);
        }}
      />
    </div>
  );
}

function EnTeteTriable({ cle, tri, onTri, children }) {
  const actif = tri.cle === cle;
  const icone = !actif ? "unfold_more" : tri.sens === 1 ? "arrow_upward" : "arrow_downward";
  return (
    <th aria-sort={!actif ? "none" : tri.sens === 1 ? "ascending" : "descending"}>
      <button className={styles.sortButton} onClick={() => onTri(cle)} type="button">
        {children}
        <span className="material-symbols-outlined" aria-hidden="true">{icone}</span>
      </button>
    </th>
  );
}

function LigneJournal({ journal }) {
  const sortie = normaliser(journal.typeMouvementJournal).includes("SORTIE");
  const statut = STATUTS[normaliser(journal.statut)] ?? {
    label: journal.statut || "Inconnu",
    icon: "draft",
    tone: "neutral",
  };
  const document = nomFichier(journal.urlPieceJointe);
  const nbLignes = lignes(journal).length;
  const partenaire = journal.fournisseur || journal.nomClient;
  const lienAction = sortie
    ? { to: `/createListeArticle/${journal.id}`, label: "Créer la liste de commande" }
    : { to: `/journaux-mouvements/${journal.id}`, label: "Contrôler le journal" };

  return (
    <tr>
      <td>
        <div className={styles.identity}>
          <span className={`${styles.thumb} ${sortie ? styles.thumbOut : styles.thumbIn}`}>
            <span className="material-symbols-outlined" aria-hidden="true">
              {sortie ? "north_east" : "south_west"}
            </span>
          </span>
          <div>
            <strong>{journal.reference}</strong>
            <small>{journal.typeMouvementJournal || "—"} · #{journal.id}</small>
          </div>
        </div>
      </td>
      <td>
        {partenaire ? (
          <>
            <span className={styles.primaryText}>{partenaire}</span>
            <small className={styles.subText}>{journal.fournisseur ? "Fournisseur" : "Client"}</small>
          </>
        ) : (
          <span className={styles.muted}>--</span>
        )}
      </td>
      <td>
        <span className={`${styles.badge} ${styles[statut.tone]}`}>
          <span className="material-symbols-outlined" aria-hidden="true">{statut.icon}</span>
          {statut.label}
        </span>
      </td>
      <td className={styles.number}>{nbLignes || <span className={styles.muted}>--</span>}</td>
      <td className={styles.number}>
        {nbLignes ? quantiteTotale(journal) : <span className={styles.muted}>--</span>}
      </td>
      <td>
        {document ? (
          <span className={styles.document} title={document}>{document}</span>
        ) : (
          <span className={styles.muted}>--</span>
        )}
      </td>
      <td className={styles.actionsCell}>
        <MenuActions journal={journal} lienAction={lienAction} />
      </td>
    </tr>
  );
}

function MenuActions({ journal, lienAction }) {
  const [ouvert, setOuvert] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!ouvert) return undefined;
    const fermer = (event) => {
      if (!ref.current?.contains(event.target)) setOuvert(false);
    };
    const echap = (event) => event.key === "Escape" && setOuvert(false);
    document.addEventListener("mousedown", fermer);
    document.addEventListener("keydown", echap);
    return () => {
      document.removeEventListener("mousedown", fermer);
      document.removeEventListener("keydown", echap);
    };
  }, [ouvert]);

  return (
    <div className={styles.menu} ref={ref}>
      <button
        aria-expanded={ouvert}
        aria-label={`Actions pour ${journal.reference}`}
        className={styles.menuButton}
        onClick={() => setOuvert((valeur) => !valeur)}
        type="button"
      >
        <span className="material-symbols-outlined" aria-hidden="true">more_horiz</span>
      </button>
      {ouvert && (
        <div className={styles.menuList} role="menu">
          <Link role="menuitem" to={lienAction.to}>{lienAction.label}</Link>
          <button
            onClick={() => {
              navigator.clipboard?.writeText(journal.reference ?? "");
              setOuvert(false);
            }}
            role="menuitem"
            type="button"
          >
            Copier la référence
          </button>
        </div>
      )}
    </div>
  );
}

export default ListeJournal;
