import "./Footer.css";

const CONTACTS = [
  { label: "Antananarivo", telephone: "+261 32 17 010 00" },
  { label: "Province Nord", telephone: "+261 32 17 001 15" },
  { label: "Province Sud", telephone: "+261 32 17 001 13" },
  { label: "Province Est", telephone: "+261 32 17 001 09" },
  { label: "Cafés - Hôtels - Restaurants", telephone: "+261 32 17 010 14" },
  { label: "Stations Service", telephone: "+261 32 17 010 14" },
];

const NAVIGATION = [
  { label: "Accueil", href: "#accueil" },
  { label: "Atouts", href: "#atouts" },
  { label: "Contacts", href: "#contacts" },
];

const LIENS_LEGAUX = [
  { label: "Mentions légales", href: "#mentions-legales" },
  { label: "Politiques de confidentialités", href: "#confidentialite" },
];

// Les pictogrammes sont des carrés blancs dont le symbole est « évidé » avec
// la couleur du fond (variable --footer-fond) : aucune dépendance d'icônes.
function IconeLinkedIn() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="1" y="1" width="22" height="22" rx="3" fill="currentColor" />
      <circle cx="7.2" cy="7.6" r="1.5" className="footer-evide" />
      <rect x="5.9" y="10.2" width="2.6" height="7.8" className="footer-evide" />
      <path
        className="footer-evide"
        d="M10.2 10.2h2.5v1.1c.4-.7 1.3-1.3 2.6-1.3 2.6 0 3.2 1.7 3.2 3.9V18h-2.6v-3.7c0-1-.1-2-1.3-2s-1.5.9-1.5 2V18h-2.5z"
      />
    </svg>
  );
}

function IconeFacebook() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="1" y="1" width="22" height="22" rx="3" fill="currentColor" />
      <path
        className="footer-evide"
        d="M13.2 23v-8h2.6l.4-3.1h-3V9.9c0-.9.3-1.5 1.6-1.5h1.6V5.6c-.3 0-1.200-.1-2.300-.1-2.300 0-3.900 1.400-3.900 4v2.400H7.500V15h2.700v8z"
      />
    </svg>
  );
}

function IconeYouTube() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect x="0.5" y="4" width="23" height="16" rx="4.5" fill="currentColor" />
      <path className="footer-evide" d="M9.8 8.8v6.4l5.5-3.2z" />
    </svg>
  );
}

const RESEAUX = [
  { label: "LinkedIn", href: "#linkedin", Icone: IconeLinkedIn },
  { label: "Facebook", href: "#facebook", Icone: IconeFacebook },
  { label: "YouTube", href: "#youtube", Icone: IconeYouTube },
];

function Footer() {
  return (
    <footer className="footer">
      <div className="footer-haut">
        <div className="footer-gauche">
          <h2 className="footer-titre">Habibo Group</h2>

          <nav className="footer-navigation" aria-label="Navigation du pied de page">
            {NAVIGATION.map((lien) => (
              <a href={lien.href} key={lien.label}>
                {lien.label}
              </a>
            ))}
          </nav>

          <ul className="footer-legal">
            {LIENS_LEGAUX.map((lien) => (
              <li key={lien.label}>
                <a href={lien.href}>{lien.label}</a>
              </li>
            ))}
          </ul>

          <ul className="footer-reseaux" aria-label="Réseaux sociaux">
            {RESEAUX.map(({ label, href, Icone }) => (
              <li key={label}>
                <a href={href} aria-label={label}>
                  <Icone />
                </a>
              </li>
            ))}
          </ul>
        </div>

        <div className="footer-droite">
          <p className="footer-copyright">
            Copyright © 2024 - Tous droits réservés Habibo Group
          </p>

          <ul className="footer-contacts">
            {CONTACTS.map((contact) => (
              <li key={contact.label}>
                <strong>{contact.label}</strong>
                <span>{contact.telephone}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="footer-marque" aria-hidden="true">
        habibo
      </div>
    </footer>
  );
}

export default Footer;
