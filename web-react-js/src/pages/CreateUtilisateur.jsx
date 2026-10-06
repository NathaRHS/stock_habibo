import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ArrowLeft, CheckCircle2, Circle, IdCard, Info, Lock } from "lucide-react";
import { getAccessToken } from "../services/authService";
import Button from "../components/Button";
import Sidebar from "../components/Sidebar";
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

  const roleChoisi = roles.find(
    (role) => String(role.id) === String(formulaire.roleId),
  );
  const reglesMotDePasse = [
    { ok: formulaire.password.length >= 8, texte: "Au moins 8 caractères" },
    {
      ok:
        formulaire.password.length > 0 &&
        formulaire.password === formulaire.confirmationMotDePasse,
      texte: "Confirmation identique",
    },
  ];
  const initiales =
    formulaire.username
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((mot) => mot[0].toUpperCase())
      .join("") || "?";

  return (
    <div className="users-page-shell">
      <Sidebar />
      <section className="users-page-workspace">
        <header className="users-page-topbar">
          <p>Administration / Utilisateurs / Nouveau compte</p>
          <div className="users-page-user">
            <span>AR</span>
            <div>
              <strong>Administrateur</strong>
              <small>Responsable entrepôt</small>
            </div>
          </div>
        </header>

        <main className="create-user-page">
          <Link className="create-user-back" to="/users">
            <ArrowLeft size={16} />
            Retour aux utilisateurs
          </Link>
          <header className="create-user-header">
            <span>Administration</span>
            <h1>Créer un compte</h1>
            <p>Ajoutez un opérateur ou un responsable et définissez son rôle.</p>
          </header>

          <div className="create-user-layout">
        <form className="create-user-form" onSubmit={handleSubmit}>
          {error && (
            <p className="create-user-error" role="alert">
              {error}
            </p>
          )}
          <h2 className="create-user-section-title">
            <span className="create-user-section-icon"><IdCard size={17} /></span>
            Identité
          </h2>
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
          </div>
          <h2 className="create-user-section-title">
            <span className="create-user-section-icon"><Lock size={17} /></span>
            Accès
          </h2>
          <div className="create-user-grid">
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
            <Button
              disabled={chargementRoles}
              loading={enregistrement}
              type="submit"
            >
              Créer le compte
            </Button>
          </footer>
        </form>

            <aside className="create-user-aside">
              <section className="create-user-card create-user-preview">
                <div className="create-user-avatar">{initiales}</div>
                <strong>{formulaire.username.trim() || "Nouvel utilisateur"}</strong>
                <small>{formulaire.email.trim() || "adresse@email.com"}</small>
                <dl>
                  <div>
                    <dt>Matricule</dt>
                    <dd>{formulaire.matricule.trim() || "—"}</dd>
                  </div>
                  <div>
                    <dt>Rôle</dt>
                    <dd>{roleChoisi?.name || "—"}</dd>
                  </div>
                </dl>
              </section>

              <section className="create-user-card">
                <h3>Mot de passe</h3>
                <ul className="create-user-rules">
                  {reglesMotDePasse.map((regle) => (
                    <li className={regle.ok ? "is-ok" : ""} key={regle.texte}>
                      {regle.ok ? <CheckCircle2 size={17} /> : <Circle size={17} />}
                      {regle.texte}
                    </li>
                  ))}
                </ul>
              </section>

              <section className="create-user-card create-user-tip">
                <Info size={18} />
                <p>
                  Le rôle détermine les pages accessibles. Il pourra être
                  modifié plus tard par un administrateur.
                </p>
              </section>
            </aside>
          </div>
        </main>
      </section>
    </div>
  );
}

export default CreateUtilisateur;
