import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { getAccessToken } from "../services/authService";

function CreateCommande() {
  const [articles, setArticles] = useState([]);
  const [articleSelectionneId, setArticleSelectionnes] = useState(1);
  const [quantite, setQuantite] = useState(0);
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const { id } = useParams();
  const token = getAccessToken();

  const [listeProvisoire, setListeProvisoire] = useState([]);

  const supprimerProvisoire = (id) => {
    setListeProvisoire((prev) => prev.filter((pr) => pr.idArticle !== id));
  };
  useEffect(() => {
    const chargerArticles = async () => {
      const reponse = await fetch(`${springUrl}/articles`, {
        headers: {
          accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      });
      if (!reponse.ok) {
        throw new Error("erreur lors de la recuperation des articles");
      }

      const data = await reponse.json();
      setArticles(data);
    };
    chargerArticles();
  }, []);

  const insererTout = async () => {
    const reponse = await fetch(
      `${springUrl}/commande/insertAllCommande/${id}`,
      {
        method:"POST",
        headers: {
          accept: "application/json",
          "Content-type":"application/json",
          Authorization: `Bearer ${token}`,
        },
        body:JSON.stringify(listeProvisoire) ,
      },
    );

    if (!reponse.ok) {
      throw new Error("erreur lors de la recuperation des articles");
    }
  };
  const insertAll = () => {
    insererTout();
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log("a");
    const donnees = {
      idArticle: Number(articleSelectionneId),
      quantiteDemande: Number(quantite),
    };

    setListeProvisoire((prev) => [...prev, donnees]);
  };
  return (
    <>
      {listeProvisoire?.map((lp) => (
        <div>
          <h1>{lp.idArticle}</h1>

          <p>{lp.quantiteDemande}</p>
          <button onClick={() => supprimerProvisoire(lp.idArticle)}>
            supprimer
          </button>
        </div>
      ))}
      <button onClick={insertAll}>Inserer tout</button>
      {articleSelectionneId}
      <div className="container">
        <form action="" onSubmit={(e) => handleSubmit(e)}>
          <select
            name=""
            id=""
            onChange={(e) => setArticleSelectionnes(e.target.value)}
          >
            <option value="" disabled>
              Veuillez sélectionner l'article{" "}
            </option>
            {articles?.map((article) => {
              return <option value={article.id}>{article.nomArticle}</option>;
            })}
          </select>
          <input
            type="number"
            name=""
            value={quantite}
            onChange={(e) => setQuantite(e.target.value)}
            id=""
            placeholder="Quantité demandée"
          />

          <button type="submit">Ajouter provisoirement</button>
        </form>
      </div>
    </>
  );
}

export default CreateCommande;
