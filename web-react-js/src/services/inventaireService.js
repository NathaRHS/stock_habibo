import { getAccessToken } from "./authService";

// Ajoute l'authentification et transforme les erreurs du backend en Error.
async function requeteInventaire(url, options = {}) {
  const token = getAccessToken();
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...options.headers,
    },
  });

  if (!response.ok) {
    let message = `Erreur serveur (${response.status})`;
    try {
      const erreur = await response.json();
      message = erreur.detail || erreur.message || erreur.error || message;
    } catch {
      // La réponse ne contient pas de JSON exploitable.
    }
    throw new Error(message);
  }

  return response.status === 204 ? null : response.json();
}

export async function chargerJournauxInventaire(springUrl) {
  const journaux = await requeteInventaire(`${springUrl}/journaux-mouvements`);
  return journaux.filter(
    (journal) => journal.typeMouvementJournal === "INVENTAIRE",
  );
}

export async function chargerDonneesControleInventaire(springUrl, journalId) {
  const [inventaire, racks, emplacements] = await Promise.all([
    requeteInventaire(`${springUrl}/inventaire/${journalId}`),
    requeteInventaire(`${springUrl}/rack`),
    requeteInventaire(`${springUrl}/emplacements`),
  ]);
  return { inventaire, racks, emplacements };
}

export function chargerParticipantsInventaire(springUrl, journalId) {
  return requeteInventaire(
    `${springUrl}/journaux-mouvements/${journalId}/participants`,
  );
}

export function changerStatutInventaire(springUrl, journalId, action) {
  return requeteInventaire(
    `${springUrl}/journaux-mouvements/${journalId}/${action}`,
    { method: "POST" },
  );
}

export function scannerArticleInventaire(springUrl, journalId, scan) {
  return requeteInventaire(
    `${springUrl}/journaux-mouvements/${journalId}/inventaire/scans`,
    { method: "POST", body: JSON.stringify(scan) },
  );
}

export function terminerParticipationInventaire(springUrl, journalId) {
  return requeteInventaire(
    `${springUrl}/journaux-mouvements/${journalId}/participants/terminer`,
    { method: "POST" },
  );
}

export async function telechargerRapportInventaire(springUrl, journalId) {
  const token = getAccessToken();
  const response = await fetch(`${springUrl}/inventaire/${journalId}/rapport.pdf`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!response.ok) {
    let message = "Impossible de générer le rapport PDF.";
    try {
      const erreur = await response.json();
      message = erreur.detail || erreur.message || message;
    } catch {
      // Le backend peut retourner une erreur sans JSON.
    }
    throw new Error(message);
  }

  return response.blob();
}
