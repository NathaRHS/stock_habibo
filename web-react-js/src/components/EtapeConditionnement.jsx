/** Etape 2 : conditionnement de l'article. Ne fait aucun appel reseau. */
function EtapeConditionnement({
  valeurs,
  onChange,
  typesConditionnement,
  nomArticle,
  desactive,
}) {
  return (
    <div className="acm-champs">
      <p className="acm-rappel">
        Conditionnement de <strong>{nomArticle || "l'article"}</strong>
      </p>

      <label>
        Type de conditionnement
        <select
          name="typeConditionnementId"
          value={valeurs.typeConditionnementId}
          onChange={onChange}
          disabled={desactive}
        >
          <option value="" disabled>
            Choisir
          </option>
          {typesConditionnement.map((type) => (
            <option key={type.id} value={type.id}>
              {type.nomConditionnement}
            </option>
          ))}
        </select>
      </label>

      <div className="acm-grille">
        <label>
          Pièces par unité
          <input
            type="number"
            name="quantitePieceStandard"
            value={valeurs.quantitePieceStandard}
            onChange={onChange}
            placeholder="Ex. 24"
            min="1"
            step="1"
            disabled={desactive}
            autoFocus
          />
        </label>

        <label>
          Code-barres du conditionnement
          <input
            type="text"
            name="codeBarres"
            value={valeurs.codeBarres}
            onChange={onChange}
            placeholder="Facultatif"
            disabled={desactive}
          />
        </label>
      </div>
    </div>
  );
}

export default EtapeConditionnement;
