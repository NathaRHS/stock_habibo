import { useEffect, useMemo, useState } from "react";
import { FileText, Search } from "lucide-react";
import PageLayout from "../components/PageLayout";
import Button from "../components/Button";
import VignetteArticle from "../components/VignetteArticle";
import { getAccessToken } from "../services/authService";
import "./css/GenererBon.css";

const TYPES_BON = [
  {
    id: "commande",
    libelle: "Bon de commande",
    prefixe: "BC",
    tiers: "client",
    sousTitre: "Produits commandés par le client.",
    signatures: ["Établi par", "Accepté par le client"],
    mention: "Ce bon de commande fait foi des produits et quantités demandés. Toute modification doit être validée par écrit avant la préparation.",
  },
  {
    id: "reception",
    libelle: "Bon de réception",
    prefixe: "BR",
    tiers: "societe",
    sousTitre: "Produits réceptionnés à l'entrepôt.",
    signatures: ["Réceptionné par", "Livreur"],
    mention: "Le destinataire vérifie les quantités et l'état des produits à la réception. Toute réserve doit être mentionnée avant signature.",
  },
  {
    id: "livraison",
    libelle: "Bon de livraison",
    prefixe: "BL",
    tiers: "societe",
    sousTitre: "Produits livrés au destinataire.",
    signatures: ["Livré par", "Reçu par le destinataire"],
    mention: "Le destinataire vérifie les quantités et l'état des produits à la livraison. Toute réserve doit être mentionnée avant signature.",
  },
];

