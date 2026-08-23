import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getAccessToken } from "../services/authService";

function ListeJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journaux, setJournaux] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();
    async function charger() {
      if (!token) { setError("Connectez-vous pour consulter les sessions."); setLoading(false); return; }
      try {
        const response = await fetch(`${springUrl}/journaux-mouvements`, { headers: { Accept: "application/json", Authorization: `Bearer ${token}` }, signal: controller.signal });
        if (!response.ok) throw new Error(`Impossible de récupérer les sessions (${response.status}).`);
        setJournaux(await response.json());
      } catch (erreur) {
        if (erreur.name !== "AbortError") setError(erreur.message || "Chargement impossible.");
      } finally { if (!controller.signal.aborted) setLoading(false); }
    }
    charger();
    return () => controller.abort();
  }, [springUrl, token]);

  if (loading) return <p>Chargement…</p>;
  return <main>
    {error && <p role="alert">{error}</p>}
    <div className="table-section"><table border={1}>
      <thead><tr><th>Référence</th><th>Pièce jointe</th><th>Client</th><th>Fournisseur</th><th>Type</th><th>Statut</th><th>Action</th></tr></thead>
      <tbody>{journaux.map((journal) => <tr key={journal.id}>
        <td>{journal.reference}</td><td>{journal.urlPieceJointe || "—"}</td><td>{journal.nomClient || "—"}</td><td>{journal.fournisseur || "—"}</td><td>{journal.typeMouvementJournal}</td><td>{journal.statut}</td><td><Link to={`/journaux-mouvements/${journal.id}`}>Contrôler</Link></td>
      </tr>)}</tbody>
    </table></div>
  </main>;
}

export default ListeJournal;
