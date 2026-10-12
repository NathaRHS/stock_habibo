import { getAccessToken } from "./authService";

// En dessous de ce total (en pièces, tous emplacements confondus), un article
// est compté en « stock faible ». Seuil d'affichage, pas une règle métier.
export const SEUIL_STOCK_FAIBLE = 100;

export const PERIODES = {
  jour: { libelle: "Aujourd’hui", jours: 1, prefixe: "du", texte: "aujourd’hui" },
  semaine: { libelle: "7 derniers jours", jours: 7, prefixe: "sur", texte: "7 jours" },
  mois: { libelle: "30 derniers jours", jours: 30, prefixe: "sur", texte: "30 jours" },
};

const MOIS = [
  "Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
  "Juil", "Août", "Sep", "Oct", "Nov", "Déc",
];
export const NOMS_MOIS = [
  "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
  "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
];

async function lire(springUrl, chemin) {
  const reponse = await fetch(`${springUrl}${chemin}`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${getAccessToken()}`,
    },
  });
  if (!reponse.ok) throw new Error(`${chemin} (${reponse.status})`);
  const donnees = await reponse.json();
  return Array.isArray(donnees) ? donnees : [];
}

/** Charge les trois sources du tableau de bord ; une source en échec reste vide. */
export async function chargerTableauDeBord(springUrl) {
  const [mouvements, stocks, articles] = await Promise.all([
    lire(springUrl, "/mouvementStock").catch(() => []),
    lire(springUrl, "/stocks/emplacements").catch(() => []),
    lire(springUrl, "/articles").catch(() => []),
  ]);
  return { mouvements, stocks, articles };
}

const debutDeJour = (date) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate());

const ajouterJours = (date, jours) => {
  const copie = new Date(date);
  copie.setDate(copie.getDate() + jours);
  return copie;
};

/** Période courante et période précédente de même durée : [debut, fin[. */
export function bornesPeriode(cle, maintenant = new Date()) {
  const { jours } = PERIODES[cle];
  const fin = ajouterJours(debutDeJour(maintenant), 1);
  const debut = ajouterJours(fin, -jours);
  return {
    courante: [debut, fin],
    precedente: [ajouterJours(debut, -jours), debut],
  };
}

function sommePieces(mouvements, type, [debut, fin]) {
  let total = 0;
  for (const mouvement of mouvements) {
    if (mouvement.typeMouvement !== type) continue;
    const date = new Date(mouvement.dateMouvement);
    if (date >= debut && date < fin) total += mouvement.quantitePiecesReelle ?? 0;
  }
  return total;
}

function nombreMouvements(mouvements, [debut, fin]) {
  return mouvements.filter((mouvement) => {
    const date = new Date(mouvement.dateMouvement);
    return date >= debut && date < fin;
  }).length;
}

/** Variation en % ; null quand la période précédente est vide. */
function variation(courant, precedent) {
  if (!precedent) return null;
  return ((courant - precedent) * 100) / precedent;
}

export function calculerIndicateurs(mouvements, stocks, cle, maintenant = new Date()) {
  const { courante, precedente } = bornesPeriode(cle, maintenant);

  const entrees = sommePieces(mouvements, "ENTREE", courante);
  const sorties = sommePieces(mouvements, "SORTIE", courante);
  const total = nombreMouvements(mouvements, courante);

  return {
    entrees,
    variationEntrees: variation(entrees, sommePieces(mouvements, "ENTREE", precedente)),
    sorties,
    variationSorties: variation(sorties, sommePieces(mouvements, "SORTIE", precedente)),
    total,
    variationTotal: variation(total, nombreMouvements(mouvements, precedente)),
    unitesDisponibles: stocks.reduce(
      (somme, ligne) => somme + (ligne.quantiteStock ?? 0),
      0,
    ),
  };
}

/** Pièces entrées et sorties par mois, de janvier au mois courant. */
export function serieMensuelle(mouvements, annee, maintenant = new Date()) {
  const dernierMois = annee === maintenant.getFullYear() ? maintenant.getMonth() : 11;
  const serie = MOIS.slice(0, dernierMois + 1).map((mois) => ({
    mois,
    entrees: 0,
    sorties: 0,
  }));

  for (const mouvement of mouvements) {
    const date = new Date(mouvement.dateMouvement);
    if (date.getFullYear() !== annee || date.getMonth() > dernierMois) continue;
    const point = serie[date.getMonth()];
    const pieces = mouvement.quantitePiecesReelle ?? 0;
    if (mouvement.typeMouvement === "ENTREE") point.entrees += pieces;
    if (mouvement.typeMouvement === "SORTIE") point.sorties += pieces;
  }

  return serie;
}

/** Articles en stock normal, en stock faible ou en rupture. */
export function etatDuStock(stocks, articles) {
  const parArticle = new Map();
  for (const ligne of stocks) {
    parArticle.set(
      ligne.articleId,
      (parArticle.get(ligne.articleId) ?? 0) + (ligne.quantiteStock ?? 0),
    );
  }

  const identifiants = articles.length
    ? articles.map((article) => article.id)
    : [...parArticle.keys()];

  let normal = 0;
  let faible = 0;
  let rupture = 0;
  for (const id of identifiants) {
    const total = parArticle.get(id) ?? 0;
    if (total <= 0) rupture += 1;
    else if (total < SEUIL_STOCK_FAIBLE) faible += 1;
    else normal += 1;
  }

  return { normal, faible, rupture, total: identifiants.length };
}
