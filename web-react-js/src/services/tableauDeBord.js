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

async function lireJson(springUrl, chemin) {
  const reponse = await fetch(`${springUrl}${chemin}`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${getAccessToken()}`,
    },
  });
  if (!reponse.ok) throw new Error(`${chemin} (${reponse.status})`);
  return reponse.json();
}

async function lire(springUrl, chemin) {
  const donnees = await lireJson(springUrl, chemin);
  return Array.isArray(donnees) ? donnees : [];
}

/**
 * Charge les sources du tableau de bord ; une source en échec reste vide.
 * Les mouvements ne sont plus téléchargés : le serveur les additionne et renvoie
 * seulement les totaux (la série mensuelle ici, la synthèse de la période plus bas).
 */
export async function chargerTableauDeBord(springUrl, annee) {
  const [stocks, articles, points] = await Promise.all([
    lire(springUrl, "/stocks/emplacements").catch(() => []),
    lire(springUrl, "/articles").catch(() => []),
    lire(springUrl, `/mouvementStock/serie-mensuelle?annee=${annee}`).catch(() => []),
  ]);
  return { stocks, articles, points };
}

const debutDeJour = (date) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate());

const ajouterJours = (date, jours) => {
  const copie = new Date(date);
  copie.setDate(copie.getDate() + jours);
  return copie;
};

// AAAA-MM-JJ avec les éléments du jour local (toISOString décalerait la date en UTC).
const dateApi = (date) => {
  const mois = String(date.getMonth() + 1).padStart(2, "0");
  const jour = String(date.getDate()).padStart(2, "0");
  return `${date.getFullYear()}-${mois}-${jour}`;
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

/**
 * Totaux des mouvements de la période et de la précédente (de même durée), additionnés
 * par le serveur. Renvoie null en cas d'échec : les indicateurs restent alors à zéro.
 */
export async function chargerSynthese(springUrl, cle, maintenant = new Date()) {
  const [debut, fin] = bornesPeriode(cle, maintenant).courante;
  try {
    return await lireJson(
      springUrl,
      `/mouvementStock/synthese?debut=${dateApi(debut)}&fin=${dateApi(fin)}`,
    );
  } catch {
    return null;
  }
}

/** Variation en % ; null quand la période précédente est vide. */
function variation(courant, precedent) {
  if (!precedent) return null;
  return ((courant - precedent) * 100) / precedent;
}

const PERIODE_VIDE = { entrees: 0, sorties: 0, nombreMouvements: 0 };

export function calculerIndicateurs(synthese, stocks) {
  const courante = synthese?.courante ?? PERIODE_VIDE;
  const precedente = synthese?.precedente ?? PERIODE_VIDE;

  return {
    entrees: courante.entrees,
    variationEntrees: variation(courante.entrees, precedente.entrees),
    sorties: courante.sorties,
    variationSorties: variation(courante.sorties, precedente.sorties),
    total: courante.nombreMouvements,
    variationTotal: variation(courante.nombreMouvements, precedente.nombreMouvements),
    unitesDisponibles: stocks.reduce(
      (somme, ligne) => somme + (ligne.quantiteStock ?? 0),
      0,
    ),
  };
}

/** Pièces entrées et sorties par mois, de janvier au mois courant (points du serveur). */
export function serieMensuelle(points, annee, maintenant = new Date()) {
  const dernierMois = annee === maintenant.getFullYear() ? maintenant.getMonth() : 11;

  return MOIS.slice(0, dernierMois + 1).map((mois, index) => {
    const point = points.find((element) => element.mois === index + 1);
    return {
      mois,
      entrees: point?.entrees ?? 0,
      sorties: point?.sorties ?? 0,
    };
  });
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
