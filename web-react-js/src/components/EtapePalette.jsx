/** Etape 3 : capacite palette. Ne fait aucun appel reseau. */
function EtapePalette({ valeurs, onChange, quantitePieceStandard, nomArticle, desactive }) {
  const quantiteMaximale = Number(valeurs.quantiteMaximale);
  const piecesParUnite = Number(quantitePieceStandard);
  const totalPieces =
    Number.isInteger(quantiteMaximale) && quantiteMaximale > 0 && piecesParUnite > 0
      ? quantiteMaximale * piecesParUnite
      : null;

  return (
    <div className="acm-champs">
      <p className="acm-rappel">
        Capacité palette de <strong>{nomArticle || "l'article"}</strong>
      </p>

      <label>
        Unités maximum par palette
        <input
          type="number"
          name="quantiteMaximale"
          value={valeurs.quantiteMaximale}
          onChange={onChange}
          placeholder="Ex. 26"
          min="1"
          step="1"
          inputMode="numeric"
          disabled={desactive}
          autoFocus
        />
      </label>

      <p className="acm-total" aria-live="polite">
        Soit <strong>{totalPieces ?? "—"}</strong> pièces par palette
      </p>
    </div>
  );
}

export default EtapePalette;
