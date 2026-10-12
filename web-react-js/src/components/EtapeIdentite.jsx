/**
 * Etape 1 : identite de l'article. Ne fait aucun appel reseau.
 *
 * En mode variante (varianteDe fourni) : le type de produit est fige, et la
 * famille est soit affichee (deja existante), soit proposee a la saisie
 * (creee a la premiere variante).
 */
function EtapeIdentite({
  valeurs,
  onChange,
  typesProduit,
  typesConditionnement,
  unites,
  chargement,
  desactive,
  varianteDe = null,
  nomFamille = "",
  onChangeFamille,
  photo = null,
  apercuPhoto = "",
  onChoisirPhoto,
  onRetirerPhoto,
}) {
  return (
    <div className="acm-champs">
      {varianteDe && (
        <div className="acm-famille">
          {varianteDe.nomFamille ? (
            <p className="acm-rappel">
              Famille : <strong>{varianteDe.nomFamille}</strong>
            </p>
          ) : (
            <label>
              Nom de la famille (créée avec cette première variante)
              <input
                type="text"
                value={nomFamille}
                onChange={onChangeFamille}
                placeholder="Ex. Coca-Cola"
                disabled={desactive}
              />
            </label>
          )}
        </div>
      )}

      <label>
        Nom de l'article
        <input
          type="text"
          name="nomArticle"
          value={valeurs.nomArticle}
          onChange={onChange}
          placeholder="Ex. Coca-Cola"
          disabled={desactive}
          autoFocus
        />
      </label>

      <label>
        Code-barres
        <input
          type="text"
          name="codeBar"
          value={valeurs.codeBar}
          onChange={onChange}
          placeholder="Code-barres de l'article"
          disabled={desactive}
        />
      </label>

      <div className="acm-grille">
        <label>
          Contenance d'une pièce
          <input
            type="number"
            name="contenanceValeur"
            value={valeurs.contenanceValeur}
            onChange={onChange}
            placeholder="Ex. 30"
            min="0"
            step="any"
            disabled={desactive}
          />
        </label>

        <label>
          Unité
          <select
            name="uniteId"
            value={valeurs.uniteId}
            onChange={onChange}
            disabled={chargement || desactive}
          >
            <option value="">Aucune</option>
            {unites.map((unite) => (
              <option key={unite.id} value={unite.id}>
                {unite.nomUnite}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="acm-grille">
        <label>
          Type de produit
          <select
            name="typeProduitId"
            value={valeurs.typeProduitId}
            onChange={onChange}
            disabled={chargement || desactive || Boolean(varianteDe)}
          >
            <option value="" disabled>
              {chargement ? "Chargement…" : "Choisir"}
            </option>
            {typesProduit.map((type) => (
              <option key={type.id} value={type.id}>
                {type.nomType}
              </option>
            ))}
          </select>
        </label>

        <label>
          Type de conditionnement
          <select
            name="typeConditionnementId"
            value={valeurs.typeConditionnementId}
            onChange={onChange}
            disabled={chargement || desactive}
          >
            <option value="" disabled>
              {chargement ? "Chargement…" : "Choisir"}
            </option>
            {typesConditionnement.map((type) => (
              <option key={type.id} value={type.id}>
                {type.nomConditionnement}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="acm-photo">
        <span className="acm-photo-apercu">
          {apercuPhoto ? (
            <img src={apercuPhoto} alt="Aperçu de la photo" />
          ) : (
            <span aria-hidden="true">Photo</span>
          )}
        </span>

        <div className="acm-photo-actions">
          <label className="acm-photo-choisir">
            {photo ? "Changer la photo" : "Ajouter une photo"}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={(event) => {
                onChoisirPhoto?.(event.target.files?.[0] ?? null);
                event.target.value = "";
              }}
              disabled={desactive}
            />
          </label>
          <small>
            {photo ? photo.name : "Facultatif · JPG, PNG ou WebP · 2 Mo maximum"}
          </small>
          {photo && (
            <button
              type="button"
              className="acm-photo-retirer"
              onClick={onRetirerPhoto}
              disabled={desactive}
            >
              Retirer
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export default EtapeIdentite;
