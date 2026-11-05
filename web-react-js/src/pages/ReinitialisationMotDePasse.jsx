import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Copy, Eye, EyeOff, RefreshCw } from "lucide-react";
import PageLayout from "../components/PageLayout";
import Button from "../components/Button";
import { requeteJson } from "../services/affectationStockService";
import "./css/ReinitialisationMotDePasse.css";

const springUrl = import.meta.env.VITE_SPRING_URL;

// Sans les lettres et chiffres qu'on confond (0/O, 1/l/I) : plus facile à dicter.
const CARACTERES = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";

// Mot de passe de 10 caractères tiré au hasard.
function genererMotDePasse() {
  const tirages = new Uint32Array(10);
  crypto.getRandomValues(tirages);

  let motDePasse = "";
  for (const tirage of tirages) {
    motDePasse += CARACTERES[tirage % CARACTERES.length];
  }
  return motDePasse;
}

function ReinitialisationMotDePasse() {
  // L'identifiant de l'utilisateur vient de l'adresse : /users/reinitialisation/12
  const { id } = useParams();

  const [utilisateur, setUtilisateur] = useState(null);
  const [motDePasse, setMotDePasse] = useState(genererMotDePasse);
  const [afficher, setAfficher] = useState(true);
  const [termine, setTermine] = useState(false);
  const [enCours, setEnCours] = useState(false);
  const [message, setMessage] = useState("");
  const [erreur, setErreur] = useState("");

  // On cherche la personne dans la liste des utilisateurs.
  useEffect(() => {
    async function chargerUtilisateur() {
      try {
        const liste = await requeteJson(`${springUrl}/user`);
        const trouve = liste.find((personne) => String(personne.id) === id);
        if (trouve) {
          setUtilisateur(trouve);
        } else {
          setErreur("Utilisateur introuvable.");
        }
      } catch (e) {
        setErreur(e.message);
      }
    }
    chargerUtilisateur();
  }, [id]);

  async function copier() {
    await navigator.clipboard.writeText(motDePasse);
    setMessage("Mot de passe copié.");
  }

  async function reinitialiser(event) {
    event.preventDefault();
    setMessage("");
    setErreur("");

    if (motDePasse.length < 6) {
      setErreur("Le mot de passe doit contenir au moins 6 caractères.");
      return;
    }

    setEnCours(true);
    try {
      await requeteJson(`${springUrl}/user/${id}/mot-de-passe`, {
        method: "PUT",
        body: JSON.stringify({ nouveauMotDePasse: motDePasse }),
      });
      setTermine(true);
    } catch (e) {
      setErreur(e.message);
    } finally {
      setEnCours(false);
    }
  }

  return (
    <PageLayout
      breadcrumb="Administration / Utilisateurs / Réinitialisation"
      kicker="Administration"
      title="Réinitialiser un mot de passe"
      description="Donnez ce nouveau mot de passe à la personne, par exemple de vive voix."
    >
      {erreur && (
        <p className="layout-message layout-message--error" role="alert">
          {erreur}
        </p>
      )}
      {message && <p className="layout-message layout-message--info">{message}</p>}

      {utilisateur && (
        <section className="layout-panel">
          <header className="layout-panel-header">
            <div>
              <h2>{utilisateur.username}</h2>
              <p>
                Matricule {utilisateur.matricule} · {utilisateur.role}
              </p>
            </div>
          </header>

          {termine ? (
            <div className="reinit-contenu">
              <p className="layout-message layout-message--success">
                Mot de passe réinitialisé. Communiquez-le maintenant à {utilisateur.username}.
              </p>
              <p className="reinit-resultat">{motDePasse}</p>
              <p className="reinit-aide">
                Il ne sera plus affiché une fois cette page quittée.
              </p>
            </div>
          ) : (
            <form className="reinit-contenu" onSubmit={reinitialiser}>
              <label htmlFor="nouveau-mot-de-passe">Nouveau mot de passe</label>

              <div className="reinit-ligne">
                <input
                  id="nouveau-mot-de-passe"
                  type={afficher ? "text" : "password"}
                  value={motDePasse}
                  onChange={(e) => setMotDePasse(e.target.value)}
                />
                <button
                  type="button"
                  title="Afficher ou masquer"
                  onClick={() => setAfficher(!afficher)}
                >
                  {afficher ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button type="button" title="Copier" onClick={copier}>
                  <Copy size={16} />
                </button>
                <button
                  type="button"
                  title="Générer un autre mot de passe"
                  onClick={() => setMotDePasse(genererMotDePasse())}
                >
                  <RefreshCw size={16} />
                </button>
              </div>

              <p className="reinit-aide">
                Un mot de passe a été généré pour vous. Vous pouvez le modifier (6 caractères au minimum).
              </p>

              <div className="reinit-actions">
                <Button type="submit" loading={enCours}>
                  Réinitialiser le mot de passe
                </Button>
              </div>
            </form>
          )}
        </section>
      )}
    </PageLayout>
  );
}

export default ReinitialisationMotDePasse;
