import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  ArrowDown,
  ArrowUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsUpDown,
  Download,
  Info,
  ListChecks,
  Plus,
  Search,
  Trash2,
} from "lucide-react";
import { getAccessToken } from "../../services/authService";
import Sidebar from "../../components/Sidebar";
import CreateJournalModal from "../../components/CreateJournalModal";
import styles from "./Journaux.module.css";

// Lignes par page.
const TAILLE_PAGE = 10;

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[_-]+/g, " ")
    .trim()
    .toUpperCase();

// Libellé et couleur de chaque statut (« Active » de la maquette = EN COURS).
const STATUTS = {
  "EN COURS": { label: "En cours", ton: "vert" },
  "EN ATTENTE": { label: "En attente", ton: "gris" },
  VALIDE: { label: "Validé", ton: "bleu" },
  MODIFIE: { label: "Modifié", ton: "orange" },
  AFFECTEE: { label: "Affectée", ton: "bleu" },
  CLOTURE: { label: "Clôturé", ton: "sombre" },
};

const FLUX = {
  ENTREE: { label: "Entrée", ton: "entree" },
  SORTIE: { label: "Sortie", ton: "sortie" },
  INVENTAIRE: { label: "Inventaire", ton: "inventaire" },
};

// Une fois affecté ou clôturé, un journal a déjà modifié le stock : on ne le supprime pas d'ici.
const STATUTS_NON_SUPPRIMABLES = new Set(["AFFECTEE", "CLOTURE"]);

const TRIS_PREDEFINIS = [
  { valeur: "id:-1", label: "Récent" },
  { valeur: "id:1", label: "Ancien" },
  { valeur: "reference:1", label: "Référence A → Z" },
  { valeur: "partenaire:1", label: "Partenaire A → Z" },
];

const partenaire = (journal) => journal.fournisseur || journal.nomClient || "";
const entite = (journal) => (journal.fournisseur ? "Fournisseur" : journal.nomClient ? "Client" : "");

const VALEURS_TRI = {
  id: (journal) => journal.id,
  reference: (journal) => normaliser(journal.reference),
  partenaire: (journal) => normaliser(partenaire(journal)),
  entite: (journal) => normaliser(entite(journal)),
  flux: (journal) => normaliser(journal.typeMouvementJournal),
  statut: (journal) => normaliser(journal.statut),
};

const nomFichier = (url) =>
  String(url ?? "")
    .replaceAll("\\", "/")
    .split("/")
    .filter(Boolean)
    .at(-1);

// Page de détail de chaque type de journal (les mêmes que dans l'ancienne liste).
function adresseDetail(journal) {
  const flux = normaliser(journal.typeMouvementJournal);
  if (flux === "SORTIE") return `/sortie/${journal.id}`;
  if (flux === "INVENTAIRE") return `/inventaire/${journal.id}`;
  return `/journaux-mouvements/${journal.id}`;
}

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
 * Nouvelle version (test) de la liste des journaux, d'après la maquette du
 * designer. Servie sous /new/journaux ; les anciennes listes restent en place.
 */
