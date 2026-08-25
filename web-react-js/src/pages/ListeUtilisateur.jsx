import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import Table from "../components/Table";
import { getAccessToken } from "../services/authService";
import "./css/CreateUtilisateur.css";

function ListeUtilisateur() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const location = useLocation();
  const [utilisateurs, setUtilisateurs] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();

    async function chargerUtilisateurs() {
      const token = getAccessToken();
      if (!token) {
        setError("Connectez-vous pour consulter les utilisateurs.");
        setLoading(false);
        return;
      }
      try {
        const response = await fetch(`${springUrl}/user`, {
          headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error(`Impossible de récupérer les utilisateurs (${response.status}).`);
        }
        const data = await response.json();
        setUtilisateurs(Array.isArray(data) ? data : []);
      } catch (requestError) {
        if (requestError.name !== "AbortError") {
          setError(requestError.message || "Impossible de joindre le serveur.");
        }
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }

    chargerUtilisateurs();
    return () => controller.abort();
  }, [springUrl]);

  if (loading) return <p>Chargement des utilisateurs…</p>;

  return (
    <main className="users-page">
      <header className="users-header">
        <div>
          <h1>Utilisateurs</h1>
          <p>Gérez les comptes et leurs rôles.</p>
        </div>
        <Link className="users-create-link" to="/users/create">Créer un compte</Link>
      </header>
      {location.state?.success && <p className="users-success" role="status">{location.state.success}</p>}
      {error ? <p role="alert">{error}</p> : <Table objetsProps={utilisateurs} title="Utilisateurs" />}
    </main>
  );
}

export default ListeUtilisateur;
