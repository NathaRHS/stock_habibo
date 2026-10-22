import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  ArrowLeft,
  Building2,
  CheckCircle2,
  FileText,
  Minus,
  PackagePlus,
  Plus,
  Search,
  Trash2,
} from "lucide-react";
import Button from "../components/Button";
import PdfViewer from "../components/PdfViewer";
import Sidebar from "../components/Sidebar";
import VignetteArticle from "../components/VignetteArticle";
import { getAccessToken } from "../services/authService";
import "../components/PageLayout.css";
import "./css/CreateCommande.css";

const extraireNomFichier = (chemin) =>
  String(chemin ?? "")
    .replaceAll("\\", "/")
    .split("/")
    .filter(Boolean)
    .at(-1);

function CreateCommande() {
  const { id } = useParams();
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();

  const [journal, setJournal] = useState(null);
  const [document, setDocument] = useState({ url: "", type: "", fichier: null });
  const [articles, setArticles] = useState([]);
  const [existantes, setExistantes] = useState([]); // déjà enregistrées en base
  const [lignes, setLignes] = useState([]); // à enregistrer : [{ article, quantite }]
  const [recherche, setRecherche] = useState("");
  const [articleChoisi, setArticleChoisi] = useState(null);
  const [quantite, setQuantite] = useState(1);
  const [chargement, setChargement] = useState(true);
  const [enregistrement, setEnregistrement] = useState(false);
  const [erreur, setErreur] = useState("");

  useEffect(() => {
    const controller = new AbortController();
    let objectUrl = "";
    const charger = async () => {
      if (!token) {
        setErreur("Votre session a expiré. Reconnectez-vous.");
        setChargement(false);
        return;
      }
      const options = {
        headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
        signal: controller.signal,
      };
      try {
        const [reponseArticles, reponseJournal, reponseCommandes] = await Promise.all([
          fetch(`${springUrl}/articles`, options),
          fetch(`${springUrl}/journaux-mouvements/${id}`, options),
          fetch(`${springUrl}/commande/${id}`, options),
        ]);
        if (!reponseArticles.ok) {
          throw new Error("Impossible de charger les articles.");
        }
        setArticles(await reponseArticles.json());
        if (reponseCommandes.ok) {
          const donnees = await reponseCommandes.json();
          setExistantes(Array.isArray(donnees?.commandes) ? donnees.commandes : []);
        }
        if (reponseJournal.ok) {
          const donneesJournal = await reponseJournal.json();
          setJournal(donneesJournal);

          // Pièce jointe du journal : le bon de commande du client.
          const nomFichier = extraireNomFichier(donneesJournal.urlPieceJointe);
          if (nomFichier) {
            const reponseFichier = await fetch(
              `${springUrl}/uploads/${encodeURIComponent(nomFichier)}`,
              {
                headers: { Authorization: `Bearer ${token}` },
                signal: controller.signal,
              },
            );
            if (!reponseFichier.ok) {
              throw new Error(`Pièce jointe indisponible (${reponseFichier.status}).`);
            }
            const blob = await reponseFichier.blob();
            objectUrl = URL.createObjectURL(blob);
            setDocument({ url: objectUrl, type: blob.type, fichier: blob });
          }
        }
      } catch (e) {
        if (e.name !== "AbortError") {
          setErreur(e.message || "Chargement impossible.");
        }
      } finally {
        if (!controller.signal.aborted) setChargement(false);
      }
    };
    charger();
    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [id, springUrl, token]);

  const resultats = useMemo(() => {
    const texte = recherche.trim().toLowerCase();
    if (!texte) return articles;
    return articles.filter(
      (article) =>
        article.nomArticle?.toLowerCase().includes(texte) ||
        article.codeBar?.toLowerCase().includes(texte),
    );
  }, [articles, recherche]);

  const totalQuantite =
    lignes.reduce((somme, ligne) => somme + ligne.quantite, 0) +
    existantes.reduce((somme, ligne) => somme + (Number(ligne.quantiteDemande) || 0), 0);
  const nombreProduits = existantes.length + lignes.length;

  const nomFichier = extraireNomFichier(journal?.urlPieceJointe);

  const ajouter = () => {
    const nombre = Math.floor(Number(quantite));
    if (!articleChoisi || !(nombre > 0)) return;
    setLignes((actuelles) => {
      const existante = actuelles.find((l) => l.article.id === articleChoisi.id);
      if (existante) {
        return actuelles.map((l) =>
          l.article.id === articleChoisi.id
            ? { ...l, quantite: l.quantite + nombre }
            : l,
        );
      }
      return [...actuelles, { article: articleChoisi, quantite: nombre }];
    });
    setArticleChoisi(null);
    setQuantite(1);
    setRecherche("");
  };

  const retirer = (articleId) =>
    setLignes((actuelles) => actuelles.filter((l) => l.article.id !== articleId));

  const enregistrer = async () => {
    if (lignes.length === 0) return;
    try {
      setEnregistrement(true);
      setErreur("");
      const reponse = await fetch(`${springUrl}/commande/insertAllCommande/${id}`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(
          lignes.map((l) => ({
            idArticle: l.article.id,
            quantiteDemande: l.quantite,
          })),
        ),
      });
      if (!reponse.ok) {
        throw new Error(
          (await reponse.text()) || `Enregistrement impossible (${reponse.status}).`,
        );
      }
      navigate("/journaux-mouvements");
    } catch (e) {
      setErreur(e instanceof Error ? e.message : "Enregistrement impossible.");
    } finally {
      setEnregistrement(false);
    }
  };

  return (
    <div className="layout-shell">
      <Sidebar />
      <section className="layout-workspace">
        <header className="layout-topbar">
          <p>Opérations / Liste de commande</p>
          <div className="layout-user">
            <span>AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="cmd-app">
          <header className="cmd-topbar">
            <Link className="cmd-retour" to="/journaux-mouvements" aria-label="Retour">
              <ArrowLeft size={18} />
            </Link>
            <div>
              <h1>{journal?.reference ?? "Nouvelle commande"}</h1>
              <p>
                <Building2 size={14} aria-hidden="true" />
                {journal?.nomClient || "Client non renseigné"} · Liste de commande
              </p>
            </div>
          </header>

          {erreur && (
            <p className="cmd-erreur" role="alert">
              {erreur}
            </p>
          )}

          <div className="cmd-workspace">
            {/* Gauche : le bon de commande du client (pièce jointe du journal) */}
            <section className="cmd-pane cmd-document">
              <div className="cmd-pane-header">
                <span>
                  <FileText size={16} aria-hidden="true" />
                  Document d'origine
                </span>
                <span className="cmd-mono">{nomFichier || "aucun-document"}</span>
              </div>
              <div className="cmd-doc-zone">
                {chargement ? (
                  <p className="cmd-vide">Chargement…</p>
                ) : !nomFichier || !document.url ? (
                  <p className="cmd-vide">
                    {nomFichier ? "Aperçu indisponible." : "Aucune pièce jointe."}
                  </p>
                ) : document.type.startsWith("image/") ? (
                  <img
                    className="cmd-image"
                    src={document.url}
                    alt={`Pièce jointe ${nomFichier}`}
                  />
                ) : document.type === "application/pdf" ? (
                  <PdfViewer
                    fichier={document.fichier}
                    urlTelechargement={document.url}
                    nomFichier={nomFichier}
                  />
                ) : (
                  <p className="cmd-vide">
                    <a href={document.url} download={nomFichier}>
                      Télécharger le fichier
                    </a>
                  </p>
                )}
              </div>
            </section>

            {/* Droite : la saisie et les lignes */}
            <aside className="cmd-pane cmd-saisie">
              <div className="cmd-pane-header">
                <span>
                  <PackagePlus size={16} aria-hidden="true" />
                  Ajouter un produit
                </span>
              </div>

              <div className="cmd-saisie-contenu">
                <label className="cmd-champ">
                  Produit
                  <span className="cmd-recherche">
                    <Search size={16} aria-hidden="true" />
                    <input
                      value={recherche}
                      onChange={(event) => setRecherche(event.target.value)}
                      placeholder="Nom ou code-barres"
                    />
                  </span>
                </label>

                <div className="cmd-resultats" role="listbox" aria-label="Produits">
                  {chargement ? (
                    <p className="cmd-vide">Chargement…</p>
                  ) : resultats.length === 0 ? (
                    <p className="cmd-vide">Aucun produit.</p>
                  ) : (
                    resultats.map((article) => (
                      <button
                        key={article.id}
                        type="button"
                        role="option"
                        aria-selected={articleChoisi?.id === article.id}
                        className={
                          articleChoisi?.id === article.id
                            ? "cmd-resultat choisi"
                            : "cmd-resultat"
                        }
                        onClick={() => setArticleChoisi(article)}
                      >
                        <VignetteArticle
                          photoUrl={article.photoUrl}
                          nom={article.nomArticle}
                          taille={36}
                        />
                        <span>
                          <strong>{article.nomArticle}</strong>
                          <small>{article.codeBar}</small>
                        </span>
                      </button>
                    ))
                  )}
                </div>

                <div className="cmd-champ">
                  <span>Quantité (conditionnements)</span>
                  <div className="cmd-quantite">
                    <button
                      type="button"
                      aria-label="Diminuer"
                      onClick={() => setQuantite((q) => Math.max(1, Number(q) - 1))}
                    >
                      <Minus size={16} />
                    </button>
                    <input
                      type="number"
                      min="1"
                      inputMode="numeric"
                      aria-label="Quantité"
                      value={quantite}
                      onChange={(event) => setQuantite(event.target.value)}
                      onKeyDown={(event) => event.key === "Enter" && ajouter()}
                    />
                    <button
                      type="button"
                      aria-label="Augmenter"
                      onClick={() => setQuantite((q) => Number(q) + 1)}
                    >
                      <Plus size={16} />
                    </button>
                  </div>
                </div>

                <Button
                  variant="secondary"
                  fullWidth
                  icon={<Plus size={16} />}
                  disabled={!articleChoisi || !(Number(quantite) > 0)}
                  onClick={ajouter}
                >
                  {articleChoisi ? `Ajouter ${articleChoisi.nomArticle}` : "Ajouter à la liste"}
                </Button>

                <div className="cmd-liste">
                  <div className="cmd-liste-titre">
                    <span>Liste de commande</span>
                    <span>
                      {nombreProduits} produit{nombreProduits > 1 ? "s" : ""}
                    </span>
                  </div>

                  {nombreProduits === 0 ? (
                    <p className="cmd-vide">Aucun produit pour le moment.</p>
                  ) : (
                    <ul>
                      {existantes.map((commande) => (
                        <li key={`existante-${commande.idCommande}`}>
                          <span>
                            <strong>{commande.nomArticle}</strong>
                            <small>Enregistré</small>
                          </span>
                          <b>{commande.quantiteDemande}</b>
                          <i />
                        </li>
                      ))}
                      {lignes.map((ligne) => (
                        <li key={ligne.article.id} className="nouvelle">
                          <span>
                            <strong>{ligne.article.nomArticle}</strong>
                            <small>À enregistrer</small>
                          </span>
                          <b>{ligne.quantite}</b>
                          <button
                            type="button"
                            className="cmd-retirer"
                            onClick={() => retirer(ligne.article.id)}
                            aria-label={`Retirer ${ligne.article.nomArticle}`}
                          >
                            <Trash2 size={15} />
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}

                  <div className="cmd-total">
                    <span>Quantité totale</span>
                    <strong>{totalQuantite}</strong>
                  </div>
                </div>
              </div>

              <div className="cmd-pied">
                <Button
                  fullWidth
                  icon={<CheckCircle2 size={16} />}
                  loading={enregistrement}
                  disabled={lignes.length === 0}
                  onClick={enregistrer}
                >
                  Enregistrer la commande
                </Button>
              </div>
            </aside>
          </div>
        </main>
      </section>
    </div>
  );
}

export default CreateCommande;
