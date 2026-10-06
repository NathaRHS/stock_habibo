import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Shapes } from "lucide-react";
import { getAccessToken } from "../services/authService";
import PageLayout from "../components/PageLayout";
import Panel from "../components/Panel";
import CreateArticleConditionnement from "./CreateArticleConditionnement";

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

  return (
    <PageLayout
      breadcrumb="Stock / Conditionnements"
      kicker="Stock"
      title="Conditionnements"
      description="Associez un article à un type de conditionnement et à sa quantité standard."
      actions={
        <Link className="layout-link-button" to="/type-conditionnement">
          <Shapes size={17} />
          Types de conditionnement
        </Link>
      }
    >
      <CreateArticleConditionnement
        onCreated={(nouveau) =>
          setArticlesConditionnements((actuels) => [...actuels, nouveau])
        }
      />

      <Panel
        title="Conditionnements enregistrés"
        subtitle={`${articlesConditionnements.length} au total`}
      >
        {loading ? (
          <p className="layout-table-empty">Chargement…</p>
        ) : error ? (
          <p className="layout-table-empty" role="alert">{error}</p>
        ) : articlesConditionnements.length === 0 ? (
          <p className="layout-table-empty">
            Aucun conditionnement d'article pour l'instant.
          </p>
        ) : (
          <div className="layout-table-scroll">
            <table className="layout-table">
              <thead>
                <tr>
                  <th>Article</th>
                  <th>Type de conditionnement</th>
                  <th>Code-barres</th>
                  <th className="is-number">Pièces par unité</th>
                </tr>
              </thead>
              <tbody>
                {articlesConditionnements.map((conditionnement) => (
                  <tr key={conditionnement.id}>
                    <td><strong>{conditionnement.nomArticle}</strong></td>
                    <td>{conditionnement.nomConditionnement}</td>
                    <td>{conditionnement.codeBarres || "—"}</td>
                    <td className="is-number">
                      {conditionnement.quantitePieceStandard}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </PageLayout>
  );
}

export default ListeArticleConditionnement;
