import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";
import Button from "../components/Button";
import Panel from "../components/Panel";

const initialArticleConditionnementState = {
  articleId: "",
  typeConditionnementId: "",
  codeBarres: "",
  quantitePieceStandard: "",
};

function CreateArticleConditionnement({ onCreated }) {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [articleConditionnement, setArticleConditionnement] = useState(
    initialArticleConditionnementState,
  );
  const [articles, setArticles] = useState([]);
  const [typesConditionnement, setTypesConditionnement] = useState([]);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loadingOptions, setLoadingOptions] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const chargerOptions = async () => {
      const token = getAccessToken();

      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        setLoadingOptions(false);
        return;
      }

      try {
        setError("");

        const [articlesResponse, typesConditionnementResponse] =
          await Promise.all([
            fetch(`${springUrl}/articles`, {
              headers: {
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }),
            fetch(`${springUrl}/types-conditionnements`, {
              headers: {
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }),
          ]);

        if (!articlesResponse.ok) {
          throw new Error("Impossible de charger la liste des articles");
        }

        if (!typesConditionnementResponse.ok) {
          throw new Error(
            "Impossible de charger les types de conditionnement",
          );
        }

        const [articlesData, typesConditionnementData] = await Promise.all([
          articlesResponse.json(),
          typesConditionnementResponse.json(),
        ]);

        setArticles(articlesData);
        setTypesConditionnement(typesConditionnementData);
      } catch (erreur) {
        setError(
          erreur instanceof Error
            ? erreur.message
            : "Impossible de charger les options du formulaire.",
        );
      } finally {
        setLoadingOptions(false);
      }
    };

    chargerOptions();
  }, [springUrl]);

  const creerArticleConditionnement = async (objet) => {
    const token = getAccessToken();

    if (!token) {
      throw new Error("Votre session a expiré. Reconnectez-vous.");
    }

    const response = await fetch(`${springUrl}/articles-conditionnements`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(objet),
    });

    if (!response.ok) {
      const message = await response.text();
      throw new Error(
        message || `Création impossible (${response.status})`,
      );
    }

    return response.json();
  };

  const handleChange = (event) => {
    const { name, value } = event.target;

    setArticleConditionnement((conditionnementActuel) => ({
      ...conditionnementActuel,
      [name]: value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    const quantite = Number(articleConditionnement.quantitePieceStandard);

    if (!articleConditionnement.articleId) {
      setError("L'article est obligatoire.");
      return;
    }

    if (!articleConditionnement.typeConditionnementId) {
      setError("Le type de conditionnement est obligatoire.");
      return;
    }

    if (!Number.isInteger(quantite) || quantite <= 0) {
      setError("La quantité standard doit être un entier positif.");
      return;
    }

    try {
      setSubmitting(true);
      setError("");
      setSuccess("");

      const cree = await creerArticleConditionnement({
        articleId: Number(articleConditionnement.articleId),
        typeConditionnementId: Number(
          articleConditionnement.typeConditionnementId,
        ),
        codeBarres: articleConditionnement.codeBarres.trim(),
        quantitePieceStandard: quantite,
      });

      setArticleConditionnement(initialArticleConditionnementState);
      setSuccess("Conditionnement ajouté.");
      onCreated?.({
        nomArticle: articles.find(
          (article) => article.id === Number(articleConditionnement.articleId),
        )?.nomArticle,
        nomConditionnement: typesConditionnement.find(
          (type) =>
            type.id === Number(articleConditionnement.typeConditionnementId),
        )?.nomConditionnement,
        ...cree,
      });
    } catch (erreur) {
      setError(
        erreur instanceof Error
          ? erreur.message
          : "Impossible de créer le conditionnement de l'article.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Panel title="Nouveau conditionnement">
      <form className="layout-form" onSubmit={handleSubmit}>
        {error && (
          <p className="layout-message layout-message--error" role="alert">
            {error}
          </p>
        )}
        {success && (
          <p className="layout-message layout-message--success" role="status">
            {success}
          </p>
        )}

        <div className="layout-form-grid">
          <label>
            Article
            <select
              name="articleId"
              value={articleConditionnement.articleId}
              onChange={handleChange}
              disabled={loadingOptions || submitting}
              required
            >
              <option value="" disabled>
                Choisir un article
              </option>
              {articles.map((article) => (
                <option key={article.id} value={article.id}>
                  {article.nomArticle}
                </option>
              ))}
            </select>
          </label>

          <label>
            Type de conditionnement
            <select
              name="typeConditionnementId"
              value={articleConditionnement.typeConditionnementId}
              onChange={handleChange}
              disabled={loadingOptions || submitting}
              required
            >
              <option value="" disabled>
                Choisir un type
              </option>
              {typesConditionnement.map((type) => (
                <option key={type.id} value={type.id}>
                  {type.nomConditionnement}
                </option>
              ))}
            </select>
          </label>

          <label>
            Code-barres
            <input
              type="text"
              name="codeBarres"
              value={articleConditionnement.codeBarres}
              onChange={handleChange}
              placeholder="Facultatif"
              disabled={submitting}
            />
          </label>

          <label>
            Pièces par unité
            <input
              type="number"
              name="quantitePieceStandard"
              value={articleConditionnement.quantitePieceStandard}
              onChange={handleChange}
              placeholder="Ex. 12"
              min="1"
              step="1"
              disabled={submitting}
              required
            />
          </label>
        </div>

        <div className="layout-form-actions">
          <Button type="submit" loading={submitting} disabled={loadingOptions}>
            Ajouter
          </Button>
        </div>
      </form>
    </Panel>
  );
}

export default CreateArticleConditionnement;
