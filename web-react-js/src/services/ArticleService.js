import { getAccessToken } from "./authService";

export async function requeteJson(url, options = {}) {
  const token = getAccessToken();

  return fetch(url, {
    ...options,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...options.headers,
    },
  });
}

export async function getFicheProduit(springUrl, id) {
  return requeteJson(`${springUrl}/stocks/fiche-produit/${id}`);
}