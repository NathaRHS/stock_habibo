import { useEffect, useState } from "react";
import Table from "../components/Table";
import { getAccessToken } from "../services/authService";
import CreateArticle from "./CreateArticle";
import Sidebar from "../components/Sidebar";
import "./css/ListeArticle.css";

function ListeArticle() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [societes, setSocietes] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const getAllSocietes = async () => {
      const token = getAccessToken();

      if (!token) {
        setError("Connectez-vous pour consulter les sociétés.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        const response = await fetch(`${springUrl}/articles`, {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error(
            `Impossible de récupérer les sociétés (${response.status})`,
          );
        }

        const data = await response.json();
        setSocietes(data);
      } catch (requestError) {
        setError(
          requestError instanceof Error
            ? requestError.message
            : "Impossible de se connecter au serveur.",
        );
      } finally {
        setLoading(false);
      }
    };

    getAllSocietes();
  }, [springUrl]);

  return (
    <div className="article-page-shell">
      <Sidebar />
      <section className="article-page-workspace">
        <header className="article-page-topbar">
          <p>Stock / Articles</p>
          <div className="article-page-user">
            <span>AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="article-page-content">
          <header className="article-list-heading">
            <span className="article-list-kicker">Catalogue</span>
            <h1>Articles</h1>
            <p>Créez et consultez les articles référencés dans le stock.</p>
          </header>

          <CreateArticle />

          {loading ? (
            <div className="article-list-card">
              <div className="article-list-loading">
                Chargement des articles…
              </div>
            </div>
          ) : error ? (
            <div className="article-list-error" role="alert">
              {error}
            </div>
          ) : (
            <Table objetsProps={societes} title="Articles" />
          )}
        </main>
      </section>
    </div>
  );
}

export default ListeArticle;
