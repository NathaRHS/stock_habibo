import "./AlertPop.css";

const olderNotifications = [1, 2, 3, 4, 6, 7, 8, 9];

function AlertPop() {
  return (
    <aside className="notification-popup" aria-label="Notifications">
      <div className="notification-header">
        <h2>Notifications</h2>
        <button className="notification-menu" type="button" aria-label="Options">•••</button>
      </div>
      <div className="notification-filters" aria-label="Filtres">
        <button className="notification-filter notification-filter--active" type="button">Toutes</button>
        <button className="notification-filter" type="button">Non lues</button>
      </div>
      <section className="notification-group">
        <div className="notification-section-header">
          <h3>Aujourd&apos;hui</h3>
          <button type="button">Tout voir</button>
        </div>
        <article className="notification-card notification-card--unread">
          <div className="notification-avatar notification-avatar--product" aria-hidden="true"><span>📦</span><i>!</i></div>
          <div className="notification-content"><p>Le produit <strong>C215-1521</strong> n&apos;existe pas.</p><span>Il y a 2 min</span></div>
          <span className="notification-unread-dot" aria-label="Non lue" />
        </article>
        <article className="notification-card notification-card--unread">
          <div className="notification-avatar notification-avatar--product" aria-hidden="true"><span>📦</span><i>!</i></div>
          <div className="notification-content"><p>Le produit <strong>C215-1521</strong> nécessite votre attention.</p><span>Il y a 15 min</span></div>
          <span className="notification-unread-dot" aria-label="Non lue" />
        </article>
      </section>
      <section className="notification-group">
        <div className="notification-section-header"><h3>Plus tôt</h3></div>
        {olderNotifications.map((item) => (
          <article className="notification-card" key={item}>
            <div className="notification-avatar notification-avatar--user" aria-hidden="true"><span>ST</span><i>⚠</i></div>
            <div className="notification-content"><p>Problème avec l&apos;utilisateur <strong>STG-0014</strong>.</p><span>Il y a {item} h</span></div>
          </article>
        ))}
      </section>
    </aside>
  );
}

export default AlertPop;
