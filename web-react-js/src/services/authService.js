const SESSION_KEY = "authSession";

export function setAuthSession(loginResponse) {
  sessionStorage.setItem(
    SESSION_KEY,
    JSON.stringify(loginResponse),
  );
}

export function getAuthSession() {
  const storedSession =
    sessionStorage.getItem(SESSION_KEY);

  return storedSession
    ? JSON.parse(storedSession)
    : null;
}

export function getAccessToken() {
  return getAuthSession()?.token ?? null;
}

export function getAuthenticatedUser() {
  return getAuthSession()?.user ?? null;
}

export function clearAuthSession() {
  sessionStorage.removeItem(SESSION_KEY);
}

// Deconnexion : le serveur note le depart dans le journal d'activite, puis la
// session locale est effacee. Meme si le serveur ne repond pas, on se deconnecte.
export async function seDeconnecter(springUrl) {
  const token = getAccessToken();

  if (token) {
    try {
      await fetch(`${springUrl}/user/logout`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch {
      // Le depart local reste possible sans le serveur.
    }
  }

  clearAuthSession();
}