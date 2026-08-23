import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";
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

  if (loading) {
    return <p>Chargement des types de conditionnement...</p>;
  }

  if (error) {
    return <p role="alert">{error}</p>;
  }

  return (
    <div>
      <CreateTypeConditionnement />
      <table border="1">
        <thead>
          <tr>
            <th>Nom du type de conditionnement</th>
          </tr>
        </thead>

        <tbody>
          {typesConditionnement.length === 0 ? (
            <tr>
              <td>Aucun type de conditionnement trouvé.</td>
            </tr>
          ) : (
            typesConditionnement.map((type) => (
              <tr key={type.id}>
                <td>{type.nomConditionnement}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

export default ListeTypeConditionnement;
