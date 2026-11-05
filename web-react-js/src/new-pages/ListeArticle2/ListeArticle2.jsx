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
import { verifierPhoto } from "../../utils/photo";
import Sidebar from "../../components/Sidebar";
import CreateArticleModal from "../../components/CreateArticleModal";
import VignetteArticle from "../../components/VignetteArticle";
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

const formaterContenance = (article) =>
  article.contenanceValeur != null && article.nomUnite
    ? `${Number(article.contenanceValeur).toLocaleString("fr-FR", { maximumFractionDigits: 3 })} ${article.nomUnite}`
    : "";

const TRIS = {
  nom: (article) => normaliser(article.nomArticle),
  codeBar: (article) => String(article.codeBar ?? ""),
  typeProduit: (article) => normaliser(article.typeProduit),
  conditionnement: (article) => normaliser(article.nomConditionnement),
  societe: (article) => normaliser(article.nomSociete),
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
 * Nouvelle version (test) de la liste des articles, avec la mise en page de la
 * liste des journaux. Servie sous /new/2/articles ; les autres pages restent en place.
 */
function ListeArticle2() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [articles, setArticles] = useState([]);
  const [conditionnements, setConditionnements] = useState(new Map());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [type, setType] = useState("TOUS");
  const [societe, setSociete] = useState("");
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: null, sens: 1 });
  const [visibles, setVisibles] = useState(PAGE);
  const [modalOuvert, setModalOuvert] = useState(false);
  // Article de départ quand on ajoute une variante (null = nouvel article).
  const [articleBase, setArticleBase] = useState(null);
  // Augmenté pour recharger la liste (après une création, une photo ou une suppression).
  const [version, setVersion] = useState(0);
  const recharger = () => setVersion((actuelle) => actuelle + 1);

  useEffect(() => {
    const controller = new AbortController();

    async function charger() {
      if (!token) return;
      try {
        const options = {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        };
        const [reponseArticles, reponseConditionnements] = await Promise.all([
          fetch(`${springUrl}/articles`, options),
          fetch(`${springUrl}/articles-conditionnements`, options),
        ]);
        if (!reponseArticles.ok || !reponseConditionnements.ok) {
          throw new Error("Impossible de récupérer les articles.");
        }

        const [listeArticles, listeConditionnements] = await Promise.all([
          reponseArticles.json(),
          reponseConditionnements.json(),
        ]);

        const parArticle = new Map();
        listeConditionnements.forEach((conditionnement) => {
          if (!parArticle.has(conditionnement.articleId)) {
            parArticle.set(conditionnement.articleId, conditionnement.nomConditionnement);
          }
        });

        setArticles(listeArticles);
        setConditionnements(parArticle);
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

  // Un article + son type de conditionnement.
  const lignes = useMemo(
    () => articles.map((article) => ({ ...article, nomConditionnement: conditionnements.get(article.id) ?? "" })),
    [articles, conditionnements],
  );

  const types = useMemo(() => {
    const compte = new Map();
    lignes.forEach((ligne) => {
      const cle = normaliser(ligne.typeProduit) || "AUTRE";
      compte.set(cle, (compte.get(cle) ?? 0) + 1);
    });
    return [...compte.entries()];
  }, [lignes]);

  const societes = useMemo(
    () => [...new Set(lignes.map((ligne) => ligne.nomSociete).filter(Boolean))].sort((a, b) => a.localeCompare(b, "fr")),
    [lignes],
  );

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtres = lignes.filter((ligne) => {
      if (type !== "TOUS" && (normaliser(ligne.typeProduit) || "AUTRE") !== type) return false;
      if (societe && ligne.nomSociete !== societe) return false;
      if (!texte) return true;
      return normaliser(
        [ligne.id, ligne.nomArticle, ligne.codeBar, ligne.typeProduit, ligne.nomConditionnement, ligne.nomSociete].join(" "),
      ).includes(texte);
    });
    if (!tri.cle) return filtres;
    const valeur = TRIS[tri.cle];
    return [...filtres].sort((a, b) => {
      const va = valeur(a);
      const vb = valeur(b);
      return (va > vb ? 1 : va < vb ? -1 : 0) * tri.sens;
    });
  }, [lignes, type, societe, recherche, tri]);

  const trier = (cle) => {
    setTri((actuel) =>
      actuel.cle !== cle ? { cle, sens: 1 } : actuel.sens === 1 ? { cle, sens: -1 } : { cle: null, sens: 1 },
    );
  };

  const avecReset = (setter) => (valeur) => {
    setter(valeur);
    setVisibles(PAGE);
  };
  const choisirType = avecReset(setType);
  const choisirSociete = avecReset(setSociete);
  const rechercher = avecReset(setRecherche);

  const ouvrirNouvelArticle = () => {
    setArticleBase(null);
    setModalOuvert(true);
  };

  const ouvrirVariante = (article) => {
    setArticleBase(article);
    setModalOuvert(true);
  };

  // Ajoute ou remplace la photo d'un article existant (PUT /articles/{id}/photo).
  const changerPhoto = async (id, fichier) => {
    const message = verifierPhoto(fichier);
    if (!fichier || message) {
      if (message) setError(message);
      return;
    }

    try {
      setError("");
      const formulaire = new FormData();
      formulaire.append("photo", fichier);
      const response = await fetch(`${springUrl}/articles/${id}/photo`, {
        method: "PUT",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
        body: formulaire,
      });
      if (!response.ok) {
        throw new Error(await lireMessageErreur(response, `Envoi impossible (${response.status}).`));
      }
      recharger();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Impossible d'enregistrer la photo.");
    }
  };

  const supprimer = async (article) => {
    if (!window.confirm(`Supprimer l'article « ${article.nomArticle} » ? Cette action est définitive.`)) return;

    try {
      setError("");
      const response = await fetch(`${springUrl}/articles/${article.id}`, {
        method: "DELETE",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        throw new Error(await lireMessageErreur(response, `Suppression impossible (${response.status}).`));
      }
      recharger();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Suppression impossible.");
    }
  };

  const messageErreur = token ? error : "Connectez-vous pour consulter les articles.";
  const enChargement = loading && Boolean(token);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Articles</h1>
          <button className={styles.primary} onClick={ouvrirNouvelArticle} type="button">
            Nouvel article
          </button>
        </header>

        <nav className={styles.tabs} aria-label="Sections">
          <NavLink end to="/new/2/articles">
            Tous les articles
          </NavLink>
          <NavLink to="/new/2/conditionnements">Conditionnements</NavLink>
          <NavLink to="/type-conditionnement">Types de conditionnement</NavLink>
          <NavLink to="/palettes-conditionnements/create">Capacités palettes</NavLink>
          <NavLink to="/new/referentiels">Référentiels</NavLink>
        </nav>

        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.segmented} role="group" aria-label="Type de produit">
              <button
                className={type === "TOUS" ? styles.segmentActive : undefined}
                onClick={() => choisirType("TOUS")}
                type="button"
              >
                Tous <span>{lignes.length}</span>
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
              <span className={styles.srOnly}>Filtrer par société</span>
              <select onChange={(event) => choisirSociete(event.target.value)} value={societe}>
                <option value="">Société</option>
                {societes.map((nom) => (
                  <option key={nom} value={nom}>
                    {nom}
                  </option>
                ))}
              </select>
              <ChevronDown size={18} aria-hidden="true" />
            </label>
          </div>

          <label className={styles.search}>
            <Search size={18} aria-hidden="true" />
            <input
              aria-label="Rechercher un article"
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
                <EnTeteTriable cle="nom" tri={tri} onTri={trier}>
                  Article
                </EnTeteTriable>
                <EnTeteTriable cle="codeBar" tri={tri} onTri={trier}>
                  Code-barres
                </EnTeteTriable>
                <EnTeteTriable cle="typeProduit" tri={tri} onTri={trier}>
                  Type de produit
                </EnTeteTriable>
                <EnTeteTriable cle="conditionnement" tri={tri} onTri={trier}>
                  Conditionnement
                </EnTeteTriable>
                <EnTeteTriable cle="societe" tri={tri} onTri={trier}>
                  Société
                </EnTeteTriable>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {enChargement ? (
                <tr>
                  <td className={styles.empty} colSpan={6}>
                    Chargement des articles…
                  </td>
                </tr>
              ) : resultats.length === 0 ? (
                <tr>
                  <td className={styles.empty} colSpan={6}>
                    Aucun article ne correspond à ces filtres.
                  </td>
                </tr>
              ) : (
                resultats.slice(0, visibles).map((article) => (
                  <LigneArticle
                    article={article}
                    key={article.id}
                    onPhoto={changerPhoto}
                    onSupprimer={supprimer}
                    onVariante={ouvrirVariante}
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

      <CreateArticleModal
        articleBase={articleBase}
        isOpen={modalOuvert}
        onClose={() => setModalOuvert(false)}
        onCreated={recharger}
      />
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

function LigneArticle({ article, onPhoto, onSupprimer, onVariante }) {
  const contenance = formaterContenance(article);

  return (
    <tr>
      <td>
        <div className={styles.identity}>
          <VignetteArticle nom={article.nomArticle} photoUrl={article.photoUrl} taille={36} />
          <div>
            <strong>{article.nomArticle}</strong>
            <small>
              {contenance ? `${contenance} · ` : ""}#{article.id}
            </small>
          </div>
        </div>
      </td>
      <td className={styles.number}>{article.codeBar || <span className={styles.muted}>--</span>}</td>
      <td>
        <span className={`${styles.badge} ${styles.neutral}`}>{article.typeProduit || "—"}</span>
      </td>
      <td>{article.nomConditionnement || <span className={styles.muted}>--</span>}</td>
      <td>
        {article.nomSociete ? (
          <span className={styles.primaryText}>{article.nomSociete}</span>
        ) : (
          <span className={styles.muted}>--</span>
        )}
      </td>
      <td className={styles.actionsCell}>
        <MenuActions article={article} onPhoto={onPhoto} onSupprimer={onSupprimer} onVariante={onVariante} />
      </td>
    </tr>
  );
}

function MenuActions({ article, onPhoto, onSupprimer, onVariante }) {
  const [ouvert, setOuvert] = useState(false);
  const ref = useRef(null);
  const champPhoto = useRef(null);

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
        aria-label={`Actions pour ${article.nomArticle}`}
        className={styles.menuButton}
        onClick={() => setOuvert((valeur) => !valeur)}
        type="button"
      >
        <MoreHorizontal size={18} aria-hidden="true" />
      </button>

      <input
        accept="image/jpeg,image/png,image/webp"
        hidden
        onChange={(event) => {
          onPhoto(article.id, event.target.files?.[0] ?? null);
          event.target.value = "";
        }}
        ref={champPhoto}
        type="file"
      />

      {ouvert && (
        <div className={styles.menuList} role="menu">
          <button
            onClick={() => {
              setOuvert(false);
              onVariante(article);
            }}
            role="menuitem"
            type="button"
          >
            Ajouter une variante
          </button>
          <button
            onClick={() => {
              setOuvert(false);
              champPhoto.current?.click();
            }}
            role="menuitem"
            type="button"
          >
            Changer la photo
          </button>
          <button
            onClick={() => {
              navigator.clipboard?.writeText(article.codeBar ?? "");
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
              onSupprimer(article);
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

export default ListeArticle2;
