import "./css/Animate.css";

function Animate() {
  return (
    <main className="packaging-page">
      <section className="packaging-panel" aria-labelledby="packaging-title">
        <div className="packaging-copy">
          <span className="packaging-eyebrow">Station d&apos;emballage</span>
          <h1 id="packaging-title">Mise en boîte</h1>
          <p>
            La boîte s&apos;ouvre, reçoit les produits, puis se referme avant
            l&apos;expédition.
          </p>
        </div>

        <div className="packaging-animation">
          <div className="packaging-status" aria-hidden="true">
            <span className="packaging-status__dot" />
            <span className="packaging-status__label packaging-status__label--opening">Ouverture de la boîte</span>
            <span className="packaging-status__label packaging-status__label--filling">Remplissage en cours</span>
            <span className="packaging-status__label packaging-status__label--closing">Fermeture du colis</span>
            <span className="packaging-status__label packaging-status__label--ready">Colis prêt</span>
          </div>

          <div
            className="packaging-scene"
            role="img"
            aria-label="Animation d'une boîte qui s'ouvre, reçoit cinq produits sphériques et se referme"
          >
            <div className="packaging-dispenser" aria-hidden="true"><span /><span /><span /></div>
            <div className="packaging-floor-shadow" aria-hidden="true" />
            <div className="packaging-box" aria-hidden="true">
              <span className="packaging-ball packaging-ball--one" />
              <span className="packaging-ball packaging-ball--two" />
              <span className="packaging-ball packaging-ball--three" />
              <span className="packaging-ball packaging-ball--four" />
              <span className="packaging-ball packaging-ball--five" />
              <div className="packaging-face packaging-face--front">
                <div className="packaging-flap packaging-flap--front" />
                <div className="packaging-label"><span>WMS</span><small>READY TO SHIP</small></div>
              </div>
              <div className="packaging-face packaging-face--back"><div className="packaging-flap packaging-flap--back" /></div>
              <div className="packaging-face packaging-face--left"><div className="packaging-flap packaging-flap--left" /></div>
              <div className="packaging-face packaging-face--right"><div className="packaging-flap packaging-flap--right" /></div>
              <div className="packaging-face packaging-face--bottom" />
            </div>
          </div>

          <div className="packaging-steps" aria-hidden="true">
            <span>Ouverture</span>
            <span>Remplissage</span>
            <span>Fermeture</span>
            <i />
          </div>
        </div>
      </section>
    </main>
  );
}

export default Animate;
