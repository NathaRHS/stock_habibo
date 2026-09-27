function Panel({ title, subtitle, children }) {
  return (
    <section className="layout-panel">
      <header className="layout-panel-header">
        {subtitle ? (
          <div>
            <h2>{title}</h2>
            <p>{subtitle}</p>
          </div>
        ) : (
          <h2>{title}</h2>
        )}
      </header>
      {children}
    </section>
  );
}

export default Panel;
