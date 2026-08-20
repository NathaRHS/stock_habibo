import "../assets/css/Dashboard.css";

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
        <button type="button"><span className="material-symbols-outlined" aria-hidden="true">delete</span><span>Supprimer</span></button>
        <button type="button"><span className="material-symbols-outlined" aria-hidden="true">filter_list</span><span>Filtres</span></button>
        <button className="export-button" type="button"><span className="material-symbols-outlined" aria-hidden="true">download</span><span>Exporter</span></button>
        <button className="primary-button" type="button"><span className="material-symbols-outlined" aria-hidden="true">add</span>Ajouter</button>
      </div>
    </section>
  );
}

export default JournalTable;
