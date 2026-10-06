import Sidebar from "./Sidebar";
import "./PageLayout.css";

function PageLayout({ breadcrumb, kicker, title, description, actions, children }) {
  return (
    <div className="layout-shell">
      <Sidebar />
      <section className="layout-workspace">
        <header className="layout-topbar">
          <p>{breadcrumb}</p>
          <div className="layout-user">
            <span>AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="layout-content">
          <header className="layout-heading">
            <div>
              {kicker && <span className="layout-kicker">{kicker}</span>}
              <h1>{title}</h1>
              {description && <p>{description}</p>}
            </div>
            {actions}
          </header>
          {children}
        </main>
      </section>
    </div>
  );
}

export default PageLayout;
