export function construireNiveaux(rack, emplacements, enrichir = () => ({})) {
  const nombreEtages = rack?.nombreEtages ?? 0;
  const emplacementsRack = emplacements.filter((emplacement) => emplacement.rackId === rack?.id);

  return Array.from({ length: nombreEtages }, (_, index) => nombreEtages - index).map(
    (niveau) => ({
      niveau,
      cases: emplacementsRack
        .filter((emplacement) => emplacement.numeroEtage === niveau)
        .sort((a, b) => (a.ordreDansEtage ?? 0) - (b.ordreDansEtage ?? 0))
        .map((emplacement) => ({ emplacement, ...enrichir(emplacement) })),
    }),
  );
}

export function calculerOccupation(niveaux) {
  const cases = niveaux.flatMap((niveau) => niveau.cases);
  if (cases.length === 0) return 0;
  const occupees = cases.filter((element) => element.infos.occupe > 0).length;
  return Math.round((occupees / cases.length) * 100);
}

export function construireRack(rack, emplacements, enrichir) {
  const niveaux = construireNiveaux(rack, emplacements, enrichir);
  return { niveaux, occupation: calculerOccupation(niveaux) };
}

export function infosStockEmplacement(emplacement, { stocks, conditionnements, palettes }) {
  const stock = stocks.find((element) => element.emplacementId === emplacement.id);
  const conditionnement = conditionnements.find(
    (element) => element.articleId === stock?.articleId,
  );
  const palette = palettes.find(
    (element) => element.articleConditionnementId === conditionnement?.id,
  );

  const occupe = conditionnement?.quantitePieceStandard
    ? (stock?.quantiteStock ?? 0) / conditionnement.quantitePieceStandard
    : 0;
  const capacite = palette?.quantiteMaximale ?? 0;

  return {
    nomArticle: conditionnement?.nomArticle ?? null,
    capacite,
    occupe,
    planifie: 0,
    placeRestante: Math.max(capacite - occupe, 0),
    tauxOccupation: capacite > 0 ? Math.min(Math.round((occupe / capacite) * 100), 100) : 0,
    incompatible: false,
    memeArticle: false,
  };
}
