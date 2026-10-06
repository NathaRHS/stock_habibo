import { requeteJson } from "./affectationStockService";

// Structure de l'entrepôt : elle ne dépend pas de la date, on la charge une seule fois.
export async function chargerEntrepot(springUrl) {
  const [racks, emplacements] = await Promise.all([
    requeteJson(`${springUrl}/rack`),
    requeteJson(`${springUrl}/emplacements`),
  ]);
  return { racks, emplacements };
}

// Stock à la fin de la période, variation et nombre de mouvements par emplacement.
// Dates au format AAAA-MM-JJ ; sans date, le serveur utilise le jour courant.
export function chargerActiviteEntrepot(springUrl, debut, fin) {
  const parametres = new URLSearchParams();
  if (debut) parametres.set("debut", debut);
  if (fin) parametres.set("fin", fin);
  const requete = parametres.toString();
  return requeteJson(`${springUrl}/mouvementStock/activite${requete ? `?${requete}` : ""}`);
}

export const creerRack = (springUrl, { name, nombreEtages }) =>
  requeteJson(`${springUrl}/rack`, {
    method: "POST",
    body: JSON.stringify({ name, nombreEtages }),
  });

export const creerEmplacement = (springUrl, { nomEmplacement, rackId, numeroEtage }) =>
  requeteJson(`${springUrl}/emplacements`, {
    method: "POST",
    body: JSON.stringify({ nomEmplacement, rackId, numeroEtage }),
  });
