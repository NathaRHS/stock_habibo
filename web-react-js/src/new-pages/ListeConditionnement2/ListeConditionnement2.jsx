import { useEffect, useMemo, useRef, useState } from "react";
import { NavLink } from "react-router-dom";
import {
  ArrowDown,
  ArrowUp,
  ChevronDown,
  ChevronsUpDown,
  MoreHorizontal,
  Search,
} from "lucide-react";
import { getAccessToken } from "../../services/authService";
import Sidebar from "../../components/Sidebar";
import Modal from "../../components/Modal";
import VignetteArticle from "../../components/VignetteArticle";
import CreateArticleConditionnement from "../../pages/CreateArticleConditionnement";
// Même feuille de style que la liste des journaux : le rendu est identique.
import styles from "../ListeJournal/ListeJournal.module.css";

const PAGE = 10;

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[_-]+/g, " ")
    .trim()
    .toUpperCase();

const TRIS = {
  article: (ligne) => normaliser(ligne.nomArticle),
  type: (ligne) => normaliser(ligne.nomConditionnement),
  codeBarres: (ligne) => String(ligne.codeBarres ?? ""),
  pieces: (ligne) => ligne.quantitePieceStandard ?? 0,
};

async function lireMessageErreur(response, parDefaut) {
  const contenu = await response.text();
  if (!contenu.trim()) return parDefaut;
  try {
    const erreur = JSON.parse(contenu);
    return erreur.detail ?? erreur.message ?? erreur.error ?? parDefaut;
  } catch {
    return contenu.trim();
  }
}

/**
 * Nouvelle version (test) de la liste des conditionnements, avec la mise en
 * page de la liste des journaux. Servie sous /new/2/conditionnements ;
 * l'ancienne page reste sur /article-conditionnements.
 */
function ListeConditionnement2() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [conditionnements, setConditionnements] = useState([]);
  // Photo de chaque article (id de l'article -> adresse), pour la vignette.
  const [photos, setPhotos] = useState(new Map());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [type, setType] = useState("TOUS");
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: null, sens: 1 });
  const [visibles, setVisibles] = useState(PAGE);
  const [modalOuvert, setModalOuvert] = useState(false);
  // Augmenté pour recharger la liste (après une suppression).
  const [version, setVersion] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    async function charger() {
      if (!token) return;
      try {
        const options = {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        };
        const [reponseConditionnements, reponseArticles] = await Promise.all([
          fetch(`${springUrl}/articles-conditionnements`, options),
          fetch(`${springUrl}/articles`, options),
        ]);
        if (!reponseConditionnements.ok) {
          throw new Error("Impossible de charger la liste des conditionnements.");
        }

        setConditionnements(await reponseConditionnements.json());

        // Les photos sont un confort : sans elles, la liste s'affiche quand même.
        if (reponseArticles.ok) {
          const articles = await reponseArticles.json();
          setPhotos(new Map(articles.map((article) => [article.id, article.photoUrl])));
        }
        setError("");
      } catch (cause) {
        if (cause.name !== "AbortError") {
          setError(cause instanceof Error ? cause.message : "Chargement impossible.");
        }
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }

    charger();
    return () => controller.abort();
  }, [springUrl, token, version]);

  const types = useMemo(() => {
    const compte = new Map();
    conditionnements.forEach((ligne) => {
      const cle = normaliser(ligne.nomConditionnement) || "AUTRE";
      compte.set(cle, (compte.get(cle) ?? 0) + 1);
    });
    return [...compte.entries()];
  }, [conditionnements]);

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtres = conditionnements.filter((ligne) => {
      if (type !== "TOUS" && (normaliser(ligne.nomConditionnement) || "AUTRE") !== type) return false;
      if (!texte) return true;
      return normaliser(
        [ligne.nomArticle, ligne.nomConditionnement, ligne.codeBarres, ligne.quantitePieceStandard].join(" "),
      ).includes(texte);
    });
    if (!tri.cle) return filtres;
    const valeur = TRIS[tri.cle];
    return [...filtres].sort((a, b) => {
      const va = valeur(a);
      const vb = valeur(b);
      return (va > vb ? 1 : va < vb ? -1 : 0) * tri.sens;
    });
  }, [conditionnements, type, recherche, tri]);

  const trier = (cle) => {
    setTri((actuel) =>
      actuel.cle !== cle ? { cle, sens: 1 } : actuel.sens === 1 ? { cle, sens: -1 } : { cle: null, sens: 1 },
    );
  };

  const choisirType = (valeur) => {
    setType(valeur);
    setVisibles(PAGE);
  };

  const rechercher = (valeur) => {
    setRecherche(valeur);
    setVisibles(PAGE);
  };

  const supprimer = async (ligne) => {
    if (
      !window.confirm(
        `Supprimer le conditionnement « ${ligne.nomConditionnement} » de ${ligne.nomArticle} ? Cette action est définitive.`,
      )
    )
      return;

    try {
      setError("");
      const response = await fetch(`${springUrl}/articles-conditionnements/${ligne.id}`, {
        method: "DELETE",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        throw new Error(await lireMessageErreur(response, `Suppression impossible (${response.status}).`));
      }
      setVersion((actuelle) => actuelle + 1);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Suppression impossible.");
    }
  };

  const messageErreur = token ? error : "Connectez-vous pour consulter les conditionnements.";
  const enChargement = loading && Boolean(token);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Conditionnements</h1>
          <button className={styles.primary} onClick={() => setModalOuvert(true)} type="button">
            Nouveau conditionnement
          </button>
        </header>

        <nav className={styles.tabs} aria-label="Sections">
          <NavLink to="/new/2/articles">Tous les articles</NavLink>
          <NavLink end to="/new/2/conditionnements">
            Conditionnements
          </NavLink>
          <NavLink to="/type-conditionnement">Types de conditionnement</NavLink>
          <NavLink to="/palettes-conditionnements/create">Capacités palettes</NavLink>
          <NavLink to="/new/referentiels">Référentiels</NavLink>
        </nav>

        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.segmented} role="group" aria-label="Type de conditionnement">
              <button
                className={type === "TOUS" ? styles.segmentActive : undefined}
                onClick={() => choisirType("TOUS")}
                type="button"
              >
                Tous <span>{conditionnements.length}</span>
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
          </div>

          <label className={styles.search}>
            <Search size={18} aria-hidden="true" />
            <input
              aria-label="Rechercher un conditionnement"
              onChange={(event) => rechercher(event.target.value)}
              placeholder="Rechercher"
              type="search"
              value={recherche}
            />
          </label>
        </div>

        {messageErreur && (
          <p className={styles.error} role="alert">
            {messageErreur}
          </p>
        )}

        <div className={styles.tableScroll}>
          <table className={styles.table}>
            <thead>
              <tr>
                <EnTeteTriable cle="article" tri={tri} onTri={trier}>
                  Article
                </EnTeteTriable>
                <EnTeteTriable cle="type" tri={tri} onTri={trier}>
                  Type de conditionnement
                </EnTeteTriable>
                <EnTeteTriable cle="codeBarres" tri={tri} onTri={trier}>
                  Code-barres
                </EnTeteTriable>
                <EnTeteTriable cle="pieces" tri={tri} onTri={trier}>
                  Pièces par unité
                </EnTeteTriable>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {enChargement ? (
                <tr>
                  <td className={styles.empty} colSpan={5}>
                    Chargement des conditionnements…
                  </td>
                </tr>
              ) : resultats.length === 0 ? (
                <tr>
                  <td className={styles.empty} colSpan={5}>
                    Aucun conditionnement ne correspond à ces filtres.
                  </td>
                </tr>
              ) : (
                resultats.slice(0, visibles).map((ligne) => (
                  <LigneConditionnement
                    key={ligne.id}
                    ligne={ligne}
                    onSupprimer={supprimer}
                    photoUrl={photos.get(ligne.articleId)}
                  />
                ))
              )}
            </tbody>
          </table>
        </div>

        {!enChargement && resultats.length > visibles && (
          <button className={styles.loadMore} onClick={() => setVisibles((n) => n + PAGE)} type="button">
            Afficher plus
            <ChevronDown size={18} aria-hidden="true" />
          </button>
        )}
      </main>

      <Modal ouverte={modalOuvert} onClose={() => setModalOuvert(false)} titre="Ajouter un conditionnement">
        <CreateArticleConditionnement
          onCreated={(nouveau) => {
            setConditionnements((actuels) => [...actuels, nouveau]);
            setModalOuvert(false);
          }}
        />
      </Modal>
    </div>
  );
}

