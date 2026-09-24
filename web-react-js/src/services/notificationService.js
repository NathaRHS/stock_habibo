import { getAccessToken } from "./authService";

async function requeteNotifications(url, options = {}) {
  const token = getAccessToken();
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw new Error(`Impossible de charger les notifications (${response.status})`);
  }
  return response.status === 204 ? null : response.json();
}

export function chargerNotifications(springUrl) {
  return requeteNotifications(`${springUrl}/notifications`);
}

export function marquerNotificationLue(springUrl, notificationId) {
  return requeteNotifications(`${springUrl}/notifications/${notificationId}/lue`, {
    method: "PATCH",
  });
}

export function marquerToutesNotificationsLues(springUrl) {
  return requeteNotifications(`${springUrl}/notifications/toutes-lues`, {
    method: "PATCH",
  });
}
