import { useState } from "react";
import { getAccessToken } from "../services/authService";
import Button from "../components/Button";
import Panel from "../components/Panel";

const initialTypeConditionnementState = {
  nomConditionnement: "",
};

function CreateTypeConditionnement({ onCreated }) {
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
      const message = await response.text();
      throw new Error(message || `Création impossible (${response.status})`);
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

      const cree = await creerTypeConditionnement({
        ...typeConditionnement,
        nomConditionnement: typeConditionnement.nomConditionnement.trim(),
      });

      setTypeConditionnement(initialTypeConditionnementState);
      onCreated?.(cree);
    } catch (erreur) {
      setError(erreur.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Panel title="Nouveau type">
      <form className="layout-form" onSubmit={handleSubmit}>
        {error && (
          <p className="layout-message layout-message--error" role="alert">
            {error}
          </p>
        )}
        <div className="layout-form-grid layout-form-inline">
          <label>
            Nom du type
            <input
              type="text"
              name="nomConditionnement"
              value={typeConditionnement.nomConditionnement}
              onChange={handleChange}
              placeholder="Ex. Carton, Sachet, Fût…"
              disabled={submitting}
            />
          </label>
          <Button type="submit" loading={submitting}>
            Ajouter
          </Button>
        </div>
      </form>
    </Panel>
  );
}

export default CreateTypeConditionnement;