function Journaux() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journaux, setJournaux] = useState([]);
  const [chargement, setChargement] = useState(true);
  const [erreur, setErreur] = useState("");
  const [recherche, setRecherche] = useState("");
  const [tri, setTri] = useState({ cle: "id", sens: -1 });
  const [page, setPage] = useState(1);
  const [modalOuvert, setModalOuvert] = useState(false);

  useEffect(() => {
    const controller = new AbortController();

    async function charger() {
      if (!token) return;
      try {
        const response = await fetch(`${springUrl}/journaux-mouvements`, {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error(`Impossible de récupérer les journaux (${response.status}).`);
        }
        setJournaux(await response.json());
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
  }, [springUrl, token]);

  const resultats = useMemo(() => {
    const texte = normaliser(recherche);
    const filtres = texte
      ? journaux.filter((journal) =>
          normaliser([journal.reference, partenaire(journal)].join(" ")).includes(texte),
        )
      : journaux;

    const valeur = VALEURS_TRI[tri.cle];
    return [...filtres].sort((a, b) => {
      const va = valeur(a);
      const vb = valeur(b);
      return (va > vb ? 1 : va < vb ? -1 : 0) * tri.sens;
    });
  }, [journaux, recherche, tri]);

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

  const exporter = () => {
    const entetes = ["Référence", "Partenaire", "Entité", "Type de flux", "Statut"];
    const corps = resultats.map((journal) => [
      journal.reference,
      partenaire(journal),
      entite(journal),
      FLUX[normaliser(journal.typeMouvementJournal)]?.label ?? journal.typeMouvementJournal,
      STATUTS[normaliser(journal.statut)]?.label ?? journal.statut,
    ]);
    const contenu = [entetes, ...corps].map((ligne) => ligne.map(echapperCsv).join(";")).join("\r\n");

    // Un BOM en tête : Excel lit alors correctement les accents.
    const fichier = new Blob([String.fromCharCode(0xfeff), contenu], { type: "text/csv;charset=utf-8" });
    const adresse = URL.createObjectURL(fichier);
    const lien = document.createElement("a");
    lien.href = adresse;
    lien.download = "journaux.csv";
    document.body.appendChild(lien);
    lien.click();
    lien.remove();
    URL.revokeObjectURL(adresse);
  };

  // La pièce jointe demande le jeton : on récupère le fichier puis on le propose au téléchargement.
  const telecharger = async (journal) => {
    const nom = nomFichier(journal.urlPieceJointe);
    if (!nom) return;

    try {
      setErreur("");
      const response = await fetch(`${springUrl}/uploads/${encodeURIComponent(nom)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        throw new Error(`Pièce jointe indisponible (${response.status}).`);
      }
      const adresse = URL.createObjectURL(await response.blob());
      const lien = document.createElement("a");
      lien.href = adresse;
      lien.download = nom;
      document.body.appendChild(lien);
      lien.click();
      lien.remove();
      URL.revokeObjectURL(adresse);
    } catch (cause) {
      setErreur(cause instanceof Error ? cause.message : "Téléchargement impossible.");
    }
  };

  const supprimer = async (journal) => {
    if (!window.confirm(`Supprimer le journal « ${journal.reference} » ? Cette action est définitive.`)) return;

    try {
      setErreur("");
      const response = await fetch(`${springUrl}/journaux-mouvements/${journal.id}`, {
        method: "DELETE",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        throw new Error(await lireMessageErreur(response, `Suppression impossible (${response.status}).`));
      }
      setJournaux((actuels) => actuels.filter((element) => element.id !== journal.id));
    } catch (cause) {
      setErreur(cause instanceof Error ? cause.message : "Suppression impossible.");
    }
  };

  const messageErreur = token ? erreur : "Connectez-vous pour consulter les journaux.";
  const enChargement = chargement && Boolean(token);
  const premier = resultats.length === 0 ? 0 : (pageCourante - 1) * TAILLE_PAGE + 1;
  const dernier = Math.min(pageCourante * TAILLE_PAGE, resultats.length);

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.page}>
        <header className={styles.heading}>
          <h1>Journaux de mouvements</h1>
          <p>Consultez, contrôlez et poursuivez les journaux de l'entrepôt.</p>
        </header>

        <div className={styles.actions}>
          <button className={styles.primary} onClick={() => setModalOuvert(true)} type="button">
            <Plus aria-hidden="true" size={16} />
            Ajouter un journal
          </button>
          <button className={styles.secondary} disabled={resultats.length === 0} onClick={exporter} type="button">
            Exporter
          </button>
        </div>

        <div className={styles.toolbar}>
          <label className={styles.search}>
            <Search aria-hidden="true" size={18} />
            <input
              aria-label="Rechercher une référence ou un partenaire"
              onChange={(event) => {
                setRecherche(event.target.value);
                setPage(1);
              }}
              placeholder="Rechercher une ref / partenaire"
              type="search"
              value={recherche}
            />
          </label>

          <label className={styles.select}>
            <span className={styles.srOnly}>Trier les journaux</span>
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
                <th>Référence</th>
                <EnTeteTriable cle="partenaire" onTri={trierColonne} tri={tri}>
                  Partenaire
                </EnTeteTriable>
                <EnTeteTriable cle="entite" onTri={trierColonne} tri={tri}>
                  Entité
                </EnTeteTriable>
                <EnTeteTriable cle="flux" onTri={trierColonne} tri={tri}>
                  Type de flux
                </EnTeteTriable>
                <EnTeteTriable cle="statut" onTri={trierColonne} tri={tri}>
                  Statut
                </EnTeteTriable>
                <th className={styles.actionsEntete}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {enChargement ? (
                <tr>
                  <td className={styles.vide} colSpan={6}>
                    Chargement des journaux…
                  </td>
                </tr>
              ) : lignesVisibles.length === 0 ? (
                <tr>
                  <td className={styles.vide} colSpan={6}>
                    Aucun journal ne correspond à la recherche.
                  </td>
                </tr>
              ) : (
                lignesVisibles.map((journal) => {
                  const cleStatut = normaliser(journal.statut);
                  const statut = STATUTS[cleStatut] ?? { label: journal.statut || "Inconnu", ton: "gris" };
                  const cleFlux = normaliser(journal.typeMouvementJournal);
                  const flux = FLUX[cleFlux];
                  const piece = nomFichier(journal.urlPieceJointe);
                  const supprimable = !STATUTS_NON_SUPPRIMABLES.has(cleStatut);
                  // Une sortie se prépare par sa liste de commande, avant le picking.
                  const listeCommande = cleFlux === "SORTIE" && cleStatut !== "CLOTURE";

                  return (
                    <tr key={journal.id}>
                      <td className={styles.reference}>{journal.reference}</td>
                      <td>{partenaire(journal) || "—"}</td>
                      <td>{entite(journal) || "—"}</td>
                      <td>
                        <span className={`${styles.flux} ${styles[flux?.ton ?? "inventaire"]}`}>
                          {flux?.label ?? journal.typeMouvementJournal}
                        </span>
                      </td>
                      <td>
                        <span className={`${styles.statut} ${styles[statut.ton]}`}>{statut.label}</span>
                      </td>
                      <td>
                        <div className={styles.iconeActions}>
                          {listeCommande && (
                            <Link
                              aria-label={`Liste de commande de ${journal.reference}`}
                              className={styles.icone}
                              title="Liste de commande"
                              to={`/createListeArticle/${journal.id}`}
                            >
                              <ListChecks aria-hidden="true" size={20} />
                            </Link>
                          )}
                          <button
                            aria-label={`Télécharger la pièce jointe de ${journal.reference}`}
                            className={`${styles.icone} ${styles.telecharger}`}
                            disabled={!piece}
                            onClick={() => telecharger(journal)}
                            title={piece ? "Télécharger la pièce jointe" : "Aucune pièce jointe"}
                            type="button"
                          >
                            <Download aria-hidden="true" size={20} />
                          </button>
                          <Link
                            aria-label={`Voir le journal ${journal.reference}`}
                            className={`${styles.icone} ${styles.details}`}
                            title="Voir le journal"
                            to={adresseDetail(journal)}
                          >
                            <Info aria-hidden="true" size={20} />
                          </Link>
                          <button
                            aria-label={`Supprimer le journal ${journal.reference}`}
                            className={`${styles.icone} ${styles.supprimer}`}
                            disabled={!supprimable}
                            onClick={() => supprimer(journal)}
                            title={supprimable ? "Supprimer" : "Journal déjà affecté ou clôturé : suppression impossible"}
                            type="button"
                          >
                            <Trash2 aria-hidden="true" size={20} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <footer className={styles.pied}>
          <span>{resultats.length === 0 ? "Aucun journal" : `Journaux ${premier}–${dernier} sur ${resultats.length}`}</span>

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

      <CreateJournalModal
        isOpen={modalOuvert}
        onClose={() => setModalOuvert(false)}
        onCreated={(journalCree) => {
          if (journalCree) setJournaux((actuels) => [journalCree, ...actuels]);
        }}
      />
    </div>
  );
}

export default Journaux;
