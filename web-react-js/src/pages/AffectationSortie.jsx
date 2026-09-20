import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useParams } from "react-router-dom";
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

  useEffect(() => {
    const controller = new AbortController();

    async function loadPicking() {
      try {
        setLoading(true);
        setError("");
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

        if (!response.ok) {
          throw new Error(
            `Impossible de charger la sortie (${response.status}).`,
          );
        }

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
  }, [id, springUrl, token]);

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
      const message = await response.text();

      throw new Error(message || "La validation du journal a échoué");
    }

    const mouvementsCrees = await response.json();
    if (!Array.isArray(mouvementsCrees)) {
      throw new Error("Réponse inattendue du serveur");
    }

    return mouvementsCrees;

  };

  const validerSortie = async () => {
    try {
      const mouvementsCrees = await appelerApiSortie();

      setNotice(`${mouvementsCrees.length} mouvement(s) de stock créé(s).`);
    } catch (erreur) {
      setError(erreur.message);
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
              <span className="material-symbols-outlined">search</span>
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
            <span className="material-symbols-outlined">arrow_back</span>
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

          <div className="confirmation-layout">
            <aside className="confirmation-document">
              <span className="confirmation-eyebrow">Document client</span>
              <h2>Pièce justificative</h2>
              <p>
                Associez le document fourni par le client à cette sortie avant
                validation.
              </p>

              <div className="confirmation-journal-info">
                <span className="material-symbols-outlined">receipt_long</span>
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
                <span className="material-symbols-outlined">
                  {file ? "task" : "upload_file"}
                </span>
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
                  <span className="material-symbols-outlined">search</span>
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
                  <span className="material-symbols-outlined">info</span>
                  Vérifiez les quantités et le document avant validation.
                </div>
                <button onClick={validerSortie} type="button">
                  Valider la sortie
                  <span className="material-symbols-outlined">
                    arrow_forward
                  </span>
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
        <span className="material-symbols-outlined confirmation-chevron">
          chevron_right
        </span>
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
