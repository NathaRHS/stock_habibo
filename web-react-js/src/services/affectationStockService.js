import { getAccessToken } from "./authService";

async function requeteJson(url, options = {}) {
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
      message = erreur.message || erreur.detail || erreur.error || message;
    } catch {
      // La réponse d'erreur ne contient pas de JSON exploitable.
    }
    throw new Error(message);
  }

  return response.status === 204 ? null : response.json();
}

export async function chargerDonneesAffectation(springUrl, journalId) {
  const [journal, racks, emplacements, stocks, conditionnements, palettes] =
    await Promise.all([
      requeteJson(`${springUrl}/journaux-mouvements/${journalId}`),
      requeteJson(`${springUrl}/rack`),
      requeteJson(`${springUrl}/emplacements`),
      requeteJson(`${springUrl}/stocks/emplacements`),
      requeteJson(`${springUrl}/articles-conditionnements`),
      requeteJson(`${springUrl}/palettes-conditionnements`),
    ]);

  return { journal, racks, emplacements, stocks, conditionnements, palettes };
}

export function creerEntreeStock(springUrl, journalId, affectations) {
  return requeteJson(`${springUrl}/mouvementStock/${journalId}/entree-stock`, {
    method: "POST", 
    body: JSON.stringify({ affectations }),
  });
}
