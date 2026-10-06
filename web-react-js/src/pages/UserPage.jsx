import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Activity, ArrowLeft, IdCard, ShieldCheck } from "lucide-react";
import Sidebar from "../components/Sidebar";
import { getAccessToken } from "../services/authService";
import "./css/UserPage.css";

function UserPage() {
  const { id } = useParams();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const token = getAccessToken();
  const [resultat, setResultat] = useState(null);
  const userId = Number(id);
  const idValide = Number.isInteger(userId) && userId > 0;

  useEffect(() => {
    const controller = new AbortController();
    if (!idValide) return () => controller.abort();

    async function chargerUtilisateur() {
      try {
        const response = await fetch(
          `${springUrl}/user/nombreOperations/${userId}`,
          {
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
            signal: controller.signal,
          },
        );

        if (!response.ok) {
          throw new Error(`Impossible de charger l'utilisateur (${response.status}).`);
        }

        const data = await response.json();
        if (!controller.signal.aborted) {
          setResultat({ id, data, error: "" });
        }
      } catch (err) {
        if (err.name !== "AbortError" && !controller.signal.aborted) {
          setResultat({ id, data: null, error: err.message });
        }
      }
    }

    chargerUtilisateur();
    return () => controller.abort();
  }, [id, idValide, springUrl, token, userId]);

  const resultatActuel = resultat?.id === id ? resultat : null;
  const userInfo = resultatActuel?.data;
  const loading = idValide && !resultatActuel;
  const error = idValide ? resultatActuel?.error : "Identifiant utilisateur invalide.";
  const operations = userInfo?.operations ?? [];
  const totalOperations = operations.reduce(
    (total, operation) => total + (operation.nombreOperations ?? 0),
    0,
  );
  const initiales = userInfo?.nom?.trim().slice(0, 2).toUpperCase() || "U";
  const roleId = userInfo?.RoleId ?? userInfo?.roleId;

  return (
    <div className="user-page-shell">
      <Sidebar />
      <main className="user-page-content">
        <header className="user-page-header">
          <div>
            <Link className="user-page-back" to="/users">
              <ArrowLeft size={16} aria-hidden="true" /> Utilisateurs
            </Link>
            <h1>Profil utilisateur</h1>
            <p>Identité et activité dans l'entrepôt</p>
          </div>
          <span className="user-page-header-label">WMS · ÉQUIPE</span>
        </header>

        {loading && (
          <div className="user-page-message" role="status">
            Chargement du profil…
          </div>
        )}

        {!loading && error && (
          <div className="user-page-message user-page-message--error" role="alert">
            {error}
          </div>
        )}

        {!loading && userInfo && (
          <div className="user-page-grid">
            <section className="user-profile-card" aria-label="Informations utilisateur">
              <div className="user-profile-top">
                <div className="user-profile-avatar" aria-hidden="true">{initiales}</div>
                <div className="user-profile-identity">
                  <span className="user-page-kicker">FICHE UTILISATEUR</span>
                  <h2>{userInfo.nom}</h2>
                  <span className="user-profile-role">
                    <ShieldCheck size={15} aria-hidden="true" />
                    {userInfo.nomRole}
                  </span>
                </div>
              </div>
              <div className="user-profile-details">
                <div>
                  <span>Matricule</span>
                  <strong><IdCard size={17} aria-hidden="true" />{userInfo.matricule}</strong>
                </div>
                <div>
                  <span>Rôle dans l'application</span>
                  <strong>{userInfo.nomRole}</strong>
                </div>
              </div>
            </section>

            <aside className="user-summary-card" aria-label="Résumé de l'activité">
              <span className="user-summary-icon"><Activity size={20} aria-hidden="true" /></span>
              <span className="user-summary-label">Participations enregistrées</span>
              <strong>{totalOperations}</strong>
              <p>Réparties sur {operations.length} type{operations.length > 1 ? "s" : ""} d'opération.</p>
            </aside>

            <section className="user-operations-card" aria-labelledby="operations-title">
              <div className="user-operations-heading">
                <div>
                  <span className="user-page-kicker">ACTIVITÉ DANS L'ENTREPÔT</span>
                  <h2 id="operations-title">Opérations suivies</h2>
                </div>
                <span className="user-operations-count">
                  {operations.length} type{operations.length > 1 ? "s" : ""}
                </span>
              </div>

              {operations.length > 0 ? (
                <div className="user-operations-list">
                  {operations.map((operation, index) => (
                    <div className="user-operation-row" key={operation.nomOperation}>
                      <span className="user-operation-index" aria-hidden="true">{index + 1}</span>
                      <div>
                        <strong>{operation.nomOperation}</strong>
                        <small>Journaux auxquels l'utilisateur a participé</small>
                      </div>
                      <span className="user-operation-value">{operation.nombreOperations}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="user-operations-empty">
                  Aucune participation enregistrée pour cet utilisateur.
                </p>
              )}
              <p className="user-operations-note">
                Les participations en cours et terminées sont incluses.
              </p>
            </section>

            <aside className="user-details-card" aria-label="Repères du profil">
              <span className="user-page-kicker">REPÈRES</span>
              <h2>Informations du compte</h2>
              <dl>
                <div><dt>Nom</dt><dd>{userInfo.nom}</dd></div>
                <div><dt>Matricule</dt><dd>{userInfo.matricule}</dd></div>
                <div><dt>Rôle</dt><dd>{userInfo.nomRole}</dd></div>
                {roleId != null && <div><dt>ID du rôle</dt><dd>#{roleId}</dd></div>}
              </dl>
            </aside>
          </div>
        )}
      </main>
    </div>
  );
}

export default UserPage;
