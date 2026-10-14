import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
import { clearAuthSession, setAuthSession } from "../services/authService";
import Footer from "../components/Footer";
import imageConnexion from "../assets/images/slide_hp_17.jpg";
import "./css/Login.css";

function Login() {
  const [matricule, setMatricule] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const handleLogin = async (event) => {
    event.preventDefault();
    setError("");

    if (!matricule.trim() || !password) {
      setError("Veuillez renseigner le matricule et le mot de passe.");
      return;
    }

    setIsLoading(true);

    try {
      const response = await fetch(`${springUrl}/user/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ matricule: matricule.trim(), password }),
      });

      if (!response.ok) {
        throw new Error("Matricule ou mot de passe incorrect.");
      }

      const loginResponse = await response.json();
      if (!loginResponse.token) {
        throw new Error("Le serveur n’a pas renvoyé de token.");
      }

      setAuthSession(loginResponse);
      const role = loginResponse?.user?.role;
      if (role === "ADMIN") {
        navigate("/accueil");
      } else if (role === "AUDITEUR") {
        // L'auditeur (rôle à part de l'inventoriste, qui compte sur mobile)
        // consulte les inventaires : il arrive directement sur leur liste.
        navigate("/inventaires/isAdmin=false");
      } else {
        // Pas de session pour un rôle qui n'a pas accès au site.
        clearAuthSession();
        setError("Votre rôle n'est pas autorisé à consulter ce site.");
      }
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Impossible de se connecter au serveur.",
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-ecran">
      <main className="login-page">
        <section className="login-formulaire">
          <button
            aria-label="Retour"
            className="login-retour"
            onClick={() => navigate(-1)}
            type="button"
          >
            <svg viewBox="0 0 46 14" aria-hidden="true">
              <path
                d="M45 7H2M7.5 1.5 1.5 7l6 5.5"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.6"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>

          <h1>Connexion à votre compte</h1>
          <p className="login-sous-titre">
            Veuillez entrer vos identifiants relatifs a Habibo.
          </p>

          <form className="login-champs" onSubmit={handleLogin}>
            <label className="login-etiquette" htmlFor="matricule">
              Numero matricule
            </label>
            <input
              id="matricule"
              name="matricule"
              type="text"
              placeholder="Numero matricule"
              autoComplete="username"
              value={matricule}
              onChange={(event) => setMatricule(event.target.value)}
            />

            <label className="login-etiquette" htmlFor="password">
              Mot de passe
            </label>
            <div className="login-mot-de-passe">
              <input
                id="password"
                name="password"
                type={showPassword ? "text" : "password"}
                placeholder="Mot de passe"
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
              <button
                aria-label={
                  showPassword
                    ? "Masquer le mot de passe"
                    : "Afficher le mot de passe"
                }
                aria-pressed={showPassword}
                className="login-oeil"
                onClick={() => setShowPassword((visible) => !visible)}
                type="button"
              >
                {showPassword ? (
                  <EyeOff aria-hidden="true" size={18} />
                ) : (
                  <Eye aria-hidden="true" size={18} />
                )}
              </button>
            </div>

            {error && (
              <p className="login-error" role="alert">
                {error}
              </p>
            )}

            <button className="login-bouton" disabled={isLoading} type="submit">
              {isLoading ? "Connexion…" : "S’identifier"}
            </button>
          </form>

          <p className="login-aide">
            Pour toute cause d’oubli des identifiants il est exclusivement
            recommandé d’informer vos administrateurs,{" "}
            <a href="#ticket">envoyer un ticket</a>
          </p>
        </section>

        <aside
          className="login-visuel"
          style={{ backgroundImage: `url(${imageConnexion})` }}
        >
          <div className="login-visuel-texte">
            <p className="login-visuel-titre">Le meilleur pour vous</p>
            <p className="login-visuel-detail">
              Plus de fluidité, plus de visibilité, plus de maîtrise.
            </p>
          </div>
        </aside>
      </main>

      <Footer />
    </div>
  );
}

export default Login;
