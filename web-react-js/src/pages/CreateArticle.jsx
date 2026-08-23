import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

const initialArticleState = {
  nomArticle: "",
  codeBar: "",
  typeProduitId: "",
  typeConditionnementId: "",
};

function CreateArticle() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [typeArticle, setTypeArticle] = useState([]);
  const [typeConditionnement, setTypeConditionnement] = useState([]);
  const [article, setArticle] = useState(initialArticleState);
  const [error, setError] = useState("");
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

        const [produitsResponse, conditionnementsResponse] =
          await Promise.all([
            fetch(`${springUrl}/types-produits`, {
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

        if (!produitsResponse.ok) {
          throw new Error(
            `Impossible de récupérer les types de produits (${produitsResponse.status})`,
          );
        }

        if (!conditionnementsResponse.ok) {
          throw new Error(
            `Impossible de récupérer les conditionnements (${conditionnementsResponse.status})`,
          );
        }

        const [produits, conditionnements] = await Promise.all([
          produitsResponse.json(),
          conditionnementsResponse.json(),
        ]);

        setTypeArticle(produits);
        setTypeConditionnement(conditionnements);
      } catch (requestError) {
        setError(
          requestError instanceof Error
            ? requestError.message
            : "Impossible de charger les options du formulaire.",
        );
      } finally {
        setLoadingOptions(false);
      }
    };

    chargerOptions();
  }, [springUrl]);

  const handleChange = (event) => {
    const { name, value } = event.target;
    const estUnIdentifiant =
      name === "typeProduitId" || name === "typeConditionnementId";

    setArticle((articleActuel) => ({
      ...articleActuel,
      [name]: estUnIdentifiant && value !== "" ? Number(value) : value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const token = getAccessToken();

    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setError("");
      setSubmitting(true);

      const response = await fetch(`${springUrl}/articles`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(article),
      });

      if (!response.ok) {
        const message = await response.text();
        throw new Error(
          message || `Création impossible (${response.status})`,
        );
      }

      setArticle(initialArticleState);
      alert("Article créé avec succès !");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Impossible de créer l'article.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="container-create-article">
      {error && <p role="alert">{error}</p>}

      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="nomArticle"
          value={article.nomArticle}
          onChange={handleChange}
          placeholder="Nom de l'article"
          required
        />

        <input
          type="text"
          name="codeBar"
          value={article.codeBar}
          onChange={handleChange}
          placeholder="Code-barres"
          required
        />

        <select
          name="typeProduitId"
          value={article.typeProduitId}
          onChange={handleChange}
          disabled={loadingOptions}
          required
        >
          <option value="" disabled>
            Choisissez le type de produit
          </option>
          {typeArticle.map((type) => (
            <option key={type.id} value={type.id}>
              {type.nomType}
            </option>
          ))}
        </select>

        <select
          name="typeConditionnementId"
          value={article.typeConditionnementId}
          onChange={handleChange}
          disabled={loadingOptions}
          required
        >
          <option value="" disabled>
            Choisissez le conditionnement
          </option>
          {typeConditionnement.map((type) => (
            <option key={type.id} value={type.id}>
              {type.nomConditionnement}
            </option>
          ))}
        </select>

        <button type="submit" disabled={loadingOptions || submitting}>
          {submitting ? "Création..." : "Créer l'article"}
        </button>
      </form>
    </div>
  );
}

export default CreateArticle;
