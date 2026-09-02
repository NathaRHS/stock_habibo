import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { getAccessToken } from "../services/authService";
import "./css/ListeJournal.css";

const FILTRES = ["TOUS", "EN COURS", "EN ATTENTE", "VALIDE", "MODIFIE"];
const normaliser = (valeur) => String(valeur ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[_-]+/g, " ").trim().toUpperCase();

function ListeJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [journaux, setJournaux] = useState([]);
  const [recherche, setRecherche] = useState("");
  const [filtre, setFiltre] = useState("TOUS");
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

  const journauxFiltres = useMemo(() => {
    const texte = normaliser(recherche);
    return journaux.filter((journal) => {
      const statutOk = filtre === "TOUS" || normaliser(journal.statut) === filtre;
      const contenu = normaliser([journal.reference, journal.nomClient, journal.fournisseur, journal.typeMouvementJournal, journal.statut].join(" "));
      return statutOk && (!texte || contenu.includes(texte));
    });
  }, [filtre, journaux, recherche]);

  if (loading) return <div className="journal-list-loading">Chargement des journaux…</div>;

  return (
    <main className="journal-list-page">
      <header className="journal-list-heading">
        <div>
          <span className="journal-list-kicker">Opérations de stock</span>
          <h1>Journaux de mouvements</h1>
          <p>Consultez, contrôlez et poursuivez les sessions de l’entrepôt.</p>
        </div>
        <Link className="journal-create-link" to="/journaux-mouvements/create">
          <span className="material-symbols-outlined">add</span>Nouveau journal
        </Link>
      </header>

      {error && <div className="journal-list-error" role="alert">{error}</div>}

      <section className="journal-list-card">
        <div className="journal-list-toolbar">
          <nav className="journal-filter-tabs" aria-label="Filtrer par statut">
            {FILTRES.map((statut) => (
              <button className={filtre === statut ? "is-active" : ""} key={statut} onClick={() => setFiltre(statut)} type="button">
                {statut === "TOUS" ? "Tous" : statut}
              </button>
            ))}
          </nav>
          <label className="journal-search">
            <span className="material-symbols-outlined">search</span>
            <span className="journal-sr-only">Rechercher un journal</span>
            <input onChange={(event) => setRecherche(event.target.value)} placeholder="Référence, client, fournisseur…" type="search" value={recherche} />
          </label>
        </div>

        <div className="journal-table-scroll">
          <table className="journal-table">
            <thead><tr><th>Référence</th><th>Partenaire</th><th>Type de flux</th><th>Document</th><th>Statut</th><th className="journal-action-cell">Action</th></tr></thead>
            <tbody>{journauxFiltres.map((journal) => <JournalRow journal={journal} key={journal.id} />)}</tbody>
          </table>
        </div>

        {!journauxFiltres.length && <div className="journal-list-empty"><span className="material-symbols-outlined">inventory_2</span><strong>Aucun journal trouvé</strong><p>Modifiez la recherche ou choisissez un autre statut.</p></div>}
        <footer className="journal-list-footer"><span>{journauxFiltres.length} affiché{journauxFiltres.length > 1 ? "s" : ""}</span><span>{journaux.length} au total</span></footer>
      </section>
    </main>
  );
}

function JournalRow({ journal }) {
  const statut = normaliser(journal.statut);
  const tonalite = statut.includes("VALIDE") ? "success" : statut.includes("MODIFIE") ? "danger" : statut.includes("ATTENTE") ? "warning" : "progress";
  const documentNom = String(journal.urlPieceJointe ?? "").replaceAll("\\", "/").split("/").filter(Boolean).at(-1);
  const partenaire = journal.fournisseur || journal.nomClient || "Non renseigné";
  const sortie = normaliser(journal.typeMouvementJournal).includes("SORTIE");

  return (
    <tr>
      <td><div className="journal-reference-cell"><span className="journal-reference-icon material-symbols-outlined">receipt_long</span><div><strong>{journal.reference}</strong><small>Session #{journal.id}</small></div></div></td>
      <td><div className="journal-partner-cell"><span className="journal-partner-avatar">{partenaire.charAt(0).toUpperCase()}</span><div><strong>{partenaire}</strong><small>{journal.fournisseur ? "Fournisseur" : "Client"}</small></div></div></td>
      <td><span className="journal-flow"><span className="material-symbols-outlined">{sortie ? "north_east" : "south_west"}</span>{journal.typeMouvementJournal || "Non renseigné"}</span></td>
      <td><span className="journal-document" title={documentNom || "Aucun document"}><span className="material-symbols-outlined">description</span>{documentNom || "Aucun document"}</span></td>
      <td><span className={`journal-status journal-status-${tonalite}`}><i />{journal.statut}</span></td>
      <td className="journal-action-cell"><Link className="journal-open-link" to={`/journaux-mouvements/${journal.id}`}><span>Contrôler</span><span className="material-symbols-outlined">arrow_forward</span></Link></td>
    </tr>
  );
}

export default ListeJournal;
