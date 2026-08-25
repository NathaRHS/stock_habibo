import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { getAccessToken } from "../services/authService";
import "./css/CreateUtilisateur.css";

const formulaireInitial = {
  username: "",
  matricule: "",
  email: "",
  password: "",
  confirmationMotDePasse: "",
  roleId: "",
};

function CreateUtilisateur() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const navigate = useNavigate();
  const [formulaire, setFormulaire] = useState(formulaireInitial);
  const [roles, setRoles] = useState([]);
  const [chargementRoles, setChargementRoles] = useState(true);
  const [enregistrement, setEnregistrement] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const controller = new AbortController();

    async function chargerRoles() {
      const token = getAccessToken();
      if (!token) {
        setError("Votre session a expiré. Reconnectez-vous.");
        setChargementRoles(false);
        return;
      }
      try {
        const response = await fetch(`${springUrl}/roles/showRoles`, {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error(
            `Impossible de charger les rôles (${response.status}).`,
          );
        }
        const data = await response.json();
        setRoles(Array.isArray(data) ? data : []);
      } catch (requestError) {
        if (requestError.name !== "AbortError") {
          setError(requestError.message || "Impossible de charger les rôles.");
        }
      } finally {
        if (!controller.signal.aborted) setChargementRoles(false);
      }
    }

    chargerRoles();
    return () => controller.abort();
  }, [springUrl]);

  function handleChange(event) {
    const { name, value } = event.target;
    setFormulaire((actuel) => ({ ...actuel, [name]: value }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");

    if (formulaire.password.length < 8) {
      setError("Le mot de passe doit contenir au moins 8 caractères.");
      return;
    }
    if (formulaire.password !== formulaire.confirmationMotDePasse) {
      setError("Les deux mots de passe ne correspondent pas.");
      return;
    }

    const token = getAccessToken();
    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setEnregistrement(true);
      const response = await fetch(`${springUrl}/user/creerCompte`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          username: formulaire.username.trim(),
          matricule: formulaire.matricule.trim(),
          email: formulaire.email.trim(),
          password: formulaire.password,
          roleId: Number(formulaire.roleId),
        }),
      });

      if (!response.ok) {
        let message = `Création impossible (${response.status}).`;
        try {
          const body = await response.json();
          message = body.detail || body.message || message;
        } catch {
          // Le message HTTP générique est conservé.
        }
        throw new Error(message);
      }

      navigate("/users", {
        replace: true,
        state: { success: "Le compte utilisateur a été créé." },
      });
    } catch (requestError) {
      setError(requestError.message || "Impossible de créer le compte.");
    } finally {
      setEnregistrement(false);
    }
  }

  return (
    <main className="create-user-page">
      <div className="create-user-shell">
        <Link className="create-user-back" to="/users">
          ← Retour aux utilisateurs
        </Link>
        <header className="create-user-header">
          <span>Administration</span>
          <h1>Créer un compte</h1>
          <p>Ajoutez un opérateur ou un responsable et définissez son rôle.</p>
        </header>

        <form className="create-user-form" onSubmit={handleSubmit}>
          {error && (
            <p className="create-user-error" role="alert">
              {error}
            </p>
          )}
          <div className="create-user-grid">
            <label>
              Nom d’utilisateur
              <input
                autoComplete="name"
                disabled={enregistrement}
                name="username"
                onChange={handleChange}
                required
                type="text"
                value={formulaire.username}
              />
            </label>
            <label>
              Matricule
              <input
                autoComplete="off"
                disabled={enregistrement}
                name="matricule"
                onChange={handleChange}
                required
                type="text"
                value={formulaire.matricule}
              />
            </label>
            <label className="create-user-wide">
              Adresse email
              <input
                autoComplete="email"
                disabled={enregistrement}
                name="email"
                onChange={handleChange}
                required
                type="email"
                value={formulaire.email}
              />
            </label>
            <label className="create-user-wide">
              Rôle
              <select
                disabled={chargementRoles || enregistrement}
                name="roleId"
                onChange={handleChange}
                required
                value={formulaire.roleId}
              >
                <option value="">
                  {chargementRoles
                    ? "Chargement des rôles…"
                    : "Sélectionnez un rôle"}
                </option>
                {roles.map((role) => (
                  <option key={role.id} value={role.id}>
                    {role.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Mot de passe
              <input
                autoComplete="new-password"
                disabled={enregistrement}
                minLength={8}
                name="password"
                onChange={handleChange}
                required
                type="password"
                value={formulaire.password}
              />
            </label>
            <label>
              Confirmer le mot de passe
              <input
                autoComplete="new-password"
                disabled={enregistrement}
                minLength={8}
                name="confirmationMotDePasse"
                onChange={handleChange}
                required
                type="password"
                value={formulaire.confirmationMotDePasse}
              />
            </label>
          </div>
          <footer className="create-user-actions">
            <Link className="create-user-cancel" to="/users">
              Annuler
            </Link>
            <button disabled={chargementRoles || enregistrement} type="submit">
              {enregistrement ? "Création en cours…" : "Créer le compte"}
            </button>
          </footer>
        </form>
      </div>
    </main>
  );
}

export default CreateUtilisateur;
