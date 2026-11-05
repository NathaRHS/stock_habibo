import { useEffect, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, ArrowRight, Box, Hexagon, Star } from "lucide-react";
import Sidebar from "../../components/Sidebar";
import { getAccessToken, getAuthenticatedUser } from "../../services/authService";
import { urlPhoto, verifierPhoto } from "../../utils/photo";
import styles from "./Profil.module.css";

// Ce que chaque rôle peut faire, d'après les droits du serveur (SecurityConfig).
const DESCRIPTIONS_ROLES = {
  ADMIN:
    "Crée les comptes et les journaux, valide les entrées, les sorties et les inventaires, et gère les référentiels.",
  OPERATEUR: "Réceptionne les entrées et prélève les sorties sur le terminal mobile.",
  INVENTORISTE: "Compte les emplacements sur le terminal mobile lors des inventaires.",
  AUDITEUR: "Consulte les écarts d'inventaire et télécharge les rapports.",
};

const LIBELLES_ROLES = {
  ADMIN: "administrateur",
  OPERATEUR: "opérateur",
  INVENTORISTE: "inventoriste",
  AUDITEUR: "auditeur",
};

// Catégorie affichée pour chaque type d'objet du journal d'activité.
const CATEGORIES = {
  USER: "UTILISATEURS",
  ARTICLE: "ARTICLES",
  JOURNAL: "JOURNAUX",
  COMMANDE: "COMMANDES",
  LIGNE_PICKING: "PICKING",
  PICKING: "PICKING",
  RACK: "RACKS",
  EMPLACEMENT: "EMPLACEMENTS",
  SOCIETE: "SOCIÉTÉS",
  UNITE: "UNITÉS",
  TYPE_PRODUIT: "TYPES DE PRODUIT",
  TYPE_CONDITIONNEMENT: "CONDITIONNEMENTS",
  CONDITIONNEMENT: "CONDITIONNEMENTS",
  PALETTE: "PALETTES",
  TYPE_MOUVEMENT: "TYPES DE MOUVEMENT",
  STATUT: "STATUTS",
};

const majuscule = (texte) => texte.charAt(0).toUpperCase() + texte.slice(1);