function EnTeteTriable({ cle, tri, onTri, children }) {
  const actif = tri.cle === cle;
  const Icone = !actif ? ChevronsUpDown : tri.sens === 1 ? ArrowUp : ArrowDown;
  return (
    <th aria-sort={!actif ? "none" : tri.sens === 1 ? "ascending" : "descending"}>
      <button className={styles.sortButton} onClick={() => onTri(cle)} type="button">
        {children}
        <Icone size={14} aria-hidden="true" />
      </button>
    </th>
  );
}

function LigneConditionnement({ ligne, photoUrl, onSupprimer }) {
  return (
    <tr>
      <td>
        <div className={styles.identity}>
          <VignetteArticle nom={ligne.nomArticle} photoUrl={photoUrl} taille={36} />
          <div>
            <strong>{ligne.nomArticle}</strong>
            <small>Article #{ligne.articleId}</small>
          </div>
        </div>
      </td>
      <td>
        <span className={`${styles.badge} ${styles.neutral}`}>{ligne.nomConditionnement || "—"}</span>
      </td>
      <td className={styles.number}>{ligne.codeBarres || <span className={styles.muted}>--</span>}</td>
      <td className={styles.number}>{ligne.quantitePieceStandard}</td>
      <td className={styles.actionsCell}>
        <MenuActions ligne={ligne} onSupprimer={onSupprimer} />
      </td>
    </tr>
  );
}

function MenuActions({ ligne, onSupprimer }) {
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
        aria-label={`Actions pour ${ligne.nomArticle}`}
        className={styles.menuButton}
        onClick={() => setOuvert((valeur) => !valeur)}
        type="button"
      >
        <MoreHorizontal size={18} aria-hidden="true" />
      </button>

      {ouvert && (
        <div className={styles.menuList} role="menu">
          <button
            disabled={!ligne.codeBarres}
            onClick={() => {
              navigator.clipboard?.writeText(ligne.codeBarres ?? "");
              setOuvert(false);
            }}
            role="menuitem"
            type="button"
          >
            Copier le code-barres
          </button>
          <button
            onClick={() => {
              setOuvert(false);
              onSupprimer(ligne);
            }}
            role="menuitem"
            type="button"
          >
            Supprimer
          </button>
        </div>
      )}
    </div>
  );
}

export default ListeConditionnement2;
