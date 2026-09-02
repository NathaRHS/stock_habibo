import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { setAuthSession } from "../services/authService";
import Button from "../components/Button";
import "./css/Login.css";

function Login() {
  const [matricule, setMatricule] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
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
      console.log("LOGIN RESPONSE" + loginResponse.token);
      if (!loginResponse.token) {
        throw new Error("Le serveur n’a pas renvoyé de token.");
      }

      setAuthSession(loginResponse);
      navigate("/accueil");
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
    <main className="login-page">
      <form className="login-card" onSubmit={handleLogin}>
        <div className="login-brand" aria-hidden="true">
          H
        </div>
        <h1>Connexion</h1>
        <p className="login-subtitle">
          Accédez à votre espace Warehouse Management System
        </p>

        <label htmlFor="matricule">Matricule</label>
        <input
          id="matricule"
          name="matricule"
          type="text"
          placeholder="Votre matricule"
          autoComplete="username"
          value={matricule}
          onChange={(event) => setMatricule(event.target.value)}
        />

        <label htmlFor="password">Mot de passe</label>
        <input
          id="password"
          name="password"
          type="password"
          placeholder="Votre mot de passe"
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />

        {error && (
          <p className="login-error" role="alert">
            {error}
          </p>
        )}
        <Button type="submit" loading={isLoading} fullWidth>
          Se connecter
        </Button>
      </form>
    </main>
  );
}

export default Login;
