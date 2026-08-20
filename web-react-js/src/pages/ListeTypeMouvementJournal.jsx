import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";
import CreateTypeMouvementJournal from "./CreateTypeMouvementJournal";

function ListeTypeMouvementJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [typesMouvementJournal, setTypesMouvementJournal] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const chargerTypesMouvementJournal = async () => {
      try {
        setLoading(true);
        setError("");

        const token = getAccessToken();

        if (!token) {
          throw new Error("Votre session a expiré. Reconnectez-vous.");
        }

        const response = await fetch(
          `${springUrl}/types-mouvements-journal`,
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
            "Impossible de charger les types de mouvement journal",
          );
        }

        const data = await response.json();
        setTypesMouvementJournal(data);
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

    chargerTypesMouvementJournal();
  }, [springUrl]);

  if (loading) {
    return <p>Chargement des types de mouvement journal...</p>;
  }

  if (error) {
    return <p role="alert">{error}</p>;
  }

  return (
    <div>
      <table border="1">
        <thead>
          <tr>
            <th>Nom du type de mouvement</th>
            <th>Sens</th>
          </tr>
        </thead>

        <tbody>
          {typesMouvementJournal.length === 0 ? (
            <tr>
              <td colSpan="2">Aucun type de mouvement journal trouvé.</td>
            </tr>
          ) : (
            typesMouvementJournal.map((type) => (
              <tr key={type.id}>
                <td>{type.nomTypeMouvement}</td>
                <td>{type.sens === 1 ? "Entrée (+1)" : "Sortie (-1)"}</td>
              </tr>
            ))
          )}
        </tbody>
      </table>

      <CreateTypeMouvementJournal/>
    </div>
  );
}

export default ListeTypeMouvementJournal;
