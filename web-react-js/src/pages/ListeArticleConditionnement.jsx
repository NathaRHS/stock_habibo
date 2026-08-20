import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

function ListeArticleConditionnement() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [articlesConditionnements, setArticlesConditionnements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const chargerArticlesConditionnements = async () => {
      try {
        setLoading(true);
        setError("");

        const token = getAccessToken();

        if (!token) {
          throw new Error("Votre session a expiré. Reconnectez-vous.");
        }

        const response = await fetch(
          `${springUrl}/articles-conditionnements`,
          {
            method: "GET",
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
          },
        );

        if (!response.ok) {
          throw new Error(
            "Impossible de charger la liste des conditionnements d'articles",
          );
        }

        const data = await response.json();
        setArticlesConditionnements(data);
      } catch (erreur) {
        setError(
          erreur instanceof Error
            ? erreur.message
            : "Impossible de se connecter au serveur.",
        );
      } finally {
        setLoading(false);
      }
    };

    chargerArticlesConditionnements();
  }, [springUrl]);

  if (loading) {
    return <p>Chargement des conditionnements d'articles...</p>;
  }

  if (error) {
    return <p role="alert">{error}</p>;
  }

  return (
    <div>
      <table border="1">
        <thead>
          <tr>
            <th>Article</th>
            <th>Type de conditionnement</th>
            <th>Code-barres</th>
            <th>Quantité standard</th>
          </tr>
        </thead>

        <tbody>
          {articlesConditionnements.length === 0 ? (
            <tr>
              <td colSpan="4">
                Aucun conditionnement d'article trouvé.
              </td>
            </tr>
          ) : (
            articlesConditionnements.map((conditionnement) => (
              <tr key={conditionnement.id}>
                <td>{conditionnement.nomArticle}</td>
                <td>{conditionnement.nomConditionnement}</td>
                <td>{conditionnement.codeBarres || "—"}</td>
                <td>{conditionnement.quantitePieceStandard}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

export default ListeArticleConditionnement;
