import { useEffect, useRef } from "react";
import styles from "./RackView.module.css";

const LEGENDE = [
  { cle: "free", label: "Libre" },
  { cle: "same", label: "Même article" },
  { cle: "almost", label: "Presque plein" },
  { cle: "blocked", label: "Autre article" },
  { cle: "suggested", label: "Suggestion" },
];

function decrire(emplacement, infos, suggestion) {
  const morceaux = [emplacement.nomEmplacement];
  if (infos.incompatible) morceaux.push(`occupé par ${infos.nomArticle}, non disponible`);
  else if (infos.nomArticle) morceaux.push(infos.nomArticle);
  else morceaux.push("libre");
  if (infos.capacite > 0) morceaux.push(`${infos.placeRestante} places sur ${infos.capacite}`);
  if (infos.planifie > 0) morceaux.push(`${infos.planifie} colis déjà planifiés`);
  if (suggestion) morceaux.push(`suggestion : ${suggestion.quantiteConditionnementsProposee} colis`);
  return morceaux.join(", ");
}

function RackView({
  racks,
  rackSelectionne,
  onRackChange,
  niveaux,
  occupation,
  emplacementSelectionneId,
  onSelect,
  articleSelectionne,
  suggestion,
  lignesExistantes,
  onApplySuggestion,
  onDismissSuggestion,
  onFocusEmplacement,
}) {
  const grilleRef = useRef(null);

  useEffect(() => {
    if (!emplacementSelectionneId) return;
    grilleRef.current
      ?.querySelector(`[data-emplacement="${emplacementSelectionneId}"]`)
      ?.scrollIntoView({ block: "nearest", inline: "nearest", behavior: "smooth" });
  }, [emplacementSelectionneId, rackSelectionne?.id]);

  const aucuneCase = niveaux.every((niveau) => niveau.cases.length === 0);

  return (
    <section className={styles.panel} aria-labelledby="rack-titre">
      <header className={styles.head}>
        <div>
          <h2 id="rack-titre">{rackSelectionne?.name ?? "Entrepôt"}</h2>
          <p>
            Occupation <strong>{occupation} %</strong>
          </p>
        </div>
        {racks.length > 1 && (
          <div className={styles.tabs} role="group" aria-label="Choisir un rack">
            {racks.map((rack) => (
              <button
                aria-pressed={rack.id === rackSelectionne?.id}
                key={rack.id}
                onClick={() => onRackChange(rack)}
                type="button"
              >
                {rack.name}
              </button>
            ))}
          </div>
        )}
      </header>

      {suggestion && (
        <div className={styles.suggestion} role="status">
          <div className={styles.suggestionHead}>
            <span className="material-symbols-outlined" aria-hidden="true">auto_awesome</span>
            <div>
              <strong>
                {suggestion.suggestions?.length
                  ? `${suggestion.suggestions.length} emplacement${suggestion.suggestions.length > 1 ? "s" : ""} proposé${suggestion.suggestions.length > 1 ? "s" : ""}`
                  : "Aucun emplacement disponible"}
              </strong>
              <p>
                pour {articleSelectionne?.nomArticle}
                {lignesExistantes > 0 &&
                  " · remplacera les lignes déjà planifiées pour cet article"}
              </p>
            </div>
          </div>

          {suggestion.suggestions?.length > 0 && (
            <div className={styles.chips}>
              {suggestion.suggestions.map((element) => (
                <button
                  aria-pressed={element.emplacementId === emplacementSelectionneId}
                  key={element.emplacementId}
                  onClick={() => onFocusEmplacement(element.emplacementId)}
                  type="button"
                >
                  {element.nomEmplacement}
                  <span>{element.quantiteConditionnementsProposee}</span>
                </button>
              ))}
            </div>
          )}

          {suggestion.suggestions?.[0]?.raisons?.length > 0 && (
            <details className={styles.reasons}>
              <summary>Pourquoi ces emplacements ?</summary>
              <ul>
                {suggestion.suggestions[0].raisons.map((raison) => (
                  <li key={raison}>{raison}</li>
                ))}
              </ul>
            </details>
          )}

          <div className={styles.suggestionActions}>
            <button className={styles.ghost} onClick={onDismissSuggestion} type="button">
              Ignorer
            </button>
            <button
              className={styles.apply}
              disabled={!suggestion.suggestions?.length}
              onClick={onApplySuggestion}
              type="button"
            >
              Appliquer au plan
            </button>
          </div>
        </div>
      )}

      <ul className={styles.legend} aria-label="Légende">
        {LEGENDE.map((element) => (
          <li key={element.cle}>
            <i className={`${styles.swatch} ${styles[element.cle]}`} aria-hidden="true" />
            {element.label}
          </li>
        ))}
      </ul>

      {!articleSelectionne && (
        <p className={styles.hint}>
          Choisissez d’abord un article : les cases compatibles s’allumeront.
        </p>
      )}

      {aucuneCase ? (
        <p className={styles.empty}>Aucun emplacement dans ce rack.</p>
      ) : (
        /*Là l'objet niveaux contenant le niveau et la liste des emplacements
        est très important
        */
        <div className={styles.grid} ref={grilleRef}>
          {niveaux.map(({ niveau, cases }) => (
            <div className={styles.row} key={niveau}>
              <span className={styles.level}>N{niveau}</span>
              <div className={styles.cells}>

                {/* liste des emplacements */}
                
                {cases.map(({ emplacement, infos, suggestion: suggestionCase }) => {
                  const selectionne = emplacement.id === emplacementSelectionneId;
                  const presquePlein = infos.tauxOccupation >= 75 && infos.placeRestante > 0;
                  const plein = infos.capacite > 0 && infos.placeRestante === 0;
                  const classes = [
                    styles.cell,
                    infos.incompatible ? styles.blocked : "",
                    infos.memeArticle ? styles.same : "",
                    presquePlein ? styles.almost : "",
                    suggestionCase ? styles.suggested : "",
                    selectionne ? styles.active : "",
                  ].join(" ");
                  const libelle = decrire(emplacement, infos, suggestionCase);

                  return (
                    <button
                      aria-label={libelle}
                      aria-pressed={selectionne}
                      className={classes}
                      data-emplacement={emplacement.id}
                      disabled={infos.incompatible}
                      key={emplacement.id}
                      onClick={() => onSelect(emplacement)}
                      title={libelle}
                      type="button"
                    >
                      <span className={styles.code}>{emplacement.nomEmplacement}</span>

                      {suggestionCase && (
                        <span className={styles.badge}>
                          {suggestionCase.quantiteConditionnementsProposee}
                        </span>
                      )}

                      <span className={styles.content}>
                        {infos.incompatible ? (
                          <span className="material-symbols-outlined" aria-hidden="true">lock</span>
                        ) : infos.nomArticle ? (
                          <span className={styles.article}>{infos.nomArticle}</span>
                        ) : (
                          <span className={styles.plus} aria-hidden="true" />
                        )}
                      </span>

                      <span className={styles.foot}>
                        {infos.planifie > 0 && (
                          <span className={styles.planned}>+{infos.planifie}</span>
                        )}
                        <span className={styles.meter} aria-hidden="true">
                          <span
                            className={plein ? styles.meterFull : undefined}
                            style={{ width: `${infos.tauxOccupation}%` }}
                          />
                        </span>
                      </span>
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

export default RackView;
