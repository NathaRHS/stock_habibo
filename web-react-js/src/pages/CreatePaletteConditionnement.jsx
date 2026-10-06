import { useCallback, useEffect, useMemo, useState } from "react";
import { getAccessToken } from "../services/authService";
import { Link } from "react-router-dom";
import { PackageOpen } from "lucide-react";
import Button from "../components/Button";
import PageLayout from "../components/PageLayout";
import Panel from "../components/Panel";
import "./css/CreatePaletteConditionnement.css";

const initialForm = {
  articleConditionnementId: "",
  quantiteMaximale: "",
};

function CreatePaletteConditionnement() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [form, setForm] = useState(initialForm);
  const [conditionnements, setConditionnements] = useState([]);
  const [regles, setRegles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const chargerDonnees = useCallback(async () => {
    const token = getAccessToken();
    if (!token) {
      throw new Error("Votre session a expiré. Reconnectez-vous.");
    }

    const headers = {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
    };
    const [conditionnementsResponse, reglesResponse] = await Promise.all([
      fetch(`${springUrl}/articles-conditionnements`, { headers }),
      fetch(`${springUrl}/palettes-conditionnements`, { headers }),
    ]);

    if (!conditionnementsResponse.ok || !reglesResponse.ok) {
      throw new Error("Impossible de charger les capacités palettes.");
    }

    const [conditionnementsData, reglesData] = await Promise.all([
      conditionnementsResponse.json(),
      reglesResponse.json(),
    ]);
    setConditionnements(conditionnementsData);
    setRegles(reglesData);
  }, [springUrl]);

  useEffect(() => {
    const initialiser = async () => {
      try {
        setError("");
        await chargerDonnees();
      } catch (erreur) {
        setError(erreur instanceof Error ? erreur.message : "Une erreur est survenue.");
      } finally {
        setLoading(false);
      }
    };

    initialiser();
  }, [chargerDonnees]);

  const idsDejaConfigures = useMemo(
    () => new Set(regles.map((regle) => regle.articleConditionnementId)),
    [regles],
  );
  const optionsDisponibles = conditionnements.filter(
    (conditionnement) => !idsDejaConfigures.has(conditionnement.id),
  );
  const conditionnementSelectionne = conditionnements.find(
    (conditionnement) => conditionnement.id === Number(form.articleConditionnementId),
  );
  const quantiteMaximale = Number(form.quantiteMaximale);
  const capaciteTotale = conditionnementSelectionne && Number.isInteger(quantiteMaximale)
    ? conditionnementSelectionne.quantitePieceStandard * quantiteMaximale
    : 0;

  const lireMessageErreur = async (response) => {
    try {
      const contenu = await response.json();
      return contenu.detail || contenu.message || contenu.error;
    } catch {
      return "";
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const articleConditionnementId = Number(form.articleConditionnementId);

    if (!Number.isInteger(articleConditionnementId) || articleConditionnementId <= 0) {
      setError("Choisissez un conditionnement d’article.");
      return;
    }
    if (!Number.isInteger(quantiteMaximale) || quantiteMaximale <= 0) {
      setError("La quantité maximale doit être un entier strictement positif.");
      return;
    }

    try {
      setSubmitting(true);
      setError("");
      setSuccess("");
      const token = getAccessToken();
      if (!token) throw new Error("Votre session a expiré. Reconnectez-vous.");

      const response = await fetch(`${springUrl}/palettes-conditionnements`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ articleConditionnementId, quantiteMaximale }),
      });

      if (!response.ok) {
        const message = await lireMessageErreur(response);
        throw new Error(message || `Création impossible (${response.status}).`);
      }

      const nouvelleRegle = await response.json();
      setRegles((reglesActuelles) => [...reglesActuelles, nouvelleRegle]);
      setForm(initialForm);
      setSuccess("La capacité palette a été enregistrée.");
    } catch (erreur) {
      setError(erreur instanceof Error ? erreur.message : "Création impossible.");
    } finally {
      setSubmitting(false);
    }
  };

  const trouverConditionnement = (id) =>
    conditionnements.find((conditionnement) => conditionnement.id === id);

  return (
    <PageLayout
      breadcrumb="Stock / Capacités palettes"
      kicker="Stock"
      title="Capacités palettes"
      description="Nombre maximum d’unités d’un conditionnement sur une place palette."
      actions={
        <Link className="layout-link-button" to="/article-conditionnements">
          <PackageOpen size={17} />
          Conditionnements
        </Link>
      }
    >
        <Panel
          title="Nouvelle capacité"
          subtitle="Une seule capacité par conditionnement d’article."
        >
          {loading ? (
            <p className="layout-table-empty">Chargement…</p>
          ) : (
            <form onSubmit={handleSubmit} className="layout-form">
              {optionsDisponibles.length === 0 && !error && (
                <p className="layout-message layout-message--info">
                  Tous les conditionnements ont déjà une capacité.
                </p>
              )}
              {error && <p className="layout-message layout-message--error" role="alert">{error}</p>}
              {success && <p className="layout-message layout-message--success" role="status">{success}</p>}

              <div className="palette-form-grid">
              <label>
                Conditionnement d’article
                <select
                  value={form.articleConditionnementId}
                  onChange={(event) => {
                    setForm((formActuel) => ({
                      ...formActuel,
                      articleConditionnementId: event.target.value,
                    }));
                    setError("");
                    setSuccess("");
                  }}
                  disabled={submitting || optionsDisponibles.length === 0}
                  required
                >
                  <option value="">Sélectionner un conditionnement</option>
                  {optionsDisponibles.map((conditionnement) => (
                    <option key={conditionnement.id} value={conditionnement.id}>
                      {conditionnement.nomArticle} — {conditionnement.nomConditionnement}
                      {` (${conditionnement.quantitePieceStandard} pièces)`}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                Unités max. par palette
                <input
                  type="number"
                  min="1"
                  step="1"
                  inputMode="numeric"
                  value={form.quantiteMaximale}
                  onChange={(event) => {
                    setForm((formActuel) => ({
                      ...formActuel,
                      quantiteMaximale: event.target.value,
                    }));
                    setError("");
                    setSuccess("");
                  }}
                  placeholder="Ex. 50"
                  disabled={submitting}
                  required
                />
              </label>

              <p className="palette-total" aria-live="polite">
                <span>Soit</span>
                <strong>{capaciteTotale > 0 ? capaciteTotale : "—"}</strong>
                <span>pièces</span>
              </p>
              </div>

              <div className="layout-form-actions">
                <Button
                  type="submit"
                  loading={submitting}
                  disabled={loading || optionsDisponibles.length === 0}
                >
                  Enregistrer
                </Button>
              </div>
            </form>
          )}
        </Panel>

        <Panel title="Capacités enregistrées" subtitle={`${regles.length} au total`}>
          {!loading && regles.length === 0 ? (
            <p className="layout-table-empty">Aucune capacité pour l’instant.</p>
          ) : (
            <div className="layout-table-scroll">
              <table className="layout-table">
                <thead>
                  <tr>
                    <th>Article</th>
                    <th>Conditionnement</th>
                    <th className="is-number">Pièces / unité</th>
                    <th className="is-number">Unités / palette</th>
                    <th className="is-number">Pièces / palette</th>
                  </tr>
                </thead>
                <tbody>
                  {regles.map((regle) => {
                    const conditionnement = trouverConditionnement(regle.articleConditionnementId);
                    return (
                      <tr key={regle.id}>
                        <td><strong>{conditionnement?.nomArticle || "Article inconnu"}</strong></td>
                        <td>{conditionnement?.nomConditionnement || `#${regle.articleConditionnementId}`}</td>
                        <td className="is-number">{conditionnement?.quantitePieceStandard ?? "—"}</td>
                        <td className="is-number">{regle.quantiteMaximale}</td>
                        <td className="is-number">
                          {conditionnement
                            ? conditionnement.quantitePieceStandard * regle.quantiteMaximale
                            : "—"}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
    </PageLayout>
  );
}

export default CreatePaletteConditionnement;
