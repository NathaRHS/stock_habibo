import QuantitySlider from "./QuantitySlider";
import styles from "./AssignmentPanel.module.css";

function Etape({ numero, fait, titre, children }) {
  return (
    <section className={styles.step}>
      <span className={`${styles.stepIndex} ${fait ? styles.stepDone : ""}`} aria-hidden="true">
        {fait ? <span className="material-symbols-outlined">check</span> : numero}
      </span>
      <div className={styles.stepBody}>
        <h3>{titre}</h3>
        {children}
      </div>
    </section>
  );
}

function raisonBlocage({ article, resteArticle, emplacement, infosEmplacement }) {
  if (!article) return "Choisissez un article dans la liste.";
  if (resteArticle === 0) return "Cet article est entièrement placé.";
  if (!emplacement) return "Cliquez sur une case du rack.";
  if (infosEmplacement?.capacite === 0) return "Aucune capacité palette définie pour cet article.";
  if (infosEmplacement?.placeRestante === 0) return "Cet emplacement est plein.";
  return null;
}

function AssignmentPanel({
  article,
  resteArticle,
  emplacement,
  nomRack,
  infosEmplacement,
  quantite,
  quantiteMax,
  onQuantiteChange,
  onAjouter,
  articleSuivant,
  onArticleSuivant,
  lignesPlan,
  onRetirer,
  resteTotal,
  planComplet,
  envoiEnCours,
  onValider,
}) {
  const blocage = raisonBlocage({ article, resteArticle, emplacement, infosEmplacement });

  return (
    <aside className={styles.panel} aria-labelledby="affectation-titre">
      <header className={styles.head}>
        <h2 id="affectation-titre">Affectation</h2>
      </header>

      <div className={styles.steps}>
        <Etape numero={1} fait={Boolean(article)} titre="Article">
          {article ? (
            <p className={styles.value}>
              <strong>{article.nomArticle}</strong>
              <span>{resteArticle} colis restants</span>
            </p>
          ) : (
            <p className={styles.placeholder}>Aucun article sélectionné</p>
          )}
        </Etape>

        <Etape numero={2} fait={Boolean(emplacement)} titre="Emplacement">
          {emplacement && infosEmplacement ? (
            <>
              <p className={styles.value}>
                <strong>{emplacement.nomEmplacement}</strong>
                <span>{nomRack}</span>
              </p>
              <div className={styles.capacity}>
                <div className={styles.capacityBar}>
                  <span style={{ width: `${infosEmplacement.tauxOccupation}%` }} />
                </div>
                <dl>
                  <div>
                    <dt>Occupé</dt>
                    <dd>{Math.round(infosEmplacement.occupe)}</dd>
                  </div>
                  <div>
                    <dt>Capacité</dt>
                    <dd>{infosEmplacement.capacite}</dd>
                  </div>
                  <div>
                    <dt>Disponible</dt>
                    <dd className={styles.available}>{infosEmplacement.placeRestante}</dd>
                  </div>
                </dl>
              </div>
            </>
          ) : (
            <p className={styles.placeholder}>Aucune case sélectionnée</p>
          )}
        </Etape>

        <Etape numero={3} fait={false} titre="Quantité">
          <form
            className={styles.form}
            onSubmit={(event) => {
              event.preventDefault();
              onAjouter();
            }}
          >
            <QuantitySlider
              disabled={Boolean(blocage)}
              label="Colis à placer"
              max={quantiteMax}
              onChange={onQuantiteChange}
              valeur={quantite}
            />
            {blocage && <p className={styles.blocked}>{blocage}</p>}
            <button className={styles.primary} disabled={Boolean(blocage)} type="submit">
              <span className="material-symbols-outlined" aria-hidden="true">add</span>
              {emplacement && !blocage
                ? `Ajouter à ${emplacement.nomEmplacement}`
                : "Ajouter au plan"}
            </button>
          </form>

          {article && resteArticle === 0 && articleSuivant && (
            <button className={styles.next} onClick={onArticleSuivant} type="button">
              Article suivant : {articleSuivant.nomArticle}
              <span className="material-symbols-outlined" aria-hidden="true">arrow_forward</span>
            </button>
          )}
        </Etape>
      </div>

      <section className={styles.plan} aria-labelledby="plan-titre">
        <header>
          <h3 id="plan-titre">Plan d’affectation</h3>
          <span>
            {lignesPlan.length} ligne{lignesPlan.length > 1 ? "s" : ""}
          </span>
        </header>
        {lignesPlan.length === 0 ? (
          <p className={styles.placeholder}>Les affectations ajoutées apparaîtront ici.</p>
        ) : (
          <ul>
            {lignesPlan.map((ligne) => (
              <li key={ligne.id}>
                <div>
                  <strong>{ligne.nomArticle}</strong>
                  <span>
                    {ligne.nomEmplacement}
                    {ligne.nomRack ? ` · ${ligne.nomRack}` : ""}
                  </span>
                </div>
                <b>
                  {ligne.nombre} <small>{ligne.nomConditionnement}</small>
                </b>
                <button
                  aria-label={`Retirer ${ligne.nomArticle} de ${ligne.nomEmplacement}`}
                  onClick={() => onRetirer(ligne.id)}
                  type="button"
                >
                  <span className="material-symbols-outlined" aria-hidden="true">close</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <footer className={styles.footer}>
        <button
          className={styles.validate}
          disabled={!planComplet || envoiEnCours}
          onClick={onValider}
          type="button"
        >
          {envoiEnCours ? "Validation en cours…" : "Valider l’entrée en stock"}
        </button>
        <p className={planComplet ? styles.ready : undefined}>
          {planComplet
            ? "Tous les colis sont placés. Les capacités seront revérifiées à l’envoi."
            : `Encore ${resteTotal} colis à placer avant de valider.`}
        </p>
      </footer>
    </aside>
  );
}

export default AssignmentPanel;
