import { useEffect, useState } from "react";
import { X } from "lucide-react";
import { getAccessToken } from "../services/authService";
import Button from "./Button";
import "../pages/css/CreateJournalModal.css";

const genererReferenceJournal = () => {
  const maintenant = new Date();
  const date = maintenant.toISOString().slice(0, 10).replaceAll("-", "");
  const heure = maintenant.toTimeString().slice(0, 8).replaceAll(":", "");
  const identifiant = crypto.randomUUID().split("-")[0].toUpperCase();
  return `JM-${date}-${heure}-${identifiant}`;
};

const creerEtatInitial = () => ({
  reference: genererReferenceJournal(),
  nomClient: "",
  fournisseurId: "",
  typeMouvementJournalId: "",
});

export default function CreateJournalModal({ isOpen, onClose, onCreated }) {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [journal, setJournal] = useState(creerEtatInitial);
  const [fichier, setFichier] = useState(null);
  const [fournisseurs, setFournisseurs] = useState([]);
  const [typesMouvement, setTypesMouvement] = useState([]);
  const [error, setError] = useState("");
  const [loadingOptions, setLoadingOptions] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!isOpen) return;
    setJournal(creerEtatInitial());
    setFichier(null);
    setError("");
    const chargerOptions = async () => {
      const token = getAccessToken();
      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        return;
      }
      try {
        setLoadingOptions(true);
        const [fournisseursResponse, typesResponse] = await Promise.all([
          fetch(`${springUrl}/societes`, { headers: { Accept: "application/json", Authorization: `Bearer ${token}` } }),
          fetch(`${springUrl}/types-mouvements-journal`, { headers: { Accept: "application/json", Authorization: `Bearer ${token}` } }),
        ]);
        if (!fournisseursResponse.ok || !typesResponse.ok) throw new Error("Impossible de charger les options du formulaire.");
        setFournisseurs(await fournisseursResponse.json());
        setTypesMouvement(await typesResponse.json());
      } catch (erreur) {
        setError(erreur instanceof Error ? erreur.message : "Impossible de charger les options du formulaire.");
      } finally {
        setLoadingOptions(false);
      }
    };
    chargerOptions();
  }, [isOpen, springUrl]);

  useEffect(() => {
    if (!isOpen) return undefined;
    const fermerAvecEchap = (event) => event.key === "Escape" && onClose();
    document.addEventListener("keydown", fermerAvecEchap);
    return () => document.removeEventListener("keydown", fermerAvecEchap);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  // Le type choisi décide des champs utiles : une sortie n'a pas de fournisseur,
  // une entrée n'a pas de client, un inventaire n'a pas de pièce jointe.
  const typeChoisi = typesMouvement
    .find((type) => String(type.id) === String(journal.typeMouvementJournalId))
    ?.nomTypeMouvement?.toUpperCase();
  const estEntree = typeChoisi === "ENTREE";
  const estSortie = typeChoisi === "SORTIE";
  const estInventaire = typeChoisi === "INVENTAIRE";

  const handleChange = ({ target: { name, value } }) => setJournal((actuel) => ({ ...actuel, [name]: value }));

  // Changer de type vide les champs qui ne servent plus : rien n'est envoyé par erreur.
  const changerType = ({ target: { value } }) => {
    const nom = typesMouvement.find((type) => String(type.id) === value)?.nomTypeMouvement?.toUpperCase();
    setJournal((actuel) => ({
      ...actuel,
      typeMouvementJournalId: value,
      nomClient: nom === "ENTREE" ? "" : actuel.nomClient,
      fournisseurId: nom === "SORTIE" ? "" : actuel.fournisseurId,
    }));
    if (nom === "INVENTAIRE") setFichier(null);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!journal.typeMouvementJournalId) return setError("Le type de mouvement est obligatoire.");
    if (!estInventaire && !fichier) return setError("La pièce jointe est obligatoire.");
    // Une entrée vient d'un fournisseur : seuls ses produits pourront être scannés.
    if (estEntree && !journal.fournisseurId) return setError("Le fournisseur est obligatoire pour une entrée.");
    const token = getAccessToken();
    if (!token) return setError("Votre session a expiré. Reconnectez-vous.");
    try {
      setSubmitting(true);
      setError("");
      let cheminFichier = null;
      if (!estInventaire) {
        const formData = new FormData();
        formData.append("file", fichier);
        const upload = await fetch(`${springUrl}/upload`, { method: "POST", headers: { Authorization: `Bearer ${token}` }, body: formData });
        cheminFichier = await upload.text();
        if (!upload.ok) throw new Error(cheminFichier || `Upload impossible (${upload.status})`);
      }
      const response = await fetch(`${springUrl}/journaux-mouvements`, {
        method: "POST",
        headers: { Accept: "application/json", "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          reference: journal.reference,
          urlPieceJointe: cheminFichier,
          nomClient: estEntree ? null : journal.nomClient.trim() || null,
          fournisseurId: estSortie || !journal.fournisseurId ? null : Number(journal.fournisseurId),
          typeMouvementJournalId: Number(journal.typeMouvementJournalId),
          statutJournalMouvementId: null,
        }),
      });
      if (!response.ok) throw new Error((await response.text()) || `Création impossible (${response.status})`);
      const resultat = await response.json();
      onCreated?.(resultat);
      onClose();
    } catch (erreur) {
      setError(erreur instanceof Error ? erreur.message : "Impossible de créer le journal.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="journal-modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="journal-modal" role="dialog" aria-modal="true" aria-labelledby="create-journal-title">
        <header className="journal-modal-header">
          <div><span className="journal-modal-kicker">Nouvelle opération</span><h2 id="create-journal-title">Créer un journal</h2><p>Déclarez un nouveau mouvement dans l'entrepôt.</p></div>
          <button className="journal-modal-close" onClick={onClose} type="button" aria-label="Fermer"><X size={18} /></button>
        </header>
        <form className="journal-modal-form" onSubmit={handleSubmit}>
          <label>Référence générée automatiquement<input name="reference" value={journal.reference} readOnly /></label>
          <div className="journal-modal-grid">
            <label>Client<input name="nomClient" value={journal.nomClient} onChange={handleChange} placeholder={estEntree ? "Non utilisé pour une entrée" : "Nom du client"} disabled={submitting || estEntree} /></label>
            <label>Fournisseur<select name="fournisseurId" value={journal.fournisseurId} onChange={handleChange} disabled={loadingOptions || submitting || estSortie} required={estEntree}><option value="">{estSortie ? "Non utilisé pour une sortie" : estEntree ? "Choisissez un fournisseur" : "Aucun fournisseur"}</option>{fournisseurs.map((fournisseur) => <option key={fournisseur.id} value={fournisseur.id}>{fournisseur.nomSociete}</option>)}</select></label>
          </div>
          <label>Type de mouvement<select name="typeMouvementJournalId" value={journal.typeMouvementJournalId} onChange={changerType} disabled={loadingOptions || submitting} required><option value="" disabled>{loadingOptions ? "Chargement…" : "Choisissez un type de mouvement"}</option>{typesMouvement.map((type) => <option key={type.id} value={type.id}>{type.nomTypeMouvement} ({type.sens === 1 ? "Entrée" : "Sortie"})</option>)}</select></label>
          {!estInventaire && <label className="journal-file-field">Pièce jointe du mouvement<input type="file" name="file" onChange={(event) => { setFichier(event.target.files?.[0] ?? null); setError(""); }} disabled={submitting} required /><small>{fichier ? fichier.name : "PDF, image ou document client"}</small></label>}
          {error && <p className="journal-modal-error" role="alert">{error}</p>}
          <footer className="journal-modal-actions"><button className="journal-modal-cancel" onClick={onClose} type="button">Annuler</button><Button type="submit" loading={submitting} disabled={loadingOptions}>Créer le journal</Button></footer>
        </form>
      </section>
    </div>
  );
}
