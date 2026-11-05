import { useEffect, useMemo, useState } from "react";
import {
  ArrowDown,
  ArrowUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsUpDown,
  Pencil,
  Plus,
  Search,
  Trash2,
} from "lucide-react";
import { getAccessToken } from "../../services/authService";
import Sidebar from "../../components/Sidebar";
import CreateArticleModal from "../../components/CreateArticleModal";
import VignetteArticle from "../../components/VignetteArticle";
import CodeBarres from "./CodeBarres";
import styles from "./ListeArticle.module.css";

// La maquette montre 5 lignes par page ; à changer ici seulement.
const TAILLE_PAGE = 5;

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .trim()
    .toUpperCase();

// Valeur de chaque colonne triable.
const VALEURS_TRI = {
  id: (article) => article.id,
  nom: (article) => normaliser(article.nomArticle),
  codeBar: (article) => String(article.codeBar ?? ""),
  typeProduit: (article) => normaliser(article.typeProduit),
};

// Choix du menu « Filtrer par » : un tri tout fait.
const TRIS_PREDEFINIS = [
  { valeur: "id:-1", label: "Récent" },
  { valeur: "id:1", label: "Ancien" },
  { valeur: "nom:1", label: "Nom A → Z" },
  { valeur: "nom:-1", label: "Nom Z → A" },
];

// 1 … 4 5 6 … 59 : la première, la dernière et les voisines de la page courante.
function pagesAffichees(courante, total) {
  const numeros = new Set([1, total, courante - 1, courante, courante + 1]);
  const triees = [...numeros].filter((numero) => numero >= 1 && numero <= total).sort((a, b) => a - b);

  const resultat = [];
  triees.forEach((numero, index) => {
    if (index > 0 && numero - triees[index - 1] > 1) resultat.push("…");
    resultat.push(numero);
  });
  return resultat;
}

const echapperCsv = (valeur) => `"${String(valeur ?? "").replaceAll('"', '""')}"`;

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

function EnTeteTriable({ cle, tri, onTri, children }) {
  const actif = tri.cle === cle;
  const Icone = !actif ? ChevronsUpDown : tri.sens === 1 ? ArrowUp : ArrowDown;
  return (
    <th aria-sort={!actif ? "none" : tri.sens === 1 ? "ascending" : "descending"}>
      <button className={styles.triBouton} onClick={() => onTri(cle)} type="button">
        {children}
        <Icone aria-hidden="true" size={14} />
      </button>
    </th>
  );
}

/**
 * Nouvelle version (test) de la liste des articles, d'après la maquette du
 * designer. Servie sous /new/articles ; l'ancienne page reste sur /article.
 */
