import { useEffect, useMemo, useState } from "react";
import {
  ArrowDown,
  ArrowUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsUpDown,
  Search,
} from "lucide-react";
import Sidebar from "../../components/Sidebar";
import { getAccessToken } from "../../services/authService";
import { chargerActivites, chargerTypesEvenement } from "../../services/journalUserService";
import styles from "./Activites.module.css";

// Événements chargés d'un coup (les plus récents) ; l'affichage se fait ensuite par pages.
const TAILLE_CHARGEMENT = 100;
const TAILLE_PAGE = 10;

const LIBELLES_CIBLE = {
  USER: "Utilisateur",
  ARTICLE: "Article",
  JOURNAL: "Journal",
  COMMANDE: "Commande",
  LIGNE_PICKING: "Ligne de picking",
  PICKING: "Picking",
  RACK: "Rack",
  EMPLACEMENT: "Emplacement",
  SOCIETE: "Société",
  UNITE: "Unité",
  TYPE_PRODUIT: "Type de produit",
  TYPE_CONDITIONNEMENT: "Type de conditionnement",
  CONDITIONNEMENT: "Conditionnement",
  PALETTE: "Capacité palette",
  TYPE_MOUVEMENT: "Type de mouvement",
  STATUT: "Statut",
};

const FILTRES_VIDES = { userId: "", type: "", depuis: "", jusqua: "" };

const TRIS_PREDEFINIS = [
  { valeur: "date:-1", label: "Récent" },
  { valeur: "date:1", label: "Ancien" },
  { valeur: "utilisateur:1", label: "Utilisateur A → Z" },
];

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .trim()
    .toUpperCase();

const majuscule = (texte) => String(texte ?? "").charAt(0).toUpperCase() + String(texte ?? "").slice(1);

