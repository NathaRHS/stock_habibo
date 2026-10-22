import { Link, NavLink, useNavigate } from "react-router-dom";
import {
  Activity,
  Boxes,
  ClipboardCheck,
  HelpCircle,
  HouseIcon,
  LayoutDashboard,
  ListChecks,
  LogOut,
  Package,
  PackageOpen,
  Receipt,
  Route,
  Settings,
  TrendingDown,
  TriangleAlert,
  Users,
} from "lucide-react";
import logoHabibo from "../assets/Logo_Habibo.png";
import "../assets/css/Sidebar.css";
import { getAuthenticatedUser, seDeconnecter } from "../services/authService";
import NotificationBell from "./NotificationBell";

const navigationItems = [
  { label: "Tableau de bord", icon: LayoutDashboard, to: "/accueil", end: true },
  { label: "Utilisateurs", icon: Users, to: "/users" },
  { label: "Racks", icon: HouseIcon, to: "/rack" },
  { label: "Articles", icon: Package, to: "/article" },
  { label: "Journaux", icon: Receipt, to: "/journaux-mouvements" },
  { label: "Inventaires", icon: ClipboardCheck, to: "/inventaires" },
  { label: "Conditionnements", icon: PackageOpen, to: "/article-conditionnements" },
  { label: "Capacités palettes", icon: Boxes, to: "/palettes-conditionnements/create" },
  { label: "Référentiels", icon: ListChecks, to: "/referentiels", adminSeulement: true },
  // Journal d'activité : réservé à l'administrateur (le serveur le refuse aux autres).
  { label: "Activités", icon: Activity, to: "/activites", adminSeulement: true },
];

const optimisationItems = [
  { label: "Anomalies", icon: TriangleAlert },
  { label: "Risques de rupture", icon: TrendingDown },
  { label: "Optimisation du picking", icon: Route },
];

function Sidebar() {
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const estAdministrateur = getAuthenticatedUser()?.role === "ADMIN";
  const liens = navigationItems.filter(
    (item) => !item.adminSeulement || estAdministrateur,
  );

  const quitter = async () => {
    await seDeconnecter(springUrl);
    navigate("/login");
  };

  return (
    <aside className="sidebar">
      <Link className="logo" to="/accueil" aria-label="Retour au tableau de bord">
        <span className="logo-mark" aria-hidden="true">
          <img src={logoHabibo} alt="" />
        </span>
        <p>WMS</p>
      </Link>
      <div className="sidebar-notification">
        <NotificationBell />
        <span>Notifications</span>
      </div>

      <nav className="sidebar-content" aria-label="Navigation principale">
        <div className="content">
          <p className="content-title">Navigation principale</p>
          {liens.map((item) => (
            <NavLink className={({ isActive }) => isActive ? "sidebar-link sidebar-link--active" : "sidebar-link"} end={item.end} key={item.label} to={item.to}>
              <item.icon size={18} aria-hidden="true" />
              {item.label}
            </NavLink>
          ))}
        </div>

        <div className="content">
          <p className="content-title">Optimisation</p>
          {optimisationItems.map((item) => (
            <button className="sidebar-link sidebar-link--disabled" disabled key={item.label} title="Fonctionnalité à venir" type="button">
              <item.icon size={18} aria-hidden="true" />
              {item.label}
              <span className="sidebar-soon">Bientôt</span>
            </button>
          ))}
        </div>
      </nav>

      <div className="sidebar-footer">
        <button disabled type="button"><HelpCircle size={18} aria-hidden="true" />Aide</button>
        <button disabled type="button"><Settings size={18} aria-hidden="true" />Paramètres</button>
        <button onClick={quitter} type="button"><LogOut size={18} aria-hidden="true" />Se déconnecter</button>
      </div>
    </aside>
  );
}

export default Sidebar;
