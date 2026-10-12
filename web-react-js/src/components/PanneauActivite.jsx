import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, ClipboardCheck, LogOut, Package } from "lucide-react";
import {
  chargerNotifications,
  marquerNotificationLue,
} from "../services/notificationService";
import { getAccessToken } from "../services/authService";
import "./PanneauActivite.css";

const heure = (date) =>
  date.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });

// « Il y a 2 minutes », « Hier, à 11:50 », « le 2 févr., à 09:10 ».
function dateRelative(valeur) {
  const date = new Date(valeur);
  if (Number.isNaN(date.getTime())) return "";

  const minutes = Math.round((Date.now() - date.getTime()) / 60000);
  if (minutes < 1) return "À l'instant";
  if (minutes < 60) return `Il y a ${minutes} minute${minutes > 1 ? "s" : ""}`;

  const heures = Math.round(minutes / 60);
  if (minutes < 1440) return `Il y a ${heures} heure${heures > 1 ? "s" : ""}`;

  const hier = new Date();
  hier.setDate(hier.getDate() - 1);
  if (date.toDateString() === hier.toDateString()) {
    return `Hier, à ${heure(date)}`;
  }

  const jour = date.toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "short",
  });
  return `le ${jour}, à ${heure(date)}`;
}

const initiales = (nom) =>
  String(nom ?? "?")
    .replace(/[^A-Za-zÀ-ÿ0-9 ]/g, " ")
    .trim()
    .slice(0, 2)
    .toUpperCase();

function Avatar({ nom }) {
  return (
    <span className="panneau-avatar" aria-hidden="true">
      {initiales(nom)}
    </span>
  );
}

const iconeNotification = (categorie) => {
  if (categorie === "SORTIE") return LogOut;
  if (categorie === "INVENTAIRE") return ClipboardCheck;
  if (categorie === "ENTREE") return Package;
  return Bell;
};

/**
 * Panneau latéral droit : notifications, activités récentes, administrateurs.
 *
 * - notifications : lues depuis GET /notifications (existant) ;
 * - administrateurs : comptes de rôle ADMIN, lus depuis GET /user ;
 * - activités : fournies par la propriété `activites`
 *   ([{ id, utilisateur, texte, date }]). Le journal d'activité n'est pas
 *   encore enregistré côté serveur : tant qu'il n'existe pas, la liste est vide.
 */
function PanneauActivite({ activites = [] }) {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState([]);
  const [administrateurs, setAdministrateurs] = useState([]);

  useEffect(() => {
    if (!getAccessToken()) return undefined;
    let actif = true;

    const charger = async () => {
      try {
        const resultat = await chargerNotifications(springUrl);
        if (actif) setNotifications(Array.isArray(resultat) ? resultat : []);
      } catch {
        // Le panneau reste affiché, sans notifications.
      }
    };

    charger();
    const minuteur = window.setInterval(charger, 30000);
    return () => {
      actif = false;
      window.clearInterval(minuteur);
    };
  }, [springUrl]);

  useEffect(() => {
    if (!getAccessToken()) return;
    let actif = true;

    fetch(`${springUrl}/user`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${getAccessToken()}`,
      },
    })
      .then((reponse) => (reponse.ok ? reponse.json() : []))
      .then((utilisateurs) => {
        if (!actif || !Array.isArray(utilisateurs)) return;
        setAdministrateurs(
          utilisateurs.filter((utilisateur) => utilisateur.role === "ADMIN"),
        );
      })
      .catch(() => {});

    return () => {
      actif = false;
    };
  }, [springUrl]);

  const ouvrir = async (notification) => {
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
    if (notification.urlCible) navigate(notification.urlCible);
  };

  return (
    <aside className="panneau-activite" aria-label="Notifications et activités">
      <section>
        <h2>Notifications</h2>
        {notifications.length === 0 ? (
          <p className="panneau-vide">Aucune notification.</p>
        ) : (
          <ul className="panneau-liste">
            {notifications.slice(0, 5).map((notification) => {
              const Icone = iconeNotification(notification.categorie);
              return (
                <li key={notification.id}>
                  <button
                    className={notification.lu ? "" : "non-lue"}
                    onClick={() => ouvrir(notification)}
                    type="button"
                  >
                    <span className="panneau-icone">
                      <Icone size={15} />
                    </span>
                    <span className="panneau-texte">
                      <strong>{notification.titre}</strong>
                      <small>{dateRelative(notification.dateCreation)}</small>
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <section>
        <h2>Activités</h2>
        {activites.length === 0 ? (
          <p className="panneau-vide">Aucune activité enregistrée.</p>
        ) : (
          <ol className="panneau-chronologie">
            {activites.slice(0, 6).map((activite) => (
              <li key={activite.id}>
                <Avatar nom={activite.utilisateur} />
                <span className="panneau-texte">
                  <span>{activite.texte}</span>
                  <small>{dateRelative(activite.date)}</small>
                </span>
              </li>
            ))}
          </ol>
        )}
      </section>

      <section>
        <h2>Admins en vigueur</h2>
        {administrateurs.length === 0 ? (
          <p className="panneau-vide">Aucun administrateur.</p>
        ) : (
          <ul className="panneau-liste panneau-admins">
            {administrateurs.map((administrateur) => (
              <li key={administrateur.id}>
                <Avatar nom={administrateur.username} />
                <span className="panneau-texte">
                  <span>{administrateur.matricule}</span>
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </aside>
  );
}

export default PanneauActivite;
