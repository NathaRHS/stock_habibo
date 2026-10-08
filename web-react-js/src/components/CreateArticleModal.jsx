import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";
import { verifierPhoto } from "../utils/photo";
import Button from "./Button";
import Modal from "./Modal";
import StepperArticle from "./StepperArticle";
import EtapeIdentite from "./EtapeIdentite";
import EtapeConditionnement from "./EtapeConditionnement";
import EtapePalette from "./EtapePalette";
import "./CreateArticleModal.css";

const ETAPES = ["Identité", "Conditionnement", "Palette"];

// Meme forme que le JSON attendu par POST /articles/complet.
const creerEtatInitial = () => ({
  article: {
    nomArticle: "",
    codeBar: "",
    typeProduitId: "",
    typeConditionnementId: "",
    contenanceValeur: "",
    uniteId: "",
  },
  conditionnement: {
    typeConditionnementId: "",
    codeBarres: "",
    quantitePieceStandard: "",
  },
  palette: {
    quantiteMaximale: "",
  },
});

// Propose un nom de famille : le nom de l'article sans la taille a la fin
// (« Lait Candia 1L » -> « Lait Candia »). L'utilisateur peut le corriger.
const proposerNomFamille = (nomArticle) =>
  (nomArticle ?? "")
    .replace(/\s+\d+(?:[.,]\d+)?\s*(?:mL|cL|L|g|kg)$/i, "")
    .trim();

const estEntierPositif = (valeur) => {
  const nombre = Number(valeur);
  return valeur !== "" && Number.isInteger(nombre) && nombre > 0;
};

async function lireMessageErreur(response, messageParDefaut) {
  const contenu = await response.text();
  if (!contenu.trim()) return messageParDefaut;

  try {
    const erreur = JSON.parse(contenu);
    const message = erreur.detail ?? erreur.message ?? erreur.error;
    if (typeof message === "string" && message.trim()) return message;
  } catch {
    // Le serveur a renvoye du texte brut.
    return contenu.trim();
  }

  return messageParDefaut;
}

/**
 * Creation d'un article en 3 etapes. Avec articleBase, le meme modal ajoute
 * une VARIANTE de cet article : type de produit fige, valeurs reprises de
 * l'article de depart, famille creee a la premiere variante.
 */
