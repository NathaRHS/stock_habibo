import { useEffect, useState } from "react";
import Table from "../components/Table";
import { getAccessToken } from "../services/authService";

function ListeUtilisateur() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [societes, setSocietes] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const getAllSocietes = async () => {
      const token = import.meta.env.VITE_TOKEN;

      if (!token) {
        setError("Connectez-vous pour consulter les sociétés.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        const response = await fetch(`${springUrl}/user`, {
          method:"GET",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error(`Impossible de récupérer les sociétés (${response.status})`);
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

  if (loading) return <p>Chargement...</p>;
  if (error) return <p role="alert">{error}</p>;

  return <Table objetsProps={societes} />;
}

export default ListeUtilisateur;
