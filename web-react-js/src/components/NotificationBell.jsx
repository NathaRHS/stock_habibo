import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, BellOff, ClipboardCheck, LogOut, Package } from "lucide-react";
import {
  chargerNotifications,
  marquerNotificationLue,
  marquerToutesNotificationsLues,
} from "../services/notificationService";
import { getAccessToken } from "../services/authService";
import "./NotificationBell.css";

const formatDate = (date) => {
  const valeur = new Date(date);
  if (Number.isNaN(valeur.getTime())) return "";
  const maintenant = new Date();
  const difference = Math.round((maintenant - valeur) / 60000);
  if (difference < 1) return "À l'instant";
  if (difference < 60) return `Il y a ${difference} min`;
  if (difference < 1440) return `Il y a ${Math.round(difference / 60)} h`;
  return valeur.toLocaleDateString("fr-FR", { day: "2-digit", month: "short" });
};

function NotificationBell() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();
  const wrapperRef = useRef(null);
  const [ouvert, setOuvert] = useState(false);
  const [filtre, setFiltre] = useState("toutes");
  const [notifications, setNotifications] = useState([]);
  const [erreur, setErreur] = useState("");

  const charger = async () => {
    if (!getAccessToken()) return;
    try {
      const resultat = await chargerNotifications(springUrl);
      setNotifications(Array.isArray(resultat) ? resultat : []);
      setErreur("");
    } catch (error) {
      setErreur(error.message);
    }
  };

  useEffect(() => {
    charger();
    const intervalle = window.setInterval(charger, 30000);
    return () => window.clearInterval(intervalle);
  }, [springUrl]);

  useEffect(() => {
    const fermer = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target))
        setOuvert(false);
    };
    document.addEventListener("mousedown", fermer);
    return () => document.removeEventListener("mousedown", fermer);
  }, []);

  const nonLues = notifications.filter(
    (notification) => !notification.lu,
  ).length;
  const notificationsAffichees = useMemo(
    () =>
      filtre === "nonLues"
        ? notifications.filter((notification) => !notification.lu)
        : notifications,
    [filtre, notifications],
  );

  const ouvrirNotification = async (notification) => {
    if (!notification.lu) {
      try {
        await marquerNotificationLue(springUrl, notification.id);
        setNotifications((actuelles) =>
          actuelles.map((element) =>
            element.id === notification.id ? { ...element, lu: true } : element,
          ),
        );
      } catch {
        // La navigation reste possible si le marquage échoue.
      }
    }
    setOuvert(false);
    if (notification.urlCible) navigate(notification.urlCible);
  };

  const toutMarquerCommeLu = async () => {
    try {
      await marquerToutesNotificationsLues(springUrl);
      setNotifications((actuelles) =>
        actuelles.map((notification) => ({ ...notification, lu: true })),
      );
    } catch (error) {
      setErreur(error.message);
    }
  };

  return (
    <div className="notification-bell" ref={wrapperRef}>
      <button
        className="notification-bell-button"
        type="button"
        aria-label="Notifications"
        aria-expanded={ouvert}
        onClick={() => setOuvert((valeur) => !valeur)}
      >
        <Bell size={20} aria-hidden="true" />
        {nonLues > 0 && (
          <span className="notification-bell-count">
            {nonLues > 9 ? "9+" : nonLues}
          </span>
        )}
      </button>
      {ouvert && (
        <aside className="notification-panel" aria-label="Notifications">
          <header className="notification-panel-header">
            <div>
              <h2>Notifications</h2>
              <span>
                {nonLues
                  ? `${nonLues} non lue${nonLues > 1 ? "s" : ""}`
                  : "Tout est à jour"}
              </span>
            </div>
            <button
              type="button"
              onClick={toutMarquerCommeLu}
              disabled={!nonLues}
            >
              Tout lire
            </button>
          </header>
          <div className="notification-panel-tabs">
            <button
              className={filtre === "toutes" ? "active" : ""}
              onClick={() => setFiltre("toutes")}
              type="button"
            >
              Toutes
            </button>
            <button
              className={filtre === "nonLues" ? "active" : ""}
              onClick={() => setFiltre("nonLues")}
              type="button"
            >
              Non lues{nonLues ? ` (${nonLues})` : ""}
            </button>
          </div>
          {erreur && <p className="notification-panel-error">{erreur}</p>}
          <div className="notification-panel-list">
            {!notificationsAffichees.length ? (
              <div className="notification-empty">
                <BellOff size={20} />
                <strong>Aucune notification</strong>
                <span>Les nouvelles actions apparaîtront ici.</span>
              </div>
            ) : (
              notificationsAffichees.map((notification) => (
                <button
                  className={`notification-item ${notification.lu ? "" : "unread"}`}
                  key={notification.id}
                  onClick={() => ouvrirNotification(notification)}
                  type="button"
                >
                  <span
                    className={`notification-item-icon priority-${String(notification.priorite ?? "INFORMATION").toLowerCase()}`}
                  >
                    {notification.categorie === "SORTIE" ? (
                      <LogOut size={16} />
                    ) : notification.categorie === "INVENTAIRE" ? (
                      <ClipboardCheck size={16} />
                    ) : (
                      <Package size={16} />
                    )}
                  </span>
                  <span className="notification-item-content">
                    <strong>{notification.titre}</strong>
                    <span>{notification.message}</span>
                    <small>{formatDate(notification.dateCreation)}</small>
                  </span>
                  {!notification.lu && (
                    <i
                      className="notification-unread-dot"
                      aria-label="Non lue"
                    />
                  )}
                </button>
              ))
            )}
          </div>
        </aside>
      )}
    </div>
  );
}

export default NotificationBell;
