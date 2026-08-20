import "../assets/css/Sidebar.css";

const navigationItems = [
  { label: "Tableau de bord", icon: "dashboard", active: true },
  { label: "Utilisateurs", icon: "group" },
  { label: "Articles", icon: "inventory_2" },
  { label: "Journal", icon: "receipt_long" },
  { label: "Emplacements", icon: "location_on" },
];

const optimisationItems = [
  { label: "Anomalies", icon: "warning" },
  { label: "Risques de rupture", icon: "trending_down" },
  { label: "Optimisation du picking", icon: "route" },
];

function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="logo">
        <span className="logo-mark material-symbols-outlined" aria-hidden="true">warehouse</span>
        <p>Warehouse</p>
      </div>

      <nav className="sidebar-content" aria-label="Navigation principale">
        <div className="content">
          <p className="content-title">Navigation principale</p>
          {navigationItems.map((item) => (
            <a className={item.active ? "sidebar-link sidebar-link--active" : "sidebar-link"} href="#" key={item.label}>
              <span className="material-symbols-outlined" aria-hidden="true">{item.icon}</span>
              {item.label}
            </a>
          ))}
        </div>

        <div className="content">
          <p className="content-title">Optimisation</p>
          {optimisationItems.map((item) => (
            <a className="sidebar-link" href="#" key={item.label}>
              <span className="material-symbols-outlined" aria-hidden="true">{item.icon}</span>
              {item.label}
            </a>
          ))}
        </div>
      </nav>

      <div className="sidebar-footer">
        <a href="#"><span className="material-symbols-outlined" aria-hidden="true">help</span>Aide</a>
        <a href="#"><span className="material-symbols-outlined" aria-hidden="true">settings</span>Paramètres</a>
      </div>
    </aside>
  );
}

export default Sidebar;
