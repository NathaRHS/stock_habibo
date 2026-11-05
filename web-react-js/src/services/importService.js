import { getAccessToken } from "./authService";

// Lit le message d'erreur du serveur (corps JSON avec "detail"), sinon un message par défaut.
async function lireErreur(response) {
  try {
    const erreur = await response.json();
    return erreur.detail || erreur.message || `Erreur serveur (${response.status})`;
  } catch {
    return `Erreur serveur (${response.status})`;
  }
}

// Envoie un fichier CSV. Pas de requeteJson ici : un envoi de fichier ne doit
// pas forcer le Content-Type en JSON.
export async function importerCsv(springUrl, route, fichier) {
  const formulaire = new FormData();
  formulaire.append("file", fichier);

  const response = await fetch(`${springUrl}${route}`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${getAccessToken()}`,
    },
    body: formulaire,
  });

  if (!response.ok) {
    throw new Error(await lireErreur(response));
  }
  return response.json();
}

// Télécharge un fichier protégé par le jeton (un simple lien ne l'enverrait pas).
export async function telechargerFichier(springUrl, route, nomFichier) {
  const response = await fetch(`${springUrl}${route}`, {
    headers: { Authorization: `Bearer ${getAccessToken()}` },
  });

  if (!response.ok) {
    throw new Error(await lireErreur(response));
  }

  const lien = document.createElement("a");
  lien.href = URL.createObjectURL(await response.blob());
  lien.download = nomFichier;
  lien.click();
  URL.revokeObjectURL(lien.href);
}
