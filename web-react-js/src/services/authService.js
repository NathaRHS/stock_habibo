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