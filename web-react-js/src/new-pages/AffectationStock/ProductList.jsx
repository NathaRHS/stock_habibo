import { Check, Sparkles } from "lucide-react";
import styles from "./ProductList.module.css";

const initiales = (nom) =>
  String(nom ?? "")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((mot) => mot[0])
    .join("")
    .toUpperCase() || "?";

function ProductList({
  articles,
  articleSelectionneId,
  onSelect,
  onSuggest,
  chargementSuggestion,
  suggestion,
}) {
  const termines = articles.filter((article) => article.reste === 0).length;

  return (
    <section className={styles.panel} aria-labelledby="articles-titre">
      <header className={styles.head}>
        <h2 id="articles-titre">Articles à placer</h2>
        <span>
          {termines}/{articles.length} placés
        </span>
      </header>

      {articles.length === 0 ? (
        <p className={styles.empty}>Ce journal ne contient aucun article.</p>
      ) : (
        <ul className={styles.list}>
          {articles.map(({ detail, conditionnement, total, reste }) => {
            const selectionne = detail.id === articleSelectionneId;
            const termine = reste === 0;
            const pourcentage = total > 0 ? Math.round(((total - reste) / total) * 100) : 0;
            const nonPlace =
              selectionne && suggestion?.quantiteConditionnementsNonAffectee > 0
                ? suggestion.quantiteConditionnementsNonAffectee
                : 0;

            return (
              <li
                className={[
                  styles.card,
                  selectionne ? styles.selected : "",
                  termine ? styles.done : "",
                ].join(" ")}
                key={detail.id}
              >
                <button
                  aria-pressed={selectionne}
                  className={styles.select}
                  onClick={() => onSelect(detail)}
                  type="button"
                >
                  <span className={styles.thumb} aria-hidden="true">
                    {termine ? (
                      <Check size={18} aria-hidden="true" />
                    ) : (
                      initiales(detail.nomArticle)
                    )}
                  </span>
                  <span className={styles.body}>
                    <strong>{detail.nomArticle}</strong>
                    <small>
                      {conditionnement?.nomConditionnement ?? "Colis"}
                      {conditionnement?.quantitePieceStandard
                        ? ` · ${conditionnement.quantitePieceStandard} pièces`
                        : ""}
                    </small>
                  </span>
                  <span className={styles.count}>
                    {termine ? (
                      <span className={styles.doneLabel}>Placé</span>
                    ) : (
                      <>
                        <strong>{reste}</strong>
                        <small>/ {total}</small>
                      </>
                    )}
                  </span>
                  <span className={styles.bar} aria-hidden="true">
                    <span style={{ width: `${pourcentage}%` }} />
                  </span>
                </button>

                {selectionne && !termine && (
                  <button
                    className={styles.suggest}
                    disabled={chargementSuggestion}
                    onClick={onSuggest}
                    type="button"
                  >
                    <Sparkles size={16} aria-hidden="true" />
                    {chargementSuggestion ? "Calcul en cours…" : "Suggérer des emplacements"}
                  </button>
                )}

                {nonPlace > 0 && (
                  <p className={styles.warning}>
                    Pas assez de place : {nonPlace} colis resteront à placer à la main.
                  </p>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}

export default ProductList;