function CreateArticleModal({ isOpen, onClose, onCreated, articleBase = null }) {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [etape, setEtape] = useState(1);
  const [donnees, setDonnees] = useState(creerEtatInitial);
  const [nomFamille, setNomFamille] = useState("");
  const [typesProduit, setTypesProduit] = useState([]);
  const [typesConditionnement, setTypesConditionnement] = useState([]);
  const [unites, setUnites] = useState([]);
  const [chargement, setChargement] = useState(false);
  const [envoi, setEnvoi] = useState(false);
  const [error, setError] = useState("");
  const [photo, setPhoto] = useState(null);
  const [apercuPhoto, setApercuPhoto] = useState("");

  // Apercu de la photo choisie, libere quand elle change ou quand le modal se ferme.
  useEffect(() => {
    if (!photo) {
      setApercuPhoto("");
      return undefined;
    }
    const adresse = URL.createObjectURL(photo);
    setApercuPhoto(adresse);
    return () => URL.revokeObjectURL(adresse);
  }, [photo]);

  const choisirPhoto = (fichier) => {
    const message = verifierPhoto(fichier);
    if (message) {
      setError(message);
      return;
    }
    setError("");
    setPhoto(fichier);
  };

  useEffect(() => {
    if (!isOpen) return;

    setEtape(1);
    setPhoto(null);
    setDonnees(creerEtatInitial());
    setNomFamille(proposerNomFamille(articleBase?.nomArticle));
    setError("");

    const chargerOptions = async () => {
      const token = getAccessToken();
      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        return;
      }

      const headers = { Accept: "application/json", Authorization: `Bearer ${token}` };

      try {
        setChargement(true);
        const appels = [
          fetch(`${springUrl}/types-produits`, { headers }),
          fetch(`${springUrl}/types-conditionnements`, { headers }),
          fetch(`${springUrl}/unites`, { headers }),
        ];

        // En mode variante, on recupere le conditionnement et la palette de
        // l'article de depart pour pre-remplir les etapes.
        if (articleBase) {
          appels.push(fetch(`${springUrl}/articles-conditionnements`, { headers }));
          appels.push(fetch(`${springUrl}/palettes-conditionnements`, { headers }));
        }

        const reponses = await Promise.all(appels);
        if (reponses.some((reponse) => !reponse.ok)) {
          throw new Error("Impossible de charger les options du formulaire.");
        }

        const [produits, conditionnements, listeUnites, tousConditionnements, toutesPalettes] =
          await Promise.all(reponses.map((reponse) => reponse.json()));

        setTypesProduit(produits);
        setTypesConditionnement(conditionnements);
        setUnites(listeUnites);

        if (articleBase) {
          const conditionnementBase = (tousConditionnements ?? []).find(
            (conditionnement) => conditionnement.articleId === articleBase.id,
          );
          const paletteBase = conditionnementBase
            ? (toutesPalettes ?? []).find(
                (palette) => palette.articleConditionnementId === conditionnementBase.id,
              )
            : null;

          setDonnees({
            article: {
              ...creerEtatInitial().article,
              nomArticle: proposerNomFamille(articleBase.nomArticle),
              typeProduitId: articleBase.typeProduitId ?? "",
              typeConditionnementId: conditionnementBase?.typeConditionnementId ?? "",
            },
            conditionnement: {
              typeConditionnementId: conditionnementBase?.typeConditionnementId ?? "",
              codeBarres: "",
              quantitePieceStandard: conditionnementBase?.quantitePieceStandard ?? "",
            },
            palette: {
              quantiteMaximale: paletteBase?.quantiteMaximale ?? "",
            },
          });
        }
      } catch (erreur) {
        setError(
          erreur instanceof Error
            ? erreur.message
            : "Impossible de charger les options du formulaire.",
        );
      } finally {
        setChargement(false);
      }
    };

    chargerOptions();
  }, [isOpen, springUrl, articleBase]);

  const changer =
    (section) =>
    ({ target: { name, value } }) => {
      setDonnees((actuel) => ({
        ...actuel,
        [section]: { ...actuel[section], [name]: value },
      }));
      setError("");
    };

  // Retourne un message si l'etape n'est pas valide, sinon une chaine vide.
  const verifierEtape = (numero) => {
    if (numero === 1) {
      const {
        nomArticle,
        codeBar,
        typeProduitId,
        typeConditionnementId,
        contenanceValeur,
        uniteId,
      } = donnees.article;
      if (!nomArticle.trim()) return "Le nom de l'article est obligatoire.";
      if (!codeBar.trim()) return "Le code-barres est obligatoire.";
      if (!typeProduitId) return "Le type de produit est obligatoire.";
      if (!typeConditionnementId) return "Le type de conditionnement est obligatoire.";

      const aValeur = contenanceValeur !== "";
      const aUnite = uniteId !== "";
      if (aValeur !== aUnite) return "La contenance demande une valeur et une unité.";
      if (aValeur && !(Number(contenanceValeur) > 0)) {
        return "La contenance doit être un nombre positif.";
      }
    }

    if (numero === 2) {
      const { typeConditionnementId, quantitePieceStandard } = donnees.conditionnement;
      if (!typeConditionnementId) return "Le type de conditionnement est obligatoire.";
      if (!estEntierPositif(quantitePieceStandard)) {
        return "Le nombre de pièces par unité doit être un entier positif.";
      }
    }

    if (numero === 3) {
      if (!estEntierPositif(donnees.palette.quantiteMaximale)) {
        return "Le nombre d'unités par palette doit être un entier positif.";
      }
    }

    return "";
  };

  const retour = () => {
    setError("");
    setEtape((actuelle) => Math.max(1, actuelle - 1));
  };

  const envoyer = async () => {
    const token = getAccessToken();
    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    const { article, conditionnement, palette } = donnees;

    const corps = {
      article: {
        nomArticle: article.nomArticle.trim(),
        codeBar: article.codeBar.trim(),
        typeProduitId: Number(article.typeProduitId),
        typeConditionnementId: Number(article.typeConditionnementId),
        contenanceValeur:
          article.contenanceValeur !== "" ? Number(article.contenanceValeur) : null,
        uniteId: article.uniteId !== "" ? Number(article.uniteId) : null,
      },
      conditionnement: {
        typeConditionnementId: Number(conditionnement.typeConditionnementId),
        codeBarres: conditionnement.codeBarres.trim(),
        quantitePieceStandard: Number(conditionnement.quantitePieceStandard),
      },
      palette: {
        quantiteMaximale: Number(palette.quantiteMaximale),
      },
    };

    if (articleBase) {
      corps.nomFamille = nomFamille.trim() || null;
    }

    const adresse = articleBase
      ? `${springUrl}/articles/${articleBase.id}/variantes`
      : `${springUrl}/articles/complet`;

    try {
      setEnvoi(true);
      setError("");

      // Partie « data » (JSON) + partie « photo » facultative. Pas de
      // Content-Type a la main : le navigateur ajoute le separateur multipart.
      const formulaire = new FormData();
      formulaire.append(
        "data",
        new Blob([JSON.stringify(corps)], { type: "application/json" }),
      );
      if (photo) {
        formulaire.append("photo", photo);
      }

      const response = await fetch(adresse, {
        method: "POST",
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: formulaire,
      });

      if (!response.ok) {
        throw new Error(
          await lireMessageErreur(response, `Création impossible (${response.status}).`),
        );
      }

      const resultat = await response.json();
      onCreated?.(resultat);
      onClose();
    } catch (erreur) {
      // Rien n'a ete enregistre : l'utilisateur reste sur l'etape 3.
      setError(erreur instanceof Error ? erreur.message : "Impossible de créer l'article.");
    } finally {
      setEnvoi(false);
    }
  };

  const suivant = () => {
    const message = verifierEtape(etape);
    if (message) {
      setError(message);
      return;
    }

    setError("");

    if (etape === ETAPES.length) {
      envoyer();
      return;
    }

    // Le type de conditionnement choisi a l'etape 1 est repris a l'etape 2.
    if (etape === 1 && !donnees.conditionnement.typeConditionnementId) {
      setDonnees((actuel) => ({
        ...actuel,
        conditionnement: {
          ...actuel.conditionnement,
          typeConditionnementId: actuel.article.typeConditionnementId,
        },
      }));
    }

    setEtape(etape + 1);
  };

  const derniereEtape = etape === ETAPES.length;

  const actions = (
    <>
      <Button variant="secondary" onClick={etape === 1 ? onClose : retour} disabled={envoi}>
        {etape === 1 ? "Annuler" : "Retour"}
      </Button>
      <Button onClick={suivant} loading={envoi} disabled={chargement}>
        {derniereEtape ? (articleBase ? "Créer la variante" : "Créer l'article") : "Suivant"}
      </Button>
    </>
  );

  return (
    <Modal
      ouverte={isOpen}
      titre={articleBase ? "Nouvelle variante" : "Nouvel article"}
      onClose={onClose}
      fermetureAutorisee={!envoi}
      actions={actions}
    >
      <form
        className="acm-form"
        onSubmit={(event) => {
          event.preventDefault();
          suivant();
        }}
      >
        <StepperArticle etapes={ETAPES} etapeCourante={etape} />

        {error && (
          <p className="acm-erreur" role="alert">
            {error}
          </p>
        )}

        {etape === 1 && (
          <EtapeIdentite
            valeurs={donnees.article}
            onChange={changer("article")}
            typesProduit={typesProduit}
            typesConditionnement={typesConditionnement}
            unites={unites}
            chargement={chargement}
            desactive={envoi}
            varianteDe={articleBase}
            nomFamille={nomFamille}
            onChangeFamille={(event) => setNomFamille(event.target.value)}
            photo={photo}
            apercuPhoto={apercuPhoto}
            onChoisirPhoto={choisirPhoto}
            onRetirerPhoto={() => setPhoto(null)}
          />
        )}

        {etape === 2 && (
          <EtapeConditionnement
            valeurs={donnees.conditionnement}
            onChange={changer("conditionnement")}
            typesConditionnement={typesConditionnement}
            nomArticle={donnees.article.nomArticle}
            desactive={envoi}
          />
        )}

        {etape === 3 && (
          <EtapePalette
            valeurs={donnees.palette}
            onChange={changer("palette")}
            quantitePieceStandard={donnees.conditionnement.quantitePieceStandard}
            nomArticle={donnees.article.nomArticle}
            desactive={envoi}
          />
        )}
      </form>
    </Modal>
  );
}

export default CreateArticleModal;
