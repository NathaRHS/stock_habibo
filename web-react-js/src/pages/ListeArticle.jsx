import { useCallback, useEffect, useMemo, useState } from "react";
import { Plus } from "lucide-react";
import Table from "../components/Table";
import Button from "../components/Button";
import CreateArticleModal from "../components/CreateArticleModal";
import VignetteArticle from "../components/VignetteArticle";
import { getAccessToken } from "../services/authService";
import { verifierPhoto } from "../utils/photo";
import Sidebar from "../components/Sidebar";
import "./css/ListeArticle.css";

// Ex. 30 cL, 1,5 L, 350 g. Vide si l'article n'a pas de contenance.
const formaterContenance = (article) =>
  article.contenanceValeur != null && article.nomUnite
    ? `${Number(article.contenanceValeur).toLocaleString("fr-FR", {
        maximumFractionDigits: 3,
      })} ${article.nomUnite}`
    : "";

function ListeArticle() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [articles, setArticles] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [modalOuvert, setModalOuvert] = useState(false);
  // Article de depart quand on ajoute une variante (null = nouvel article).
  const [articleBase, setArticleBase] = useState(null);
  const [erreurPhoto, setErreurPhoto] = useState("");

  const chargerArticles = useCallback(async () => {
    const token = getAccessToken();

    if (!token) {
      setError("Connectez-vous pour consulter les articles.");
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
          `Impossible de récupérer les articles (${response.status})`,
        );
      }

      setArticles(await response.json());
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Impossible de se connecter au serveur.",
      );
    } finally {
      setLoading(false);
    }
  }, [springUrl]);

  useEffect(() => {
    chargerArticles();
  }, [chargerArticles]);

  // Colonnes lisibles pour le tableau (au lieu de tous les champs bruts).
  const lignes = useMemo(
    () =>
      articles.map((article) => ({
        id: article.id,
        photo: article.photoUrl ?? "",
        article: article.nomArticle,
        contenance: formaterContenance(article),
        famille: article.nomFamille,
        codeBarres: article.codeBar,
        typeProduit: article.typeProduit,
        variante: "",
      })),
    [articles],
  );

  const ouvrirNouvelArticle = () => {
    setArticleBase(null);
    setModalOuvert(true);
  };

  const ouvrirVariante = (id) => {
    setArticleBase(articles.find((article) => article.id === id) ?? null);
    setModalOuvert(true);
  };

  // Ajoute ou remplace la photo d'un article existant (PUT /articles/{id}/photo).
  const changerPhoto = async (id, fichier) => {
    const message = verifierPhoto(fichier);
    if (!fichier || message) {
      if (message) setErreurPhoto(message);
      return;
    }

    const token = getAccessToken();
    if (!token) {
      setErreurPhoto("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setErreurPhoto("");
      const formulaire = new FormData();
      formulaire.append("photo", fichier);

      const response = await fetch(`${springUrl}/articles/${id}/photo`, {
        method: "PUT",
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
        body: formulaire,
      });

      if (!response.ok) {
        throw new Error(
          (await response.text()) || `Envoi impossible (${response.status}).`,
        );
      }

      await chargerArticles();
    } catch (erreur) {
      setErreurPhoto(
        erreur instanceof Error ? erreur.message : "Impossible d'enregistrer la photo.",
      );
    }
  };

  const renderCell = (ligne, colonne) => {
    if (colonne === "photo") {
      const article = articles.find((element) => element.id === ligne.id);
      return (
        <label className="vignette-bouton" title="Changer la photo">
          <VignetteArticle photoUrl={article?.photoUrl} nom={ligne.article} />
          <input
            type="file"
            accept="image/jpeg,image/png,image/webp"
            aria-label={`Changer la photo de ${ligne.article}`}
            onChange={(event) => {
              changerPhoto(ligne.id, event.target.files?.[0] ?? null);
              event.target.value = "";
            }}
          />
        </label>
      );
    }

    if (colonne === "variante") {
      return (
        <Button variant="secondary" onClick={() => ouvrirVariante(ligne.id)}>
          Ajouter une variante
        </Button>
      );
    }

    return undefined;
  };

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

          <div className="article-list-toolbar">
            <Button icon={<Plus size={16} />} onClick={ouvrirNouvelArticle}>
              Nouvel article
            </Button>
          </div>

          {erreurPhoto && (
            <div className="article-list-error" role="alert">
              {erreurPhoto}
            </div>
          )}

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
            <Table objetsProps={lignes} title="Articles" renderCell={renderCell} />
          )}
        </main>
      </section>

      <CreateArticleModal
        isOpen={modalOuvert}
        articleBase={articleBase}
        onClose={() => setModalOuvert(false)}
        onCreated={chargerArticles}
      />
    </div>
  );
}

export default ListeArticle;
