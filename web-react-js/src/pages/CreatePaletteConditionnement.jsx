import { useCallback, useEffect, useMemo, useState } from "react";
import { getAccessToken } from "../services/authService";
import Button from "../components/Button";
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
    <main className="palette-page">
      <header className="palette-header">
        <div>
          <p className="palette-eyebrow">Configuration du stockage</p>
          <h1>Capacités des palettes</h1>
          <p>
            Définissez combien de conditionnements d’un article peuvent tenir sur
            une place palette.
          </p>
        </div>
        <a href="/article-conditionnements" className="palette-back-link">
          Voir les conditionnements
        </a>
      </header>

      <div className="palette-layout">
        <section className="palette-card palette-form-card">
          <div className="palette-card-heading">
            <span className="palette-step">01</span>
            <div>
              <h2>Nouvelle règle</h2>
              <p>Une seule règle peut être créée par conditionnement d’article.</p>
            </div>
          </div>

          {loading ? (
            <p className="palette-state">Chargement des conditionnements…</p>
          ) : (
            <form onSubmit={handleSubmit} className="palette-form">
              <label>
                <span>Conditionnement d’article</span>
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
                <span>Conditionnements maximum par palette</span>
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

              <div className="palette-capacity-preview" aria-live="polite">
                <span>Capacité calculée</span>
                <strong>{capaciteTotale > 0 ? `${capaciteTotale} pièces` : "—"}</strong>
                <small>
                  {conditionnementSelectionne && quantiteMaximale > 0
                    ? `${quantiteMaximale} × ${conditionnementSelectionne.quantitePieceStandard} pièces`
                    : "Choisissez un conditionnement et une quantité."}
                </small>
              </div>

              {optionsDisponibles.length === 0 && !error && (
                <p className="palette-message palette-message--info">
                  Tous les conditionnements possèdent déjà une règle palette.
                </p>
              )}
              {error && <p className="palette-message palette-message--error" role="alert">{error}</p>}
              {success && <p className="palette-message palette-message--success" role="status">{success}</p>}

              <Button
                type="submit"
                loading={submitting}
                disabled={loading || optionsDisponibles.length === 0}
              >
                Enregistrer la capacité
              </Button>
            </form>
          )}
        </section>

        <section className="palette-card palette-list-card">
          <div className="palette-card-heading">
            <span className="palette-step">02</span>
            <div>
              <h2>Règles configurées</h2>
              <p>{regles.length} capacité{regles.length > 1 ? "s" : ""} enregistrée{regles.length > 1 ? "s" : ""}</p>
            </div>
          </div>

          <div className="palette-rules">
            {!loading && regles.length === 0 ? (
              <p className="palette-state">Aucune capacité palette configurée.</p>
            ) : (
              regles.map((regle) => {
                const conditionnement = trouverConditionnement(regle.articleConditionnementId);
                const total = conditionnement
                  ? conditionnement.quantitePieceStandard * regle.quantiteMaximale
                  : null;
                return (
                  <article className="palette-rule" key={regle.id}>
                    <div>
                      <strong>{conditionnement?.nomArticle || "Article inconnu"}</strong>
                      <span>{conditionnement?.nomConditionnement || `Conditionnement #${regle.articleConditionnementId}`}</span>
                    </div>
                    <div className="palette-rule-values">
                      <strong>{regle.quantiteMaximale}</strong>
                      <span>conditionnements</span>
                      {total && <small>{total} pièces au total</small>}
                    </div>
                  </article>
                );
              })
            )}
          </div>
        </section>
      </div>
    </main>
  );
}

export default CreatePaletteConditionnement;
