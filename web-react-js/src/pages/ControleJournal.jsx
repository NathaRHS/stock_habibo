import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Button from "../components/Button";
import PdfViewer from "../components/PdfViewer";
import Sidebar from "../components/Sidebar";
import { getAccessToken } from "../services/authService";
import "./css/ControleJournal.css";

const normaliser = (valeur) =>
  String(valeur ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[_-]+/g, " ")
    .trim()
    .toUpperCase();

const extraireNomFichier = (chemin) =>
  String(chemin ?? "")
    .replaceAll("\\", "/")
    .split("/")
    .filter(Boolean)
    .at(-1);

function ControleJournal() {
  const { id } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journal, setJournal] = useState(null);
  const [document, setDocument] = useState({ url: "", type: "", fichier: null });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const controller = new AbortController();
    let objectUrl = "";
    async function charger() {
      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        setLoading(false);
        return;
      }
      try {
        const headers = {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        };
        const journalResponse = await fetch(
          `${springUrl}/journaux-mouvements/${id}`,
          { headers, signal: controller.signal },
        );
        if (!journalResponse.ok)
          throw new Error(`Session indisponible (${journalResponse.status}).`);
        const journalData = await journalResponse.json();
        setJournal(journalData);
        const nomFichier = extraireNomFichier(journalData.urlPieceJointe);
        if (nomFichier) {
          const response = await fetch(
            `${springUrl}/uploads/${encodeURIComponent(nomFichier)}`,
            {
              headers: { Authorization: `Bearer ${token}` },
              signal: controller.signal,
            },
          );
          if (!response.ok)
            throw new Error(`Pièce jointe indisponible (${response.status}).`);
          const blob = await response.blob();
          objectUrl = URL.createObjectURL(blob);
          setDocument({ url: objectUrl, type: blob.type, fichier: blob });
        }
      } catch (erreur) {
        if (erreur.name !== "AbortError")
          setError(erreur.message || "Chargement impossible.");
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }
    charger();
    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [id, springUrl, token]);

  const statutActuel = normaliser(journal?.statut);
  const peutDecider = statutActuel === "EN ATTENTE";
  const peutAffecter = statutActuel === "VALIDE";

  async function executerDecision(endpoint, action) {
    if (!window.confirm(`Confirmer : ${action} ?`)) return;
    try {
      setSaving(true);
      setError("");
      const response = await fetch(
        `${springUrl}/journaux-mouvements/${id}/${endpoint}`,
        {
          method: "POST",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        },
      );
      if (!response.ok)
        throw new Error(`Décision non enregistrée (${response.status}).`);
      setJournal(await response.json());
    } catch (erreur) {
      setError(erreur.message || "Décision non enregistrée.");
    } finally {
      setSaving(false);
    }
  }

  if (loading)
    return <main className="controle-page">Chargement de la session…</main>;
  if (!journal)
    return (
      <main className="controle-page">
        <Link to="/journaux-mouvements">← Retour aux sessions</Link>
        <p className="controle-error" role="alert">
          {error || "Session indisponible."}
        </p>
      </main>
    );

  const details = Array.isArray(journal.details) ? journal.details : [];
  const nomFichier = extraireNomFichier(journal.urlPieceJointe);
  const totalQuantite = details.reduce((acc, d) => acc + (Number(d.quantite) || 0), 0);

  return (
    <div className="controle-shell">
      <Sidebar />
      <section className="controle-main-section">
        <header className="controle-global-topbar">
          <p>Opérations / Contrôle du journal</p>
          <label><span className="material-symbols-outlined">search</span><input placeholder="Rechercher" type="search" /></label>
          <div className="controle-global-user"><span>AR</span><div><strong>Administrateur</strong><small>Responsable entrepôt</small></div></div>
        </header>
    <main className="controle-app">
      {/* Topbar aux standards du design UI/UX */}
      <header className="topbar">
        <div className="topbar-left">
          <Link className="controle-back" to="/journaux-mouvements" style={{ textDecoration: 'none', color: 'inherit', display: 'flex', alignItems: 'center', marginRight: '8px' }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </Link>
          <div className="title-group">
            <h1>
              {journal.reference}
              <span className="badge-status">
                <span className="material-symbols-outlined" style={{ fontSize: '13px' }}>schedule</span>
                {journal.statut}
              </span>
            </h1>
            <div className="meta-info">
              {journal.fournisseur || "Fournisseur Test"} · Réception d'entrepôt
            </div>
          </div>
        </div>

        {/* Boutons d'en-tête alignés sur le design system */}
        <div className="topbar-right">
          {peutDecider && (
            <>
              <Button
                className="btn btn-primary"
                disabled={saving}
                onClick={() =>
                  executerDecision(
                    "demander-modification",
                    "Demander une modification",
                  )
                }
                type="button"
              >
                <span className="material-symbols-outlined">edit_note</span>
                Modifier
              </Button>
              <Button
                className="btn btn-accent"
                disabled={saving}
                onClick={() => executerDecision("valider", "Valider la session")}
                type="button"
              >
                <span className="material-symbols-outlined">check_circle</span>
                {saving ? "Enregistrement…" : "Valider la session"}
              </Button>
            </>
          )}
      
        </div>
      </header>

      {/* Metrics Strip inspiré du design B2B moderne */}
      <section className="metrics-grid">
        <div className="metric-item">
          <span className="metric-label">
            <span className="material-symbols-outlined">swap_horiz</span>
            Type de flux
          </span>
          <span className="metric-value">{journal.typeMouvementJournal || "Entrée de stock"}</span>
        </div>
        <div className="metric-item">
          <span className="metric-label">
            <span className="material-symbols-outlined">local_shipping</span>
            Fournisseur
          </span>
          <span className="metric-value">{journal.fournisseur || "Non renseigné"}</span>
        </div>
        <div className="metric-item">
          <span className="metric-label">
            <span className="material-symbols-outlined">apartment</span>
            Client
          </span>
          <span className="metric-value">{journal.nomClient || "Non renseigné"}</span>
        </div>
        <div className="metric-item">
          <span className="metric-label">
            <span className="material-symbols-outlined">qr_code_scanner</span>
            Lignes scannées
          </span>
          <span className="metric-value">{details.length} / {details.length} lignes</span>
        </div>
      </section>

      {error && (
        <p className="controle-error" role="alert" style={{ margin: '16px 36px', padding: '12px', background: '#fef2f2', color: '#991b1b', borderRadius: '6px' }}>
          {error}
        </p>
      )}

      {/* Workspace en deux colonnes (Document & Résultats) */}
      <div className="controle-workspace">
        {/* Left: Document Viewer */}
        <section className="viewer-pane">
          <div className="pane-header">
            <span>
              <span className="material-symbols-outlined" style={{ verticalAlign: "-3px", marginRight: "6px" }}>description</span>
              Document d'origine
            </span>
            <span style={{ fontFamily: "monospace", fontSize: "11px", fontWeight: "500", textTransform: "none", color: "var(--text)" }}>
              {nomFichier || "aucun-document"}
            </span>
          </div>
          <div className="doc-container">
            {!nomFichier || !document.url ? (
              <Empty>
                {nomFichier ? "Aperçu indisponible." : "Aucune pièce jointe."}
              </Empty>
            ) : document.type.startsWith("image/") ? (
              <div className="paper-sheet" style={{ padding: '20px', display: 'flex', justifyContent: 'center' }}>
                <img
                  className="controle-image"
                  src={document.url}
                  alt={`Pièce jointe ${nomFichier}`}
                  style={{ maxWidth: '100%', maxHeight: '450px', objectFit: 'contain', borderRadius: '8px' }}
                />
              </div>
            ) : document.type === "application/pdf" ? (
              <PdfViewer
                fichier={document.fichier}
                urlTelechargement={document.url}
                nomFichier={nomFichier}
              />
            ) : (
              <Empty>
                <a href={document.url} download={nomFichier}>
                  Télécharger le fichier
                </a>
              </Empty>
            )}
          </div>
        </section>

        {/* Right: Scanned Result */}
        <aside className="results-pane">
          <div className="pane-header">
            <span>
              <span className="material-symbols-outlined" style={{ verticalAlign: "-3px", marginRight: "6px" }}>inventory_2</span>
              Résultat du terrain
            </span>
            <span style={{ fontWeight: "700", color: "var(--text)", fontFamily: "monospace", textTransform: "none" }}>
              {totalQuantite} unités totales
            </span>
          </div>

          <div className="results-content">
            <div>
              <div className="section-title">
                <span>Articles scannés</span>
                <span style={{ fontSize: "11px", color: "var(--muted)", fontWeight: "500" }}>
                  {details.length} produit{details.length > 1 ? "s" : ""}
                </span>
              </div>

              {!details.length ? (
                <Empty>Aucun produit enregistré pour cette session.</Empty>
              ) : (
                <div className="scanned-list">
                  {details.map((d) => (
                    <div className="scanned-item" key={d.id}>
                      <div className="item-info">
                        <h4>{d.nomArticle}</h4>
                        <span>
                          <span className="material-symbols-outlined">verified</span>
                          Code scanné validé
                        </span>
                      </div>
                      <div className="item-qty">{d.quantite}</div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Summary Block */}
            <div className="control-summary">
              <div className="summary-row">
                <span>Lignes contrôlées</span>
                <strong>{details.length} / {details.length}</strong>
              </div>
              <div className="summary-row">
                <span>État général</span>
                <span className={statutActuel === "VALIDE" ? "text-success" : ""}>{journal.statut}</span>
              </div>
              <div className="summary-row">
                <span>Écart constaté</span>
                <strong>0 unité</strong>
              </div>
            </div>
          </div>

          {/* Footer d'action principal de la modale / panneau */}
          <div className="pane-footer">
            {peutDecider && (
              <Button
                className="btn btn-accent"
                disabled={saving}
                onClick={() => executerDecision("valider", "Valider la réception")}
                type="button"
                style={{ width: '100%' }}
              >
                <span className="material-symbols-outlined">check_circle</span>
                {saving ? "Enregistrement…" : "Valider la réception"}
              </Button>
            )}
            {peutAffecter && (
              <Button
                className="btn btn-accent"
                onClick={() =>
                  navigate(`/journaux-mouvements/${id}/affectation-stock`)
                }
                type="button"
                style={{ width: '100%' }}
              >
                <span className="material-symbols-outlined">rule_folder</span>
                Affecter les emplacements
              </Button>
            )}
          </div>
        </aside>
      </div>
    </main>
      </section>
    </div>
  );
}

function Info({ label, value }) {
  return (
    <div className="metric-item">
      <span className="metric-label">{label}</span>
      <span className="metric-value">{value}</span>
    </div>
  );
}

function PanelTitle({ kicker, title, children }) {
  return (
    <header className="controle-panel-title">
      <div>
        <span className="controle-kicker">{kicker}</span>
        <h2>{title}</h2>
      </div>
      {children}
    </header>
  );
}

function Empty({ children }) {
  return <div className="controle-empty" style={{ padding: '24px', textAlign: 'center', color: '#6b7280' }}>{children}</div>;
}

export default ControleJournal;