// « Mercredi, 16 Janvier 2026 »
function dateLongue(valeur) {
  const date = new Date(valeur);
  if (Number.isNaN(date.getTime())) return "";
  const parties = new Intl.DateTimeFormat("fr-FR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).formatToParts(date);
  const lire = (type) => parties.find((partie) => partie.type === type)?.value ?? "";
  return `${majuscule(lire("weekday"))}, ${lire("day")} ${majuscule(lire("month"))} ${lire("year")}`;
}

// Un journal d'entrée, de sortie ou d'inventaire se reconnaît à son type entre parenthèses.
function categorie(activite) {
  const type = /\((ENTREE|SORTIE|INVENTAIRE)\)/.exec(activite.details ?? "")?.[1];
  if (activite.cibleType === "JOURNAL" && type) return type === "ENTREE" ? "ENTRÉE" : type;
  return CATEGORIES[activite.cibleType] ?? "ACTIVITÉ";
}

function IconeCategorie({ nom }) {
  if (nom === "UTILISATEURS") return <Star aria-hidden="true" fill="currentColor" size={22} />;
  if (nom === "INVENTAIRE") return <Hexagon aria-hidden="true" size={22} />;
  return <Box aria-hidden="true" size={22} />;
}

// Lecture tolérante : une erreur ici ne doit pas empêcher d'afficher le profil.
async function lireJson(url, options) {
  try {
    const response = await fetch(url, options);
    return response.ok ? await response.json() : null;
  } catch (cause) {
    if (cause.name === "AbortError") throw cause;
    return null;
  }
}

/**
 * Nouvelle version (test) du profil, d'après la maquette du designer.
 * /new/profil : le profil de la personne connectée.
 * /new/user/:id : le profil d'un utilisateur (l'ancienne page reste sur /user/:id).
 */
function Profil() {
  const { id } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const moi = getAuthenticatedUser();
  const champFichier = useRef(null);

  const userId = Number(id ?? moi?.id);
  const idValide = Number.isInteger(userId) && userId > 0;
  const estMoi = moi?.id === userId;

  const [resultat, setResultat] = useState(null);
  const [envoiEnCours, setEnvoiEnCours] = useState(false);
  const [erreurPhoto, setErreurPhoto] = useState("");

  useEffect(() => {
    const controller = new AbortController();
    if (!idValide) return () => controller.abort();

    async function charger() {
      try {
        const options = {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        };

        const reponseInfo = await fetch(`${springUrl}/user/nombreOperations/${userId}`, options);
        if (!reponseInfo.ok) {
          throw new Error(`Impossible de charger l'utilisateur (${reponseInfo.status}).`);
        }
        const info = await reponseInfo.json();

        // L'e-mail vient de la liste des utilisateurs.
        const utilisateurs = await lireJson(`${springUrl}/user`, options);
        const email = utilisateurs?.find((utilisateur) => utilisateur.id === userId)?.email ?? "";

        // Le journal d'activité n'est lisible que par l'administrateur : sinon, on s'en passe.
        const recentes = await lireJson(`${springUrl}/journal-user?userId=${userId}&taille=2`, options);
        let activites = null;
        let premiereActivite = "";
        if (recentes) {
          activites = recentes.elements ?? [];
          // Les plus récentes d'abord : la dernière page d'une ligne donne la plus ancienne.
          const plusAncienne =
            recentes.total > activites.length
              ? (await lireJson(
                  `${springUrl}/journal-user?userId=${userId}&page=${recentes.total - 1}&taille=1`,
                  options,
                ))?.elements?.[0]
              : activites.at(-1);
          premiereActivite = plusAncienne?.date ?? "";
        }

        if (!controller.signal.aborted) {
          setResultat({
            cle: userId,
            data: { ...info, email, activites, premiereActivite },
            error: "",
          });
        }
      } catch (cause) {
        if (cause.name !== "AbortError" && !controller.signal.aborted) {
          setResultat({ cle: userId, data: null, error: cause.message });
        }
      }
    }

    charger();
    return () => controller.abort();
  }, [idValide, springUrl, token, userId]);

  // Envoie la photo choisie, puis affiche celle que le serveur a enregistrée.
  const changerPhoto = async (event) => {
    const fichier = event.target.files?.[0];
    event.target.value = ""; // permet de rechoisir le même fichier
    if (!fichier) return;

    const probleme = verifierPhoto(fichier);
    if (probleme) {
      setErreurPhoto(probleme);
      return;
    }

    setErreurPhoto("");
    setEnvoiEnCours(true);
    try {
      const formulaire = new FormData();
      formulaire.append("photo", fichier);

      const response = await fetch(`${springUrl}/user/${userId}/photo`, {
        method: "PUT",
        headers: { Authorization: `Bearer ${token}` },
        body: formulaire,
      });

      if (!response.ok) {
        let message = `Impossible d'enregistrer la photo (${response.status}).`;
        try {
          const corps = await response.json();
          if (corps?.detail) message = corps.detail;
        } catch {
          // Réponse sans JSON : le message par défaut reste.
        }
        throw new Error(message);
      }

      const utilisateur = await response.json();
      setResultat((courant) =>
        courant?.data
          ? { ...courant, data: { ...courant.data, imageUser: utilisateur.imageUser } }
          : courant,
      );
    } catch (cause) {
      setErreurPhoto(cause.message);
    } finally {
      setEnvoiEnCours(false);
    }
  };

  const resultatActuel = resultat?.cle === userId ? resultat : null;
  const profil = resultatActuel?.data;
  const chargement = idValide && !resultatActuel;
  const erreur = idValide ? resultatActuel?.error : "Identifiant utilisateur invalide.";

  const initiales = profil?.nom?.trim().slice(0, 2).toUpperCase() || "U";
  const role = String(profil?.nomRole ?? "").toUpperCase();
  const libelleRole = LIBELLES_ROLES[role] ?? role.toLowerCase();
  const elision = /^[aeiouyhéèêâîôû]/i.test(libelleRole) ? "qu'" : "que ";
  const sujet = estMoi ? "vous" : "cet utilisateur";

  const activites = profil?.activites ?? null;
  const operations = profil?.operations ?? [];
  const dateArrivee = profil?.premiereActivite ? dateLongue(profil.premiereActivite) : "";

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <div>
            <h1>{estMoi ? "Votre profil" : "Profil utilisateur"}</h1>
            <p>Identité et activités dans l'entrepôt</p>
          </div>
          <button className={styles.retour} onClick={() => navigate(-1)} type="button">
            <ArrowLeft aria-hidden="true" size={16} />
            Retour
          </button>
        </header>

        {chargement && (
          <p className={styles.message} role="status">
            Chargement du profil…
          </p>
        )}

        {!chargement && erreur && (
          <p className={`${styles.message} ${styles.messageErreur}`} role="alert">
            {erreur}
          </p>
        )}

        {!chargement && profil && (
          <div className={styles.grille}>
            {/* ---------- Colonne de gauche ---------- */}
            <section aria-label="Identité" className={styles.grandeCarte}>
              <div className={styles.entete}>
                <div className={styles.avatar}>
                  {profil.imageUser ? (
                    <img alt={`Photo de ${profil.nom}`} src={urlPhoto(profil.imageUser)} />
                  ) : (
                    <span aria-hidden="true">{initiales}</span>
                  )}
                </div>
                <input
                  accept="image/jpeg,image/png,image/webp"
                  hidden
                  onChange={changerPhoto}
                  ref={champFichier}
                  type="file"
                />
                <button
                  className={styles.pastille}
                  disabled={envoiEnCours}
                  onClick={() => champFichier.current?.click()}
                  type="button"
                >
                  {envoiEnCours ? "Envoi…" : "Modifier la photo"}
                </button>
              </div>

              {erreurPhoto && (
                <p className={styles.erreurPhoto} role="alert">
                  {erreurPhoto}
                </p>
              )}

              <div className={styles.cadre}>
                <dl className={styles.champs}>
                  <div>
                    <dt>Nom d'utilisateur</dt>
                    <dd>{profil.nom}</dd>
                  </div>
                  {profil.email && (
                    <div>
                      <dt>Email</dt>
                      <dd className={styles.ligneEmail}>
                        <span>{profil.email}</span>
                        {/* La vérification de l'e-mail n'existe pas encore. */}
                        <button
                          className={styles.pastillePetite}
                          disabled
                          title="Vérification de l'e-mail : bientôt disponible"
                          type="button"
                        >
                          Vérifier
                        </button>
                      </dd>
                    </div>
                  )}
                  <div>
                    <dt>Matricule</dt>
                    <dd>{profil.matricule}</dd>
                  </div>
                </dl>
              </div>

              <div className={styles.cadre}>
                <h2>
                  {estMoi ? "Vos rôles" : "Rôles"} en tant {elision}
                  {libelleRole}
                </h2>
                <p className={styles.texte}>
                  {DESCRIPTIONS_ROLES[role] ?? "Aucune description disponible pour ce rôle."}
                </p>
              </div>

              <div className={styles.cadre}>
                <h2 className={styles.titreLeger}>Situation</h2>
                <ul className={styles.situation}>
                  <li>
                    <span>Statut</span>
                    {/* Aucune désactivation de compte n'existe : un compte qui se connecte est actif. */}
                    <span className={styles.pastilleVerte}>Actif</span>
                  </li>
                  <li>
                    <span>Inventaire</span>
                    <Link className={styles.pastillePetite} to="/inventaires">
                      Voir
                    </Link>
                  </li>
                </ul>
              </div>
            </section>

            {/* ---------- Colonne de droite ---------- */}
            <section aria-label="Activité" className={styles.grandeCarte}>
              <div className={styles.cadre}>
                <div className={styles.membre}>
                  <div>
                    <strong>
                      {estMoi ? "Votre première activité le :" : "Première activité le :"}
                    </strong>
                    <span>{dateArrivee || "Non disponible"}</span>
                  </div>
                  <span aria-hidden="true" className={styles.etoiles}>
                    <Star className={styles.etoileArriere} fill="currentColor" size={34} />
                    <Star className={styles.etoileAvant} fill="currentColor" size={30} />
                  </span>
                </div>
              </div>

              <h3 className={styles.sousTitre}>Badges</h3>
              {/* Aucun badge n'existe encore : les quatre emplacements sont vides. */}
              <ul className={styles.badges}>
                {[0, 1, 2, 3].map((index) => (
                  <li key={index}>
                    <i className={styles[`badgeIcone${index}`]} aria-hidden="true" />
                    Vide
                  </li>
                ))}
              </ul>

              <h3 className={styles.sousTitre}>Opérations suivies</h3>

              {activites ? (
                activites.length > 0 ? (
                  <ul className={styles.operations}>
                    {activites.map((activite) => {
                      const nom = categorie(activite);
                      return (
                        <li key={activite.id}>
                          <div>
                            <strong>{nom}</strong>
                            <small>
                              {majuscule(activite.libelleType ?? "")}
                              {activite.details ? ` : ${activite.details}` : ""}
                            </small>
                          </div>
                          <span className={styles.bloc}>
                            <IconeCategorie nom={nom} />
                          </span>
                        </li>
                      );
                    })}
                  </ul>
                ) : (
                  <p className={styles.texte}>Aucune activité enregistrée.</p>
                )
              ) : operations.length > 0 ? (
                // Sans accès au journal d'activité : les participations par type d'opération.
                <ul className={styles.operations}>
                  {operations.map((operation) => (
                    <li key={operation.nomOperation}>
                      <div>
                        <strong>{operation.nomOperation}</strong>
                        <small>Journaux auxquels {sujet} a participé</small>
                      </div>
                      <span
                        aria-label={`${operation.nombreOperations} participations`}
                        className={`${styles.bloc} ${styles.blocChiffre}`}
                      >
                        {operation.nombreOperations}
                      </span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className={styles.texte}>Aucune participation enregistrée.</p>
              )}

              {activites && activites.length > 0 && (
                <Link className={styles.voirTout} to="/activites">
                  Voir tout
                  <ArrowRight aria-hidden="true" size={14} />
                </Link>
              )}
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

export default Profil;