function ListeArticle() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [articles, setArticles] = useState([]);
  // Type de conditionnement de chaque article (id de l'article -> nom).
  const [conditionnements, setConditionnements] = useState(new Map());
  const [chargement, setChargement] = useState(true);
  const [erreur, setErreur] = useState("");
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: "id", sens: -1 });
  const [page, setPage] = useState(1);
  const [modalOuvert, setModalOuvert] = useState(false);

  // Augmenté pour recharger la liste (après une création ou une suppression).
  const [version, setVersion] = useState(0);
  const recharger = () => setVersion((actuelle) => actuelle + 1);

  const connecte = Boolean(getAccessToken());

  useEffect(() => {
    const controller = new AbortController();

    async function charger() {
      const token = getAccessToken();
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
        setErreur("");
      } catch (cause) {
        if (cause.name !== "AbortError") {
          setErreur(cause instanceof Error ? cause.message : "Chargement impossible.");
        }
      } finally {
        if (!controller.signal.aborted) setChargement(false);
      }
    }

    charger();
    return () => controller.abort();
  }, [springUrl, version]);

  // Une ligne = un article + son type de conditionnement.
  const lignes = useMemo(
    () =>
      articles.map((article) => ({
        ...article,
        nomConditionnement: conditionnements.get(article.id) ?? "",
      })),
    [articles, conditionnements],
  );

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtrees = texte
      ? lignes.filter((ligne) =>
          normaliser(
            [ligne.id, ligne.nomArticle, ligne.codeBar, ligne.typeProduit, ligne.nomConditionnement, ligne.nomSociete].join(" "),
          ).includes(texte),
        )
      : lignes;

    const valeur = VALEURS_TRI[tri.cle];
    return [...filtrees].sort((a, b) => {
      const va = valeur(a);
      const vb = valeur(b);
      return (va > vb ? 1 : va < vb ? -1 : 0) * tri.sens;
    });
  }, [lignes, recherche, tri]);

  const totalPages = Math.max(1, Math.ceil(resultats.length / TAILLE_PAGE));
  const pageCourante = Math.min(page, totalPages);
  const lignesVisibles = resultats.slice((pageCourante - 1) * TAILLE_PAGE, pageCourante * TAILLE_PAGE);

  const trierColonne = (cle) => {
    setTri((actuel) => (actuel.cle === cle ? { cle, sens: actuel.sens * -1 } : { cle, sens: 1 }));
    setPage(1);
  };

  const choisirTri = (valeur) => {
    const [cle, sens] = valeur.split(":");
    setTri({ cle, sens: Number(sens) });
    setPage(1);
  };

  const rechercher = (valeur) => {
    setRecherche(valeur);
    setPage(1);
  };

  const valeurTri = `${tri.cle}:${tri.sens}`;
  const triPredefini = TRIS_PREDEFINIS.some((choix) => choix.valeur === valeurTri);

  // Exporte toute la liste filtrée (pas seulement la page affichée).
  const exporter = () => {
    const entetes = ["ID", "Article", "Code-barres", "Type de produit", "Type de conditionnement", "Société"];
    const corps = resultats.map((ligne) => [
      ligne.id,
      ligne.nomArticle,
      ligne.codeBar,
      ligne.typeProduit,
      ligne.nomConditionnement,
      ligne.nomSociete,
    ]);
    const contenu = [entetes, ...corps].map((ligne) => ligne.map(echapperCsv).join(";")).join("\r\n");

    // BOM : Excel lit alors correctement les accents.
    const fichier = new Blob([String.fromCharCode(0xfeff), contenu], { type: "text/csv;charset=utf-8" });
    const adresse = URL.createObjectURL(fichier);
    const lien = document.createElement("a");
    lien.href = adresse;
    lien.download = "articles.csv";
    document.body.appendChild(lien);
    lien.click();
    lien.remove();
    URL.revokeObjectURL(adresse);
  };

  const supprimer = async (ligne) => {
    if (!window.confirm(`Supprimer l'article « ${ligne.nomArticle} » ? Cette action est définitive.`)) return;

    const token = getAccessToken();
    if (!token) {
      setErreur("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setErreur("");
      const response = await fetch(`${springUrl}/articles/${ligne.id}`, {
        method: "DELETE",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        throw new Error(await lireMessageErreur(response, `Suppression impossible (${response.status}).`));
      }
      recharger();
    } catch (cause) {
      setErreur(cause instanceof Error ? cause.message : "Suppression impossible.");
    }
  };

  // Sans jeton, rien n'est chargé : on le dit au lieu d'attendre indéfiniment.
  const messageErreur = connecte ? erreur : "Connectez-vous pour consulter les articles.";
  const enChargement = chargement && connecte;

  const premier = resultats.length === 0 ? 0 : (pageCourante - 1) * TAILLE_PAGE + 1;
  const dernier = Math.min(pageCourante * TAILLE_PAGE, resultats.length);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Gestion des articles</h1>
          <p>Gérez les articles et leurs propriétés.</p>
        </header>

        <div className={styles.actions}>
          <button className={styles.primary} onClick={() => setModalOuvert(true)} type="button">
            <Plus aria-hidden="true" size={16} />
            Ajouter un article
          </button>
          <button
            className={styles.secondary}
            disabled={resultats.length === 0}
            onClick={exporter}
            type="button"
          >
            Exporter
          </button>
        </div>

        <div className={styles.toolbar}>
          <label className={styles.search}>
            <Search aria-hidden="true" size={18} />
            <input
              aria-label="Rechercher un article"
              onChange={(event) => rechercher(event.target.value)}
              placeholder="Rechercher"
              type="search"
              value={recherche}
            />
          </label>

          <label className={styles.select}>
            <span className={styles.srOnly}>Trier les articles</span>
            <select onChange={(event) => choisirTri(event.target.value)} value={triPredefini ? valeurTri : "colonne"}>
              {!triPredefini && (
                <option disabled value="colonne">
                  Filtrer par : colonne
                </option>
              )}
              {TRIS_PREDEFINIS.map((choix) => (
                <option key={choix.valeur} value={choix.valeur}>
                  Filtrer par : {choix.label}
                </option>
              ))}
            </select>
            <ChevronDown aria-hidden="true" size={18} />
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
                <th>ID</th>
                <EnTeteTriable cle="nom" onTri={trierColonne} tri={tri}>
                  Produit
                </EnTeteTriable>
                <EnTeteTriable cle="codeBar" onTri={trierColonne} tri={tri}>
                  Code-barres
                </EnTeteTriable>
                <EnTeteTriable cle="typeProduit" onTri={trierColonne} tri={tri}>
                  Type de produit
                </EnTeteTriable>
                <th>Type de conditionnement</th>
                <th className={styles.actionsEntete}>Action</th>
              </tr>
            </thead>
            <tbody>
              {enChargement ? (
                <tr>
                  <td className={styles.vide} colSpan={6}>
                    Chargement des articles…
                  </td>
                </tr>
              ) : lignesVisibles.length === 0 ? (
                <tr>
                  <td className={styles.vide} colSpan={6}>
                    Aucun article ne correspond à la recherche.
                  </td>
                </tr>
              ) : (
                lignesVisibles.map((ligne) => (
                  <tr key={ligne.id}>
                    <td className={styles.identifiant}>#{ligne.id}</td>
                    <td>
                      <div className={styles.produit}>
                        <VignetteArticle nom={ligne.nomArticle} photoUrl={ligne.photoUrl} taille={32} />
                        <div>
                          <strong>{ligne.nomArticle}</strong>
                          {ligne.nomSociete && <small>{ligne.nomSociete}</small>}
                        </div>
                      </div>
                    </td>
                    <td>
                      <CodeBarres code={ligne.codeBar} />
                    </td>
                    <td>{ligne.typeProduit}</td>
                    <td>{ligne.nomConditionnement || "—"}</td>
                    <td>
                      <div className={styles.iconeActions}>
                        {/* Pas encore de formulaire de modification dans l'application. */}
                        <button
                          aria-label={`Modifier ${ligne.nomArticle} (bientôt disponible)`}
                          className={styles.modifier}
                          disabled
                          title="Modification bientôt disponible"
                          type="button"
                        >
                          <Pencil aria-hidden="true" size={18} />
                        </button>
                        <button
                          aria-label={`Supprimer ${ligne.nomArticle}`}
                          className={styles.supprimer}
                          onClick={() => supprimer(ligne)}
                          title="Supprimer"
                          type="button"
                        >
                          <Trash2 aria-hidden="true" size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <footer className={styles.pied}>
          <span>
            {resultats.length === 0
              ? "Aucun article"
              : `Articles ${premier}–${dernier} sur ${resultats.length}`}
          </span>

          <nav aria-label="Pagination" className={styles.pagination}>
            <button
              aria-label="Page précédente"
              disabled={pageCourante === 1}
              onClick={() => setPage(pageCourante - 1)}
              type="button"
            >
              <ChevronLeft aria-hidden="true" size={16} />
            </button>
            {pagesAffichees(pageCourante, totalPages).map((numero, index) =>
              numero === "…" ? (
                <span className={styles.ellipse} key={`ellipse-${index}`}>
                  …
                </span>
              ) : (
                <button
                  aria-current={numero === pageCourante ? "page" : undefined}
                  className={numero === pageCourante ? styles.pageActive : undefined}
                  key={numero}
                  onClick={() => setPage(numero)}
                  type="button"
                >
                  {numero}
                </button>
              ),
            )}
            <button
              aria-label="Page suivante"
              disabled={pageCourante === totalPages}
              onClick={() => setPage(pageCourante + 1)}
              type="button"
            >
              <ChevronRight aria-hidden="true" size={16} />
            </button>
          </nav>
        </footer>
      </main>

      <CreateArticleModal
        isOpen={modalOuvert}
        onClose={() => setModalOuvert(false)}
        onCreated={recharger}
      />
    </div>
  );
}

export default ListeArticle;
