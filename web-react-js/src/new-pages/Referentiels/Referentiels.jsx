import { useEffect, useMemo, useState } from "react";
import { Building2, Layers, Plus, Ruler, Search, Tag } from "lucide-react";
import Sidebar from "../../components/Sidebar";
import { requeteJson } from "../../services/affectationStockService";
import styles from "./Referentiels.module.css";

const springUrl = import.meta.env.VITE_SPRING_URL;

// Un référentiel = une route du serveur et le champ qui porte le nom de chaque élément
// (envoyé à la création, lu dans la réponse).
const REFERENTIELS = [
  {
    route: "unites",
    champ: "nomUnite",
    titre: "Unités",
    icone: Ruler,
    exemple: "Ex. : cL, kg, pièce",
    description: "L'unité de la contenance d'une pièce : 30 cL, 1,5 L, 350 g…",
  },
  {
    route: "types-produits",
    champ: "nomType",
    titre: "Types de produit",
    icone: Tag,
    exemple: "Ex. : Boisson",
    description: "La catégorie d'un article. Les articles d'une même famille ont le même type.",
  },
  {
    route: "familles",
    champ: "nom",
    titre: "Familles",
    icone: Layers,
    exemple: "Ex. : Coca-Cola",
    description: "Regroupe les variantes d'un même produit, par exemple ses différentes contenances.",
  },
  {
    route: "societes",
    champ: "nomSociete",
    titre: "Sociétés",
    icone: Building2,
    exemple: "Ex. : HB",
    description: "Le fournisseur d'une entrée et la société de chaque article : une entrée ne scanne que les articles de son fournisseur.",
  },
];

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .trim()
    .toUpperCase();

const pluriel = (nombre) => `${nombre} élément${nombre > 1 ? "s" : ""}`;

/**
 * Nouvelle version (test) des référentiels : un menu à gauche, le référentiel
 * choisi à droite. Servie sous /new/referentiels ; l'ancienne page reste sur /referentiels.
 */
