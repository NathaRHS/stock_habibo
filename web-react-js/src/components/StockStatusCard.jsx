import "../assets/css/Dashboard.css";

const stockStates = [
  { label: "Stock normal", value: 72, className: "stock-status--normal" },
  { label: "Stock faible", value: 20, className: "stock-status--low" },
  { label: "Rupture", value: 8, className: "stock-status--empty" },
];

function StockStatusCard() {
  return (
    <section className="stock-status-card" aria-labelledby="stock-status-title">
      <div className="stock-status-header">
        <div>
          <p className="stock-status-eyebrow">État du stock</p>
          <h2 id="stock-status-title">10 432</h2>
          <span>unités disponibles</span>
        </div>
        <span className="stock-status-icon material-symbols-outlined" aria-hidden="true">inventory_2</span>
      </div>
      <div className="stock-status-bar" aria-label="Répartition de l’état du stock">
        {stockStates.map((state) => (
          <span className={state.className} style={{ width: `${state.value}%` }} key={state.label} />
        ))}
      </div>
      <ul className="stock-status-list">
        {stockStates.map((state) => (
          <li key={state.label}>
            <span className={`stock-status-dot ${state.className}`} />
            <span>{state.label}</span>
            <strong>{state.value}%</strong>
          </li>
        ))}
      </ul>
      <button type="button">
        Voir les détails
        <span className="material-symbols-outlined" aria-hidden="true">arrow_forward</span>
      </button>
    </section>
  );
}

export default StockStatusCard;