const echapper = (texte) =>
  String(texte ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");

const genererNumero = (prefixe) => {
  const maintenant = new Date();
  const date = maintenant.toISOString().slice(0, 10).replaceAll("-", "");
  const heure = maintenant.toTimeString().slice(0, 8).replaceAll(":", "");
  return `${prefixe}-${date}-${heure}`;
};

/** Ouvre le bon dans une fenêtre d'impression : « Enregistrer en PDF » suffit. */
const imprimerBon = ({ type, numero, tiersLibelle, tiersValeur, lignes }) => {
  const fenetre = window.open("", "_blank");
  if (!fenetre) return false;

  const total = lignes.reduce((somme, ligne) => somme + ligne.quantite, 0);
  const maintenant = new Date();
  const dateEdition = `${maintenant.toLocaleDateString("fr-FR")} ${maintenant.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}`;

  const corps = lignes
    .map((ligne, index) => {
      const contenance =
        ligne.contenanceValeur != null && ligne.nomUnite
          ? `${Number(ligne.contenanceValeur)} ${echapper(ligne.nomUnite)}`
          : "-";
      return `<tr>
        <td class="n">${index + 1}</td>
        <td><strong>${echapper(ligne.nomArticle)}</strong>${
          ligne.nomFamille
            ? `<br><span class="muted">${echapper(ligne.nomFamille)}</span>`
            : ""
        }</td>
        <td>${echapper(ligne.codeBar ?? "-")}</td>
        <td>${contenance}</td>
        <td class="right quantite">${ligne.quantite}</td>
      </tr>`;
    })
    .join("");

  const signatures = type.signatures
    .map(
      (libelle) =>
        `<div class="signature"><span class="label">${echapper(libelle)}</span><div class="zone"></div><span class="muted">Nom, date et signature</span></div>`,
    )
    .join("");

  fenetre.document.write(`<!doctype html>
<html lang="fr"><head><meta charset="utf-8">
<title>${echapper(numero)}</title>
<style>
  @page { size: A4; margin: 18mm 14mm 19mm 14mm; @bottom-center { content: "Page " counter(page) " / " counter(pages); color: #71808a; font-size: 8pt; } }
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { margin: 0; font-family: Helvetica, Arial, sans-serif; color: #18212a; font-size: 10pt; }
  .header { position: relative; padding-bottom: 14px; margin-bottom: 18px; border-bottom: 2px solid #01498e; }
  .brand { color: #01498e; font-size: 11pt; font-weight: bold; letter-spacing: 1px; }
  h1 { margin: 8px 0 4px; font-size: 22pt; font-weight: 500; }
  .subtitle { margin: 0; color: #667482; }
  .reference { position: absolute; right: 0; bottom: 14px; padding: 9px 12px; border-left: 3px solid #01498e; background: #f4f8fb; }
  .reference strong { display: block; margin-top: 4px; font-size: 11pt; }
  .label { display: block; color: #71808a; font-size: 8pt; font-weight: bold; text-transform: uppercase; }
  .meta, .summary { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
  .meta td { width: 25%; padding: 10px; border: 1px solid #dfe4e8; vertical-align: top; }
  .meta strong { display: block; margin-top: 5px; font-size: 10pt; }
  .summary td { width: 50%; padding: 11px; border: 1px solid #dfe4e8; vertical-align: top; }
  .summary .number { display: block; margin-top: 8px; font-size: 20pt; font-weight: normal; color: #01498e; }
  h2 { margin: 20px 0 8px; font-size: 13pt; }
  .lignes { width: 100%; border-collapse: collapse; }
  .lignes th { padding: 8px; background: #01498e; color: #fff; font-size: 8pt; text-align: left; text-transform: uppercase; }
  .lignes td { padding: 9px 8px; border-bottom: 1px solid #dfe4e8; vertical-align: top; }
  .lignes tr:nth-child(even) { background: #f7f9fa; }
  .lignes tr { page-break-inside: avoid; }
  .lignes thead { display: table-header-group; }
  .n { width: 28px; color: #71808a; }
  .muted { color: #71808a; font-size: 8pt; }
  .right { text-align: right; }
  .quantite { font-size: 12pt; font-weight: bold; }
  .total td { padding: 10px 8px; border-top: 2px solid #01498e; border-bottom: 0; font-weight: bold; background: #fff; }
  .signatures { margin-top: 28px; page-break-inside: avoid; }
  .signature { display: inline-block; width: 48%; margin-right: 1.5%; vertical-align: top; }
  .signature .zone { height: 70px; margin: 8px 0 5px; border: 1px solid #dfe4e8; background: #fbfcfd; }
  .notice { margin-top: 18px; padding: 11px 13px; border-left: 3px solid #d99016; background: #fff9ec; color: #6e5725; font-size: 9pt; }
</style></head><body>
  <div class="header">
    <div class="brand">HABIBO WMS - GESTION D'ENTREPOT</div>
    <h1>${echapper(type.libelle)}</h1>
    <p class="subtitle">${echapper(type.sousTitre)}</p>
    <div class="reference"><span class="label">Référence</span><strong>${echapper(numero)}</strong></div>
  </div>

  <table class="meta"><tr>
    <td><span class="label">${echapper(tiersLibelle)}</span><strong>${echapper(tiersValeur)}</strong></td>
    <td><span class="label">Date d'édition</span><strong>${dateEdition}</strong></td>
    <td><span class="label">Nombre de produits</span><strong>${lignes.length}</strong></td>
    <td><span class="label">Document</span><strong>${echapper(type.libelle)}</strong></td>
  </tr></table>

  <table class="summary"><tr>
    <td><span class="label">Produits</span><strong class="number">${lignes.length}</strong></td>
    <td><span class="label">Quantité totale</span><strong class="number">${total}</strong></td>
  </tr></table>

  <h2>Détail des produits</h2>
  <table class="lignes">
    <thead><tr><th>N°</th><th>Produit</th><th>Code-barres</th><th>Contenance</th><th class="right">Quantité</th></tr></thead>
    <tbody>${corps}</tbody>
    <tfoot><tr class="total"><td colspan="4">Total</td><td class="right quantite">${total}</td></tr></tfoot>
  </table>

  <div class="signatures">${signatures}</div>
  <div class="notice">${echapper(type.mention)}</div>
</body></html>`);
  fenetre.document.close();
  fenetre.focus();
  fenetre.print();
  return true;
};

function GenererBon() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [articles, setArticles] = useState([]);
  const [societes, setSocietes] = useState([]);
  const [typeId, setTypeId] = useState("commande");
  const [nomClient, setNomClient] = useState("");
  const [societeId, setSocieteId] = useState("");
  const [quantites, setQuantites] = useState({});
  const [recherche, setRecherche] = useState("");
  const [erreur, setErreur] = useState("");
  const [chargement, setChargement] = useState(true);

  const type = TYPES_BON.find((element) => element.id === typeId);

  useEffect(() => {
    const charger = async () => {
      const token = getAccessToken();
      if (!token) {
        setErreur("Votre session a expiré. Reconnectez-vous.");
        setChargement(false);
        return;
      }
      const options = {
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
      };
      try {
        const [reponseArticles, reponseSocietes] = await Promise.all([
          fetch(`${springUrl}/articles`, options),
          fetch(`${springUrl}/societes`, options),
        ]);
        if (!reponseArticles.ok || !reponseSocietes.ok) {
          throw new Error("Impossible de charger les produits ou les sociétés.");
        }
        setArticles(await reponseArticles.json());
        setSocietes(await reponseSocietes.json());
      } catch (e) {
        setErreur(e instanceof Error ? e.message : "Chargement impossible.");
      } finally {
        setChargement(false);
      }
    };
    charger();
  }, [springUrl]);

  const articlesAffiches = useMemo(() => {
    const texte = recherche.trim().toLowerCase();
    if (!texte) return articles;
    return articles.filter(
      (article) =>
        article.nomArticle?.toLowerCase().includes(texte) ||
        article.codeBar?.toLowerCase().includes(texte),
    );
  }, [articles, recherche]);

  const lignes = useMemo(
    () =>
      articles
        .map((article) => ({
          ...article,
          quantite: Number(quantites[article.id]) || 0,
        }))
        .filter((article) => article.quantite > 0),
    [articles, quantites],
  );

  const societe = societes.find((element) => String(element.id) === societeId);
  const tiersValeur =
    type.tiers === "client" ? nomClient.trim() : (societe?.nomSociete ?? "");
  const pret = tiersValeur !== "" && lignes.length > 0;

  const changerQuantite = (id, valeur) =>
    setQuantites((actuelles) => ({
      ...actuelles,
      [id]: valeur === "" ? "" : Math.max(0, Math.floor(Number(valeur))),
    }));

  const generer = () => {
    const ouvert = imprimerBon({
      type,
      numero: genererNumero(type.prefixe),
      tiersLibelle: type.tiers === "client" ? "Client" : "Société",
      tiersValeur,
      lignes,
    });
    if (!ouvert) setErreur("Autorisez les fenêtres pop-up pour ouvrir le bon.");
  };

  return (
    <PageLayout
      breadcrumb="Documents / Générer un bon"
      kicker="Documents"
      title="Générer un bon"
      description="Choisissez les produits et les quantités, puis imprimez le bon."
    >
      <div className="bon-page">
        <div className="bon-types" role="tablist">
          {TYPES_BON.map((element) => (
            <button
              key={element.id}
              type="button"
              role="tab"
              aria-selected={element.id === typeId}
              className={element.id === typeId ? "bon-type actif" : "bon-type"}
              onClick={() => setTypeId(element.id)}
            >
              {element.libelle}
            </button>
          ))}
        </div>

        <div className="bon-carte bon-entete">
          {type.tiers === "client" ? (
            <label>
              Nom du client
              <input
                value={nomClient}
                onChange={(event) => setNomClient(event.target.value)}
                placeholder="Nom du client"
              />
            </label>
          ) : (
            <label>
              Société
              <select
                value={societeId}
                onChange={(event) => setSocieteId(event.target.value)}
              >
                <option value="">Choisir une société</option>
                {societes.map((element) => (
                  <option key={element.id} value={element.id}>
                    {element.nomSociete}
                  </option>
                ))}
              </select>
            </label>
          )}
          <label className="bon-recherche">
            Produit
            <span>
              <Search size={16} aria-hidden="true" />
              <input
                value={recherche}
                onChange={(event) => setRecherche(event.target.value)}
                placeholder="Rechercher un produit ou un code-barres"
              />
            </span>
          </label>
        </div>

        {erreur && <p className="bon-erreur" role="alert">{erreur}</p>}

        <div className="bon-carte bon-liste">
          {chargement ? (
            <p className="bon-vide">Chargement…</p>
          ) : articlesAffiches.length === 0 ? (
            <p className="bon-vide">Aucun produit.</p>
          ) : (
            articlesAffiches.map((article) => (
              <div className="bon-ligne" key={article.id}>
                <VignetteArticle photoUrl={article.photoUrl} nom={article.nomArticle} />
                <div className="bon-ligne-texte">
                  <strong>{article.nomArticle}</strong>
                  <small>{article.codeBar}</small>
                </div>
                <input
                  type="number"
                  min="0"
                  inputMode="numeric"
                  aria-label={`Quantité de ${article.nomArticle}`}
                  placeholder="0"
                  value={quantites[article.id] ?? ""}
                  onChange={(event) => changerQuantite(article.id, event.target.value)}
                />
              </div>
            ))
          )}
        </div>

        <footer className="bon-pied">
          <span>
            {lignes.length} produit{lignes.length > 1 ? "s" : ""} sélectionné
            {lignes.length > 1 ? "s" : ""}
          </span>
          <Button icon={<FileText size={16} />} disabled={!pret} onClick={generer}>
            Générer le {type.libelle.toLowerCase()}
          </Button>
        </footer>
      </div>
    </PageLayout>
  );
}

export default GenererBon;
