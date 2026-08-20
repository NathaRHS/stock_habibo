import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

const STATUT_VALIDE = 2;
const STATUT_MODIFIE = 3;

function ListeJournal() {
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [journaux, setJournaux] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const token = getAccessToken();
  const [statutChoisi, setStatutChoisi] = useState("");
  // const [JournalSelectionne,setJournalSelectionne] = useState();

  const [detailJournal, setDetailJournal] = useState([]);

  const takeAllDetailJournal = async () => {
    try {
      const response = await fetch(
        `${springUrl}/journaux-mouvements/detailJournal`,
        {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        },
      );
      console.log(response);
      if (!response.ok) {
        throw new Error("Detail indisponible");
      }
      const data = await response.json();
      setDetailJournal(data);
    } catch (err) {
      console.log(err);
    }
  };

  useEffect(() => {
    const getAllJournaux = async () => {
      if (!token) {
        setError("Connectez-vous pour consulter les journaux.");
        setLoading(false);
        return;
      }

      try {
        setError("");
        const response = await fetch(`${springUrl}/journaux-mouvements`, {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error(
            `Impossible de récupérer les journaux (${response.status})`,
          );
        }

        setJournaux(await response.json());
      } catch (requestError) {
        setError(
          requestError instanceof Error
            ? requestError.message
            : "Impossible de se connecter au serveur.",
        );
      } finally {
        setLoading(false);
      }
    };

    getAllJournaux();
    takeAllDetailJournal();
  }, [springUrl]);

  const updateStatut = async (idJournal, idStatut) => {
    if (!token) {
      setError("Votre session a expiré. Reconnectez-vous.");
      return;
    }

    try {
      setError("");
      setUpdatingId(idJournal);

      const response = await fetch(
        `${springUrl}/journaux-mouvements/${idJournal}/statut`,
        {
          method: "PUT",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ statutId: idStatut }),
        },
      );

      if (!response.ok) {
        throw new Error(
          `Impossible de modifier le statut (${response.status})`,
        );
      }

      const journalActualise = await response.json();
      setJournaux((journauxActuels) =>
        journauxActuels.map((journal) =>
          journal.id === idJournal ? journalActualise : journal,
        ),
      );
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Impossible de modifier le statut.",
      );
    } finally {
      setUpdatingId(null);
    }
  };

  if (loading) return <p>Chargement...</p>;

  return (
    <>
      {error && <p role="alert">{error}</p>}

      <div className="table-section" style={{ display: "flex" }}>
        <table border={1}>
          <thead>
            <tr>
              <th>Référence</th>
              <th>Pièce jointe</th>
              <th>Client</th>
              <th>Fournisseur</th>
              <th>Type de mouvement</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>

          <tbody>
            {journaux.map((journal) => (
              <tr key={journal.id}>
                <td>{journal.reference}</td>
                <td>{journal.urlPieceJointe}</td>
                <td>{journal.nomClient}</td>
                <td>{journal.fournisseur}</td>
                <td>{journal.typeMouvementJournal}</td>
                <td>{journal.statut}</td>
                <td>
                  <select
                    value={journal.statutJournalMouvementId ?? ""}
                    disabled={updatingId === journal.id}
                    onChange={(event) =>
                      updateStatut(journal.id, Number(event.target.value))
                    }
                  >
                    <option value="" disabled>
                      Choisir un statut
                    </option>

                    <option value={STATUT_VALIDE}>Validé</option>

                    <option value={STATUT_MODIFIE}>Modifié</option>
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="table-section">
        <table border={1}>
          <thead>
            <tr>
              <th>Nom produit</th>
              <th>Quantite</th>
              <th>Référence</th>
            </tr>
          </thead>

          <tbody>
            {detailJournal.map((dt) => (
              <tr key={dt.id}>
                <td>{dt.nomArticle}</td>
                <td>{dt.quantite}</td>
                <td>{dt.reference}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}

export default ListeJournal;
