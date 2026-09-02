import "../assets/css/Dashboard.css";
import Button from "./Button";

function JournalTable() {
  return (
    <section className="journal-panel" aria-labelledby="journal-title">
      <div>
        <div className="journal-title-line">
          <h2 id="journal-title">Liste des journaux</h2>
          <span>Mouvements récents</span>
        </div>
        <p>Consultez et gérez les derniers mouvements de stock</p>
      </div>
      <div className="journal-actions">
        <Button icon={<span className="material-symbols-outlined" aria-hidden="true">delete</span>} variant="danger">Supprimer</Button>
        <Button icon={<span className="material-symbols-outlined" aria-hidden="true">filter_list</span>} variant="secondary">Filtres</Button>
        <Button icon={<span className="material-symbols-outlined" aria-hidden="true">download</span>} variant="secondary">Exporter</Button>
        <Button icon={<span className="material-symbols-outlined" aria-hidden="true">add</span>}>Ajouter</Button>
      </div>
    </section>
  );
}

export default JournalTable;
