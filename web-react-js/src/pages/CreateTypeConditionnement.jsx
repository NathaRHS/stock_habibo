import { useState } from "react";
import { getAccessToken } from "../services/authService";

const initialTypeConditionnementState = {
  nomConditionnement: "",
};

function CreateTypeConditionnement() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [typeConditionnement, setTypeConditionnement] = useState(
    initialTypeConditionnementState,
  );
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const creerTypeConditionnement = async (objet) => {
    const token = getAccessToken();

    const response = await fetch(`${springUrl}/types-conditionnements`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(objet),
    });

    if (!response.ok) {
      
    }

    return response.json();
  };

  const handleChange = (event) => {
    const { name, value } = event.target;

    setTypeConditionnement((conditionnementActuel) => ({
      ...conditionnementActuel,
      [name]: value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!typeConditionnement.nomConditionnement.trim()) {
      setError("Le nom du conditionnement est obligatoire.");
      return;
    }

    try {
      setSubmitting(true);
      setError("");

      await creerTypeConditionnement({
        ...typeConditionnement,
        nomConditionnement:
          typeConditionnement.nomConditionnement.trim(),
      });

      setTypeConditionnement(initialTypeConditionnementState);
    } catch (erreur) {
      setError(erreur.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="container-create-conditionnement">
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="nomConditionnement"
          value={typeConditionnement.nomConditionnement}
          onChange={handleChange}
          placeholder="Nom du conditionnement"
          disabled={submitting}
        />

        <button type="submit" disabled={submitting}>
          {submitting
            ? "Ajout en cours..."
            : "Ajouter un type de conditionnement"}
        </button>

        {error && <p role="alert">{error}</p>}
      </form>
    </div>
  );
}

export default CreateTypeConditionnement;