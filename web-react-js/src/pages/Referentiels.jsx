import { useEffect, useState } from "react";
import PageLayout from "../components/PageLayout";
import Button from "../components/Button";
import { requeteJson } from "../services/affectationStockService";
import "./css/Referentiels.css";

const springUrl = import.meta.env.VITE_SPRING_URL;

// Un bloc = une liste + un champ pour ajouter un élément.
// `champ` est le nom du champ envoyé au serveur ET lu dans la réponse.
function BlocReferentiel({ titre, route, champ, exemple }) {
  const [elements, setElements] = useState([]);
  const [nom, setNom] = useState("");
  const [erreur, setErreur] = useState("");
  const [enCours, setEnCours] = useState(false);

  // `version` change après chaque ajout : cela relance le chargement de la liste.
  const [version, setVersion] = useState(0);

  useEffect(() => {
    requeteJson(`${springUrl}/${route}`)
      .then(setElements)
      .catch((e) => setErreur(e.message));
  }, [route, version]);

  async function ajouter(event) {
    event.preventDefault();
    if (!nom.trim()) {
      setErreur("Le nom est obligatoire.");
      return;
    }
    setEnCours(true);
    setErreur("");
    try {
      await requeteJson(`${springUrl}/${route}`, {
        method: "POST",
        body: JSON.stringify({ [champ]: nom.trim() }),
      });
      setNom("");
      setVersion(version + 1);
    } catch (e) {
      setErreur(e.message);
    } finally {
      setEnCours(false);
    }
  }

  return (
    <section className="layout-panel">
      <header className="layout-panel-header">
        <div>
          <h2>{titre}</h2>
          <p>
            {elements.length} élément{elements.length > 1 ? "s" : ""}
          </p>
        </div>
      </header>

      <form className="layout-form referentiel-form" onSubmit={ajouter}>
        <input
          value={nom}
          onChange={(e) => setNom(e.target.value)}
          placeholder={exemple}
          disabled={enCours}
        />
        <Button type="submit" loading={enCours}>
          Ajouter
        </Button>
      </form>

      {erreur && (
        <p className="layout-message layout-message--error referentiel-message" role="alert">
          {erreur}
        </p>
      )}

      {elements.length === 0 ? (
        <p className="referentiel-vide">Aucun élément pour le moment.</p>
      ) : (
        <ul className="referentiel-liste">
          {elements.map((element) => (
            <li key={element.id}>{element[champ]}</li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Referentiels() {
  return (
    <PageLayout
      breadcrumb="Administration / Référentiels"
      kicker="Administration"
      title="Référentiels"
      description="Les listes utilisées pour décrire les articles et les journaux."
    >
      <div className="referentiels-grille">
        <BlocReferentiel titre="Unités" route="unites" champ="nomUnite" exemple="Ex. : cl, kg, pièce" />
        <BlocReferentiel titre="Types de produit" route="types-produits" champ="nomType" exemple="Ex. : Boisson" />
        <BlocReferentiel titre="Familles" route="familles" champ="nom" exemple="Ex. : Coca-Cola" />
        <BlocReferentiel titre="Sociétés" route="societes" champ="nomSociete" exemple="Ex. : Fournisseur Alpha" />
      </div>
    </PageLayout>
  );
}

export default Referentiels;