const formaterDate = (valeur) => {
  const date = new Date(valeur);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const VALEURS_TRI = {
  date: (ligne) => ligne.dateBrute,
  utilisateur: (ligne) => normaliser(ligne.utilisateur),
  action: (ligne) => normaliser(ligne.action),
  cible: (ligne) => normaliser(ligne.cible),
};

// 1 … 4 5 6 … 12 : la première, la dernière et les voisines de la page courante.
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
 * Nouvelle version (test) du journal d'activité : même contenu et mêmes filtres
 * que /activites, avec le tableau de la liste des journaux. Réservé aux
 * administrateurs (le serveur refuse les autres).
 */
function Activites() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [filtres, setFiltres] = useState(FILTRES_VIDES);
  const [types, setTypes] = useState([]);
  const [utilisateurs, setUtilisateurs] = useState([]);
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: "date", sens: -1 });
  const [page, setPage] = useState(1);

  // Résultat de la dernière recherche, avec les filtres qui l'ont produit :
  // tant qu'ils diffèrent des filtres actuels, une recherche est en cours.
  const cleFiltres = JSON.stringify(filtres);
  const [resultat, setResultat] = useState({ cle: null, elements: [], total: 0, erreur: "" });
  const sessionAbsente = !getAccessToken();
  const chargement = !sessionAbsente && resultat.cle !== cleFiltres;
  const erreur = sessionAbsente ? "Connectez-vous pour consulter le journal d'activité." : resultat.erreur;

  // Listes des filtres : types d'événement et comptes utilisateurs.
  useEffect(() => {
    if (!getAccessToken()) return;

    chargerTypesEvenement(springUrl)
      .then((liste) => setTypes(Array.isArray(liste) ? liste : []))
      .catch(() => {});

    fetch(`${springUrl}/user`, {
      headers: { Accept: "application/json", Authorization: `Bearer ${getAccessToken()}` },
    })
      .then((reponse) => (reponse.ok ? reponse.json() : []))
      .then((liste) => setUtilisateurs(Array.isArray(liste) ? liste : []))
      .catch(() => {});
  }, [springUrl]);

  // Recherche : relancée à chaque changement de filtre ; le résultat n'est gardé
  // que s'il correspond encore aux filtres affichés.
  useEffect(() => {
    if (!getAccessToken()) return undefined;

    let actif = true;
    chargerActivites(springUrl, { ...JSON.parse(cleFiltres), taille: TAILLE_CHARGEMENT })
      .then((reponse) => {
        if (!actif) return;
        setResultat({ cle: cleFiltres, elements: reponse.elements ?? [], total: reponse.total ?? 0, erreur: "" });
      })
      .catch((requestError) => {
        if (!actif) return;
        setResultat({
          cle: cleFiltres,
          elements: [],
          total: 0,
          erreur: requestError instanceof Error ? requestError.message : "Impossible de se connecter au serveur.",
        });
      });

    return () => {
      actif = false;
    };
  }, [springUrl, cleFiltres]);

  const changerFiltre = (evenement) => {
    const { name, value } = evenement.target;
    setFiltres((actuels) => ({ ...actuels, [name]: value }));
    setPage(1);
  };

  // Une ligne = un événement mis en forme pour le tableau.
  const lignes = useMemo(
    () =>
      resultat.elements.map((activite) => ({
        id: activite.id,
        dateBrute: activite.date ?? "",
        date: formaterDate(activite.date),
        utilisateur: activite.matricule ? activite.matricule : activite.utilisateur,
        action: majuscule(activite.libelleType),
        cible: activite.cibleType
          ? `${LIBELLES_CIBLE[activite.cibleType] ?? activite.cibleType}${activite.cibleId ? ` n° ${activite.cibleId}` : ""}`
          : "",
        details: activite.details ?? "",
      })),
    [resultat.elements],
  );

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtrees = texte
      ? lignes.filter((ligne) =>
          normaliser([ligne.date, ligne.utilisateur, ligne.action, ligne.cible, ligne.details].join(" ")).includes(texte),
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

  const valeurTri = `${tri.cle}:${tri.sens}`;
  const triPredefini = TRIS_PREDEFINIS.some((choix) => choix.valeur === valeurTri);
  const aDesFiltres = Object.values(filtres).some(Boolean);

  const exporter = () => {
    const entetes = ["Date", "Utilisateur", "Action", "Cible", "Détails"];
    const corps = resultats.map((ligne) => [ligne.date, ligne.utilisateur, ligne.action, ligne.cible, ligne.details]);
    const contenu = [entetes, ...corps].map((ligne) => ligne.map(echapperCsv).join(";")).join("\r\n");

    // Un BOM en tête : Excel lit alors correctement les accents.
    const fichier = new Blob([String.fromCharCode(0xfeff), contenu], { type: "text/csv;charset=utf-8" });
    const adresse = URL.createObjectURL(fichier);
    const lien = document.createElement("a");
    lien.href = adresse;
    lien.download = "activites.csv";
    document.body.appendChild(lien);
    lien.click();
    lien.remove();
    URL.revokeObjectURL(adresse);
  };

  const premier = resultats.length === 0 ? 0 : (pageCourante - 1) * TAILLE_PAGE + 1;
  const dernier = Math.min(pageCourante * TAILLE_PAGE, resultats.length);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Activités</h1>
          <p>Qui a fait quoi, et quand.</p>
        </header>

        <div className={styles.actions}>
          <button className={styles.secondary} disabled={resultats.length === 0} onClick={exporter} type="button">
            Exporter
          </button>
        </div>

        <form className={styles.filtres} onSubmit={(evenement) => evenement.preventDefault()}>
          <label>
            Utilisateur
            <select name="userId" onChange={changerFiltre} value={filtres.userId}>
              <option value="">Tous</option>
              {utilisateurs.map((utilisateur) => (
                <option key={utilisateur.id} value={utilisateur.id}>
                  {utilisateur.matricule} — {utilisateur.username}
                </option>
              ))}
            </select>
          </label>

          <label>
            Action
            <select name="type" onChange={changerFiltre} value={filtres.type}>
              <option value="">Toutes</option>
              {types.map((type) => (
                <option key={type.code} value={type.code}>
                  {type.libelle}
                </option>
              ))}
            </select>
          </label>

          <label>
            Du
            <input
              max={filtres.jusqua || undefined}
              name="depuis"
              onChange={changerFiltre}
              type="date"
              value={filtres.depuis}
            />
          </label>

          <label>
            Au
            <input
              min={filtres.depuis || undefined}
              name="jusqua"
              onChange={changerFiltre}
              type="date"
              value={filtres.jusqua}
            />
          </label>

          <button
            className={styles.reinitialiser}
            disabled={!aDesFiltres}
            onClick={() => {
              setFiltres(FILTRES_VIDES);
              setPage(1);
            }}
            type="button"
          >
            Réinitialiser
          </button>
        </form>

        <div className={styles.toolbar}>
          <label className={styles.search}>
            <Search aria-hidden="true" size={18} />
            <input
              aria-label="Rechercher dans les activités"
              onChange={(event) => {
                setRecherche(event.target.value);
                setPage(1);
              }}
              placeholder="Rechercher"
              type="search"
              value={recherche}
            />
          </label>

          <label className={styles.select}>
            <span className={styles.srOnly}>Trier les activités</span>
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

        {erreur && (
          <p className={styles.error} role="alert">
            {erreur}
          </p>
        )}

        <div className={styles.tableScroll}>
          <table className={styles.table}>
            <thead>
              <tr>
                <EnTeteTriable cle="date" onTri={trierColonne} tri={tri}>
                  Date
                </EnTeteTriable>
                <EnTeteTriable cle="utilisateur" onTri={trierColonne} tri={tri}>
                  Utilisateur
                </EnTeteTriable>
                <EnTeteTriable cle="action" onTri={trierColonne} tri={tri}>
                  Action
                </EnTeteTriable>
                <EnTeteTriable cle="cible" onTri={trierColonne} tri={tri}>
                  Cible
                </EnTeteTriable>
                <th>Détails</th>
              </tr>
            </thead>
            <tbody>
              {chargement ? (
                <tr>
                  <td className={styles.vide} colSpan={5}>
                    Chargement des activités…
                  </td>
                </tr>
              ) : lignesVisibles.length === 0 ? (
                <tr>
                  <td className={styles.vide} colSpan={5}>
                    Aucune activité ne correspond à ces critères.
                  </td>
                </tr>
              ) : (
                lignesVisibles.map((ligne) => (
                  <tr key={ligne.id}>
                    <td className={styles.date}>{ligne.date}</td>
                    <td className={styles.utilisateur}>{ligne.utilisateur}</td>
                    <td>{ligne.action}</td>
                    <td>{ligne.cible ? <span className={styles.cible}>{ligne.cible}</span> : "—"}</td>
                    <td className={styles.details} title={ligne.details}>
                      {ligne.details || "—"}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {resultat.total > resultat.elements.length && (
          <p className={styles.note}>
            Les {resultat.elements.length} événements les plus récents sur {resultat.total}. Affinez les filtres pour
            voir les autres.
          </p>
        )}

        <footer className={styles.pied}>
          <span>
            {resultats.length === 0 ? "Aucune activité" : `Activités ${premier}–${dernier} sur ${resultats.length}`}
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
    </div>
  );
}

export default Activites;
