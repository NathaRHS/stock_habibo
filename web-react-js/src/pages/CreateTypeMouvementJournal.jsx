import { useState } from "react";
import { getAccessToken } from "../services/authService";

const initialTypeMouvementJournalState = {
  nomTypeMouvement: "",
  sens: "",
};

function CreateTypeMouvementJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [typeMouvementJournal, setTypeMouvementJournal] = useState(
    initialTypeMouvementJournalState,
  );
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const creerTypeMouvementJournal = async (objet) => {
    const token = getAccessToken();

    if (!token) {
      throw new Error("Votre session a expiré. Reconnectez-vous.");
    }

    const response = await fetch(`${springUrl}/types-mouvements-journal`, {
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
        message || `Création impossible (${response.status})`,
      );
    }

    return response.json();
  };

  const handleChange = (event) => {
    const { name, value } = event.target;

    setTypeMouvementJournal((typeActuel) => ({
      ...typeActuel,
      [name]: value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!typeMouvementJournal.nomTypeMouvement.trim()) {
      setError("Le nom du type de mouvement est obligatoire.");
      return;
    }

    if (
      typeMouvementJournal.sens !== "1" &&
      typeMouvementJournal.sens !== "-1"
    ) {
      setError("Le sens du mouvement est obligatoire.");
      return;
    }

    try {
      setSubmitting(true);
      setError("");

      await creerTypeMouvementJournal({
        nomTypeMouvement: typeMouvementJournal.nomTypeMouvement.trim(),
        sens: Number(typeMouvementJournal.sens),
      });

      setTypeMouvementJournal(initialTypeMouvementJournalState);
      alert("Type de mouvement journal ajouté avec succès !");
    } catch (erreur) {
      setError(
        erreur instanceof Error
          ? erreur.message
          : "Impossible de créer le type de mouvement journal.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="container-create-type-mouvement-journal">
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="nomTypeMouvement"
          value={typeMouvementJournal.nomTypeMouvement}
          onChange={handleChange}
          placeholder="Nom du type de mouvement"
          disabled={submitting}
          required
        />

        <select
          name="sens"
          value={typeMouvementJournal.sens}
          onChange={handleChange}
          disabled={submitting}
          required
        >
          <option value="" disabled>
            Choisissez le sens du mouvement
          </option>
          <option value="1">Entrée (+1)</option>
          <option value="-1">Sortie (-1)</option>
        </select>

        <button type="submit" disabled={submitting}>
          {submitting
            ? "Ajout en cours..."
            : "Ajouter un type de mouvement journal"}
        </button>

        {error && <p role="alert">{error}</p>}
      </form>
    </div>
  );
}

export default CreateTypeMouvementJournal;
