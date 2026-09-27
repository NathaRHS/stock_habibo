import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getAccessToken } from "../services/authService";
import PageLayout from "../components/PageLayout";
import Panel from "../components/Panel";
import CreateTypeConditionnement from "./CreateTypeConditionnement";

function ListeTypeConditionnement() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [typesConditionnement, setTypesConditionnement] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const chargerTypesConditionnement = async () => {
      try {
        setLoading(true);
        setError("");

        const token = getAccessToken();

        const response = await fetch(`${springUrl}/types-conditionnements`, {
          method: "GET",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error(
            "Impossible de charger la liste des types de conditionnement",
          );
        }

        const data = await response.json();
        setTypesConditionnement(data);
      } catch (erreur) {
        setError(erreur.message);
      } finally {
        setLoading(false);
      }
    };

    chargerTypesConditionnement();
  }, [springUrl]);

  return (
    <PageLayout
      breadcrumb="Stock / Conditionnements / Types"
      kicker="Stock"
      title="Types de conditionnement"
      description="Les formats disponibles pour conditionner un article."
      actions={
        <Link className="layout-link-button" to="/article-conditionnements">
          <span className="material-symbols-outlined">arrow_back</span>
          Conditionnements
        </Link>
      }
    >
      <CreateTypeConditionnement
        onCreated={(nouveau) =>
          setTypesConditionnement((actuels) => [...actuels, nouveau])
        }
      />

      <Panel
        title="Types enregistrés"
        subtitle={`${typesConditionnement.length} au total`}
      >
        {loading ? (
          <p className="layout-table-empty">Chargement…</p>
        ) : error ? (
          <p className="layout-table-empty" role="alert">{error}</p>
        ) : typesConditionnement.length === 0 ? (
          <p className="layout-table-empty">
            Aucun type de conditionnement pour l'instant.
          </p>
        ) : (
          <table className="layout-table">
            <thead>
              <tr>
                <th>Nom</th>
              </tr>
            </thead>
            <tbody>
              {typesConditionnement.map((type) => (
                <tr key={type.id}>
                  <td><strong>{type.nomConditionnement}</strong></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Panel>
    </PageLayout>
  );
}

export default ListeTypeConditionnement;
