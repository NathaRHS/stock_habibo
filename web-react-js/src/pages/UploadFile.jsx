import { useState } from "react";
import { getAccessToken } from "../services/authService";

function UploadFile() {
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const [file, setFile] = useState(null);
  const [error, setError] = useState("");
  const [cheminFichier, setCheminFichier] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (event) => {
    const fichierSelectionne = event.target.files?.[0] ?? null;

    setFile(fichierSelectionne);
    setError("");
    setCheminFichier("");
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!file) {
      setError("Veuillez sélectionner un fichier.");
      return;
    }

    const token = getAccessToken();

    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    const formData = new FormData();
    formData.append("file", file);

    try {
      setSubmitting(true);
      setError("");
      setCheminFichier("");

      const response = await fetch(`${springUrl}/upload`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
        },
        body: formData,
      });

      const message = await response.text();

      if (!response.ok) {
        throw new Error(
          message || `Envoi du fichier impossible (${response.status})`,
        );
      }

      setCheminFichier(message);
      setFile(null);
      event.target.reset();
    } catch (erreur) {
      setError(
        erreur instanceof Error
          ? erreur.message
          : "Impossible d'envoyer le fichier.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="container-upload-file">
      <form onSubmit={handleSubmit}>
        <input
          type="file"
          name="file"
          onChange={handleChange}
          disabled={submitting}
          required
        />

        <button type="submit" disabled={!file || submitting}>
          {submitting ? "Envoi en cours..." : "Envoyer le fichier"}
        </button>

        {error && <p role="alert">{error}</p>}

        {cheminFichier && (
          <p role="status">
            Fichier enregistré : <strong>{cheminFichier}</strong>
          </p>
        )}
      </form>
    </div>
  );
}

export default UploadFile;
