import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

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

function CreateJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [journal, setJournal] = useState(creerEtatInitial);
  const [fichier, setFichier] = useState(null);
  const [fournisseurs, setFournisseurs] = useState([]);
  const [typesMouvement, setTypesMouvement] = useState([]);
  const [error, setError] = useState("");
  const [loadingOptions, setLoadingOptions] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [journalCree, setJournalCree] = useState(null);

  useEffect(() => {
    const chargerOptions = async () => {
      const token = getAccessToken();

      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        setLoadingOptions(false);
        return;
      }

      try {
        setError("");

        const [fournisseursResponse, typesMouvementResponse] =
          await Promise.all([
            fetch(`${springUrl}/societes`, {
              headers: {
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }),
            fetch(`${springUrl}/types-mouvements-journal`, {
              headers: {
                Accept: "application/json",
                Authorization: `Bearer ${token}`,
              },
            }),
          ]);

        if (!fournisseursResponse.ok) {
          throw new Error("Impossible de charger les fournisseurs");
        }

        if (!typesMouvementResponse.ok) {
          throw new Error("Impossible de charger les types de mouvement");
        }

        const [fournisseursData, typesMouvementData] = await Promise.all([
          fournisseursResponse.json(),
          typesMouvementResponse.json(),
        ]);

        setFournisseurs(fournisseursData);
        setTypesMouvement(typesMouvementData);
      } catch (erreur) {
        setError(
          erreur instanceof Error
            ? erreur.message
            : "Impossible de charger les options du formulaire.",
        );
      } finally {
        setLoadingOptions(false);
      }
    };

    chargerOptions();
  }, [springUrl]);

  const uploaderFichier = async (token) => {
    const formData = new FormData();
    formData.append("file", fichier);

    const response = await fetch(`${springUrl}/upload`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    });

    const cheminFichier = await response.text();

    if (!response.ok) {
      throw new Error(
        cheminFichier || `Upload impossible (${response.status})`,
      );
    }

    return cheminFichier;
  };

  const creerJournal = async (objet, token) => {
    const response = await fetch(`${springUrl}/journaux-mouvements`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(objet),
    });

    if (!response.ok) {
      const message = await response.text();
      throw new Error(
        message || `Création du journal impossible (${response.status})`,
      );
    }

    return response.json();
  };

  const handleChange = (event) => {
    const { name, value } = event.target;

    setJournal((journalActuel) => ({
      ...journalActuel,
      [name]: value,
    }));
  };

  const handleFileChange = (event) => {
    setFichier(event.target.files?.[0] ?? null);
    setError("");
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!journal.typeMouvementJournalId) {
      setError("Le type de mouvement est obligatoire.");
      return;
    }

    if (!fichier) {
      setError("La pièce jointe est obligatoire.");
      return;
    }

    const token = getAccessToken();

    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setSubmitting(true);
      setError("");
      setJournalCree(null);

      const urlPieceJointe = await uploaderFichier(token);

      const resultat = await creerJournal(
        {
          reference: journal.reference,
          urlPieceJointe,
          nomClient: journal.nomClient.trim() || null,
          fournisseurId: journal.fournisseurId
            ? Number(journal.fournisseurId)
            : null,
          typeMouvementJournalId: Number(
            journal.typeMouvementJournalId,
          ),
          statutJournalMouvementId: null,
        },
        token,
      );

      setJournalCree(resultat);
      setJournal(creerEtatInitial());
      setFichier(null);
      event.target.reset();
    } catch (erreur) {
      setError(
        erreur instanceof Error
          ? erreur.message
          : "Impossible de créer le journal.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="container-create-journal">
      <form onSubmit={handleSubmit}>
        <label htmlFor="reference">Référence générée automatiquement</label>
        <input
          id="reference"
          type="text"
          name="reference"
          value={journal.reference}
          readOnly
        />

        <input
          type="text"
          name="nomClient"
          value={journal.nomClient}
          onChange={handleChange}
          placeholder="Nom du client"
          disabled={submitting}
        />

        <select
          name="fournisseurId"
          value={journal.fournisseurId}
          onChange={handleChange}
          disabled={loadingOptions || submitting}
        >
          <option value="">Aucun fournisseur</option>
          {fournisseurs.map((fournisseur) => (
            <option key={fournisseur.id} value={fournisseur.id}>
              {fournisseur.nomSociete}
            </option>
          ))}
        </select>

        <select
          name="typeMouvementJournalId"
          value={journal.typeMouvementJournalId}
          onChange={handleChange}
          disabled={loadingOptions || submitting}
          required
        >
          <option value="" disabled>
            Choisissez un type de mouvement
          </option>
          {typesMouvement.map((type) => (
            <option key={type.id} value={type.id}>
              {type.nomTypeMouvement} ({type.sens === 1 ? "Entrée" : "Sortie"})
            </option>
          ))}
        </select>

        <input
          type="file"
          name="file"
          onChange={handleFileChange}
          disabled={submitting}
          required
        />

        <button
          type="submit"
          disabled={loadingOptions || submitting}
        >
          {submitting ? "Création en cours..." : "Créer le journal"}
        </button>

        {error && <p role="alert">{error}</p>}

        {journalCree && (
          <p role="status">
            Journal {journalCree.reference} créé avec succès. Pièce jointe :{" "}
            {journalCree.urlPieceJointe}
          </p>
        )}
      </form>
    </div>
  );
}

export default CreateJournal;
