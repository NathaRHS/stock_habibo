import styles from "./NewRackView.module.css";

// Grille d'un rack : en-tête avec onglets, une ligne par étage, une case par emplacement.
// Le contenu des cases est fourni par la page via renderCase.
function NewRackview({
  racks = [],
  rackSelectionne,
  onRackChange,
  niveaux = [],
  occupation,
  emplacementSelectionneId,
  onSelect,
  renderCase,
}) {
  const aucuneCase = niveaux.every((niveau) => niveau.cases.length === 0);

  return (
    <section className={styles.panel} aria-labelledby="rack-titre">
      <header className={styles.head}>
        <div>
          <h2 id="rack-titre">{rackSelectionne?.name ?? "Entrepôt"}</h2>
          {occupation !== undefined && (
            <p>
              Occupation <strong>{occupation} %</strong>
            </p>
          )}
        </div>

        {racks.length > 1 && (
          <div className={styles.tabs} role="group" aria-label="Choisir un rack">
            {racks.map((rack) => (
              <button
                aria-pressed={rack.id === rackSelectionne?.id}
                key={rack.id}
                onClick={() => onRackChange?.(rack)}
                type="button"
              >
                {rack.name}
              </button>
            ))}
          </div>
        )}
      </header>

      {aucuneCase ? (
        <p className={styles.empty}>Aucun emplacement dans ce rack.</p>
      ) : (
        <div className={styles.grid}>
          {niveaux.map(({ niveau, cases }) => (
            <div className={styles.row} key={niveau}>
              <span className={styles.level}>N{niveau}</span>
              <div className={styles.cells}>
                {cases.map((element) => {
                  const { emplacement } = element;
                  const selectionne = emplacement.id === emplacementSelectionneId;
                  return (
                    <button
                      aria-pressed={selectionne}
                      className={`${styles.cell} ${selectionne ? styles.active : ""}`}
                      key={emplacement.id}
                      onClick={() => onSelect?.(emplacement)}
                      title={emplacement.nomEmplacement}
                      type="button"
                    >
                      {renderCase ? renderCase(element) : emplacement.nomEmplacement}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

export default NewRackview;
