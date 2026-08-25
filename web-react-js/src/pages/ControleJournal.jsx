import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
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
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journal, setJournal] = useState(null);
  const [document, setDocument] = useState({ url: "", type: "" });
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
          setDocument({ url: objectUrl, type: blob.type });
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

  return (
    <main className="controle-page">
      <Link className="controle-back" to="/journaux-mouvements">
        ← Retour aux sessions
      </Link>
      <header className="controle-header">
        <div>
          <span className="controle-kicker">Contrôle de session</span>
          <h1>{journal.reference}</h1>
          <p>
            Comparez le document original avec les produits enregistrés par
            l'opérateur.
          </p>
        </div>
        <strong className="controle-status">{journal.statut}</strong>
      </header>
      {error && (
        <p className="controle-error" role="alert">
          {error}
        </p>
      )}
      <section className="controle-meta">
        <Info label="Type" value={journal.typeMouvementJournal} />
        <Info
          label="Fournisseur"
          value={journal.fournisseur || "Non renseigné"}
        />
        <Info label="Client" value={journal.nomClient || "Non renseigné"} />
        <Info label="Lignes scannées" value={details.length} />
      </section>
      <div className="controle-grid">
        <section className="controle-panel">
          <PanelTitle kicker="Document métier" title="Pièce jointe">
            {document.url && (
              <a href={document.url} target="_blank" rel="noreferrer">
                Ouvrir
              </a>
            )}
          </PanelTitle>
          {!nomFichier || !document.url ? (
            <Empty>
              {nomFichier ? "Aperçu indisponible." : "Aucune pièce jointe."}
            </Empty>
          ) : document.type.startsWith("image/") ? (
            <img
              className="controle-image"
              src={document.url}
              alt={`Pièce jointe ${nomFichier}`}
            />
          ) : document.type === "application/pdf" ? (
            <iframe
              className="controle-frame"
              src={document.url}
              title={`Pièce jointe ${nomFichier}`}
            />
          ) : (
            <Empty>
              <a href={document.url} download={nomFichier}>
                Télécharger le fichier
              </a>
            </Empty>
          )}
        </section>
        <section className="controle-panel">
          <PanelTitle kicker="Résultat terrain" title="Produits scannés">
            <span>
              {details.length} ligne{details.length > 1 ? "s" : ""}
            </span>
          </PanelTitle>
          {!details.length ? (
            <Empty>Aucun produit enregistré pour cette session.</Empty>
          ) : (
            <div className="controle-table-wrap">
              <table className="controle-table">
                <thead>
                  <tr>
                    <th>Article</th>
                    <th>Quantité scannée</th>
                  </tr>
                </thead>
                <tbody>
                  {details.map((d) => (
                    <tr key={d.id}>
                      <td>{d.nomArticle}</td>
                      <td>{d.quantite}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>
      <footer className="controle-actions">
        <div>
          <strong>Décision du responsable</strong>
          <p>
            {peutDecider
              ? "La session est prête à être contrôlée."
              : `Aucune décision possible avec le statut « ${journal.statut} ».`}
          </p>
        </div>
        {peutDecider && (
          <div className="controle-buttons">
            <button
              className="secondary"
              disabled={saving}
              onClick={() =>
                executerDecision(
                  "demander-modification",
                  "Demander une modification",
                )
              }
              type="button"
            >
              Demander une modification
            </button>
            <button
              className="primary"
              disabled={saving}
              onClick={() => executerDecision("valider", "Valider la session")}
              type="button"
            >
              {saving ? "Enregistrement…" : "Valider la session"}
            </button>
          </div>
        )}
      </footer>
    </main>
  );
}
function Info({ label, value }) {
  return (
    <div>
      <span>{label}</span>
      <strong>{value}</strong>
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
  return <div className="controle-empty">{children}</div>;
}
export default ControleJournal;
