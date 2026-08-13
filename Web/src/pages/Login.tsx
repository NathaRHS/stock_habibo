import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

type UserResponse = {
  id: number;
  username: string;
  matricule: string;
  email: string;
  role: string;
};

function Login() {
  const [matricule, setMatricule] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const navigate = useNavigate();
  const springUrl = import.meta.env.VITE_SPRING_URL;

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
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
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          matricule: matricule.trim(),
          password,
        }),
      });

      if (!response.ok) {
        throw new Error("Matricule ou mot de passe incorrect.");
      }

      const user: UserResponse = await response.json();
      sessionStorage.setItem("user", JSON.stringify(user));
      navigate("/");
    } catch (requestError) {
      const message =
        requestError instanceof Error
          ? requestError.message
          : "Impossible de se connecter au serveur.";
      setError(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main>
      <form onSubmit={handleLogin}>
        <h1>Connexion</h1>

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

        {error && <p role="alert">{error}</p>}

        <button type="submit" disabled={isLoading}>
          {isLoading ? "Connexion..." : "Se connecter"}
        </button>
      </form>
    </main>
  );
}

export default Login;
