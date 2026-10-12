import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { ArrowLeft, ArrowRight, CheckSquare, ChevronRight, FileText, FileUp, Info, Receipt, Search } from "lucide-react";
import Sidebar from "../components/Sidebar";
import { getAccessToken } from "../services/authService";
import "./css/AffectationSortie.css";

const formatDate = (value) => {
  if (!value) return "Non renseignée";
  return new Intl.DateTimeFormat("fr-FR").format(new Date(value));
};

const normalize = (value) =>
  String(value ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();

async function lireMessageErreur(response, messageParDefaut) {
  const contenu = await response.text();
  if (!contenu.trim()) return messageParDefaut;

  try {
    const erreur = JSON.parse(contenu);
    const message =
      erreur.detail ??
      erreur.message ??
      erreur.title ??
      erreur.error;

    if (typeof message === "string" && message.trim()) return message;
  } catch {
    const typeContenu = response.headers.get("content-type") ?? "";
    if (typeContenu.includes("text/plain")) return contenu.trim();
  }

  return messageParDefaut;
}

function AffectationSortie() {
  const { id } = useParams();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const fileInput = useRef(null);
  const [lignes, setLignes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [file, setFile] = useState(null);
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState("ordre");
  const [startTime, setStartTime] = useState("");
  const [endTime, setEndTime] = useState("");
  const [openLine, setOpenLine] = useState(null);
  const [notice, setNotice] = useState("");
  const [statutJournal, setStatutJournal] = useState("");
  const [validationEnCours, setValidationEnCours] = useState(false);
  // Vrai quand aucun picking n'existe pour cette sortie.
  const [sansPicking, setSansPicking] = useState(false);
  // Le bon de reste cree a la validation : un seul bon pour tous les manques.
  const [bonReste, setBonReste] = useState(null);
  const [impressionEnCours, setImpressionEnCours] = useState(false);
  const cloture = statutJournal === "CLOTURE";

  // Cherche le bon de reste de cette sortie (204 s'il n'y en a pas).
  const chargerBonReste = useCallback(
    async (signal) => {
      const response = await fetch(
        `${springUrl}/journaux-mouvements/${id}/bon-reste`,
        {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
          signal,
        },
      );

      if (response.status === 200) {
        setBonReste(await response.json());
      } else {
        setBonReste(null);
      }
    },
    [id, springUrl, token],
  );

  // Ouvre le PDF du bon dans un nouvel onglet. Le jeton doit etre envoye : un
  // simple lien ne suffit donc pas, on recupere le fichier puis on l'affiche.
  const imprimerBon = async () => {
    if (!bonReste || impressionEnCours) return;

    // L'onglet est ouvert tout de suite, sur le clic, pour ne pas etre bloque.
    const fenetre = window.open("", "_blank");

    try {
      setImpressionEnCours(true);
      const response = await fetch(
        `${springUrl}/journaux-mouvements/${bonReste.id}/bon.pdf`,
        { headers: { Authorization: `Bearer ${token}` } },
      );

      if (!response.ok) {
        throw new Error(
          await lireMessageErreur(
            response,
            `Impossible de générer le bon (${response.status}).`,
          ),
        );
      }

      const blob = await response.blob();
      const adresse = URL.createObjectURL(blob);
      if (fenetre) {
        fenetre.location.href = adresse;
      } else {
        window.location.href = adresse;
      }
    } catch (erreur) {
      fenetre?.close();
      setError(erreur.message);
    } finally {
      setImpressionEnCours(false);
    }
  };

  useEffect(() => {
    const controller = new AbortController();

    async function loadPicking() {
      try {
        setLoading(true);
        setError("");

        // Le statut du journal indique si la sortie est deja cloturee.
        const journalResponse = await fetch(
          `${springUrl}/journaux-mouvements/${id}`,
          {
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
            signal: controller.signal,
          },
        );

        if (journalResponse.ok) {
          const journal = await journalResponse.json();
          setStatutJournal(journal.statut ?? "");

          // Sortie deja cloturee : on retrouve son bon de reste pour le reimprimer.
          if (journal.statut === "CLOTURE") {
            await chargerBonReste(controller.signal);
          }
        }

        const response = await fetch(
          `${springUrl}/lignes-picking/getLignes/${id}`,
          {
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
            signal: controller.signal,
          },
        );

        // 404 : aucun picking pour cette sortie. Ce n'est pas une erreur : soit
        // le parcours n'a pas encore ete genere (cas d'un bon de reste neuf),
        // soit rien n'etait disponible au moment de le generer.
        if (response.status === 404) {
          setLignes([]);
          setSansPicking(true);
          return;
        }

        if (!response.ok) {
          throw new Error(
            await lireMessageErreur(
              response,
              `Impossible de charger la sortie (${response.status}).`,
            ),
          );
        }

        setSansPicking(false);
        const data = await response.json();
        setLignes(Array.isArray(data) ? data : []);
      } catch (cause) {
        if (cause.name !== "AbortError") {
          setError(cause.message || "Le chargement de la sortie a échoué.");
        }
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }

    loadPicking();
    return () => controller.abort();
  }, [id, springUrl, token, chargerBonReste]);

  const filteredLines = useMemo(() => {
    const value = normalize(search);
    const result = lignes.filter((line) =>
      normalize(
        `${line.nomArticle} ${line.nomEmplacement} ${line.statut}`,
      ).includes(value),
    );

    return [...result].sort((a, b) => {
      if (sort === "article") {
        return String(a.nomArticle).localeCompare(String(b.nomArticle), "fr");
      }
      if (sort === "quantite") {
        return (
          (b.quantiteConditionnementsAPrelever ?? 0) -
          (a.quantiteConditionnementsAPrelever ?? 0)
        );
      }
      return (a.ordrePassage ?? 0) - (b.ordrePassage ?? 0);
    });
  }, [lignes, search, sort]);

  const appelerApiSortie = async () => {
    const response = await fetch(
      `${springUrl}/mouvementStock/validerSortie/${id}`,
      {
        method: "POST",
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      },
    );

    if (!response.ok) {
      throw new Error(
        await lireMessageErreur(response, "La validation du journal a échoué"),
      );
    }

    const mouvementsCrees = await response.json();
    if (!Array.isArray(mouvementsCrees)) {
      throw new Error("Réponse inattendue du serveur");
    }

    return mouvementsCrees;

  };

  const validerSortie = async () => {
    if (cloture || validationEnCours) return;

    // Sans picking, la validation reprend toute la commande dans un nouveau bon :
    // on demande confirmation pour ne pas le faire par erreur.
    if (
      sansPicking &&
      !window.confirm(
        "Aucun picking n'a été généré pour cette sortie. Valider reprendra " +
          "toute la commande dans un nouveau bon de reste. Continuer ?",
      )
    ) {
      return;
    }

    try {
      setValidationEnCours(true);
      setError("");
      const mouvementsCrees = await appelerApiSortie();

      setStatutJournal("CLOTURE");
      setNotice(
        `Sortie clôturée : ${mouvementsCrees.length} mouvement(s) de stock créé(s).`,
      );

      // S'il reste des produits a servir, le bon de reste vient d'etre cree.
      await chargerBonReste();
    } catch (erreur) {
      setError(erreur.message);
    } finally {
      setValidationEnCours(false);
    }
  };

  return (
    <div className="confirmation-shell">
      <Sidebar />
      <section className="confirmation-workspace">
        <header className="confirmation-topbar">
          <span>Opérations / Confirmation de sortie</span>
          <div className="confirmation-topbar-right">
            <label className="confirmation-global-search">
              <Search size={16} />
              <input
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Rechercher"
                type="search"
                value={search}
              />
            </label>
            <div className="confirmation-user">
              <span>AR</span>
              <div>
                <strong>Administrateur</strong>
                <small>Responsable entrepôt</small>
              </div>
            </div>
          </div>
        </header>

        <main className="confirmation-page">
          <Link className="confirmation-back" to="/journaux-mouvements">
            <ArrowLeft size={16} />
            Journaux de mouvements
          </Link>

          <header className="confirmation-heading">
            <div>
              <h1>Confirmation de sortie</h1>
              <p>Contrôlez les prélèvements avant la validation définitive.</p>
            </div>
            <div className="confirmation-reference">
              Journal <strong>#{id}</strong>
            </div>
          </header>

          {error && (
            <div className="confirmation-error" role="alert">
              {error}
            </div>
          )}
          {notice && (
            <div className="confirmation-notice" role="status">
              {notice}
            </div>
          )}
          {sansPicking && !cloture && !error && (
            <div className="confirmation-notice" role="status">
              Aucun picking n’a encore été généré pour cette sortie : le
              parcours se génère depuis l’application mobile. Si le stock est
              vide, il ne sera pas créé.
            </div>
          )}
          {bonReste && (
            <div className="confirmation-bon" role="status">
              <FileText size={20} />
              <div>
                <strong>Bon de reste {bonReste.reference}</strong>
                <small>
                  {bonReste.nombreProduits} produit(s) à servir lorsque le
                  stock sera disponible.
                </small>
              </div>
              <button
                disabled={impressionEnCours}
                onClick={imprimerBon}
                type="button"
              >
                {impressionEnCours ? "Génération…" : "Imprimer le bon"}
              </button>
            </div>
          )}

          <div className="confirmation-layout">
            <aside className="confirmation-document">
              <span className="confirmation-eyebrow">Document client</span>
              <h2>Pièce justificative</h2>
              <p>
                Associez le document fourni par le client à cette sortie avant
                validation.
              </p>

              <div className="confirmation-journal-info">
                <Receipt size={18} />
                <div>
                  <small>Journal sélectionné</small>
                  <strong>Sortie #{id}</strong>
                </div>
              </div>

              <input
                accept=".pdf,.png,.jpg,.jpeg"
                hidden
                onChange={(event) => setFile(event.target.files?.[0] ?? null)}
                ref={fileInput}
                type="file"
              />
              <button
                className={`confirmation-upload ${file ? "has-file" : ""}`}
                onClick={() => fileInput.current?.click()}
                type="button"
              >
                {file ? <CheckSquare size={22} /> : <FileUp size={22} />}
                <strong>{file ? file.name : "Importer un document"}</strong>
                <small>
                  {file
                    ? "Cliquer pour remplacer"
                    : "PDF, PNG ou JPG · 10 Mo maximum"}
                </small>
              </button>
            </aside>

            <section className="confirmation-picking">
              <header className="confirmation-picking-header">
                <div className="confirmation-operator">
                  <span>OP</span>
                  <div>
                    <small>Opérateur affecté</small>
                    <strong>À récupérer depuis le picking</strong>
                  </div>
                </div>
                <div className="confirmation-times">
                  <div>
                    <small>Début du picking</small>
                    <strong>—</strong>
                  </div>
                  <i />
                  <div>
                    <small>Fin du picking</small>
                    <strong>—</strong>
                  </div>
                </div>
              </header>

              <div className="confirmation-toolbar">
                <label className="confirmation-search">
                  <Search size={16} />
                  <input
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Rechercher un article ou emplacement"
                    type="search"
                    value={search}
                  />
                </label>
                <div className="confirmation-time-filter">
                  <input
                    aria-label="Heure de début"
                    onChange={(event) => setStartTime(event.target.value)}
                    type="time"
                    value={startTime}
                  />
                  <span>à</span>
                  <input
                    aria-label="Heure de fin"
                    onChange={(event) => setEndTime(event.target.value)}
                    type="time"
                    value={endTime}
                  />
                </div>
                <select
                  className="confirmation-sort"
                  onChange={(event) => setSort(event.target.value)}
                  value={sort}
                >
                  <option value="ordre">Ordre de passage</option>
                  <option value="article">Nom de l’article</option>
                  <option value="quantite">Quantité</option>
                </select>
              </div>

              <div className="confirmation-list-heading">
                <div>
                  <h2>Prélèvements</h2>
                  <span>{filteredLines.length}</span>
                </div>
                <small>{lignes.length} ligne(s) dans ce journal</small>
              </div>

              <div className="confirmation-table">
                <div className="confirmation-table-head">
                  <span>#</span>
                  <span>Article</span>
                  <span>Emplacement</span>
                  <span>Statut</span>
                  <span>Quantité</span>
                  <span />
                </div>

                {loading ? (
                  <div className="confirmation-empty">
                    Chargement des prélèvements…
                  </div>
                ) : filteredLines.length === 0 ? (
                  <div className="confirmation-empty">
                    Aucun prélèvement trouvé.
                  </div>
                ) : (
                  filteredLines.map((line) => (
                    <PickingRow
                      key={line.id}
                      line={line}
                      open={openLine === line.id}
                      toggle={() =>
                        setOpenLine((current) =>
                          current === line.id ? null : line.id,
                        )
                      }
                    />
                  ))
                )}
              </div>

              <footer className="confirmation-footer">
                <div>
                  <Info size={16} />
                  {cloture
                    ? "Cette sortie est clôturée. Vous consultez son résumé."
                    : "Vérifiez les quantités et le document avant validation."}
                </div>
                <button
                  disabled={cloture || validationEnCours}
                  onClick={validerSortie}
                  type="button"
                >
                  {cloture ? "Sortie clôturée" : "Valider la sortie"}
                  {!cloture && <ArrowRight size={16} />}
                </button>
              </footer>
            </section>
          </div>
        </main>
      </section>
    </div>
  );
}

function PickingRow({ line, open, toggle }) {
  return (
    <div className={`confirmation-row-wrap ${open ? "is-open" : ""}`}>
      <button className="confirmation-row" onClick={toggle} type="button">
        <span className="confirmation-order">
          {String(line.ordrePassage ?? "—").padStart(2, "0")}
        </span>
        <span className="confirmation-article">
          <strong>{line.nomArticle}</strong>
          <small>DLC {formatDate(line.dlc)}</small>
        </span>
        <span className="confirmation-location">
          {line.nomEmplacement || "—"}
        </span>
        <span className="confirmation-status">
          <i />
          {String(line.statut ?? "À contrôler").replaceAll("_", " ")}
        </span>
        <span className="confirmation-quantity">
          <strong>{line.quantiteConditionnementsAPrelever ?? 0}</strong>
          <small>conditionnements</small>
        </span>
        <ChevronRight className="confirmation-chevron" size={17} />
      </button>
      {open && (
        <div className="confirmation-details">
          <Detail label="DLV" value={formatDate(line.dlv)} />
          <Detail
            label="Quantité en pièces"
            value={line.quantitePiecesAPrelever}
          />
          <Detail label="Ligne picking" value={`#${line.id}`} />
          <Detail label="Picking" value={`#${line.pickingId}`} />
        </div>
      )}
    </div>
  );
}

function Detail({ label, value }) {
  return (
    <div>
      <small>{label}</small>
      <strong>{value ?? "Non renseigné"}</strong>
    </div>
  );
}

export default AffectationSortie;