function Referentiels() {
  const [choisi, setChoisi] = useState(REFERENTIELS[0].route);
  // Éléments de chaque référentiel (null tant qu'ils ne sont pas chargés ou si le chargement a échoué).
  const [listes, setListes] = useState({});
  const [erreurs, setErreurs] = useState({});
  const [chargement, setChargement] = useState(true);
  // Augmenté après chaque ajout : relance le chargement des listes.
  const [version, setVersion] = useState(0);

  const [nom, setNom] = useState("");
  const [recherche, setRecherche] = useState("");
  const [erreurAjout, setErreurAjout] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [enCours, setEnCours] = useState(false);

  useEffect(() => {
    let actif = true;

    async function charger() {
      const resultats = await Promise.allSettled(
        REFERENTIELS.map((referentiel) => requeteJson(`${springUrl}/${referentiel.route}`)),
      );
      if (!actif) return;

      const nouvelles = {};
      const erreursChargement = {};
      resultats.forEach((resultat, index) => {
        const { route } = REFERENTIELS[index];
        if (resultat.status === "fulfilled") {
          nouvelles[route] = Array.isArray(resultat.value) ? resultat.value : [];
        } else {
          nouvelles[route] = null;
          erreursChargement[route] = resultat.reason?.message ?? "Chargement impossible.";
        }
      });
      setListes(nouvelles);
      setErreurs(erreursChargement);
      setChargement(false);
    }

    charger();
    return () => {
      actif = false;
    };
  }, [version]);

  const referentiel = REFERENTIELS.find((element) => element.route === choisi);
  const elements = listes[choisi];
  const Icone = referentiel.icone;

  const choisir = (route) => {
    setChoisi(route);
    setNom("");
    setRecherche("");
    setErreurAjout("");
    setConfirmation("");
  };

  // Les éléments par ordre alphabétique, filtrés par la recherche.
  const visibles = useMemo(() => {
    if (!elements) return [];
    const texte = normaliser(recherche);
    return [...elements]
      .filter((element) => !texte || normaliser(element[referentiel.champ]).includes(texte))
      .sort((a, b) => String(a[referentiel.champ]).localeCompare(String(b[referentiel.champ]), "fr"));
  }, [elements, recherche, referentiel.champ]);

  async function ajouter(event) {
    event.preventDefault();
    const valeur = nom.trim();
    if (!valeur) {
      setErreurAjout("Le nom est obligatoire.");
      return;
    }

    setEnCours(true);
    setErreurAjout("");
    setConfirmation("");
    try {
      await requeteJson(`${springUrl}/${referentiel.route}`, {
        method: "POST",
        body: JSON.stringify({ [referentiel.champ]: valeur }),
      });
      setNom("");
      setConfirmation(`« ${valeur} » a été ajouté.`);
      setVersion((actuelle) => actuelle + 1);
    } catch (cause) {
      setErreurAjout(cause instanceof Error ? cause.message : "Ajout impossible.");
    } finally {
      setEnCours(false);
    }
  }

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Référentiels</h1>
          <p>Les listes utilisées pour décrire les articles et les journaux.</p>
        </header>

        <div className={styles.grille}>
          <nav aria-label="Référentiels" className={styles.menu}>
            {REFERENTIELS.map((element) => {
              const IconeMenu = element.icone;
              const liste = listes[element.route];
              return (
                <button
                  aria-current={element.route === choisi ? "true" : undefined}
                  className={element.route === choisi ? styles.menuActif : undefined}
                  key={element.route}
                  onClick={() => choisir(element.route)}
                  type="button"
                >
                  <span className={styles.menuIcone}>
                    <IconeMenu aria-hidden="true" size={18} />
                  </span>
                  <span className={styles.menuTexte}>
                    <strong>{element.titre}</strong>
                    <small>{liste ? pluriel(liste.length) : chargement ? "Chargement…" : "Indisponible"}</small>
                  </span>
                </button>
              );
            })}
          </nav>

          <section aria-labelledby="referentiel-titre" className={styles.panneau}>
            <header className={styles.panneauEntete}>
              <span className={styles.panneauIcone}>
                <Icone aria-hidden="true" size={22} />
              </span>
              <div>
                <h2 id="referentiel-titre">{referentiel.titre}</h2>
                <p>{referentiel.description}</p>
              </div>
            </header>

            <form className={styles.ajout} onSubmit={ajouter}>
              <input
                aria-label={`Nouvel élément de ${referentiel.titre}`}
                disabled={enCours}
                onChange={(event) => {
                  setNom(event.target.value);
                  setConfirmation("");
                }}
                placeholder={referentiel.exemple}
                value={nom}
              />
              <button disabled={enCours} type="submit">
                <Plus aria-hidden="true" size={16} />
                {enCours ? "Ajout…" : "Ajouter"}
              </button>
            </form>

            {erreurAjout && (
              <p className={styles.erreur} role="alert">
                {erreurAjout}
              </p>
            )}
            {confirmation && (
              <p className={styles.confirmation} role="status">
                {confirmation}
              </p>
            )}

            {erreurs[choisi] ? (
              <p className={styles.erreur} role="alert">
                {erreurs[choisi]}
              </p>
            ) : chargement ? (
              <p className={styles.vide}>Chargement…</p>
            ) : (
              <>
                <div className={styles.barre}>
                  <span>{pluriel(visibles.length)}</span>
                  <label className={styles.recherche}>
                    <Search aria-hidden="true" size={16} />
                    <input
                      aria-label="Rechercher dans la liste"
                      onChange={(event) => setRecherche(event.target.value)}
                      placeholder="Rechercher"
                      type="search"
                      value={recherche}
                    />
                  </label>
                </div>

                {visibles.length === 0 ? (
                  <p className={styles.vide}>
                    {elements?.length === 0
                      ? "Aucun élément pour le moment. Ajoutez le premier ci-dessus."
                      : "Aucun élément ne correspond à la recherche."}
                  </p>
                ) : (
                  <ul className={styles.liste}>
                    {visibles.map((element) => (
                      <li key={element.id}>
                        <span aria-hidden="true" className={styles.initiale}>
                          {String(element[referentiel.champ]).charAt(0).toUpperCase()}
                        </span>
                        <span className={styles.nom}>{element[referentiel.champ]}</span>
                        <small>#{element.id}</small>
                      </li>
                    ))}
                  </ul>
                )}
              </>
            )}
          </section>
        </div>
      </main>
    </div>
  );
}

export default Referentiels;
