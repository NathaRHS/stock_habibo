import { Download, ListFilter, Plus, Trash2 } from "lucide-react";
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
        <Button icon={<Trash2 size={16} aria-hidden="true" />} variant="danger">Supprimer</Button>
        <Button icon={<ListFilter size={16} aria-hidden="true" />} variant="secondary">Filtres</Button>
        <Button icon={<Download size={16} aria-hidden="true" />} variant="secondary">Exporter</Button>
        <Button icon={<Plus size={16} aria-hidden="true" />}>Ajouter</Button>
      </div>
    </section>
  );
}

export default JournalTable;
