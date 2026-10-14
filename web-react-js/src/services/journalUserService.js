import { getAccessToken } from "./authService";

async function requete(url) {
  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${getAccessToken()}`,
    },
  });

  if (response.status === 403) {
    throw new Error("Le journal d'activité est réservé aux administrateurs.");
  }
  if (!response.ok) {
    throw new Error(`Impossible de charger le journal d'activité (${response.status})`);
  }
  return response.json();
}

// Derniers evenements, pour le panneau « Activités » (tout utilisateur connecté).
export function chargerActivitesRecentes(springUrl, limite = 6) {
  return requete(`${springUrl}/journal-user/recentes?limite=${limite}`);
}

// Liste des types d'evenement, pour le filtre de la page (administrateur).
export function chargerTypesEvenement(springUrl) {
  return requete(`${springUrl}/journal-user/types`);
}

// Recherche avec filtres (administrateur). Les filtres vides sont ignores.
export function chargerActivites(springUrl, { userId, type, depuis, jusqua, page = 0, taille = 100 } = {}) {
  const parametres = new URLSearchParams();
  if (userId) parametres.set("userId", userId);
  if (type) parametres.set("type", type);
  if (depuis) parametres.set("depuis", depuis);
  if (jusqua) parametres.set("jusqua", jusqua);
  parametres.set("page", String(page));
  parametres.set("taille", String(taille));

  return requete(`${springUrl}/journal-user?${parametres.toString()}`);
}
