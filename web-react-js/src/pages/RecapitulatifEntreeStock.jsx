import { useLocation, useNavigate, useParams } from "react-router-dom";
import Button from "../components/Button";
import "./css/RecapitulatifEntreeStock.css";

function RecapitulatifEntreeStock() {
  const { journalId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();

  const journal = location.state?.journal;
  const mouvements = location.state?.mouvements ?? [];
  const emplacements = location.state?.emplacements ?? [];
  const conditionnements = location.state?.conditionnements ?? [];
  const recapitulatifDisponible = Boolean(journal && mouvements.length > 0);

  const obtenirInformationsMouvement = (mouvement) => {
    const detail = journal?.details?.find(
      (element) => element.id === mouvement.detailJournalId,
    );
    const emplacement = emplacements.find(
      (element) => element.id === mouvement.emplacementId,
    );
    const conditionnement = conditionnements.find(
      (element) => element.articleId === detail?.articleId,
    );

    return {
      nomArticle: detail?.nomArticle ?? "Article inconnu",
      nomConditionnement:
        conditionnement?.nomConditionnement ?? "conditionnements",
      destination: mouvement.enReserve
        ? "Reserve"
        : emplacement?.nomEmplacement ?? "Emplacement inconnu",
      nomRack: mouvement.enReserve ? "" : emplacement?.nomRack ?? "",
    };
  };

  const totalConditionnements = mouvements.reduce(
    (total, mouvement) => total + mouvement.nombreConditionnements,
    0,
  );
  const totalPieces = mouvements.reduce(
    (total, mouvement) => total + mouvement.quantitePiecesReelle,
    0,
  );
  const totalReserve = mouvements
    .filter((mouvement) => mouvement.enReserve)
    .reduce(
      (total, mouvement) => total + mouvement.nombreConditionnements,
      0,
    );
  const nombreEmplacements = new Set(
    mouvements
      .filter((mouvement) => !mouvement.enReserve)
      .map((mouvement) => mouvement.emplacementId),
  ).size;
  const dateMouvement = mouvements[0]?.dateMouvement
    ? new Date(mouvements[0].dateMouvement).toLocaleString("fr-FR")
    : "-";

  if (!recapitulatifDisponible) {
    return (
      <main className="recap-page recap-unavailable">
        <section className="recap-unavailable-card">
          <span className="recap-kicker">Recapitulatif indisponible</span>
          <h1>Les donnees de confirmation ne sont plus en memoire</h1>
          <p>
            Cette page affiche la reponse recue juste apres l'entree en stock.
            Revenez au journal pour consulter l'operation.
          </p>
          <div className="recap-actions">
            <Button
              variant="primary"
              onClick={() => navigate(`/journaux-mouvements/${journalId}`)}
            >
              Revenir au journal
            </Button>
          </div>
        </section>
      </main>
    );
  }

  return (
    <main className="recap-page">
      <div className="recap-container">
        <header className="recap-header">
          <div>
            <span className="recap-kicker">Entree en stock terminee</span>
            <h1>Recapitulatif de l'affectation</h1>
            <p>
              Les mouvements ont ete enregistres et le stock a ete mis a jour.
            </p>
          </div>

          <div className="recap-actions">
            <Button
              variant="secondary"
              onClick={() => navigate("/journaux-mouvements")}
            >
              Liste des journaux
            </Button>
            <Button
              variant="primary"
              onClick={() => navigate(`/journaux-mouvements/${journalId}`)}
            >
              Revenir au journal
            </Button>
          </div>
        </header>

        <section className="recap-operation">
          <div>
            <span>Journal de reception</span>
            <strong>{journal.reference}</strong>
          </div>
          <div>
            <span>Etat de l'operation</span>
            <strong className="recap-confirmed"><i /> Confirmee</strong>
          </div>
          <div>
            <span>Date du mouvement</span>
            <strong>{dateMouvement}</strong>
          </div>
        </section>

        <section className="recap-stats">
          <article>
            <span>Mouvements crees</span>
            <strong>{mouvements.length}</strong>
          </article>
          <article>
            <span>Conditionnements traites</span>
            <strong>{totalConditionnements}</strong>
          </article>
          <article>
            <span>Pieces enregistrees</span>
            <strong>{totalPieces}</strong>
          </article>
          <article className={totalReserve > 0 ? "reserve-stat" : ""}>
            <span>Places en reserve</span>
            <strong>{totalReserve}</strong>
          </article>
          <article>
            <span>Emplacements utilises</span>
            <strong>{nombreEmplacements}</strong>
          </article>
        </section>

        <section className="recap-details">
          <div className="recap-section-head">
            <div>
              <h2>Detail des mouvements</h2>
              <p>Repartition definitive des produits dans l'entrepot.</p>
            </div>
            <span>{mouvements.length} lignes</span>
          </div>

          <div className="recap-table-wrapper">
            <table className="recap-table">
              <thead>
                <tr>
                  <th>Article</th>
                  <th>Destination</th>
                  <th>Conditionnements</th>
                  <th>Pieces</th>
                  <th>Statut</th>
                </tr>
              </thead>
              <tbody>
                {mouvements.map((mouvement) => {
                  const informations =
                    obtenirInformationsMouvement(mouvement);

                  return (
                    <tr key={mouvement.mouvementStockId}>
                      <td>
                        <strong>{informations.nomArticle}</strong>
                        <span>
                          Detail journal {mouvement.detailJournalId}
                        </span>
                      </td>
                      <td>
                        <strong>{informations.destination}</strong>
                        {informations.nomRack && (
                          <span>{informations.nomRack}</span>
                        )}
                      </td>
                      <td>
                        <strong>{mouvement.nombreConditionnements}</strong>
                        <span>{informations.nomConditionnement}</span>
                      </td>
                      <td>{mouvement.quantitePiecesReelle}</td>
                      <td>
                        <span
                          className={`recap-badge ${
                            mouvement.enReserve ? "reserve" : "stored"
                          }`}
                        >
                          {mouvement.enReserve ? "En reserve" : "Range"}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>

        {totalReserve > 0 && (
          <section className="recap-reserve-note">
            <div>
              <h2>Quantite placee en reserve</h2>
              <p>
                {totalReserve} conditionnements n'ont pas ete associes a un
                emplacement et restent disponibles pour une affectation
                ulterieure.
              </p>
            </div>
          </section>
        )}
      </div>
    </main>
  );
}

export default RecapitulatifEntreeStock;
