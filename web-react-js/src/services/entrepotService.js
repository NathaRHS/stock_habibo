import { requeteJson } from "./affectationStockService";

// Structure de l'entrepôt : elle ne dépend pas de la date, on la charge une seule fois.
export async function chargerEntrepot(springUrl) {
  const [racks, emplacements] = await Promise.all([
    requeteJson(`${springUrl}/rack`),
    requeteJson(`${springUrl}/emplacements`),
  ]);
  return { racks, emplacements };
}

// Liste de base de l'entrepôt : une ligne SOLDE_INITIAL par (emplacement, article)
// avec le stock avant la période, puis un mouvement par ligne (quantité signée).
// La page en déduit le stock, les variations, les totaux et le détail.
// Dates au format AAAA-MM-JJ ; sans date, le serveur utilise le jour courant.
export function chargerActiviteEntrepot(springUrl, debut, fin) {
  const parametres = new URLSearchParams();
  if (debut) parametres.set("debut", debut);
  if (fin) parametres.set("fin", fin);
  const requete = parametres.toString();
  return requeteJson(`${springUrl}/mouvementStock/activite${requete ? `?${requete}` : ""}`);
}

// Pièces par unité et unités par palette : de quoi calculer la capacité d'un
// emplacement (unités par palette × pièces par unité, pour l'article présent).
export async function chargerCapacitesEntrepot(springUrl) {
  const [conditionnements, palettes] = await Promise.all([
    requeteJson(`${springUrl}/articles-conditionnements`),
    requeteJson(`${springUrl}/palettes-conditionnements`),
  ]);
  return { conditionnements, palettes };
}

export const creerRack = (springUrl, { name, nombreEtages }) =>
  requeteJson(`${springUrl}/rack`, {
    method: "POST",
    body: JSON.stringify({ name, nombreEtages }),
  });

// Crée le rack et tous ses emplacements en une seule transaction.
export const creerRackComplet = (springUrl, { name, nombreEtages, emplacements }) =>
  requeteJson(`${springUrl}/emplacements/complet`, {
    method: "POST",
    body: JSON.stringify({ name, nombreEtages, emplacements }),
  });

export const creerEmplacement =(springUrl, { nomEmplacement, rackId, numeroEtage }) =>
  requeteJson(`${springUrl}/emplacements`, {
    method: "POST",
    body: JSON.stringify({ nomEmplacement, rackId, numeroEtage }),
  });
