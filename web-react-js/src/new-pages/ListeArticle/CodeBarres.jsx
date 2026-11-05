import styles from "./ListeArticle.module.css";

// Motifs EAN-13 : 7 modules par chiffre (1 = barre noire).
const GAUCHE_L = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"];
const GAUCHE_G = ["0100111", "0110011", "0011011", "0100001", "0011101", "0111001", "0000101", "0010001", "0001001", "0010111"];
const DROITE_R = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"];

// Le premier chiffre ne se dessine pas : il choisit L ou G pour les 6 suivants.
const PARITES = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG", "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"];

// Suite de 95 modules : garde, 6 chiffres, centre, 6 chiffres, garde.
function modulesEan13(code) {
  const parite = PARITES[Number(code[0])];
  let modules = "101";
  for (let i = 1; i <= 6; i += 1) {
    const motifs = parite[i - 1] === "L" ? GAUCHE_L : GAUCHE_G;
    modules += motifs[Number(code[i])];
  }
  modules += "01010";
  for (let i = 7; i <= 12; i += 1) {
    modules += DROITE_R[Number(code[i])];
  }
  return `${modules}101`;
}

// Regroupe les modules noirs voisins en un seul rectangle.
function barres(modules) {
  const rectangles = [];
  let debut = null;
  for (let i = 0; i <= modules.length; i += 1) {
    const noir = modules[i] === "1";
    if (noir && debut === null) debut = i;
    if (!noir && debut !== null) {
      rectangles.push({ x: debut, largeur: i - debut });
      debut = null;
    }
  }
  return rectangles;
}

/**
 * Code-barres d'un article : dessin EAN-13 quand le code a 13 chiffres,
 * sinon seulement le numéro (le dessin serait faux pour un autre format).
 * Le numéro reste affiché : c'est lui qu'on recherche et qu'on compare.
 */
function CodeBarres({ code }) {
  const texte = String(code ?? "").trim();
  const dessinable = /^\d{13}$/.test(texte);

  return (
    <span className={styles.codeBarres} title={texte}>
      {dessinable && (
        <svg
          aria-hidden="true"
          className={styles.codeBarresDessin}
          preserveAspectRatio="none"
          shapeRendering="crispEdges"
          viewBox="0 0 95 30"
        >
          {barres(modulesEan13(texte)).map((rectangle) => (
            <rect
              fill="currentColor"
              height="30"
              key={rectangle.x}
              width={rectangle.largeur}
              x={rectangle.x}
              y="0"
            />
          ))}
        </svg>
      )}
      <span className={styles.codeBarresNumero}>{texte || "—"}</span>
    </span>
  );
}

export default CodeBarres;
