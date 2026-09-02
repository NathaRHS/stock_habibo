import { Link, NavLink } from "react-router-dom";
import "../assets/css/Sidebar.css";

const navigationItems = [
  { label: "Tableau de bord", icon: "dashboard", to: "/accueil", end: true },
  { label: "Utilisateurs", icon: "group", to: "/users" },
  { label: "Articles", icon: "inventory_2", to: "/article" },
  { label: "Journaux", icon: "receipt_long", to: "/journaux-mouvements" },
  { label: "Conditionnements", icon: "package_2", to: "/article-conditionnements" },
  { label: "Capacités palettes", icon: "pallet", to: "/palettes-conditionnements/create" },
];

const optimisationItems = [
  { label: "Anomalies", icon: "warning" },
  { label: "Risques de rupture", icon: "trending_down" },
  { label: "Optimisation du picking", icon: "route" },
];

function Sidebar() {
  return (
    <aside className="sidebar">
      <Link className="logo" to="/accueil" aria-label="Retour au tableau de bord">
        <span className="logo-mark material-symbols-outlined" aria-hidden="true">warehouse</span>
        <p>Warehouse</p>
      </Link>

      <nav className="sidebar-content" aria-label="Navigation principale">
        <div className="content">
          <p className="content-title">Navigation principale</p>
          {navigationItems.map((item) => (
            <NavLink className={({ isActive }) => isActive ? "sidebar-link sidebar-link--active" : "sidebar-link"} end={item.end} key={item.label} to={item.to}>
              <span className="material-symbols-outlined" aria-hidden="true">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </div>

        <div className="content">
          <p className="content-title">Optimisation</p>
          {optimisationItems.map((item) => (
            <button className="sidebar-link sidebar-link--disabled" disabled key={item.label} title="Fonctionnalité à venir" type="button">
              <span className="material-symbols-outlined" aria-hidden="true">{item.icon}</span>
              {item.label}
              <span className="sidebar-soon">Bientôt</span>
            </button>
          ))}
        </div>
      </nav>

      <div className="sidebar-footer">
        <button disabled type="button"><span className="material-symbols-outlined" aria-hidden="true">help</span>Aide</button>
        <button disabled type="button"><span className="material-symbols-outlined" aria-hidden="true">settings</span>Paramètres</button>
      </div>
    </aside>
  );
}

export default Sidebar;
