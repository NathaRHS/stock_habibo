import { useEffect, useMemo, useState } from "react";
import Sidebar from "../components/Sidebar";
import Table from "../components/Table";
import Button from "../components/Button";
import { getAccessToken, getAuthenticatedUser } from "../services/authService";
import {
  chargerActivites,
  chargerTypesEvenement,
} from "../services/journalUserService";
import "./css/ListeArticle.css";
import "./css/ListeActivite.css";

const TAILLE_PAGE = 100;

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

const initiales = (nom) =>
  String(nom ?? "?")
    .replace(/[^A-Za-zÀ-ÿ0-9 ]/g, " ")
    .trim()
    .slice(0, 2)
    .toUpperCase();

/**
 * Journal d'activité : qui a fait quoi, et quand. Réservé aux administrateurs.
 * Les 100 événements les plus récents correspondant aux filtres sont chargés ;
 * la recherche, la pagination et l'export se font ensuite dans le tableau.
 */
function ListeActivite() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const utilisateurConnecte = getAuthenticatedUser();

  const [filtres, setFiltres] = useState(FILTRES_VIDES);
  const [types, setTypes] = useState([]);
  const [utilisateurs, setUtilisateurs] = useState([]);

  // Résultat de la dernière recherche, avec les filtres qui l'ont produit :
  // tant qu'ils diffèrent des filtres actuels, une recherche est en cours.
  const cleFiltres = JSON.stringify(filtres);
  const [resultat, setResultat] = useState({
    cle: null,
    elements: [],
    total: 0,
    erreur: "",
  });
  const sessionAbsente = !getAccessToken();
  const chargement = !sessionAbsente && resultat.cle !== cleFiltres;
  const erreur = sessionAbsente
    ? "Connectez-vous pour consulter le journal d'activité."
    : resultat.erreur;
  const activites = resultat.elements;
  const total = resultat.total;

  // Listes des filtres : types d'événement et comptes utilisateurs.
  useEffect(() => {
    if (!getAccessToken()) return;

    chargerTypesEvenement(springUrl)
      .then((resultat) => setTypes(Array.isArray(resultat) ? resultat : []))
      .catch(() => {});

    fetch(`${springUrl}/user`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${getAccessToken()}`,
      },
    })
      .then((reponse) => (reponse.ok ? reponse.json() : []))
      .then((liste) => setUtilisateurs(Array.isArray(liste) ? liste : []))
      .catch(() => {});
  }, [springUrl]);

  // Recherche : relancée à chaque changement de filtre. Le résultat n'est
  // gardé que s'il correspond encore aux filtres affichés.
  useEffect(() => {
    if (!getAccessToken()) return undefined;

    let actif = true;
    chargerActivites(springUrl, { ...JSON.parse(cleFiltres), taille: TAILLE_PAGE })
      .then((reponse) => {
        if (!actif) return;
        setResultat({
          cle: cleFiltres,
          elements: reponse.elements ?? [],
          total: reponse.total ?? 0,
          erreur: "",
        });
      })
      .catch((requestError) => {
        if (!actif) return;
        setResultat({
          cle: cleFiltres,
          elements: [],
          total: 0,
          erreur:
            requestError instanceof Error
              ? requestError.message
              : "Impossible de se connecter au serveur.",
        });
      });

    return () => {
      actif = false;
    };
  }, [springUrl, cleFiltres]);

  const changerFiltre = (evenement) => {
    const { name, value } = evenement.target;
    setFiltres((actuels) => ({ ...actuels, [name]: value }));
  };

  // Colonnes lisibles pour le tableau (au lieu de tous les champs bruts).
  const lignes = useMemo(
    () =>
      activites.map((activite) => ({
        date: formaterDate(activite.date),
        utilisateur: activite.matricule
          ? `${activite.matricule}`
          : activite.utilisateur,
        action: activite.libelleType,
        cible: activite.cibleType
          ? `${LIBELLES_CIBLE[activite.cibleType] ?? activite.cibleType}${
              activite.cibleId ? ` n° ${activite.cibleId}` : ""
            }`
          : "",
        détails: activite.details ?? "",
      })),
    [activites],
  );

  const aDesFiltres = Object.values(filtres).some(Boolean);
  const nomAffiche = utilisateurConnecte?.username ?? "Administrateur";

  return (
    <div className="article-page-shell">
      <Sidebar />
      <section className="article-page-workspace">
        <header className="article-page-topbar">
          <p>Administration / Activités</p>
          <div className="article-page-user">
            <span>{initiales(nomAffiche)}</span>
            <div>
              <strong>{nomAffiche}</strong>
              <small style={utilisateurConnecte?.role === "ADMIN" ? {color:"blue"} :""}>{utilisateurConnecte?.role ?? "aa "}</small>
            </div>
          </div>
        </header>

        <main className="article-page-content">
          <header className="article-list-heading">
            <span className="article-list-kicker">Administration</span>
            <h1>Activités</h1>
            <p>Qui a fait quoi, et quand.</p>
          </header>

          <form
            className="activite-filtres"
            onSubmit={(evenement) => evenement.preventDefault()}
          >
            <label>
              Utilisateur
              <select name="userId" value={filtres.userId} onChange={changerFiltre}>
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
              <select name="type" value={filtres.type} onChange={changerFiltre}>
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
                name="depuis"
                type="date"
                value={filtres.depuis}
                max={filtres.jusqua || undefined}
                onChange={changerFiltre}
              />
            </label>

            <label>
              Au
              <input
                name="jusqua"
                type="date"
                value={filtres.jusqua}
                min={filtres.depuis || undefined}
                onChange={changerFiltre}
              />
            </label>

            <Button
              variant="secondary"
              disabled={!aDesFiltres}
              onClick={() => setFiltres(FILTRES_VIDES)}
            >
              Réinitialiser
            </Button>
          </form>

          {erreur ? (
            <div className="article-list-error" role="alert">
              {erreur}
            </div>
          ) : chargement ? (
            <div className="article-list-card">
              <div className="article-list-loading">Chargement des activités…</div>
            </div>
          ) : (
            <>
              <Table objetsProps={lignes} title="Activités" />
              {total > activites.length && (
                <p className="activite-note">
                  Les {activites.length} événements les plus récents sur {total}.
                  Affinez les filtres pour voir les autres.
                </p>
              )}
            </>
          )}
        </main>
      </section>
    </div>
  );
}

export default ListeActivite;
